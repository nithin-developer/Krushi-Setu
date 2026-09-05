"""
Sarvam AI Speech-to-Text (Saaras v3) — Streaming WebSocket Client

Connects to Sarvam's streaming STT WebSocket and forwards audio chunks.
Returns transcribed text when speech ends.
"""

import asyncio
import base64
import json
import logging
from typing import AsyncGenerator, Optional

import websockets

from app.core.config import settings

logger = logging.getLogger(__name__)

# Sarvam STT streaming WebSocket URL
SARVAM_STT_WS_URL = "wss://api.sarvam.ai/speech-to-text-translate/ws"

# Language code mapping
LANGUAGE_CODES = {
    "Kannada": "kn-IN",
    "English": "en-IN",
    "Hindi": "hi-IN",
    "Telugu": "te-IN",
    "Tamil": "ta-IN",
    "Marathi": "mr-IN",
}


class SarvamSTTEvent:
    """Represents an event from the Sarvam STT stream."""

    def __init__(self, event_type: str, data: Optional[dict] = None, transcript: Optional[str] = None):
        self.event_type = event_type  # "speech_start", "speech_end", "transcript", "error"
        self.data = data
        self.transcript = transcript

    def __repr__(self):
        return f"SarvamSTTEvent(type={self.event_type}, transcript={self.transcript})"


class SarvamSTTClient:
    """
    Streaming STT client that connects to Sarvam's WebSocket.
    
    Usage:
        client = SarvamSTTClient(language="kn-IN")
        await client.connect()
        await client.send_audio(audio_chunk_bytes)
        ...
        transcript = await client.get_transcript()
        await client.close()
    """

    def __init__(self, language_code: str = "kn-IN"):
        self.language_code = language_code
        self._ws: Optional[websockets.WebSocketClientProtocol] = None
        self._connected = False
        self._transcript_buffer = ""
        self._receive_task: Optional[asyncio.Task] = None
        self._events: asyncio.Queue[SarvamSTTEvent] = asyncio.Queue()

    async def connect(self):
        """Establish WebSocket connection to Sarvam STT."""
        params = {
            "model": "saaras:v3",
            "language_code": self.language_code,
            "mode": "transcribe",
            "high_vad_sensitivity": "true",
            "vad_signals": "true",
            "sample_rate": "16000",
            "input_audio_codec": "pcm_s16le",
        }
        query_string = "&".join(f"{k}={v}" for k, v in params.items())
        url = f"{SARVAM_STT_WS_URL}?{query_string}"

        headers = {
            "api-subscription-key": settings.SARVAM_API_KEY,
        }

        try:
            self._ws = await websockets.connect(
                url,
                additional_headers=headers,
                ping_interval=20,
                ping_timeout=20,
                close_timeout=10,
            )
            self._connected = True
            self._receive_task = asyncio.create_task(self._receive_loop())
            logger.info(f"Connected to Sarvam STT (lang={self.language_code})")
        except Exception as e:
            logger.error(f"Failed to connect to Sarvam STT: {e}")
            raise

    async def _receive_loop(self):
        """Background task to receive messages from Sarvam STT."""
        try:
            async for message in self._ws:
                try:
                    if isinstance(message, str):
                        data = json.loads(message)
                        await self._handle_message(data)
                    else:
                        # Binary message — unlikely from STT but handle gracefully
                        logger.debug(f"Received binary message from STT: {len(message)} bytes")
                except json.JSONDecodeError:
                    logger.warning(f"Non-JSON message from STT: {message[:100]}")
        except websockets.exceptions.ConnectionClosed as e:
            logger.info(f"STT WebSocket closed: code={e.code}, reason={e.reason}")
        except Exception as e:
            logger.error(f"STT receive error: {e}")
        finally:
            self._connected = False

    async def _handle_message(self, data: dict):
        """Parse and route incoming STT messages."""
        msg_type = data.get("type", "")
        
        if msg_type == "events":
            signal_type = data.get("data", {}).get("signal_type", "")
            if signal_type == "START_SPEECH":
                await self._events.put(SarvamSTTEvent("speech_start", data=data))
                logger.debug("STT: speech_start detected")
            elif signal_type == "END_SPEECH":
                await self._events.put(SarvamSTTEvent("speech_end", data=data))
                logger.debug("STT: speech_end detected")
        elif msg_type == "data":
            transcript = data.get("data", {}).get("transcript", "")
            if transcript:
                self._transcript_buffer = transcript
                await self._events.put(
                    SarvamSTTEvent("transcript", data=data, transcript=transcript)
                )
                logger.info(f"STT transcript: {transcript[:80]}...")
        elif msg_type == "error":
            error_msg = data.get("message", str(data))
            await self._events.put(SarvamSTTEvent("error", data=data))
            logger.error(f"STT error: {error_msg}")
        else:
            logger.debug(f"STT unknown message type: {msg_type} — {str(data)[:100]}")

    async def send_audio(self, audio_bytes: bytes):
        """
        Send raw PCM audio chunk to Sarvam STT.
        
        Args:
            audio_bytes: Raw PCM audio (16kHz, 16-bit, mono)
        """
        if not self._connected or not self._ws:
            logger.warning("Cannot send audio — STT not connected")
            return

        try:
            # Sarvam expects base64-encoded audio in a JSON envelope
            audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")
            message = json.dumps({
                "audio": {
                    "data": audio_b64,
                    "encoding": "audio/wav",
                    "sample_rate": 16000,
                }
            })
            await self._ws.send(message)
        except Exception as e:
            logger.error(f"Failed to send audio to STT: {e}")
            self._connected = False

    async def get_events(self) -> AsyncGenerator[SarvamSTTEvent, None]:
        """Yield STT events as they arrive."""
        while self._connected or not self._events.empty():
            try:
                event = await asyncio.wait_for(self._events.get(), timeout=0.5)
                yield event
            except asyncio.TimeoutError:
                continue

    async def flush(self):
        """Force immediate processing of buffered audio."""
        if self._connected and self._ws:
            try:
                await self._ws.send(json.dumps({"type": "flush"}))
            except Exception as e:
                logger.error(f"Failed to flush STT: {e}")
                self._connected = False

    async def close(self):
        """Close the STT WebSocket connection."""
        self._connected = False
        if self._receive_task and not self._receive_task.done():
            self._receive_task.cancel()
            try:
                await self._receive_task
            except asyncio.CancelledError:
                pass
        if self._ws:
            try:
                await self._ws.close()
            except Exception:
                pass
            self._ws = None
        logger.info("STT connection closed")

    @property
    def is_connected(self) -> bool:
        return self._connected
