import os
import math
import uuid
import logging
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query, status

from app.api.deps import get_current_admin
from app.models.admin import AdminModel
from app.models.blog import BlogModel
from app.schemas.blog import (
    BlogCreate,
    BlogUpdate,
    BlogResponse,
    BlogListResponse,
    BlogUploadImageResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter()

# Directory for storing blog images
UPLOAD_DIR = Path("uploads/blogs")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


@router.get("", response_model=BlogListResponse)
async def list_blogs(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    category: Optional[str] = Query(None),
    status_filter: Optional[str] = Query(None, alias="status"),
    search: Optional[str] = Query(None),
):
    """
    List blog posts with search, category filtering, status filtering, and pagination.
    Accessible to farmers and admins.
    """
    skip = (page - 1) * limit
    blogs = await BlogModel.list_blogs(
        skip=skip,
        limit=limit,
        category=category,
        status=status_filter,
        search=search,
    )
    total = await BlogModel.count_blogs(
        category=category,
        status=status_filter,
        search=search,
    )
    total_pages = math.ceil(total / limit) if total > 0 else 1

    return BlogListResponse(
        blogs=[BlogResponse(**b) for b in blogs],
        total=total,
        page=page,
        limit=limit,
        total_pages=total_pages,
    )


@router.get("/{blog_id}", response_model=BlogResponse)
async def get_blog_detail(blog_id: str):
    """
    Get detailed blog post by ID or slug.
    Increments views count automatically.
    """
    blog = await BlogModel.get_by_id(blog_id)
    if not blog:
        blog = await BlogModel.get_by_slug(blog_id)

    if not blog:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Blog post not found",
        )

    # Increment view count in background/async
    await BlogModel.increment_views(blog["id"])
    blog["views_count"] = blog.get("views_count", 0) + 1

    return BlogResponse(**blog)


@router.post("", response_model=BlogResponse, status_code=status.HTTP_201_CREATED)
async def create_blog(
    blog_in: BlogCreate,
    current_admin=Depends(get_current_admin),
):
    """
    Create a new blog post. (Admin only)
    """
    blog_data = blog_in.dict()
    blog_data["author"] = current_admin.full_name or "Krushi Setu Admin"
    
    created_blog = await BlogModel.create(blog_data)
    if not created_blog:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create blog post",
        )
    return BlogResponse(**created_blog)


@router.put("/{blog_id}", response_model=BlogResponse)
async def update_blog(
    blog_id: str,
    blog_in: BlogUpdate,
    current_admin=Depends(get_current_admin),
):
    """
    Update an existing blog post. (Admin only)
    """
    existing = await BlogModel.get_by_id(blog_id)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Blog post not found",
        )

    update_data = {k: v for k, v in blog_in.dict().items() if v is not None}
    if not update_data:
        return BlogResponse(**existing)

    updated_blog = await BlogModel.update(blog_id, update_data)
    if not updated_blog:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update blog post",
        )
    return BlogResponse(**updated_blog)


@router.delete("/{blog_id}", status_code=status.HTTP_200_OK)
async def delete_blog(
    blog_id: str,
    current_admin=Depends(get_current_admin),
):
    """
    Delete a blog post by ID. (Admin only)
    """
    existing = await BlogModel.get_by_id(blog_id)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Blog post not found",
        )

    success = await BlogModel.delete(blog_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete blog post",
        )

    return {"message": "Blog post deleted successfully", "id": blog_id}


@router.post("/upload-image", response_model=BlogUploadImageResponse)
async def upload_blog_image(
    file: UploadFile = File(...),
    current_admin=Depends(get_current_admin),
):
    """
    Upload an image for a blog cover or content. (Admin only)
    """
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".svg"}
    ext = Path(file.filename).suffix.lower() if file.filename else ""

    if ext not in allowed_extensions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid image format: {ext}. Allowed: {allowed_extensions}",
        )

    filename = f"{uuid.uuid4().hex}{ext}"
    filepath = UPLOAD_DIR / filename

    try:
        content = await file.read()
        with open(filepath, "wb") as f:
            f.write(content)

        # Public relative URL path
        public_url = f"/uploads/blogs/{filename}"
        return BlogUploadImageResponse(url=public_url, filename=filename)
    except Exception as e:
        logger.error(f"Image upload failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Image upload failed: {str(e)}",
        )
