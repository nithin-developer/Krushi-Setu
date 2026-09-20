"""
Knowledge Retriever — Qdrant Vector Search

Searches the knowledge base using semantic similarity.
Embeds the query with BGE-M3, searches Qdrant, and returns
the most relevant document chunks with scores.
"""

import logging
from dataclasses import dataclass
from typing import List, Optional, Dict, Any

from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance,
    VectorParams,
    PointStruct,
    Filter,
    FieldCondition,
    MatchValue,
)

from app.core.config import settings
from app.services.knowledge.embeddings import EmbeddingService

logger = logging.getLogger(__name__)

# Singleton Qdrant client — one per process
_qdrant_client: Optional[QdrantClient] = None


def get_qdrant_client() -> QdrantClient:
    """Get or create the Qdrant client (local disk mode)."""
    global _qdrant_client
    if _qdrant_client is None:
        _qdrant_client = QdrantClient(path=settings.QDRANT_PATH)
        logger.info(f"Qdrant client initialized at {settings.QDRANT_PATH}")
    return _qdrant_client


@dataclass
class RetrievedChunk:
    """A retrieved knowledge chunk with relevance score."""
    content: str
    score: float
    document_title: str = ""
    section_heading: str = ""
    category: str = ""
    source_file: str = ""
    document_id: str = ""
    chunk_index: int = 0


class KnowledgeRetriever:
    """
    Retrieves relevant knowledge chunks from Qdrant using semantic search.
    
    Usage:
        retriever = KnowledgeRetriever()
        chunks = retriever.search("PM-KISAN eligibility", top_k=3)
        for chunk in chunks:
            print(f"[{chunk.score:.2f}] {chunk.document_title}: {chunk.content[:100]}")
    """

    def __init__(self):
        self._embedding_service = EmbeddingService()
        self._client = get_qdrant_client()
        self._ensure_collection()

    def _ensure_collection(self):
        """Create the Qdrant collection if it doesn't exist."""
        collections = self._client.get_collections().collections
        collection_names = [c.name for c in collections]

        if settings.QDRANT_COLLECTION not in collection_names:
            self._client.create_collection(
                collection_name=settings.QDRANT_COLLECTION,
                vectors_config=VectorParams(
                    size=settings.EMBEDDING_DIMENSION,
                    distance=Distance.COSINE,
                ),
            )
            logger.info(f"Created Qdrant collection: {settings.QDRANT_COLLECTION}")

    def search(
        self,
        query: str,
        top_k: int = None,
        category: Optional[str] = None,
        score_threshold: float = 0.3,
    ) -> List[RetrievedChunk]:
        """
        Search the knowledge base for relevant chunks.
        
        Args:
            query: The search query (any language)
            top_k: Number of results to return
            category: Filter by document category (e.g., "government_scheme")
            score_threshold: Minimum relevance score (0-1)
        
        Returns:
            List of RetrievedChunk objects sorted by relevance.
        """
        if top_k is None:
            top_k = settings.KB_SEARCH_TOP_K

        # Embed the query
        query_vector = self._embedding_service.embed_text(query)

        # Build optional category filter
        search_filter = None
        if category:
            search_filter = Filter(
                must=[
                    FieldCondition(
                        key="category",
                        match=MatchValue(value=category),
                    )
                ]
            )

        # Search Qdrant using query_points (v1.19+ API) with expanded candidate limit for reranking
        from qdrant_client.models import Query
        from app.services.knowledge.reranking import Reranker

        candidate_limit = max(top_k * 3, 10)
        results = self._client.query_points(
            collection_name=settings.QDRANT_COLLECTION,
            query=query_vector,
            query_filter=search_filter,
            limit=candidate_limit,
            score_threshold=score_threshold,
        )

        candidates = []
        for hit in results.points:
            payload = hit.payload or {}
            candidates.append(RetrievedChunk(
                content=payload.get("content", ""),
                score=hit.score,
                document_title=payload.get("document_title", ""),
                section_heading=payload.get("section_heading", ""),
                category=payload.get("category", ""),
                source_file=payload.get("source_file", ""),
                document_id=payload.get("document_id", ""),
                chunk_index=payload.get("chunk_index", 0),
            ))

        # Apply hybrid reranking
        reranker = Reranker()
        chunks = reranker.rerank(
            query=query,
            chunks=candidates,
            top_n=top_k,
            category_filter=category,
        )

        logger.info(
            f"KB search & rerank: query='{query[:50]}...', "
            f"candidates={len(candidates)} -> reranked={len(chunks)}, "
            f"top_score={chunks[0].score:.3f}" if chunks else f"KB search: no results"
        )
        return chunks

    def get_collection_info(self) -> Dict[str, Any]:
        """Get info about the knowledge base collection."""
        try:
            info = self._client.get_collection(settings.QDRANT_COLLECTION)
            return {
                "name": settings.QDRANT_COLLECTION,
                "vectors_count": getattr(info, 'indexed_vectors_count', 0) or 0,
                "points_count": info.points_count,
                "status": info.status.value if info.status else "unknown",
            }
        except Exception as e:
            logger.error(f"Error getting collection info: {e}")
            return {"name": settings.QDRANT_COLLECTION, "error": str(e)}
