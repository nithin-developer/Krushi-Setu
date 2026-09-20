"""
Conversation MongoDB Model

Data access layer for the conversations collection.
Provides static methods for CRUD operations on conversation documents.
"""

from datetime import datetime, timezone
from typing import Optional, List

from bson import ObjectId

from app.db.mongodb import get_db


class ConversationModel:
    """
    MongoDB model for the conversations collection.
    
    Document structure:
    {
        "_id": ObjectId,
        "farmer_id": str,
        "language": str,
        "created_at": datetime,
        "updated_at": datetime,
        "turns": [
            {
                "role": "user" | "assistant",
                "content": str,
                "timestamp": str (ISO),
                "intent": str,
                "confidence": float,
                "context_used": dict,
                "sources": list,
            }
        ],
        "metadata": {
            "total_turns": int,
            "intents_detected": [str],
            "farmer_location": str,
        }
    }
    """

    collection_name = "conversations"

    @classmethod
    def get_collection(cls):
        db = get_db()
        return db[cls.collection_name]

    @classmethod
    async def get_by_id(cls, conversation_id: str) -> Optional[dict]:
        collection = cls.get_collection()
        try:
            doc = await collection.find_one({"_id": ObjectId(conversation_id)})
            if doc:
                doc["_id"] = str(doc["_id"])
            return doc
        except Exception:
            return None

    @classmethod
    async def get_farmer_conversations(
        cls,
        farmer_id: str,
        skip: int = 0,
        limit: int = 20,
    ) -> List[dict]:
        """List conversations for a farmer (without full turn data)."""
        collection = cls.get_collection()
        cursor = collection.find(
            {"farmer_id": farmer_id},
            {"turns": 0},  # Exclude turns for listing
        ).sort("updated_at", -1).skip(skip).limit(limit)

        conversations = await cursor.to_list(length=limit)
        for conv in conversations:
            conv["_id"] = str(conv["_id"])
        return conversations

    @classmethod
    async def count_farmer_conversations(cls, farmer_id: str) -> int:
        collection = cls.get_collection()
        return await collection.count_documents({"farmer_id": farmer_id})

    @classmethod
    async def count_all_conversations(cls) -> int:
        """Total conversations across all farmers (for admin analytics)."""
        collection = cls.get_collection()
        return await collection.count_documents({})

    @classmethod
    async def get_recent_conversations(
        cls, limit: int = 50
    ) -> List[dict]:
        """Get most recent conversations across all farmers (admin analytics)."""
        collection = cls.get_collection()
        cursor = collection.find(
            {},
            {"turns": {"$slice": -2}},  # Only last turn pair
        ).sort("updated_at", -1).limit(limit)

        conversations = await cursor.to_list(length=limit)
        for conv in conversations:
            conv["_id"] = str(conv["_id"])
        return conversations
