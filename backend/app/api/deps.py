from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from app.core.config import settings
from app.models.user import UserModel
from app.models.admin import AdminModel
from app.schemas.user import UserResponse
from app.schemas.admin import AdminResponse

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")
admin_oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/admin/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)) -> UserResponse:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        if user_id is None or token_type != "access":
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    user = await UserModel.get_by_id(user_id)
    if user is None:
        raise credentials_exception
        
    if user.get("status") != "active":
        raise HTTPException(status_code=400, detail="Inactive user")
        
    # convert _id to id for the response model mapping
    user["id"] = user.get("_id")
    return UserResponse(**user)

async def get_current_admin(token: str = Depends(admin_oauth2_scheme)) -> AdminResponse:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        admin_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        if admin_id is None or token_type != "access":
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    admin = await AdminModel.get_by_id(admin_id)
    if admin is None:
        raise credentials_exception
        
    if admin.get("status") != "active":
        raise HTTPException(status_code=400, detail="Inactive admin")
        
    # convert _id to id for the response model mapping
    admin["id"] = admin.get("_id")
    return AdminResponse(**admin)
