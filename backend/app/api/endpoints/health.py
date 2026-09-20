"""
Health & System Diagnostic API Endpoint
GET /api/v1/health

Returns the operational status of backend components:
- MongoDB connection
- Qdrant Vector DB knowledge collection
- Sarvam AI API keys configuration
"""

from fastapi import APIRouter
from app.db.mongodb import get_db
from app.core.config import settings

router = APIRouter()

@router.get("")
async def check_health():
    # 1. MongoDB Status
    mongo_status = "healthy"
    try:
        db = get_db()
        if db is None:
            mongo_status = "disconnected"
        else:
            await db.command("ping")
    except Exception as e:
        mongo_status = f"unhealthy: {str(e)}"

    # 2. Qdrant KB Status
    qdrant_status = "healthy"
    kb_info = {}
    try:
        from app.services.knowledge.retriever import KnowledgeRetriever
        retriever = KnowledgeRetriever()
        kb_info = retriever.get_collection_info()
    except Exception as e:
        qdrant_status = f"unhealthy: {str(e)}"

    # 3. Sarvam API Config
    sarvam_configured = bool(settings.SARVAM_API_KEY and settings.SARVAM_API_KEY != "YOUR_SARVAM_API_KEY")

    is_all_healthy = (mongo_status == "healthy") and (qdrant_status == "healthy") and sarvam_configured

    return {
        "status": "ok" if is_all_healthy else "degraded",
        "services": {
            "mongodb": mongo_status,
            "qdrant_vector_db": {
                "status": qdrant_status,
                "collection": kb_info,
            },
            "sarvam_ai": {
                "configured": sarvam_configured,
                "llm_model": settings.SARVAM_LLM_MODEL,
                "embedding_model": settings.EMBEDDING_MODEL,
            }
        }
    }
