"""
Sarvam AI Text-to-Speech (Bulbul v3) — REST Client

Converts text to speech audio using Sarvam's TTS REST API.
Returns base64-encoded WAV audio for each text chunk.
"""

import base64
import logging
from typing import Optional

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

SARVAM_TTS_URL = "https://api.sarvam.ai/text-to-speech"

# Language to voice mapping — using natural-sounding Bulbul voices
# Sarvam voice IDs may vary; these are reasonable defaults
LANGUAGE_VOICE_MAP = {
    "kn-IN": "anushka",    # Kannada female voice
    "en-IN": "anushka",    # English Indian female voice
    "hi-IN": "anushka",    # Hindi female voice
    "te-IN": "anushka",    # Telugu female voice
    "ta-IN": "anushka",    # Tamil female voice
    "mr-IN": "anushka",    # Marathi female voice
}


class SarvamTTSClient:
    """
    TTS client that converts text to speech using Sarvam's Bulbul v3.
    
    Uses the REST API for simplicity — each call returns a complete
    audio chunk for one sentence, enabling sentence-level streaming.
    """

    def __init__(self, language_code: str = "kn-IN"):
        self.language_code = language_code
        self.speaker = LANGUAGE_VOICE_MAP.get(language_code, "priya")
        self._http_client = httpx.AsyncClient(timeout=30.0)

    async def synthesize(self, text: str) -> Optional[str]:
        """
        Convert text to speech audio.
        
        Args:
            text: The text to convert to speech
            
        Returns:
            Base64-encoded WAV audio string, or None on failure
        """
        if not text or not text.strip():
            return None

        headers = {
            "api-subscription-key": settings.SARVAM_API_KEY,
            "Content-Type": "application/json",
        }

        payload = {
            "inputs": [text],
            "target_language_code": self.language_code,
            "speaker": self.speaker,
            "model": "bulbul:v2",
            "pace": 1.0,
            "speech_sample_rate": 16000,
            "enable_preprocessing": True,
        }

        try:
            response = await self._http_client.post(
                SARVAM_TTS_URL,
                headers=headers,
                json=payload,
            )

            if response.status_code == 200:
                data = response.json()
                audios = data.get("audios", [])
                if audios and len(audios) > 0:
                    audio_b64 = audios[0]
                    logger.info(f"TTS generated audio for: {text[:50]}...")
                    return audio_b64
                else:
                    logger.warning(f"TTS returned empty audio for: {text[:50]}")
                    return None
            else:
                logger.error(f"TTS error {response.status_code}: {response.text[:200]}")
                return None

        except httpx.HTTPError as e:
            logger.error(f"TTS HTTP error: {e}")
            return None
        except Exception as e:
            logger.error(f"TTS unexpected error: {e}")
            return None

    async def close(self):
        """Close the HTTP client."""
        await self._http_client.aclose()
