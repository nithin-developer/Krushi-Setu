"""
Document Ingestion Pipeline

Full pipeline: File → Extract → Chunk → Embed → Store in Qdrant.

Supports:
- Single file ingestion (PDF, MD, TXT)
- Batch directory ingestion
- Raw text ingestion (for admin-entered content)
- MongoDB tracking of ingested documents (metadata only)
"""

import uuid
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from pathlib import Path

from qdrant_client.models import PointStruct

from app.core.config import settings
from app.services.knowledge.chunker import DocumentChunker, TextChunk
from app.services.knowledge.embeddings import EmbeddingService
from app.services.knowledge.retriever import get_qdrant_client

logger = logging.getLogger(__name__)


class DocumentIngestionPipeline:
    """
    End-to-end document ingestion for the knowledge base.
    
    Usage:
        pipeline = DocumentIngestionPipeline()
        
        # Ingest a file
        count = pipeline.ingest_file(
            "docs/pm_kisan.md",
            category="government_scheme",
            tags=["pm-kisan", "subsidy"],
        )
        
        # Ingest raw text
        count = pipeline.ingest_text(
            "PM-KISAN provides ₹6,000/year...",
            title="PM-KISAN Overview",
            category="government_scheme",
        )
    """

    def __init__(self):
        self._chunker = DocumentChunker(
            chunk_size=settings.KB_CHUNK_SIZE,
            chunk_overlap=settings.KB_CHUNK_OVERLAP,
        )
        self._embedding_service = EmbeddingService()
        self._qdrant = get_qdrant_client()
        self._ensure_collection()

    def _ensure_collection(self):
        """Create the Qdrant collection if it doesn't exist."""
        from qdrant_client.models import Distance, VectorParams

        collections = self._qdrant.get_collections().collections
        collection_names = [c.name for c in collections]

        if settings.QDRANT_COLLECTION not in collection_names:
            self._qdrant.create_collection(
                collection_name=settings.QDRANT_COLLECTION,
                vectors_config=VectorParams(
                    size=settings.EMBEDDING_DIMENSION,
                    distance=Distance.COSINE,
                ),
            )
            logger.info(f"Created Qdrant collection: {settings.QDRANT_COLLECTION}")

    def ingest_file(
        self,
        file_path: str,
        category: str = "general",
        tags: Optional[List[str]] = None,
        language: str = "en",
        region: str = "all_india",
        crops: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Ingest a document file into the knowledge base.
        
        Args:
            file_path: Path to the file (PDF, MD, or TXT)
            category: Document category for filtering
            tags: Searchable tags
            language: Document language code
            region: Geographic relevance
            crops: Relevant crop names
        
        Returns:
            Dict with ingestion results (document_id, chunks_count, etc.)
        """
        path = Path(file_path)
        document_id = str(uuid.uuid4())
        document_title = path.stem.replace('_', ' ').replace('-', ' ').title()

        logger.info(f"Ingesting file: {file_path} → doc_id={document_id}")

        # Delete any existing chunks for this source_file to prevent duplicates
        self.delete_by_source_file(path.name)

        # Step 1: Chunk the document
        chunks = self._chunker.chunk_file(
            file_path=file_path,
            document_title=document_title,
        )

        if not chunks:
            logger.warning(f"No chunks produced from {file_path}")
            return {"document_id": document_id, "chunks_count": 0, "status": "empty"}

        # Step 2: Embed all chunks
        texts = [chunk.content for chunk in chunks]
        embeddings = self._embedding_service.embed_batch(texts)

        # Step 3: Store in Qdrant
        points = []
        for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            point_id = str(uuid.uuid4())
            points.append(PointStruct(
                id=point_id,
                vector=embedding,
                payload={
                    "content": chunk.content,
                    "document_id": document_id,
                    "document_title": document_title,
                    "source_file": chunk.source_file,
                    "section_heading": chunk.section_heading,
                    "chunk_index": chunk.chunk_index,
                    "category": category,
                    "tags": tags or [],
                    "language": language,
                    "region": region,
                    "crops": crops or [],
                    "created_at": datetime.now(timezone.utc).isoformat(),
                },
            ))

        # Upsert in batches of 100
        batch_size = 100
        for i in range(0, len(points), batch_size):
            batch = points[i:i + batch_size]
            self._qdrant.upsert(
                collection_name=settings.QDRANT_COLLECTION,
                points=batch,
            )

        result = {
            "document_id": document_id,
            "document_title": document_title,
            "source_file": path.name,
            "chunks_count": len(points),
            "category": category,
            "status": "success",
        }

        logger.info(f"Ingested {len(points)} chunks from {path.name}")
        return result

    def ingest_text(
        self,
        text: str,
        title: str,
        category: str = "general",
        tags: Optional[List[str]] = None,
        language: str = "en",
        region: str = "all_india",
        crops: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Ingest raw text into the knowledge base.
        
        Used for admin-entered content or programmatically generated knowledge.
        """
        document_id = str(uuid.uuid4())
        
        logger.info(f"Ingesting text: '{title}' → doc_id={document_id}")

        # Chunk the text
        chunks = self._chunker.chunk_text(
            text=text,
            source_file=f"{title.lower().replace(' ', '_')}.txt",
            document_title=title,
        )

        if not chunks:
            return {"document_id": document_id, "chunks_count": 0, "status": "empty"}

        # Embed
        texts = [chunk.content for chunk in chunks]
        embeddings = self._embedding_service.embed_batch(texts)

        # Store
        points = []
        for chunk, embedding in zip(chunks, embeddings):
            points.append(PointStruct(
                id=str(uuid.uuid4()),
                vector=embedding,
                payload={
                    "content": chunk.content,
                    "document_id": document_id,
                    "document_title": title,
                    "source_file": chunk.source_file,
                    "section_heading": chunk.section_heading,
                    "chunk_index": chunk.chunk_index,
                    "category": category,
                    "tags": tags or [],
                    "language": language,
                    "region": region,
                    "crops": crops or [],
                    "created_at": datetime.now(timezone.utc).isoformat(),
                },
            ))

        self._qdrant.upsert(
            collection_name=settings.QDRANT_COLLECTION,
            points=points,
        )

        return {
            "document_id": document_id,
            "document_title": title,
            "chunks_count": len(points),
            "category": category,
            "status": "success",
        }

    def ingest_directory(
        self,
        dir_path: str,
        category: str = "general",
        tags: Optional[List[str]] = None,
        language: str = "en",
        region: str = "all_india",
        crops: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Ingest all supported files from a directory.
        """
        path = Path(dir_path)
        if not path.is_dir():
            raise FileNotFoundError(f"Directory not found: {dir_path}")

        results = []
        supported = {'.txt', '.md', '.pdf'}

        for file_path in sorted(path.rglob('*')):
            if file_path.suffix.lower() in supported:
                try:
                    result = self.ingest_file(
                        file_path=str(file_path),
                        category=category,
                        tags=tags,
                        language=language,
                        region=region,
                        crops=crops,
                    )
                    results.append(result)
                except Exception as e:
                    logger.error(f"Failed to ingest {file_path}: {e}")
                    results.append({
                        "source_file": file_path.name,
                        "status": "error",
                        "error": str(e),
                    })

        total_chunks = sum(r.get("chunks_count", 0) for r in results)
        logger.info(f"Directory ingestion complete: {len(results)} files, {total_chunks} total chunks")
        return results

    def delete_document(self, document_id: str) -> int:
        """
        Delete all chunks for a document from Qdrant.
        
        Returns the number of deleted points.
        """
        from qdrant_client.models import Filter, FieldCondition, MatchValue

        # Count before deletion
        result = self._qdrant.scroll(
            collection_name=settings.QDRANT_COLLECTION,
            scroll_filter=Filter(
                must=[FieldCondition(key="document_id", match=MatchValue(value=document_id))]
            ),
            limit=1000,
        )
        count = len(result[0])

        # Delete
        self._qdrant.delete(
            collection_name=settings.QDRANT_COLLECTION,
            points_selector=Filter(
                must=[FieldCondition(key="document_id", match=MatchValue(value=document_id))]
            ),
        )

        logger.info(f"Deleted {count} chunks for document {document_id}")
        return count

    def delete_by_source_file(self, source_file: str) -> int:
        """
        Delete all chunks associated with a specific source filename.
        """
        from qdrant_client.models import Filter, FieldCondition, MatchValue

        try:
            scroll_res, _ = self._qdrant.scroll(
                collection_name=settings.QDRANT_COLLECTION,
                scroll_filter=Filter(
                    must=[FieldCondition(key="source_file", match=MatchValue(value=source_file))]
                ),
                limit=1000,
            )
            count = len(scroll_res)
            if count > 0:
                self._qdrant.delete(
                    collection_name=settings.QDRANT_COLLECTION,
                    points_selector=Filter(
                        must=[FieldCondition(key="source_file", match=MatchValue(value=source_file))]
                    ),
                )
                logger.info(f"Deleted {count} existing chunks for source_file={source_file}")
            return count
        except Exception as e:
            logger.error(f"Error deleting by source file {source_file}: {e}")
            return 0

    def get_documents(self) -> List[Dict[str, Any]]:
        """
        Scroll all vectors from Qdrant and aggregate unique document metadata summaries.
        """
        try:
            scroll_res, _ = self._qdrant.scroll(
                collection_name=settings.QDRANT_COLLECTION,
                limit=1000,
                with_payload=True,
                with_vectors=False,
            )

            docs_map: Dict[str, Dict[str, Any]] = {}
            for point in scroll_res:
                payload = point.payload or {}
                doc_id = payload.get("document_id") or "legacy_unknown"
                if doc_id not in docs_map:
                    docs_map[doc_id] = {
                        "document_id": doc_id,
                        "document_title": payload.get("document_title", "Untitled Document"),
                        "source_file": payload.get("source_file", ""),
                        "category": payload.get("category", "general"),
                        "language": payload.get("language", "en"),
                        "region": payload.get("region", "all_india"),
                        "crops": payload.get("crops", []),
                        "tags": payload.get("tags", []),
                        "created_at": payload.get("created_at", datetime.now(timezone.utc).isoformat()),
                        "chunks_count": 0,
                    }
                docs_map[doc_id]["chunks_count"] += 1

            return list(docs_map.values())
        except Exception as e:
            logger.error(f"Error fetching documents list: {e}")
            return []

    def get_document_detail(self, document_id: str) -> Optional[Dict[str, Any]]:
        """
        Get detail view of a single document including all its text chunks.
        """
        from qdrant_client.models import Filter, FieldCondition, MatchValue

        try:
            scroll_res, _ = self._qdrant.scroll(
                collection_name=settings.QDRANT_COLLECTION,
                scroll_filter=Filter(
                    must=[FieldCondition(key="document_id", match=MatchValue(value=document_id))]
                ),
                limit=500,
                with_payload=True,
                with_vectors=False,
            )

            if not scroll_res:
                return None

            chunks = []
            doc_info = None

            for point in scroll_res:
                payload = point.payload or {}
                if not doc_info:
                    doc_info = {
                        "document_id": document_id,
                        "document_title": payload.get("document_title", "Untitled Document"),
                        "source_file": payload.get("source_file", ""),
                        "category": payload.get("category", "general"),
                        "language": payload.get("language", "en"),
                        "region": payload.get("region", "all_india"),
                        "crops": payload.get("crops", []),
                        "tags": payload.get("tags", []),
                        "created_at": payload.get("created_at", datetime.now(timezone.utc).isoformat()),
                    }

                chunks.append({
                    "chunk_id": str(point.id),
                    "chunk_index": payload.get("chunk_index", 0),
                    "section_heading": payload.get("section_heading", ""),
                    "content": payload.get("content", ""),
                })

            chunks.sort(key=lambda c: c["chunk_index"])
            doc_info["chunks"] = chunks
            doc_info["chunks_count"] = len(chunks)
            return doc_info

        except Exception as e:
            logger.error(f"Error getting document detail for {document_id}: {e}")
            return None
