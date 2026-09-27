from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from bson import ObjectId
import re
from app.db.mongodb import get_db

class BlogModel:
    collection_name = "blogs"

    @classmethod
    def get_collection(cls):
        db = get_db()
        return db[cls.collection_name]

    @classmethod
    def _format_doc(cls, doc: Dict[str, Any]) -> Dict[str, Any]:
        if doc:
            doc["id"] = str(doc["_id"])
            doc["_id"] = str(doc["_id"])
        return doc

    @classmethod
    async def get_by_id(cls, blog_id: str) -> Optional[Dict[str, Any]]:
        try:
            collection = cls.get_collection()
            doc = await collection.find_one({"_id": ObjectId(blog_id)})
            return cls._format_doc(doc) if doc else None
        except Exception:
            return None

    @classmethod
    async def get_by_slug(cls, slug: str) -> Optional[Dict[str, Any]]:
        collection = cls.get_collection()
        doc = await collection.find_one({"slug": slug})
        return cls._format_doc(doc) if doc else None

    @classmethod
    async def create(cls, blog_data: Dict[str, Any]) -> Dict[str, Any]:
        collection = cls.get_collection()
        now = datetime.now(timezone.utc)

        # Generate base slug from title if not present
        if "slug" not in blog_data or not blog_data["slug"]:
            base_slug = re.sub(r'[^a-z0-9]+', '-', blog_data.get("title", "").lower()).strip('-')
            slug = base_slug
            counter = 1
            while await collection.find_one({"slug": slug}):
                slug = f"{base_slug}-{counter}"
                counter += 1
            blog_data["slug"] = slug

        blog_data["views_count"] = blog_data.get("views_count", 0)
        blog_data["status"] = blog_data.get("status", "published")
        blog_data["created_at"] = now
        blog_data["updated_at"] = now

        result = await collection.insert_one(blog_data)
        return await cls.get_by_id(str(result.inserted_id))

    @classmethod
    async def update(cls, blog_id: str, blog_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        try:
            collection = cls.get_collection()
            now = datetime.now(timezone.utc)
            blog_data["updated_at"] = now

            await collection.update_one(
                {"_id": ObjectId(blog_id)},
                {"$set": blog_data}
            )
            return await cls.get_by_id(blog_id)
        except Exception:
            return None

    @classmethod
    async def delete(cls, blog_id: str) -> bool:
        try:
            collection = cls.get_collection()
            result = await collection.delete_one({"_id": ObjectId(blog_id)})
            return result.deleted_count > 0
        except Exception:
            return False

    @classmethod
    async def list_blogs(
        cls,
        skip: int = 0,
        limit: int = 10,
        category: Optional[str] = None,
        status: Optional[str] = None,
        search: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        collection = cls.get_collection()
        query: Dict[str, Any] = {}

        if category and category.lower() != "all":
            query["category"] = category

        if status and status.lower() != "all":
            query["status"] = status

        if search:
            regex = re.compile(search, re.IGNORECASE)
            query["$or"] = [
                {"title": regex},
                {"summary": regex},
                {"content": regex},
                {"tags": regex},
                {"target_crops": regex}
            ]

        cursor = collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
        docs = await cursor.to_list(length=limit)
        return [cls._format_doc(doc) for doc in docs]

    @classmethod
    async def count_blogs(
        cls,
        category: Optional[str] = None,
        status: Optional[str] = None,
        search: Optional[str] = None
    ) -> int:
        collection = cls.get_collection()
        query: Dict[str, Any] = {}

        if category and category.lower() != "all":
            query["category"] = category

        if status and status.lower() != "all":
            query["status"] = status

        if search:
            regex = re.compile(search, re.IGNORECASE)
            query["$or"] = [
                {"title": regex},
                {"summary": regex},
                {"content": regex},
                {"tags": regex},
                {"target_crops": regex}
            ]

        return await collection.count_documents(query)

    @classmethod
    async def increment_views(cls, blog_id: str) -> None:
        try:
            collection = cls.get_collection()
            await collection.update_one(
                {"_id": ObjectId(blog_id)},
                {"$inc": {"views_count": 1}}
            )
        except Exception:
            pass
