"""
BGE-M3 Embedding Service for Krushi Setu

Uses BAAI/bge-m3 for multilingual embeddings (supports Kannada, Hindi,
Telugu, Tamil, English). Produces 1024-dimensional dense vectors.

The model is loaded lazily on first use and cached in memory.
"""

import logging
from typing import List, Optional

logger = logging.getLogger(__name__)

# Singleton model instance — loaded once, reused across requests
_model = None
_model_loading = False


def _get_model():
    """Lazy-load the BGE-M3 model (singleton)."""
    global _model, _model_loading

    if _model is not None:
        return _model

    if _model_loading:
        raise RuntimeError("Model is currently loading, please wait")

    _model_loading = True
    try:
        from sentence_transformers import SentenceTransformer
        logger.info("Loading BGE-M3 embedding model (first call only)...")
        
        from app.core.config import settings
        _model = SentenceTransformer(settings.EMBEDDING_MODEL)
        
        logger.info(f"BGE-M3 loaded. Embedding dimension: {_model.get_embedding_dimension()}")
        return _model
    except Exception as e:
        _model_loading = False
        logger.error(f"Failed to load BGE-M3: {e}")
        raise
    finally:
        _model_loading = False


class EmbeddingService:
    """
    Embedding service using BGE-M3 for multilingual text.
    
    Usage:
        svc = EmbeddingService()
        vector = svc.embed_text("ಟೊಮೇಟೊ ಬೆಳೆ ಬಗ್ಗೆ")
        vectors = svc.embed_batch(["text1", "text2", "text3"])
    """

    def __init__(self):
        self._model = None

    def _ensure_model(self):
        """Ensure the model is loaded."""
        if self._model is None:
            self._model = _get_model()

    def embed_text(self, text: str) -> List[float]:
        """
        Embed a single text string.
        
        Args:
            text: Text to embed (any language)
        
        Returns:
            1024-dimensional float vector.
        """
        self._ensure_model()
        
        # BGE-M3 works best with short prefix for retrieval
        embedding = self._model.encode(text, normalize_embeddings=True)
        return embedding.tolist()

    def embed_batch(self, texts: List[str], batch_size: int = 32) -> List[List[float]]:
        """
        Embed multiple texts in a batch.
        
        Args:
            texts: List of texts to embed
            batch_size: Batch size for encoding
        
        Returns:
            List of 1024-dimensional vectors.
        """
        if not texts:
            return []

        self._ensure_model()
        
        embeddings = self._model.encode(
            texts,
            normalize_embeddings=True,
            batch_size=batch_size,
            show_progress_bar=len(texts) > 10,
        )
        
        logger.info(f"Embedded {len(texts)} texts, dim={embeddings.shape[1]}")
        return embeddings.tolist()

    @property
    def dimension(self) -> int:
        """Return the embedding dimension."""
        self._ensure_model()
        return self._model.get_embedding_dimension()
