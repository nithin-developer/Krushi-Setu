import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Krushi Setu Backend"
    API_V1_STR: str = "/api/v1"
    
    # Secret Key for JWT
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-super-secret-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # MongoDB
    MONGODB_URL: str = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    DATABASE_NAME: str = "krushisetu"
    
    # Google Auth
    GOOGLE_CLIENT_ID: str = os.getenv("GOOGLE_CLIENT_ID", "your-google-client-id.apps.googleusercontent.com")
    
    # Sarvam AI
    SARVAM_API_KEY: str = os.getenv("SARVAM_API_KEY", "your-sarvam-api-key")

    # AI Orchestrator — Sarvam 105B
    SARVAM_LLM_MODEL: str = os.getenv("SARVAM_LLM_MODEL", "sarvam-105b-conversations")
    SARVAM_LLM_TEMPERATURE: float = 0.7
    SARVAM_LLM_MAX_TOKENS: int = 500

    # Weather — Open-Meteo (free, no API key needed)
    WEATHER_CACHE_TTL_SECONDS: int = 3600

    # Qdrant Vector DB (local disk mode — no server needed)
    QDRANT_PATH: str = os.getenv("QDRANT_PATH", "./qdrant_data")
    QDRANT_COLLECTION: str = "krushi_knowledge"

    # Embeddings — BGE-M3 (multilingual, 1024-dim)
    EMBEDDING_MODEL: str = "BAAI/bge-m3"
    EMBEDDING_DIMENSION: int = 1024

    # Knowledge Base
    KB_CHUNK_SIZE: int = 500
    KB_CHUNK_OVERLAP: int = 50
    KB_SEARCH_TOP_K: int = 3

    class Config:
        env_file = ".env"

settings = Settings()
