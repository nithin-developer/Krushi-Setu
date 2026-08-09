from fastapi import APIRouter, Depends, HTTPException, status
from app.api.deps import get_current_user
from app.schemas.user import UserResponse
from app.schemas.digital_twin import DigitalTwinProfile
from app.models.user import UserModel

router = APIRouter()

@router.post("/digital-twin")
async def update_digital_twin(
    profile: DigitalTwinProfile,
    current_user: UserResponse = Depends(get_current_user)
):
    try:
        await UserModel.update_digital_twin_profile(current_user.id, profile.model_dump())
        return {"message": "Digital Twin profile updated successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update profile: {str(e)}"
        )
