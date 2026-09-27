"""
Sarvam AI Text-to-Speech (Bulbul v3) — REST Client

Converts text to speech audio using Sarvam's TTS REST API.
Returns base64-encoded WAV audio for each text chunk.
"""

import re
import base64
import logging
from typing import Optional

import httpx

from app.core.config import settings
from app.services.voice.kannada_formatter import KannadaSpokenFormatter

logger = logging.getLogger(__name__)

SARVAM_TTS_URL = "https://api.sarvam.ai/text-to-speech"

# Language to voice mapping — using natural-sounding Bulbul v3 voices
LANGUAGE_VOICE_MAP = {
    "kn-IN": "rohan",      # Kannada female voice
    "en-IN": "rohan",      # English Indian female voice
    "hi-IN": "rohan",      # Hindi female voice
    "te-IN": "rohan",      # Telugu female voice
    "ta-IN": "rohan",      # Tamil female voice
    "mr-IN": "rohan",      # Marathi female voice
    "ml-IN": "rohan",      # Malayalam female voice
    "bn-IN": "rohan",      # Bengali female voice
    "gu-IN": "rohan",      # Gujarati female voice
    "pa-IN": "rohan",      # Punjabi female voice
    "od-IN": "rohan",      # Odia female voice
}


class SarvamTTSClient:
    """
    TTS client that converts text to speech using Sarvam's Bulbul v3.
    
    Uses the REST API for simplicity — each call returns a complete
    audio chunk for one sentence, enabling sentence-level streaming.
    """

    def __init__(
        self,
        language_code: str = "kn-IN",
        speaker: Optional[str] = None,
        pace: float = 1.0,
    ):
        self.language_code = language_code
        self.speaker = speaker or LANGUAGE_VOICE_MAP.get(language_code, "kavya")
        self.pace = pace
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

        # Pre-process text for natural speech
        if self.language_code.startswith("kn"):
            spoken_text = KannadaSpokenFormatter.format_for_speech(text)
        else:
            # Strip markdown, asterisks, emojis and extra spaces for other languages
            s = re.sub(r'[*_~`#]', '', text)
            s = re.sub(r'^\s*[-+]\s*', '', s, flags=re.MULTILINE)
            s = re.sub(r'[\U00010000-\U0010ffff\u2600-\u26FF\u2700-\u27BF]', '', s)
            spoken_text = re.sub(r'\s+', ' ', s).strip()

        if not spoken_text:
            return None

        headers = {
            "api-subscription-key": settings.SARVAM_API_KEY,
            "Content-Type": "application/json",
        }

        payload = {
            "inputs": [spoken_text],
            "target_language_code": self.language_code,
            "speaker": self.speaker,
            "model": "bulbul:v3",
            "pace": self.pace,
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
