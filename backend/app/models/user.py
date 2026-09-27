from datetime import datetime, timezone
from bson import ObjectId
from app.db.mongodb import get_db
from typing import Optional

class UserModel:
    collection_name = "users"

    @classmethod
    def get_collection(cls):
        db = get_db()
        if db is None:
            return None
        return db[cls.collection_name]

    @classmethod
    async def get_by_email(cls, email: str):
        collection = cls.get_collection()
        if collection is None or not email:
            return None
        user = await collection.find_one({"email": email})
        if user:
            user["_id"] = str(user["_id"])
        return user
        
    @classmethod
    async def get_by_google_id(cls, google_id: str):
        collection = cls.get_collection()
        if collection is None or not google_id:
            return None
        user = await collection.find_one({"google_id": google_id})
        if user:
            user["_id"] = str(user["_id"])
        return user

    @classmethod
    async def get_by_id(cls, user_id: Optional[str]):
        if not user_id:
            return None
        collection = cls.get_collection()
        if collection is None:
            return None
        try:
            user = await collection.find_one({"_id": ObjectId(user_id)})
            if user:
                user["_id"] = str(user["_id"])
            return user
        except Exception:
            return None

    @classmethod
    async def create_user(cls, user_data: dict):
        collection = cls.get_collection()
        
        now = datetime.now(timezone.utc)
        user_data["created_at"] = now
        user_data["updated_at"] = now
        user_data["status"] = "active"
        user_data["profile_completed"] = False
        
        if "password" in user_data:
            user_data.pop("password")
            
        result = await collection.insert_one(user_data)
        created_user = await cls.get_by_id(str(result.inserted_id))
        return created_user

    @classmethod
    async def update_last_login(cls, user_id: str):
        collection = cls.get_collection()
        now = datetime.now(timezone.utc)
        await collection.update_one(
            {"_id": ObjectId(user_id)}, 
            {"$set": {"last_login": now, "updated_at": now}}
        )

    @classmethod
    async def update_digital_twin_profile(cls, user_id: str, profile_data: dict):
        collection = cls.get_collection()
        now = datetime.now(timezone.utc)
        await collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": {
                "digital_twin": profile_data,
                "profile_completed": True,
                "updated_at": now
            }}
        )

    @classmethod
    async def update_user_profile(cls, user_id: str, update_data: dict):
        collection = cls.get_collection()
        now = datetime.now(timezone.utc)
        update_data["updated_at"] = now
        await collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": update_data}
        )
        return await cls.get_by_id(user_id)

    @classmethod
    async def get_all_users(cls, skip: int = 0, limit: int = 10, search: Optional[str] = None, status_filter: Optional[str] = None):
        collection = cls.get_collection()
        
        query = {}
        if search:
            query["$or"] = [
                {"full_name": {"$regex": search, "$options": "i"}},
                {"email": {"$regex": search, "$options": "i"}}
            ]
        if status_filter:
            query["status"] = status_filter
            
        users = await collection.find(query).skip(skip).limit(limit).sort("created_at", -1).to_list(length=limit)
        for user in users:
            user["_id"] = str(user["_id"])
        return users

    @classmethod
    async def count_users(cls, search: Optional[str] = None, status_filter: Optional[str] = None):
        collection = cls.get_collection()
        
        query = {}
        if search:
            query["$or"] = [
                {"full_name": {"$regex": search, "$options": "i"}},
                {"email": {"$regex": search, "$options": "i"}}
            ]
        if status_filter:
            query["status"] = status_filter
            
        return await collection.count_documents(query)

