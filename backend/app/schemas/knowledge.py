"""
Knowledge Base API Schemas

Request/response models for the knowledge base admin endpoints.
"""

from pydantic import BaseModel, Field
from typing import List, Optional


class IngestFileRequest(BaseModel):
    """Request to ingest a document file."""
    category: str = Field(default="general", description="Document category: government_scheme, pest_disease, crop_guide, soil_health, weather, general")
    tags: List[str] = Field(default_factory=list, description="Searchable tags")
    language: str = Field(default="en", description="Document language (en, kn, hi)")
    region: str = Field(default="all_india", description="Geographic relevance")
    crops: List[str] = Field(default_factory=list, description="Relevant crop names")


class IngestTextRequest(BaseModel):
    """Request to ingest raw text content."""
    title: str = Field(..., description="Document title")
    content: str = Field(..., description="Text content to ingest")
    category: str = Field(default="general")
    tags: List[str] = Field(default_factory=list)
    language: str = Field(default="en")
    region: str = Field(default="all_india")
    crops: List[str] = Field(default_factory=list)


class IngestResponse(BaseModel):
    """Response from document ingestion."""
    document_id: str
    document_title: str = ""
    source_file: str = ""
    chunks_count: int
    category: str
    status: str


class SearchRequest(BaseModel):
    """Request to search the knowledge base."""
    query: str = Field(..., description="Search query (any language)")
    top_k: int = Field(default=3, ge=1, le=20)
    category: Optional[str] = Field(default=None, description="Filter by category")
    score_threshold: float = Field(default=0.3, ge=0.0, le=1.0)


class SearchResultItem(BaseModel):
    """A single search result."""
    content: str
    score: float
    document_title: str
    section_heading: str = ""
    category: str
    source_file: str = ""


class SearchResponse(BaseModel):
    """Response from knowledge base search."""
    query: str
    results: List[SearchResultItem]
    total: int


class CollectionInfoResponse(BaseModel):
    """Information about the knowledge base collection."""
    name: str
    vectors_count: int = 0
    points_count: int = 0
    status: str = ""


class DocumentSummary(BaseModel):
    """Summary metadata of an ingested document."""
    document_id: str
    document_title: str
    source_file: str = ""
    category: str
    language: str = "en"
    region: str = "all_india"
    crops: List[str] = Field(default_factory=list)
    tags: List[str] = Field(default_factory=list)
    created_at: str = ""
    chunks_count: int = 0


class DocumentListResponse(BaseModel):
    """Response containing list of documents in KB."""
    documents: List[DocumentSummary]
    total_documents: int
    total_chunks: int


class ChunkDetail(BaseModel):
    """Detail of a single chunk within a document."""
    chunk_id: str
    chunk_index: int
    section_heading: str = ""
    content: str


class DocumentDetailResponse(BaseModel):
    """Detail response for a document including chunks."""
    document_id: str
    document_title: str
    source_file: str = ""
    category: str
    language: str = "en"
    region: str = "all_india"
    crops: List[str] = Field(default_factory=list)
    tags: List[str] = Field(default_factory=list)
    created_at: str = ""
    chunks_count: int = 0
    chunks: List[ChunkDetail] = Field(default_factory=list)

