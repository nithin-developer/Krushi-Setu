from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.admin import AdminCreate, AdminLogin, AdminToken, AdminResponse, RefreshTokenReq
from app.models.admin import AdminModel
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.api import deps
from jose import jwt, JWTError
from app.core.config import settings

router = APIRouter()

@router.post("/register", response_model=AdminToken)
async def register_admin(admin_in: AdminCreate):
    admin = await AdminModel.get_by_email(admin_in.email)
    if admin:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An admin with this email already exists in the system.",
        )

    admin_data = {
        "full_name": admin_in.full_name,
        "email": admin_in.email,
        "role": admin_in.role,
        "password_hash": get_password_hash(admin_in.password),
    }

    created_admin = await AdminModel.create_admin(admin_data)

    return {
        "access_token": create_access_token(created_admin["_id"]),
        "refresh_token": create_refresh_token(created_admin["_id"]),
        "token_type": "bearer"
    }

@router.post("/login", response_model=AdminToken)
async def login_admin(login_data: AdminLogin):
    admin = await AdminModel.get_by_email(login_data.email)
    if not admin or not admin.get("password_hash"):
        raise HTTPException(status_code=400, detail="Incorrect email or password")

    if not verify_password(login_data.password, admin["password_hash"]):
        raise HTTPException(status_code=400, detail="Incorrect email or password")

    await AdminModel.update_last_login(admin["_id"])

    return {
        "access_token": create_access_token(admin["_id"]),
        "refresh_token": create_refresh_token(admin["_id"]),
        "token_type": "bearer"
    }

@router.post("/refresh", response_model=AdminToken)
async def refresh_admin_token(req: RefreshTokenReq):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )
    try:
        payload = jwt.decode(req.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        admin_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        if admin_id is None or token_type != "refresh":
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    admin = await AdminModel.get_by_id(admin_id)
    if not admin:
        raise credentials_exception

    return {
        "access_token": create_access_token(admin_id),
        "refresh_token": create_refresh_token(admin_id),
        "token_type": "bearer"
    }

@router.get("/me", response_model=AdminResponse)
async def get_me(current_admin: AdminResponse = Depends(deps.get_current_admin)):
    return current_admin