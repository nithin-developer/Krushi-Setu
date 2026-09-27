from fastapi import APIRouter, Depends, HTTPException, status
from app.api.deps import get_current_user
from app.schemas.user import UserResponse, UserUpdateProfile
from app.schemas.digital_twin import DigitalTwinProfile
from app.models.user import UserModel

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_my_profile(current_user: UserResponse = Depends(get_current_user)):
    """
    Get current authenticated user's profile details including Digital Twin.
    """
    user = await UserModel.get_by_id(current_user.id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found",
        )
    user["id"] = user.get("_id") or current_user.id
    return UserResponse(**user)


@router.patch("/me", response_model=UserResponse)
async def update_my_profile(
    profile_in: UserUpdateProfile,
    current_user: UserResponse = Depends(get_current_user),
):
    """
    Update basic profile details (full_name, phone_number, preferred_language, profile_image).
    """
    update_data = {k: v for k, v in profile_in.model_dump().items() if v is not None}
    if not update_data:
        user = await UserModel.get_by_id(current_user.id)
        user["id"] = user.get("_id") or current_user.id
        return UserResponse(**user)

    updated_user = await UserModel.update_user_profile(current_user.id, update_data)
    if not updated_user:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile",
        )

    updated_user["id"] = updated_user.get("_id") or current_user.id
    return UserResponse(**updated_user)


@router.get("/digital-twin")
async def get_digital_twin(current_user: UserResponse = Depends(get_current_user)):
    """
    Get saved Digital Twin farm profile for the current user.
    """
    user = await UserModel.get_by_id(current_user.id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    digital_twin = user.get("digital_twin")
    return {
        "user_id": current_user.id,
        "profile_completed": user.get("profile_completed", False),
        "digital_twin": digital_twin,
    }


@router.post("/digital-twin")
@router.put("/digital-twin")
async def update_digital_twin(
    profile: DigitalTwinProfile,
    current_user: UserResponse = Depends(get_current_user),
):
    """
    Create or update Digital Twin farm profile parameters (location, land size, water sources, crops, soil).
    """
    try:
        await UserModel.update_digital_twin_profile(current_user.id, profile.model_dump())
        return {
            "message": "Digital Twin profile updated successfully",
            "profile_completed": True,
            "digital_twin": profile.model_dump(),
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update profile: {str(e)}",
        )
