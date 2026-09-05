from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.api.endpoints import auth, profile, voice, admin_auth, admin_users, locations
from app.db.mongodb import connect_to_mongo, close_mongo_connection
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

@app.on_event("shutdown")
async def shutdown_db_client():
    await close_mongo_connection()

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(profile.router, prefix=f"{settings.API_V1_STR}/profile", tags=["profile"])
app.include_router(voice.router, prefix=f"{settings.API_V1_STR}/voice", tags=["voice"])
app.include_router(admin_auth.router, prefix=f"{settings.API_V1_STR}/admin/auth", tags=["admin-auth"])
app.include_router(admin_users.router, prefix=f"{settings.API_V1_STR}/admin", tags=["admin-users"])
app.include_router(locations.router, prefix=f"{settings.API_V1_STR}/locations", tags=["locations"])

@app.get("/")
def root():
    return {"message": "Welcome to Krushi Setu API"}
