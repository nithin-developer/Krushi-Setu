"""
AI Orchestrator — The Brain of Krushi Setu

Central coordinator that connects intent detection, context building,
conversation memory, LLM generation, and safety validation into a
single coherent pipeline.

Flow:
    User Message → Intent → Context → History → LLM → Safety → Response

Provides two modes:
    answer()          — Non-streaming for text chat (POST /ai/chat)
    answer_streaming() — Streaming for voice pipeline (sentence-by-sentence)
"""

import logging
from dataclasses import dataclass, field
from typing import Optional, List, AsyncGenerator

from app.services.ai.intent import IntentDetector, IntentResult
from app.services.ai.language import detect_language
from app.services.ai.prompts import build_system_prompt, build_messages, LANGUAGE_NAMES
from app.services.ai.response_generator import ResponseGenerator, StreamingLLMResult
from app.services.ai.safety import SafetyValidator
from app.services.context.context_builder import ContextBuilder
from app.services.conversation.memory import ConversationMemory

logger = logging.getLogger(__name__)

# Lazy-loaded retriever (loads BGE-M3 on first use)
_knowledge_retriever = None


def _get_retriever():
    """Lazy-load the KnowledgeRetriever to avoid loading BGE-M3 on startup."""
    global _knowledge_retriever
    if _knowledge_retriever is None:
        try:
            from app.services.knowledge.retriever import KnowledgeRetriever
            _knowledge_retriever = KnowledgeRetriever()
            logger.info("Knowledge retriever initialized")
        except Exception as e:
            logger.warning(f"Knowledge retriever unavailable: {e}. RAG disabled.")
    return _knowledge_retriever


@dataclass
class AIResponse:
    """Complete response from the AI orchestrator."""
    answer: str
    conversation_id: str
    intent: str
    confidence: float
    language: str = "kn"
    context_used: dict = field(default_factory=dict)
    sources: list = field(default_factory=list)
    token_usage: dict = field(default_factory=dict)


