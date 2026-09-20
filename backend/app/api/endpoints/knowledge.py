"""
Knowledge Base Admin API Endpoints

Admin-only endpoints for managing the agricultural knowledge base:
- Upload and ingest documents (PDF, MD, TXT)
- Ingest raw text content
- Search the knowledge base
- View collection info
- Delete documents
"""

import logging
from typing import Optional

from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from app.schemas.knowledge import (
    IngestTextRequest,
    IngestResponse,
    SearchRequest,
    SearchResponse,
    SearchResultItem,
    CollectionInfoResponse,
    DocumentSummary,
    DocumentListResponse,
    DocumentDetailResponse,
    ChunkDetail,
)
from app.services.knowledge.ingestion import DocumentIngestionPipeline
from app.services.knowledge.retriever import KnowledgeRetriever

logger = logging.getLogger(__name__)

router = APIRouter()

# Lazy initialization — these load BGE-M3 on first use
_pipeline: Optional[DocumentIngestionPipeline] = None
_retriever: Optional[KnowledgeRetriever] = None


def _get_pipeline() -> DocumentIngestionPipeline:
    global _pipeline
    if _pipeline is None:
        _pipeline = DocumentIngestionPipeline()
    return _pipeline


def _get_retriever() -> KnowledgeRetriever:
    global _retriever
    if _retriever is None:
        _retriever = KnowledgeRetriever()
    return _retriever


@router.post("/ingest/text", response_model=IngestResponse)
async def ingest_text(request: IngestTextRequest):
    """
    Ingest raw text content into the knowledge base.
    
    Use this for admin-entered articles, scheme descriptions, etc.
    """
    try:
        pipeline = _get_pipeline()
        result = pipeline.ingest_text(
            text=request.content,
            title=request.title,
            category=request.category,
            tags=request.tags,
            language=request.language,
            region=request.region,
            crops=request.crops,
        )
        return IngestResponse(**result)
    except Exception as e:
        logger.error(f"Text ingestion failed: {e}")
        raise HTTPException(status_code=500, detail=f"Ingestion failed: {str(e)}")


@router.post("/ingest/file", response_model=IngestResponse)
async def ingest_file(
    file: UploadFile = File(...),
    category: str = Form(default="general"),
    tags: str = Form(default=""),
    language: str = Form(default="en"),
    region: str = Form(default="all_india"),
    crops: str = Form(default=""),
):
    """
    Upload and ingest a document file (PDF, MD, TXT).
    
    The file is temporarily saved, processed, then deleted.
    """
    import tempfile
    import os
    from pathlib import Path

    allowed_extensions = {'.pdf', '.md', '.txt'}
    file_ext = Path(file.filename).suffix.lower() if file.filename else ''
    
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {file_ext}. Allowed: {allowed_extensions}",
        )

    # Save uploaded file temporarily
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_ext) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        pipeline = _get_pipeline()
        result = pipeline.ingest_file(
            file_path=tmp_path,
            category=category,
            tags=[t.strip() for t in tags.split(",") if t.strip()],
            language=language,
            region=region,
            crops=[c.strip() for c in crops.split(",") if c.strip()],
        )

        # Override source_file with original filename
        result["source_file"] = file.filename or result.get("source_file", "")

        return IngestResponse(**result)

    except Exception as e:
        logger.error(f"File ingestion failed: {e}")
        raise HTTPException(status_code=500, detail=f"Ingestion failed: {str(e)}")
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass


@router.post("/search", response_model=SearchResponse)
async def search_knowledge_base(request: SearchRequest):
    """
    Search the knowledge base with semantic similarity.
    
    Admin debug tool to test KB retrieval quality.
    """
    try:
        retriever = _get_retriever()
        chunks = retriever.search(
            query=request.query,
            top_k=request.top_k,
            category=request.category,
            score_threshold=request.score_threshold,
        )

        results = [
            SearchResultItem(
                content=c.content,
                score=c.score,
                document_title=c.document_title,
                section_heading=c.section_heading,
                category=c.category,
                source_file=c.source_file,
            )
            for c in chunks
        ]

        return SearchResponse(
            query=request.query,
            results=results,
            total=len(results),
        )
    except Exception as e:
        logger.error(f"KB search failed: {e}")
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")


@router.get("/info", response_model=CollectionInfoResponse)
async def get_collection_info():
    """Get information about the knowledge base (vector count, status)."""
    try:
        retriever = _get_retriever()
        info = retriever.get_collection_info()
        return CollectionInfoResponse(**info)
    except Exception as e:
        logger.error(f"Collection info failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/documents/{document_id}")
async def delete_document(document_id: str):
    """Delete a document and all its chunks from the knowledge base."""
    try:
        pipeline = _get_pipeline()
        count = pipeline.delete_document(document_id)
        return {"document_id": document_id, "deleted_chunks": count}
    except Exception as e:
        logger.error(f"Document deletion failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/documents", response_model=DocumentListResponse)
async def list_documents():
    """List all ingested documents in the knowledge base with summaries and chunk counts."""
    try:
        pipeline = _get_pipeline()
        docs_raw = pipeline.get_documents()
        documents = [DocumentSummary(**d) for d in docs_raw]
        total_chunks = sum(d.chunks_count for d in documents)

        return DocumentListResponse(
            documents=documents,
            total_documents=len(documents),
            total_chunks=total_chunks,
        )
    except Exception as e:
        logger.error(f"List documents failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/documents/{document_id}", response_model=DocumentDetailResponse)
async def get_document_detail(document_id: str):
    """Get detailed information for a single document including all text chunks."""
    try:
        pipeline = _get_pipeline()
        detail = pipeline.get_document_detail(document_id)
        if not detail:
            raise HTTPException(status_code=404, detail="Document not found")
        return DocumentDetailResponse(**detail)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get document detail failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

