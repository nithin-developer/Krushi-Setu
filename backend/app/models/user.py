from datetime import datetime, timezone
from bson import ObjectId
from app.db.mongodb import get_db

class UserModel:
    collection_name = "users"

    @classmethod
    def get_collection(cls):
        db = get_db()
        return db[cls.collection_name]

    @classmethod
    async def get_by_email(cls, email: str):
        collection = cls.get_collection()
        user = await collection.find_one({"email": email})
        if user:
            user["_id"] = str(user["_id"])
        return user
        
    @classmethod
    async def get_by_google_id(cls, google_id: str):
        collection = cls.get_collection()
        user = await collection.find_one({"google_id": google_id})
        if user:
            user["_id"] = str(user["_id"])
        return user

    @classmethod
    async def get_by_id(cls, user_id: str):
        collection = cls.get_collection()
        user = await collection.find_one({"_id": ObjectId(user_id)})
        if user:
            user["_id"] = str(user["_id"])
        return user

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