class AIOrchestrator:
    """
    The central brain of Krushi Setu AI.
    
    Coordinates the full pipeline:
    1. Detect intent from the farmer's query
    2. Detect input language from Unicode script
    3. Build query-aware context from Digital Twin + Weather
    4. Load recent conversation history (selective, not full DB)
    5. Construct structured prompt with context
    6. Call Sarvam 105B for the response
    7. Validate response through safety layer
    8. Save the conversation turn permanently to MongoDB
    9. Return structured AIResponse
    """

    def __init__(self):
        self._intent_detector = IntentDetector()
        self._context_builder = ContextBuilder()
        self._response_generator = ResponseGenerator()
        self._safety_validator = SafetyValidator()

    async def answer(
        self,
        farmer_id: str,
        message: str,
        conversation_id: Optional[str] = None,
        language: Optional[str] = None,
    ) -> AIResponse:
        """
        Process a farmer's message and return an AI response (non-streaming).
        
        Args:
            farmer_id: The authenticated farmer's user ID
            message: The farmer's text message (Kannada/English/etc.)
            conversation_id: Optional existing conversation ID for continuity
            language: Optional preferred language code (e.g. "kn", "hi", "kn-IN")
        
        Returns:
            AIResponse with the answer, intent, confidence, and metadata.
        """
        logger.info(f"Orchestrator: processing message from farmer={farmer_id}: {message[:80]}...")

        # ── Step 1: Detect Intent ──────────────────────────────────────
        intent_result: IntentResult = self._intent_detector.detect(message)
        logger.info(f"Intent: {intent_result.intent} (confidence={intent_result.confidence:.2f})")

        # ── Step 2: Detect input language ──────────────────────────────
        detected_language = detect_language(message)

        # ── Step 3: Create or continue conversation ────────────────────
        if not conversation_id:
            conversation_id = await ConversationMemory.create_conversation(
                farmer_id=farmer_id,
            )

        # ── Step 4: Build query-aware context ──────────────────────────
        recent_turns = await ConversationMemory.get_recent_turns(
            conversation_id=conversation_id,
            limit=10,
        )

        conversation_summary = None
        if recent_turns:
            last_user_turns = [t for t in recent_turns if t.role == "user"]
            if last_user_turns:
                conversation_summary = f"Previous topic: {last_user_turns[-1].content[:100]}"

        farmer_context = await self._context_builder.build(
            farmer_id=farmer_id,
            intent=intent_result.intent,
            conversation_summary=conversation_summary,
        )

        # Resolve target language:
        # 1. If message contains Indic script (Kannada, Hindi, etc.), use detected language
        # 2. Else if explicit language was requested, use requested language
        # 3. Else fallback to profile language or default "kn"
        if detected_language and detected_language != "en":
            target_lang = detected_language
        elif language:
            target_lang = language.split("-")[0] if "-" in language else language
        elif farmer_context.farmer.language:
            target_lang = farmer_context.farmer.language
        else:
            target_lang = "kn"
        language = target_lang

        # ── Step 5: RAG — retrieve relevant knowledge chunks ─────────
        kb_chunks = []
        retriever = _get_retriever()
        if retriever:
            try:
                # Map intent to KB category for filtered search
                category_map = {
                    "government_scheme": "government_scheme",
                    "pest_disease": "pest_disease",
                    "fertilizer": "crop_guide",
                    "crop_management": "crop_guide",
                    "soil": "soil_health",
                }
                category = category_map.get(intent_result.intent)
                kb_chunks = retriever.search(
                    query=message,
                    top_k=3,
                    category=category,
                )
                if kb_chunks:
                    logger.info(f"RAG: retrieved {len(kb_chunks)} chunks (top score={kb_chunks[0].score:.3f})")
            except Exception as e:
                logger.warning(f"RAG retrieval failed (non-fatal): {e}")

        # ── Step 6: Build LLM prompt ────────────────────────────────
        system_prompt = build_system_prompt(
            language=language,
            intent=intent_result.intent,
        )

        messages = build_messages(
            system_prompt=system_prompt,
            farmer_context=farmer_context,
            conversation_history=recent_turns,
            user_message=message,
            kb_chunks=kb_chunks,
        )

        # ── Step 7: Generate response ─────────────────────────────
        llm_response = await self._response_generator.generate(messages)

        # ── Step 8: Safety validation ─────────────────────────────────
        safe_response = self._safety_validator.validate(
            response_text=llm_response.text,
            intent=intent_result.intent,
            language=language,
        )

        # ── Step 8: Save conversation turn to MongoDB ─────────────────
        context_summary = self._build_context_summary(farmer_context)
        source_titles = [
            f"{c.document_title}" + (f" ({c.section_heading})" if c.section_heading else "")
            for c in kb_chunks
        ]

        await ConversationMemory.add_turn(
            conversation_id=conversation_id,
            user_message=message,
            ai_response=safe_response,
            intent=intent_result.intent,
            confidence=intent_result.confidence,
            context_used=context_summary,
            sources=source_titles,
        )

        if farmer_context.farmer.district:
            await ConversationMemory.update_metadata(
                conversation_id=conversation_id,
                farmer_location=f"{farmer_context.farmer.district}, {farmer_context.farmer.state}",
            )

        # ── Step 9: Return structured response ────────────────────────
        return AIResponse(
            answer=safe_response,
            conversation_id=conversation_id,
            intent=intent_result.intent,
            confidence=intent_result.confidence,
            language=language,
            context_used=context_summary,
            sources=source_titles,
            token_usage={
                "prompt_tokens": llm_response.prompt_tokens,
                "completion_tokens": llm_response.completion_tokens,
                "total_tokens": llm_response.total_tokens,
            },
        )

    async def answer_streaming(
        self,
        farmer_id: str,
        message: str,
        conversation_id: Optional[str] = None,
        language: Optional[str] = None,
    ) -> AsyncGenerator[str, None]:
        """
        Process a farmer's message and yield response sentences as they stream.
        
        Used by the voice pipeline for low-latency TTS. Steps 1-4 (intent,
        language, context, history) run the same as answer(). Step 5 uses
        streaming generation. Steps 6-7 (safety, save) run after streaming
        completes.
        
        Also stores the last AIResponse and conversation_id for the caller
        to access after iteration:
            self.last_response — the final AIResponse
            self.last_conversation_id — the conversation ID used
        
        Yields:
            Complete sentences suitable for TTS.
        """
        logger.info(f"Orchestrator (streaming): processing from farmer={farmer_id}: {message[:80]}...")

        # ── Steps 1-4: Same as non-streaming ──────────────────────────
        intent_result: IntentResult = self._intent_detector.detect(message)
        detected_language = detect_language(message)

        if not conversation_id:
            conversation_id = await ConversationMemory.create_conversation(
                farmer_id=farmer_id,
            )

        # Store for caller access
        self.last_conversation_id = conversation_id

        recent_turns = await ConversationMemory.get_recent_turns(
            conversation_id=conversation_id,
            limit=10,
        )

        conversation_summary = None
        if recent_turns:
            last_user_turns = [t for t in recent_turns if t.role == "user"]
            if last_user_turns:
                conversation_summary = f"Previous topic: {last_user_turns[-1].content[:100]}"

        farmer_context = await self._context_builder.build(
            farmer_id=farmer_id,
            intent=intent_result.intent,
            conversation_summary=conversation_summary,
        )

        # Resolve target language:
        # 1. If message contains Indic script (Kannada, Hindi, etc.), use detected language
        # 2. Else if explicit language was requested, use requested language
        # 3. Else fallback to profile language or default "kn"
        if detected_language and detected_language != "en":
            target_lang = detected_language
        elif language:
            target_lang = language.split("-")[0] if "-" in language else language
        elif farmer_context.farmer.language:
            target_lang = farmer_context.farmer.language
        else:
            target_lang = "kn"
        language = target_lang

        # ── Step 5: RAG — retrieve knowledge chunks ───────────────────
        kb_chunks = []
        retriever = _get_retriever()
        if retriever:
            try:
                category_map = {
                    "government_scheme": "government_scheme",
                    "pest_disease": "pest_disease",
                    "fertilizer": "crop_guide",
                    "crop_management": "crop_guide",
                    "soil": "soil_health",
                }
                category = category_map.get(intent_result.intent)
                kb_chunks = retriever.search(
                    query=message,
                    top_k=3,
                    category=category,
                )
                if kb_chunks:
                    logger.info(f"RAG (streaming): {len(kb_chunks)} chunks retrieved")
            except Exception as e:
                logger.warning(f"RAG retrieval failed (non-fatal): {e}")

        # ── Step 6: Build prompt ──────────────────────────────────────
        system_prompt = build_system_prompt(
            language=language,
            intent=intent_result.intent,
        )

        messages = build_messages(
            system_prompt=system_prompt,
            farmer_context=farmer_context,
            conversation_history=recent_turns,
            user_message=message,
            kb_chunks=kb_chunks,
        )

        # ── Step 6: Stream generation ─────────────────────────────────
        streaming_result = StreamingLLMResult()
        full_text_parts = []

        async for sentence in self._response_generator.generate_streaming(
            messages=messages,
            result=streaming_result,
        ):
            full_text_parts.append(sentence)
            yield sentence

        # ── Step 7: Post-stream safety + save ─────────────────────────
        full_text = " ".join(full_text_parts)
        safe_response = self._safety_validator.validate(
            response_text=full_text,
            intent=intent_result.intent,
            language=language,
        )

        context_summary = self._build_context_summary(farmer_context)

        await ConversationMemory.add_turn(
            conversation_id=conversation_id,
            user_message=message,
            ai_response=safe_response,
            intent=intent_result.intent,
            confidence=intent_result.confidence,
            context_used=context_summary,
            sources=[],
        )

        if farmer_context.farmer.district:
            await ConversationMemory.update_metadata(
                conversation_id=conversation_id,
                farmer_location=f"{farmer_context.farmer.district}, {farmer_context.farmer.state}",
            )

        # Store for caller access
        self.last_response = AIResponse(
            answer=safe_response,
            conversation_id=conversation_id,
            intent=intent_result.intent,
            confidence=intent_result.confidence,
            context_used=context_summary,
            sources=[],
            token_usage={
                "prompt_tokens": streaming_result.prompt_tokens,
                "completion_tokens": streaming_result.completion_tokens,
                "total_tokens": streaming_result.total_tokens,
            },
        )

    def _build_context_summary(self, context) -> dict:
        """
        Build a minimal summary of what context was used.
        Stored with each conversation turn for analytics/debugging.
        """
        summary = {}

        if context.farmer.district:
            summary["location"] = f"{context.farmer.district}, {context.farmer.state}"

        if context.crop and context.crop.name:
            crop_summary = {"name": context.crop.name}
            if context.crop.growth_stage:
                crop_summary["stage"] = context.crop.growth_stage
            summary["crop"] = crop_summary

        if context.weather and context.weather.current:
            w = context.weather.current
            weather_summary = {}
            if w.temperature_c is not None:
                weather_summary["temperature_c"] = w.temperature_c
            if w.humidity_percent is not None:
                weather_summary["humidity_percent"] = w.humidity_percent
            if w.precipitation_mm is not None:
                weather_summary["precipitation_mm"] = w.precipitation_mm
            if weather_summary:
                summary["weather"] = weather_summary

        if context.farm:
            farm_summary = {}
            if context.farm.area_value > 0:
                farm_summary["area"] = f"{context.farm.area_value} {context.farm.area_unit}"
            if context.farm.water_sources:
                farm_summary["water_sources"] = context.farm.water_sources
            if farm_summary:
                summary["farm"] = farm_summary

        return summary

    async def close(self):
        """Clean up resources."""
        await self._response_generator.close()
