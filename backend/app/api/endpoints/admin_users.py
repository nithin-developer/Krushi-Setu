from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional
from app.schemas.user import UserResponse
from app.models.user import UserModel
from app.api import deps

router = APIRouter()

@router.get("/users", response_model=dict)
async def get_users(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    status_filter: Optional[str] = None,
    current_admin: dict = Depends(deps.get_current_admin)
):
    """Get all users (farmers) with pagination and filters"""
    skip = (page - 1) * limit
    
    users = await UserModel.get_all_users(skip=skip, limit=limit, search=search, status_filter=status_filter)
    total = await UserModel.count_users(search=search, status_filter=status_filter)
    
    return {
        "users": users,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": (total + limit - 1) // limit
    }

@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    current_admin: dict = Depends(deps.get_current_admin)
):
    """Get a single user by ID"""
    user = await UserModel.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user["id"] = user.get("_id")
    return UserResponse(**user)

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: str,
    current_admin: dict = Depends(deps.get_current_admin)
):
    """Delete a user"""
    user = await UserModel.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    collection = UserModel.get_collection()
    from bson import ObjectId
    await collection.delete_one({"_id": ObjectId(user_id)})
    
    return {"message": "User deleted successfully"}

@router.patch("/users/{user_id}/status")
async def update_user_status(
    user_id: str,
    status: str,
    current_admin: dict = Depends(deps.get_current_admin)
):
    """Update user status (active/banned)"""
    user = await UserModel.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if status not in ["active", "banned"]:
        raise HTTPException(status_code=400, detail="Invalid status")
    
    collection = UserModel.get_collection()
    from bson import ObjectId
    from datetime import datetime, timezone
    await collection.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"status": status, "updated_at": datetime.now(timezone.utc)}}
    )
    
    return {"message": f"User status updated to {status}"}