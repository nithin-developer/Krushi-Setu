"""
Conversation Memory — MongoDB Persistence

Stores full conversation history permanently in MongoDB for analytics
and historical context. Provides selective retrieval of recent/relevant
turns for LLM prompt injection.
"""

import logging
from datetime import datetime, timezone
from typing import List, Optional
from dataclasses import dataclass

from bson import ObjectId

from app.db.mongodb import get_db

logger = logging.getLogger(__name__)


@dataclass
class ConversationTurn:
    """A single turn in a conversation."""
    role: str  # "user" or "assistant"
    content: str
    timestamp: str
    intent: str = ""
    confidence: float = 0.0
    context_used: dict = None
    sources: list = None

    def __post_init__(self):
        if self.context_used is None:
            self.context_used = {}
        if self.sources is None:
            self.sources = []


class ConversationMemory:
    """
    Manages conversation persistence in MongoDB.
    
    Design principle: Store everything permanently, but retrieve selectively.
    - Full history is always available for analytics dashboards
    - LLM prompts only get the most recent N turns for coherence
    """

    COLLECTION = "conversations"

    @classmethod
    def _get_collection(cls):
        db = get_db()
        if db is None:
            return None
        return db[cls.COLLECTION]

    @classmethod
    async def create_conversation(cls, farmer_id: str, language: str = "kn") -> str:
        """
        Create a new conversation session.
        
        Returns:
            The conversation_id (string ObjectId or fallback UUID).
        """
        collection = cls._get_collection()
        if collection is None:
            import uuid
            fallback_id = str(uuid.uuid4())
            logger.warning(f"MongoDB not connected. Generated ephemeral conversation_id: {fallback_id}")
            return fallback_id

        now = datetime.now(timezone.utc)

        doc = {
            "farmer_id": farmer_id,
            "language": language,
            "created_at": now,
            "updated_at": now,
            "turns": [],
            "metadata": {
                "total_turns": 0,
                "intents_detected": [],
                "farmer_location": "",
            },
        }

        result = await collection.insert_one(doc)
        conversation_id = str(result.inserted_id)
        logger.info(f"Created conversation {conversation_id} for farmer {farmer_id}")
        return conversation_id

    @classmethod
    async def add_turn(
        cls,
        conversation_id: str,
        user_message: str,
        ai_response: str,
        intent: str = "",
        confidence: float = 0.0,
        context_used: Optional[dict] = None,
        sources: Optional[list] = None,
    ):
        """
        Save a complete conversation turn (user message + AI response).
        
        Both messages are saved as separate turn entries within the
        same conversation document. Metadata is updated atomically.
        """
        collection = cls._get_collection()
        if collection is None:
            logger.warning("MongoDB not connected. Turn not saved.")
            return
        now = datetime.now(timezone.utc)

        user_turn = {
            "role": "user",
            "content": user_message,
            "timestamp": now.isoformat(),
            "intent": intent,
            "confidence": confidence,
        }

        assistant_turn = {
            "role": "assistant",
            "content": ai_response,
            "timestamp": now.isoformat(),
            "context_used": context_used or {},
            "sources": sources or [],
        }

        try:
            await collection.update_one(
                {"_id": ObjectId(conversation_id)},
                {
                    "$push": {
                        "turns": {"$each": [user_turn, assistant_turn]},
                    },
                    "$inc": {"metadata.total_turns": 2},
                    "$addToSet": {"metadata.intents_detected": intent},
                    "$set": {"updated_at": now},
                },
            )
            logger.debug(f"Added turn to conversation {conversation_id}: intent={intent}")
        except Exception as e:
            logger.error(f"Failed to save conversation turn: {e}")

    @classmethod
    async def get_recent_turns(
        cls,
        conversation_id: str,
        limit: int = 10,
    ) -> List[ConversationTurn]:
        """
        Get the most recent turns for LLM context injection.
        
        Only retrieves the last `limit` turns (user + assistant pairs)
        to keep the prompt within token limits. Full history remains
        in MongoDB for analytics.
        """
        collection = cls._get_collection()
        if collection is None:
            return []

        try:
            doc = await collection.find_one(
                {"_id": ObjectId(conversation_id)},
                {"turns": {"$slice": -limit}},  # Last N turns
            )
            if not doc or "turns" not in doc:
                return []

            turns = []
            for t in doc["turns"]:
                turns.append(ConversationTurn(
                    role=t.get("role", "user"),
                    content=t.get("content", ""),
                    timestamp=t.get("timestamp", ""),
                    intent=t.get("intent", ""),
                    confidence=t.get("confidence", 0.0),
                    context_used=t.get("context_used", {}),
                    sources=t.get("sources", []),
                ))
            return turns

        except Exception as e:
            logger.error(f"Failed to retrieve conversation turns: {e}")
            return []

    @classmethod
    async def get_conversation(cls, conversation_id: str) -> Optional[dict]:
        """Get a full conversation document by ID."""
        collection = cls._get_collection()
        if collection is None:
            return None
        try:
            doc = await collection.find_one({"_id": ObjectId(conversation_id)})
            if doc:
                doc["_id"] = str(doc["_id"])
            return doc
        except Exception as e:
            logger.error(f"Failed to get conversation: {e}")
            return None

    @classmethod
    async def get_farmer_conversations(
        cls,
        farmer_id: str,
        skip: int = 0,
        limit: int = 20,
    ) -> List[dict]:
        """
        List all conversations for a farmer, sorted by most recent.
        Used by analytics dashboards — returns metadata without full turn data.
        """
        collection = cls._get_collection()
        if collection is None:
            return []
        try:
            cursor = collection.find(
                {"farmer_id": farmer_id},
                {
                    "turns": 0,  # Exclude full turn data for listing
                },
            ).sort("updated_at", -1).skip(skip).limit(limit)

            conversations = await cursor.to_list(length=limit)
            for conv in conversations:
                conv["_id"] = str(conv["_id"])
            return conversations

        except Exception as e:
            logger.error(f"Failed to list farmer conversations: {e}")
            return []

    @classmethod
    async def update_metadata(
        cls,
        conversation_id: str,
        farmer_location: str = "",
    ):
        """Update conversation metadata (e.g., farmer location for analytics)."""
        collection = cls._get_collection()
        if collection is None:
            return
        try:
            update = {}
            if farmer_location:
                update["metadata.farmer_location"] = farmer_location
            if update:
                await collection.update_one(
                    {"_id": ObjectId(conversation_id)},
                    {"$set": update},
                )
        except Exception as e:
            logger.error(f"Failed to update conversation metadata: {e}")
