"""
Voice Chat WebSocket Endpoint

Handles bidirectional WebSocket communication between the Flutter app
and the Voice Session Manager. Supports both JSON control messages
and binary audio frames.
"""

import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from jose import jwt, JWTError

from app.core.config import settings
from app.services.voice.voice_session import VoiceSession

logger = logging.getLogger(__name__)

router = APIRouter()


async def authenticate_ws(token: str) -> str:
    """
    Validate JWT token from WebSocket query parameter.
    Returns user_id if valid, raises exception otherwise.
    """
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        token_type = payload.get("type")
        if user_id is None or token_type != "access":
            return None
        return user_id
    except JWTError:
        return None


@router.websocket("/ws")
async def voice_websocket(
    websocket: WebSocket,
    token: str = Query(default=None),
):
    """
    Main voice chat WebSocket endpoint.
    
    Connection: ws://host/api/v1/voice/ws?token=<jwt>
    
    Protocol:
        Client → Server:
            - JSON: {"type": "session_start", "language": "Kannada"}
            - Binary: Raw PCM audio frames (16kHz, 16-bit, mono)
            - JSON: {"type": "speech_end"}
            - JSON: {"type": "interrupt"}
            - JSON: {"type": "session_end"}
        
        Server → Client:
            - JSON: {"type": "session_ready", "language": "kn-IN"}
            - JSON: {"type": "transcript", "text": "...", "is_final": true}
            - JSON: {"type": "ai_text", "text": "...", "is_final": false}
            - JSON: {"type": "audio", "data": "<base64>"}
            - JSON: {"type": "state", "state": "listening|processing|speaking"}
            - JSON: {"type": "error", "message": "..."}
    """
    # Authenticate
    user_id = "anonymous"
    if token:
        authenticated_user = await authenticate_ws(token)
        if authenticated_user:
            user_id = authenticated_user
        else:
            logger.warning("WebSocket auth failed — allowing anonymous for dev")

    await websocket.accept()
    logger.info(f"Voice WebSocket connected: user={user_id}")

    session = VoiceSession(websocket=websocket, user_id=user_id)

    try:
        while True:
            # Receive message — can be text (JSON) or bytes (audio)
            message = await websocket.receive()

            if "text" in message:
                # JSON control message
                try:
                    data = json.loads(message["text"])
                    msg_type = data.get("type", "")

                    if msg_type == "session_start":
                        language = data.get("language", "Kannada")
                        await session.start(language=language)

                    elif msg_type == "speech_end":
                        await session.handle_speech_end()

                    elif msg_type == "session_end":
                        await session.close()
                        break

                    else:
                        logger.debug(f"Unknown message type: {msg_type}")

                except json.JSONDecodeError:
                    logger.warning(f"Invalid JSON from client: {message['text'][:100]}")

            elif "bytes" in message:
                # Binary audio frame
                audio_bytes = message["bytes"]
                if audio_bytes:
                    await session.handle_audio(audio_bytes)

    except WebSocketDisconnect:
        logger.info(f"Voice WebSocket disconnected: user={user_id}")
    except Exception as e:
        logger.error(f"Voice WebSocket error: {e}")
    finally:
        await session.close()
        logger.info(f"Voice session cleaned up: user={user_id}")
