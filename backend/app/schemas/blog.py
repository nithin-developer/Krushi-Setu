from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class BlogBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    summary: str = Field(..., min_length=5, max_length=500)
    content: str = Field(..., min_length=10)
    cover_image: Optional[str] = ""
    category: str = Field(default="general")  # scheme, pest, weather, soil, farming_tips, general
    category_label: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    target_crops: List[str] = Field(default_factory=list)
    author: Optional[str] = "Krushi Setu Admin"
    status: str = Field(default="published")  # published, draft

class BlogCreate(BlogBase):
    pass

class BlogUpdate(BaseModel):
    title: Optional[str] = None
    summary: Optional[str] = None
    content: Optional[str] = None
    cover_image: Optional[str] = None
    category: Optional[str] = None
    category_label: Optional[str] = None
    tags: Optional[List[str]] = None
    target_crops: Optional[List[str]] = None
    author: Optional[str] = None
    status: Optional[str] = None

class BlogResponse(BlogBase):
    id: str
    slug: str
    views_count: int = 0
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True

class BlogListResponse(BaseModel):
    blogs: List[BlogResponse]
    total: int
    page: int
    limit: int
    total_pages: int

class BlogUploadImageResponse(BaseModel):
    url: str
    filename: str
