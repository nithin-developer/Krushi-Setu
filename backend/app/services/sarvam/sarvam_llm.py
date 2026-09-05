"""
Sarvam AI Chat Completion (Sarvam 105B) — Streaming Client

Uses Sarvam's OpenAI-compatible chat completion API with streaming
to generate responses in the farmer's language.
"""

import json
import logging
import re
from typing import AsyncGenerator, List, Dict, Optional

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

SARVAM_CHAT_URL = "https://api.sarvam.ai/v1/chat/completions"

# System prompt for Krushi Setu agricultural AI assistant
KRUSHI_SYSTEM_PROMPT = """You are **Krushi Setu AI**, a friendly and knowledgeable agricultural assistant for Indian farmers.

## Your Role
- You help farmers with crop management, pest control, soil health, irrigation, weather-related decisions, fertilizer recommendations, and market information.
- You speak in the **same language** the farmer uses. If they speak Kannada, respond in Kannada. If Hindi, respond in Hindi. Always match their language.
- Keep responses concise and practical — farmers need actionable advice, not academic lectures.
- Use simple, everyday language that rural farmers can understand easily.

## Agricultural Knowledge Base
You have expertise in:

### Crops & Cultivation
- Major Indian crops: Rice (Paddy), Wheat, Maize, Ragi (Finger Millet), Jowar (Sorghum), Bajra (Pearl Millet)
- Cash crops: Sugarcane, Cotton, Jute, Tobacco, Coffee, Tea, Rubber
- Pulses: Tur (Pigeon pea), Moong (Green gram), Urad (Black gram), Chana (Chickpea), Masoor (Lentil)
- Oilseeds: Groundnut, Mustard, Soybean, Sunflower, Sesame, Castor
- Spices: Turmeric, Chili, Coriander, Cumin, Black pepper, Cardamom
- Vegetables: Tomato, Onion, Potato, Brinjal, Okra, Beans, Cabbage, Cauliflower
- Fruits: Mango, Banana, Papaya, Guava, Pomegranate, Grapes, Coconut, Areca nut (Adike), Cashew
- Plantation: Arecanut, Coconut, Coffee, Rubber, Oil palm

### Soil Management
- Soil types: Black soil, Red soil, Laterite, Alluvial, Sandy, Clay, Loamy
- Soil testing and pH management
- Organic matter improvement
- Green manuring and composting
- Vermicomposting techniques

### Pest & Disease Management (IPM)
- Common pests and their organic/chemical control
- Neem-based pest control
- Biological pest control methods
- Disease identification (yellowing leaves, wilting, spots, rot)
- Fungal, bacterial, and viral disease management
- Integrated Pest Management (IPM) principles

### Fertilizers & Nutrition
- NPK requirements for different crops
- Organic fertilizers: FYM, compost, bone meal, neem cake
- Chemical fertilizers: Urea, DAP, MOP, SSP, complex fertilizers
- Micronutrient deficiency symptoms and corrections
- Foliar sprays and their timing

### Irrigation & Water Management
- Drip irrigation setup and benefits
- Sprinkler irrigation
- Furrow and flood irrigation best practices
- Rainwater harvesting
- Mulching for moisture retention
- Critical irrigation stages for major crops

### Weather & Seasonal Planning
- Kharif season (June–October): Rice, Cotton, Soybean, Groundnut, Maize
- Rabi season (November–March): Wheat, Chickpea, Mustard, Barley
- Zaid season (March–June): Watermelon, Muskmelon, Cucumber, Moong
- Monsoon preparedness
- Drought management strategies
- Frost protection for crops

### Government Schemes (India)
- PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)
- PM Fasal Bima Yojana (Crop Insurance)
- Kisan Credit Card (KCC)
- Soil Health Card Scheme
- PM Krishi Sinchai Yojana (Irrigation)
- e-NAM (National Agriculture Market)
- State-specific schemes for Karnataka, Maharashtra, Tamil Nadu, etc.

### Market Information
- APMC mandi system
- Direct marketing and FPOs
- Minimum Support Price (MSP) concepts
- Storage and post-harvest management
- Value addition techniques

## Response Guidelines
1. First acknowledge the farmer's concern
2. Identify the likely cause based on symptoms described
3. Provide 2-3 practical solutions they can implement immediately
4. Mention preventive measures for the future
5. If the situation sounds serious, recommend consulting their local Krishi Vigyan Kendra (KVK) or agricultural extension officer
6. Keep responses under 150 words for voice — farmers are listening, not reading
7. Use familiar crop names in the local language when possible
"""


