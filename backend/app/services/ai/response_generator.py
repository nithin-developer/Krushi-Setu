"""
Response Generator — Sarvam 105B LLM Wrapper

Non-streaming and streaming wrappers for the Sarvam chat completion API.
Non-streaming is used for the text chat endpoint.
Streaming is used for the voice pipeline (sentence-level chunks for TTS).
"""

import json
import logging
import re
from dataclasses import dataclass, field
from typing import List, Optional, AsyncGenerator

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

SARVAM_CHAT_URL = "https://api.sarvam.ai/v1/chat/completions"

# Sentence-ending patterns for Indian languages
SENTENCE_END_PATTERN = re.compile(r'[.?!।\n]')


@dataclass
class LLMResponse:
    """Complete response from the LLM."""
    text: str
    model: str = ""
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    finish_reason: str = ""


@dataclass
class StreamingLLMResult:
    """
    Collects the full result after streaming completes.
    The orchestrator reads this after iterating the stream.
    """
    text: str = ""
    model: str = ""
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    finish_reason: str = ""


class ResponseGenerator:
    """
    Sarvam 105B client for the AI pipeline.
    
    Provides both non-streaming (text chat) and streaming (voice) modes.
    """

    def __init__(self):
        self._http_client = httpx.AsyncClient(timeout=60.0)

    async def generate(
        self,
        messages: List[dict],
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> LLMResponse:
        """
        Send messages to Sarvam 105B and return the complete response.
        
        Args:
            messages: List of message dicts with 'role' and 'content'
            temperature: Override default temperature (0-1)
            max_tokens: Override default max tokens
        
        Returns:
            LLMResponse with the generated text and usage stats.
        """
        headers = {
            "api-subscription-key": settings.SARVAM_API_KEY,
            "Content-Type": "application/json",
        }

        payload = {
            "model": settings.SARVAM_LLM_MODEL,
            "messages": messages,
            "stream": False,
            "temperature": temperature or settings.SARVAM_LLM_TEMPERATURE,
            "max_tokens": max_tokens or settings.SARVAM_LLM_MAX_TOKENS,
        }

        try:
            response = await self._http_client.post(
                SARVAM_CHAT_URL,
                headers=headers,
                json=payload,
            )

            if response.status_code != 200:
                error_body = response.text[:500]
                logger.error(f"Sarvam LLM error {response.status_code}: {error_body}")
                return LLMResponse(
                    text="ಕ್ಷಮಿಸಿ, ನಿಮ್ಮ ಪ್ರಶ್ನೆಗೆ ಉತ್ತರಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
                    finish_reason="error",
                )

            data = response.json()

            # Extract response text
            choices = data.get("choices", [])
            if not choices:
                logger.error("Sarvam LLM returned empty choices")
                return LLMResponse(
                    text="ಕ್ಷಮಿಸಿ, ಉತ್ತರ ಸಿಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಕೇಳಿ.",
                    finish_reason="error",
                )

            message = choices[0].get("message", {})
            raw_content = message.get("content") or ""
            text = raw_content.strip()
            finish_reason = choices[0].get("finish_reason", "")

            # Extract token usage
            usage = data.get("usage", {})

            llm_response = LLMResponse(
                text=text,
                model=data.get("model", settings.SARVAM_LLM_MODEL),
                prompt_tokens=usage.get("prompt_tokens", 0),
                completion_tokens=usage.get("completion_tokens", 0),
                total_tokens=usage.get("total_tokens", 0),
                finish_reason=finish_reason,
            )

            logger.info(
                f"LLM response: {len(text)} chars, "
                f"tokens={llm_response.total_tokens}, "
                f"finish={finish_reason}"
            )
            return llm_response

        except httpx.HTTPError as e:
            logger.error(f"HTTP error calling Sarvam LLM: {e}")
            return LLMResponse(
                text="ಸಂಪರ್ಕದಲ್ಲಿ ಸಮಸ್ಯೆ ಇದೆ. ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಪ್ರಯತ್ನಿಸಿ.",
                finish_reason="error",
            )
        except Exception as e:
            logger.error(f"Unexpected error in LLM call: {e}")
            return LLMResponse(
                text="ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
                finish_reason="error",
            )

    async def generate_streaming(
        self,
        messages: List[dict],
        result: StreamingLLMResult,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
    ) -> AsyncGenerator[str, None]:
        """
        Stream response from Sarvam 105B, yielding complete sentences.
        
        Used by the voice pipeline for low-latency TTS. Each yielded
        string is a complete sentence that can be sent to TTS immediately.
        
        The `result` object is populated with the full response text and
        token usage AFTER the generator is exhausted.
        
        Args:
            messages: Structured message list (system + context + history + user)
            result: StreamingLLMResult to populate with final stats
            temperature: Override default temperature
            max_tokens: Override default max tokens
        
        Yields:
            Complete sentences as they arrive from the LLM stream.
        """
        headers = {
            "api-subscription-key": settings.SARVAM_API_KEY,
            "Content-Type": "application/json",
        }

        payload = {
            "model": settings.SARVAM_LLM_MODEL,
            "messages": messages,
            "stream": True,
            "temperature": temperature or settings.SARVAM_LLM_TEMPERATURE,
            "max_tokens": max_tokens or settings.SARVAM_LLM_MAX_TOKENS,
        }

        full_response = ""
        sentence_buffer = ""

        try:
            async with self._http_client.stream(
                "POST",
                SARVAM_CHAT_URL,
                headers=headers,
                json=payload,
            ) as response:
                if response.status_code != 200:
                    error_body = await response.aread()
                    logger.error(f"Sarvam LLM streaming error {response.status_code}: {error_body}")
                    yield "ಕ್ಷಮಿಸಿ, ಉತ್ತರಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ."
                    return

                async for line in response.aiter_lines():
                    if not line.startswith("data: "):
                        continue

                    data_str = line[6:].strip()
                    if data_str == "[DONE]":
                        break

                    try:
                        chunk_data = json.loads(data_str)
                        choices = chunk_data.get("choices", [])
                        if not choices:
                            continue

                        delta = choices[0].get("delta", {})
                        content = delta.get("content", "")

                        if content:
                            full_response += content
                            sentence_buffer += content

                            # Check for sentence boundaries
                            if SENTENCE_END_PATTERN.search(sentence_buffer):
                                parts = SENTENCE_END_PATTERN.split(sentence_buffer)
                                delimiters = SENTENCE_END_PATTERN.findall(sentence_buffer)

                                for i, part in enumerate(parts[:-1]):
                                    delimiter = delimiters[i] if i < len(delimiters) else ""
                                    sentence = (part + delimiter).strip()
                                    if sentence:
                                        yield sentence

                                sentence_buffer = parts[-1] if parts else ""

                        # Capture model info from first chunk
                        if not result.model and chunk_data.get("model"):
                            result.model = chunk_data["model"]

                        # Check for usage in the final chunk
                        if chunk_data.get("usage"):
                            usage = chunk_data["usage"]
                            result.prompt_tokens = usage.get("prompt_tokens", 0)
                            result.completion_tokens = usage.get("completion_tokens", 0)
                            result.total_tokens = usage.get("total_tokens", 0)

                        finish = choices[0].get("finish_reason")
                        if finish:
                            result.finish_reason = finish

                    except json.JSONDecodeError:
                        continue

            # Yield any remaining text in the buffer
            if sentence_buffer.strip():
                yield sentence_buffer.strip()

            # Populate the result with the full response
            result.text = full_response

            logger.info(
                f"LLM streaming complete: {len(full_response)} chars, "
                f"tokens={result.total_tokens}"
            )

        except httpx.HTTPError as e:
            logger.error(f"HTTP error in LLM streaming: {e}")
            yield "ಸಂಪರ್ಕದಲ್ಲಿ ಸಮಸ್ಯೆ ಇದೆ. ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಪ್ರಯತ್ನಿಸಿ."
        except Exception as e:
            logger.error(f"Unexpected error in LLM streaming: {e}")
            yield "ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ."

    async def close(self):
        """Close the HTTP client."""
        await self._http_client.aclose()
