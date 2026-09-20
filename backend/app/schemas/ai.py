"""
Pydantic Schemas for the AI Chat API

Request and response models for POST /api/v1/ai/chat
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any


class ChatRequest(BaseModel):
    """Request body for the AI chat endpoint."""
    message: str = Field(
        ...,
        min_length=1,
        max_length=2000,
        description="The farmer's text message (Kannada, English, or other supported language)",
    )
    conversation_id: Optional[str] = Field(
        default=None,
        description="Existing conversation ID for continuity. If omitted, a new conversation is created.",
    )


class ChatResponse(BaseModel):
    """Response from the AI chat endpoint."""
    answer: str = Field(
        description="The AI-generated response in the farmer's language",
    )
    conversation_id: str = Field(
        description="Conversation ID for follow-up messages",
    )
    intent: str = Field(
        description="Detected intent category (e.g., weather, pest_disease, fertilizer)",
    )
    confidence: float = Field(
        description="Intent detection confidence score (0-1)",
    )
    context_used: Dict[str, Any] = Field(
        default_factory=dict,
        description="Summary of context injected into the LLM prompt (location, crop, weather)",
    )
    sources: List[str] = Field(
        default_factory=list,
        description="Knowledge base sources used (populated when RAG is enabled)",
    )
