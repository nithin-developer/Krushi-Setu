from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.api.endpoints import auth, profile, voice, chat, admin_auth, admin_users, admin_analytics, admin_management, locations, knowledge, health
from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.models.admin import AdminModel
from app.core.security import get_password_hash
import traceback
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS: allow_origins=["*"] with allow_credentials=True is invalid per browser CORS spec.
# Use allow_origin_regex to match all origins while keeping credentials support.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r".*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handler to ensure unhandled errors return JSON (with CORS headers)
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    traceback.print_exc()
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )

@app.on_event("startup")
async def startup_db_client():
    await connect_to_mongo()
    # Check and auto-seed default super-admin if no admins exist
    try:
        admin_count = await AdminModel.count_admins()
        if admin_count == 0:
            default_admin = {
                "full_name": "Krushi Setu Super Admin",
                "email": "admin@krushisetu.com",
                "role": "super_admin",
                "password_hash": get_password_hash("Admin@123"),
            }
            await AdminModel.create_admin(default_admin)
            logging.info("Initialized default super-admin account: admin@krushisetu.com")
    except Exception as e:
        logging.warning(f"Could not auto-seed admin on startup: {e}")

@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(profile.router, prefix=f"{settings.API_V1_STR}/profile", tags=["profile"])
app.include_router(voice.router, prefix=f"{settings.API_V1_STR}/voice", tags=["voice"])
app.include_router(chat.router, prefix=f"{settings.API_V1_STR}/ai", tags=["ai"])
app.include_router(admin_auth.router, prefix=f"{settings.API_V1_STR}/admin/auth", tags=["admin-auth"])
app.include_router(admin_users.router, prefix=f"{settings.API_V1_STR}/admin", tags=["admin-users"])
app.include_router(admin_analytics.router, prefix=f"{settings.API_V1_STR}/admin/analytics", tags=["admin-analytics"])
app.include_router(admin_management.router, prefix=f"{settings.API_V1_STR}/admin", tags=["admin-management"])
app.include_router(knowledge.router, prefix=f"{settings.API_V1_STR}/admin/knowledge", tags=["admin-knowledge"])
app.include_router(health.router, prefix=f"{settings.API_V1_STR}/health", tags=["health"])
app.include_router(locations.router, prefix=f"{settings.API_V1_STR}/locations", tags=["locations"])

@app.get("/")
def root():
    return {"message": "Welcome to Krushi Setu API"}
