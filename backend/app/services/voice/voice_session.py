"""
Voice Session Manager — Orchestrates the full STT → AI → TTS pipeline.

Each WebSocket connection creates one VoiceSession that manages:
- Audio buffering and forwarding to Sarvam STT
- Transcript handling and forwarding to AI Orchestrator
- AI response streaming and sentence-level TTS
- Barge-in support (user interrupts AI speech)
- State management and client notifications

The AI Orchestrator provides:
- Intent detection (weather, pest, fertilizer, etc.)
- Digital Twin context (farmer's location, crops, farm details)
- Live weather data from Open-Meteo
- Conversation memory (persisted in MongoDB)
- Safety validation on every response
"""

import asyncio
import base64
import json
import logging
from enum import Enum
from typing import Optional

from fastapi import WebSocket

from app.services.sarvam.sarvam_stt import SarvamSTTClient, LANGUAGE_CODES
from app.services.sarvam.sarvam_tts import SarvamTTSClient
from app.services.ai.orchestrator import AIOrchestrator

logger = logging.getLogger(__name__)


class VoiceState(str, Enum):
    IDLE = "idle"
    LISTENING = "listening"
    PROCESSING = "processing"
    SPEAKING = "speaking"


class VoiceSession:
    """
    Manages a single voice conversation session between a farmer and the AI.
    
    Lifecycle:
        1. Client sends session_start with language
        2. Session connects to Sarvam STT
        3. Client sends audio chunks → forwarded to STT
        4. STT returns transcript → sent to AI Orchestrator
        5. Orchestrator: Intent → Context → LLM (streaming) → Safety
        6. Each sentence → TTS → audio streamed back to client
        7. Returns to LISTENING for next turn
    """

    def __init__(self, websocket: WebSocket, user_id: str = "anonymous"):
        self.websocket = websocket
        self.user_id = user_id
        self.language_code = "kn-IN"
        self.language_name = "Kannada"
        self.state = VoiceState.IDLE

        self._stt_client: Optional[SarvamSTTClient] = None
        self._orchestrator: Optional[AIOrchestrator] = None
        self._tts_client: Optional[SarvamTTSClient] = None

        self._conversation_id: Optional[str] = None  # Persistent across turns

        self._is_active = False
        self._is_speaking = False  # True while AI audio is being sent
        self._stt_task: Optional[asyncio.Task] = None
        self._turn_task: Optional[asyncio.Task] = None

    async def start(self, language: str = "Kannada"):
        """Initialize the voice session with the selected language."""
        self.language_name = language
        self.language_code = LANGUAGE_CODES.get(language, "kn-IN")

        # Initialize service clients
        self._orchestrator = AIOrchestrator()
        self._tts_client = SarvamTTSClient(language_code=self.language_code)
        
        self._is_active = True
        await self._set_state(VoiceState.LISTENING)
        
        # Connect to STT
        await self._connect_stt()

        await self._send_json({
            "type": "session_ready",
            "language": self.language_code,
        })
        
        logger.info(f"Voice session started for user={self.user_id}, lang={self.language_code}")

    async def _connect_stt(self):
        """Connect to Sarvam STT and start listening for events."""
        try:
            if self._stt_client:
                try:
                    await self._stt_client.close()
                except Exception:
                    pass

            self._stt_client = SarvamSTTClient(language_code=self.language_code)
            await self._stt_client.connect()
            
            if self._stt_task and not self._stt_task.done():
                self._stt_task.cancel()
            self._stt_task = asyncio.create_task(self._process_stt_events())
        except Exception as e:
            logger.error(f"Failed to connect STT: {e}")
            await self._send_error(f"Failed to start speech recognition: {str(e)}")

    async def _process_stt_events(self):
        """Background task that listens for STT events and processes them."""
        try:
            async for event in self._stt_client.get_events():
                if not self._is_active:
                    break

                elif event.event_type == "speech_start":
                    pass

                elif event.event_type == "transcript":
                    if event.transcript:
                        # Process the transcript
                        logger.info(f"User transcript: {event.transcript}")
                        self._is_speaking = False
                        await self._set_state(VoiceState.LISTENING)

                        # Send transcript to client
                        await self._send_json({
                            "type": "transcript",
                            "text": event.transcript,
                            "is_final": True,
                        })
                        
                        # Process the transcript through AI Orchestrator → TTS pipeline
                        if self._turn_task is None or self._turn_task.done():
                            self._turn_task = asyncio.create_task(self._process_turn(event.transcript))

                elif event.event_type == "speech_end":
                    logger.debug("STT speech_end event")

                elif event.event_type == "error":
                    await self._send_error("Speech recognition error")

        except asyncio.CancelledError:
            logger.info("STT event processing cancelled")
        except Exception as e:
            logger.error(f"Error processing STT events: {e}")

    async def handle_audio(self, audio_bytes: bytes):
        """Handle incoming audio chunk from the client."""
        if not self._is_active:
            return
        
        if self._stt_client is None or not self._stt_client.is_connected:
            logger.info("STT disconnected. Reconnecting...")
            await self._connect_stt()

        if self._stt_client and self._stt_client.is_connected:
            try:
                await self._stt_client.send_audio(audio_bytes)
            except Exception as e:
                logger.error(f"Error sending audio to STT: {e}")

    async def handle_speech_end(self):
        """Client signals end of speech — flush STT."""
        if self._stt_client and self._stt_client.is_connected:
            try:
                await self._stt_client.flush()
            except Exception as e:
                logger.error(f"Error flushing STT: {e}")


    async def _process_turn(self, transcript: str):
        """
        Full turn processing: transcript → AI Orchestrator → TTS → audio.
        
        The orchestrator handles:
        - Intent detection (weather? pest? fertilizer?)
        - Context building (Digital Twin + weather + conversation history)
        - LLM generation (streaming, sentence-by-sentence)
        - Safety validation (post-generation)
        - Conversation persistence (MongoDB)
        
        Each sentence from the orchestrator is sent to TTS immediately
        for low-latency audio streaming.
        """
        await self._set_state(VoiceState.PROCESSING)
        self._is_speaking = True

        try:
            # Notify client that we're understanding the question
            await self._send_json({
                "type": "thinking",
                "message": "understanding",
            })

            full_ai_text = ""
            async for sentence in self._orchestrator.answer_streaming(
                farmer_id=self.user_id,
                message=transcript,
                conversation_id=self._conversation_id,
            ):
                full_ai_text += sentence + " "
                
                # Send AI text chunk to client
                await self._send_json({
                    "type": "ai_text",
                    "text": sentence,
                    "is_final": False,
                })

                # Convert sentence to speech
                await self._set_state(VoiceState.SPEAKING)
                audio_b64 = await self._tts_client.synthesize(sentence)
                
                if audio_b64:
                    await self._send_json({
                        "type": "audio",
                        "data": audio_b64,
                    })

            # Capture the conversation_id for subsequent turns
            if hasattr(self._orchestrator, 'last_conversation_id'):
                self._conversation_id = self._orchestrator.last_conversation_id

            # Send intent info to client (for loading state display)
            if hasattr(self._orchestrator, 'last_response') and self._orchestrator.last_response:
                await self._send_json({
                    "type": "intent",
                    "intent": self._orchestrator.last_response.intent,
                    "confidence": self._orchestrator.last_response.confidence,
                })

            # Signal end of AI response stream
            await self._send_json({
                "type": "ai_text",
                "text": "",
                "is_final": True,
            })

        except asyncio.CancelledError:
            logger.info("Turn processing cancelled due to barge-in")
        except Exception as e:
            logger.error(f"Error in turn processing: {e}")
            await self._send_error("Failed to generate response")
        finally:
            self._is_speaking = False
            if self._is_active:
                await self._set_state(VoiceState.LISTENING)

    async def _set_state(self, state: VoiceState):
        """Update state and notify client."""
        self.state = state
        await self._send_json({
            "type": "state",
            "state": state.value,
        })

    async def _send_json(self, data: dict):
        """Send JSON message to WebSocket client."""
        try:
            await self.websocket.send_json(data)
        except Exception as e:
            logger.error(f"Failed to send to client: {e}")

    async def _send_error(self, message: str):
        """Send error message to client."""
        await self._send_json({
            "type": "error",
            "message": message,
        })

    async def close(self):
        """Clean up all resources."""
        self._is_active = False
        self._is_speaking = False

        if self._stt_task and not self._stt_task.done():
            self._stt_task.cancel()
            try:
                await self._stt_task
            except asyncio.CancelledError:
                pass

        if self._turn_task and not self._turn_task.done():
            self._turn_task.cancel()
            
        if self._stt_client:
            await self._stt_client.close()
            
        if self._orchestrator:
            await self._orchestrator.close()
            
        if self._tts_client:
            await self._tts_client.close()

        logger.info(f"Voice session closed for user={self.user_id}")
