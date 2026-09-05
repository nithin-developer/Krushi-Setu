from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List
from bson import ObjectId
from datetime import datetime, timezone
from pydantic import BaseModel, EmailStr
from app.models.admin import AdminModel
from app.core.security import get_password_hash
from app.api import deps

router = APIRouter()

class AdminCreateReq(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: str = "admin" # super_admin, admin, moderator

class AdminStatusReq(BaseModel):
    status: str # active, inactive

@router.get("/admins", response_model=dict)
async def get_admins(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    current_admin: dict = Depends(deps.get_current_admin)
):
    """List all administrators in the system"""
    skip = (page - 1) * limit
    admins = await AdminModel.get_all_admins(skip=skip, limit=limit)
    total = await AdminModel.count_admins()

    # Sanitise password hashes before returning
    safe_admins = []
    for adm in admins:
        adm_copy = dict(adm)
        adm_copy.pop("password_hash", None)
        adm_copy["id"] = str(adm_copy.get("_id"))
        safe_admins.append(adm_copy)

    return {
        "admins": safe_admins,
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": (total + limit - 1) // limit
    }

@router.post("/admins", status_code=status.HTTP_201_CREATED)
async def create_admin_user(
    data: AdminCreateReq,
    current_admin: dict = Depends(deps.get_current_admin)
):
    """Create a new administrator account"""
    existing = await AdminModel.get_by_email(data.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An administrator with this email already exists."
        )

    admin_dict = {
        "full_name": data.full_name,
        "email": data.email,
        "role": data.role,
        "password_hash": get_password_hash(data.password),
    }

    created = await AdminModel.create_admin(admin_dict)
    created.pop("password_hash", None)
    created["id"] = str(created.get("_id"))
    return created

@router.patch("/admins/{admin_id}/status")
async def update_admin_status(
    admin_id: str,
    status_data: AdminStatusReq,
    current_admin: dict = Depends(deps.get_current_admin)
):
    """Update administrator status (active / inactive)"""
    if str(current_admin.get("_id") or current_admin.get("id")) == admin_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot change your own administrator status."
        )

    target_admin = await AdminModel.get_by_id(admin_id)
    if not target_admin:
        raise HTTPException(status_code=404, detail="Admin not found")

    if status_data.status not in ["active", "inactive"]:
        raise HTTPException(status_code=400, detail="Status must be 'active' or 'inactive'")

    col = AdminModel.get_collection()
    await col.update_one(
        {"_id": ObjectId(admin_id)},
        {"$set": {"status": status_data.status, "updated_at": datetime.now(timezone.utc)}}
    )

    return {"message": f"Admin status updated to {status_data.status}"}

@router.delete("/admins/{admin_id}")
async def delete_admin(
    admin_id: str,
    current_admin: dict = Depends(deps.get_current_admin)
):
    """Delete an administrator account"""
    if str(current_admin.get("_id") or current_admin.get("id")) == admin_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot delete your own administrator account."
        )

    target_admin = await AdminModel.get_by_id(admin_id)
    if not target_admin:
        raise HTTPException(status_code=404, detail="Admin not found")

    col = AdminModel.get_collection()
    await col.delete_one({"_id": ObjectId(admin_id)})

    return {"message": "Admin deleted successfully"}
