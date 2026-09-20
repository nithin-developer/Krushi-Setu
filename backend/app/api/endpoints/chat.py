"""
AI Chat Endpoint — Text-based Conversational AI

POST /api/v1/ai/chat

Authenticated endpoint that processes a farmer's text message through
the AI Orchestrator pipeline: Intent → Context → LLM → Safety → Response.
"""

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.schemas.user import UserResponse
from app.schemas.ai import ChatRequest, ChatResponse
from app.services.ai.orchestrator import AIOrchestrator

logger = logging.getLogger(__name__)

router = APIRouter()

# Singleton orchestrator instance — reused across requests
_orchestrator = AIOrchestrator()


@router.post("/chat", response_model=ChatResponse)
async def ai_chat(
    request: ChatRequest,
    current_user: UserResponse = Depends(get_current_user),
):
    """
    Process a farmer's text message and return an AI-generated response.
    
    The response is personalized using the farmer's Digital Twin data
    (location, crops, farm details) and real-time weather information.
    
    - **message**: The farmer's question in any supported language (Kannada, English, Hindi, etc.)
    - **conversation_id**: Optional. Pass an existing conversation ID for follow-up messages.
      If omitted, a new conversation session is created.
    
    Returns the AI answer, detected intent, confidence score, and
    a summary of the context used for the response.
    """
    try:
        result = await _orchestrator.answer(
            farmer_id=current_user.id,
            message=request.message,
            conversation_id=request.conversation_id,
        )

        return ChatResponse(
            answer=result.answer,
            conversation_id=result.conversation_id,
            intent=result.intent,
            confidence=result.confidence,
            context_used=result.context_used,
            sources=result.sources,
        )

    except Exception as e:
        logger.error(f"AI chat error for user={current_user.id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process your message. Please try again.",
        )
