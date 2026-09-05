from datetime import datetime, timezone
from bson import ObjectId
from app.db.mongodb import get_db

class AdminModel:
    collection_name = "admins"

    @classmethod
    def get_collection(cls):
        db = get_db()
        return db[cls.collection_name]

    @classmethod
    async def get_by_email(cls, email: str):
        collection = cls.get_collection()
        admin = await collection.find_one({"email": email})
        if admin:
            admin["_id"] = str(admin["_id"])
        return admin

    @classmethod
    async def get_by_id(cls, admin_id: str):
        collection = cls.get_collection()
        admin = await collection.find_one({"_id": ObjectId(admin_id)})
        if admin:
            admin["_id"] = str(admin["_id"])
        return admin

    @classmethod
    async def create_admin(cls, admin_data: dict):
        collection = cls.get_collection()

        now = datetime.now(timezone.utc)
        admin_data["created_at"] = now
        admin_data["updated_at"] = now
        admin_data["status"] = "active"
        admin_data["last_login"] = None

        result = await collection.insert_one(admin_data)
        created_admin = await cls.get_by_id(str(result.inserted_id))
        return created_admin

    @classmethod
    async def update_last_login(cls, admin_id: str):
        collection = cls.get_collection()
        now = datetime.now(timezone.utc)
        await collection.update_one(
            {"_id": ObjectId(admin_id)},
            {"$set": {"last_login": now, "updated_at": now}}
        )

    @classmethod
    async def get_all_admins(cls, skip: int = 0, limit: int = 10):
        collection = cls.get_collection()
        admins = await collection.find().skip(skip).limit(limit).to_list(length=limit)
        for admin in admins:
            admin["_id"] = str(admin["_id"])
        return admins

    @classmethod
    async def count_admins(cls):
        collection = cls.get_collection()
        return await collection.count_documents({})