class SarvamLLMClient:
    """
    Streaming chat completion client for Sarvam 105B.
    
    Maintains conversation history and yields response text
    in sentence-level chunks for progressive TTS.
    """

    def __init__(self, language_code: str = "kn-IN"):
        self.language_code = language_code
        self.conversation_history: List[Dict[str, str]] = []
        self._http_client = httpx.AsyncClient(timeout=60.0)
        
        language_names = {
            "kn-IN": "Kannada",
            "en-IN": "English",
            "hi-IN": "Hindi",
            "te-IN": "Telugu",
            "ta-IN": "Tamil",
            "mr-IN": "Marathi",
        }
        selected_lang = language_names.get(language_code, "Kannada")
        
        # Initialize with system prompt and strict language constraint
        system_content = KRUSHI_SYSTEM_PROMPT + f"\n\nCRITICAL INSTRUCTION: You MUST respond ONLY in {selected_lang}. Do NOT mix multiple languages. Even if the user asks in English, reply in {selected_lang}. Do not use English words unless absolutely necessary for technical terms."
        
        self.conversation_history.append({
            "role": "system",
            "content": system_content,
        })

    def add_user_message(self, text: str):
        """Add a user message to conversation history."""
        if self.conversation_history and self.conversation_history[-1]["role"] == "user":
            self.conversation_history[-1]["content"] = text
        else:
            self.conversation_history.append({
                "role": "user",
                "content": text,
            })
        # Keep conversation manageable — last 10 turns + system prompt
        if len(self.conversation_history) > 21:
            self.conversation_history = [self.conversation_history[0]] + self.conversation_history[-20:]

    async def generate_response_stream(self, user_text: str) -> AsyncGenerator[str, None]:
        """
        Send user text to Sarvam 105B and yield response in sentence chunks.
        
        Splits on sentence boundaries (. ? ! ।) so each chunk can be
        sent to TTS independently for lower latency.
        """
        self.add_user_message(user_text)

        headers = {
            "api-subscription-key": settings.SARVAM_API_KEY,
            "Content-Type": "application/json",
        }

        payload = {
            "model": "sarvam-105b-conversations",
            "messages": self.conversation_history,
            "stream": True,
            "temperature": 0.7,
            "max_tokens": 350,
        }

        full_response = ""
        sentence_buffer = ""
        # Sentence-ending patterns for Indian languages
        sentence_end_pattern = re.compile(r'[.?!।\n]')

        try:
            async with self._http_client.stream(
                "POST",
                SARVAM_CHAT_URL,
                headers=headers,
                json=payload,
            ) as response:
                if response.status_code != 200:
                    error_body = await response.aread()
                    logger.error(f"Sarvam LLM error {response.status_code}: {error_body}")
                    yield "I'm sorry, I couldn't process your question right now. Please try again."
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
                            
                            # Check if we have a complete sentence
                            if sentence_end_pattern.search(sentence_buffer):
                                # Split on sentence boundaries
                                parts = sentence_end_pattern.split(sentence_buffer)
                                # Find the actual delimiters
                                delimiters = sentence_end_pattern.findall(sentence_buffer)
                                
                                # Yield all complete sentences
                                for i, part in enumerate(parts[:-1]):
                                    delimiter = delimiters[i] if i < len(delimiters) else ""
                                    sentence = (part + delimiter).strip()
                                    if sentence:
                                        yield sentence
                                
                                # Keep the incomplete part in buffer
                                sentence_buffer = parts[-1] if parts else ""
                    
                    except json.JSONDecodeError:
                        continue

            # Yield any remaining text in buffer
            if sentence_buffer.strip():
                yield sentence_buffer.strip()

            # Store assistant response in history
            if full_response:
                self.conversation_history.append({
                    "role": "assistant",
                    "content": full_response,
                })
                logger.info(f"LLM response ({len(full_response)} chars): {full_response[:80]}...")

        except httpx.HTTPError as e:
            logger.error(f"HTTP error calling Sarvam LLM: {e}")
            yield "I'm having trouble connecting. Please try again in a moment."
        except Exception as e:
            logger.error(f"Unexpected error in LLM stream: {e}")
            yield "Something went wrong. Please try again."

    async def close(self):
        """Close the HTTP client."""
        await self._http_client.aclose()
