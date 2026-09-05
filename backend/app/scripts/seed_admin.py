import asyncio
import logging
from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.models.admin import AdminModel
from app.core.security import get_password_hash

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def seed_admin(
    email: str = "admin@krushisetu.com",
    password: str = "Admin@123",
    full_name: str = "Krushi Setu Super Admin",
    role: str = "super_admin"
):
    await connect_to_mongo()
    try:
        existing = await AdminModel.get_by_email(email)
        if existing:
            logger.info(f"Admin with email '{email}' already exists.")
            return existing

        admin_data = {
            "full_name": full_name,
            "email": email,
            "role": role,
            "password_hash": get_password_hash(password),
        }
        created = await AdminModel.create_admin(admin_data)
        logger.info(f"Successfully seeded super admin: {email} (ID: {created['_id']})")
        return created
    finally:
        await close_mongo_connection()

if __name__ == "__main__":
    asyncio.run(seed_admin())
