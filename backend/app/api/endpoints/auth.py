from fastapi import APIRouter, Depends, HTTPException, status
from app.schemas.user import UserCreate, UserLogin, GoogleLogin, Token, UserResponse, RefreshTokenReq
from app.models.user import UserModel
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.api import deps
from google.oauth2 import id_token
from google.auth.transport import requests
from app.core.config import settings
from jose import jwt, JWTError

router = APIRouter()

@router.post("/register", response_model=Token)
async def register(user_in: UserCreate):
    user = await UserModel.get_by_email(user_in.email)
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The user with this email already exists in the system.",
        )
    
    user_data = {
        "full_name": user_in.full_name,
        "email": user_in.email,
        "phone_number": user_in.phone_number,
        "provider": "email",
        "preferred_language": user_in.preferred_language,
        "profile_image": None,
        "google_id": None,
    }
    
    if user_in.password:
        user_data["password_hash"] = get_password_hash(user_in.password)
    
    created_user = await UserModel.create_user(user_data)
    
    return {
        "access_token": create_access_token(created_user["_id"]),
        "refresh_token": create_refresh_token(created_user["_id"]),
        "token_type": "bearer"
    }

@router.post("/login", response_model=Token)
async def login(login_data: UserLogin):
    user = await UserModel.get_by_email(login_data.email)
    if not user or not user.get("password_hash"):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
        
    if not verify_password(login_data.password, user["password_hash"]):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
        
    await UserModel.update_last_login(user["_id"])
    
    return {
        "access_token": create_access_token(user["_id"]),
        "refresh_token": create_refresh_token(user["_id"]),
        "token_type": "bearer"
    }

@router.post("/google-login", response_model=Token)
async def google_login(login_data: GoogleLogin):
    try:
        # Verify Google ID Token
        idinfo = id_token.verify_oauth2_token(login_data.id_token, requests.Request(), settings.GOOGLE_CLIENT_ID)
        
        email = idinfo['email']
        google_id = idinfo['sub']
        name = idinfo.get('name', '')
        picture = idinfo.get('picture', None)
        
        user = await UserModel.get_by_google_id(google_id)
        if not user:
            # check by email
            user = await UserModel.get_by_email(email)
            if user:
                # Link google account to existing email
                collection = UserModel.get_collection()
                from bson import ObjectId
                await collection.update_one({"_id": ObjectId(user["_id"])}, {"$set": {"google_id": google_id, "provider": "google"}})
            else:
                # Create new user
                user_data = {
                    "full_name": name,
                    "email": email,
                    "provider": "google",
                    "google_id": google_id,
                    "profile_image": picture,
                    "preferred_language": "en"
                }
                user = await UserModel.create_user(user_data)
                
        await UserModel.update_last_login(user["_id"])
        
        return {
            "access_token": create_access_token(user["_id"]),
            "refresh_token": create_refresh_token(user["_id"]),
            "token_type": "bearer"
        }
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid Google ID token")

@router.post("/refresh", response_model=Token)
async def refresh_token(req: RefreshTokenReq):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )
    try:
        payload = jwt.decode(req.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        if user_id is None or token_type != "refresh":
            raise credentials_exception
    except JWTError:
        raise credentials_exception
        
    user = await UserModel.get_by_id(user_id)
    if not user:
        raise credentials_exception
        
    return {
        "access_token": create_access_token(user_id),
        "refresh_token": create_refresh_token(user_id),
        "token_type": "bearer"
    }

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: UserResponse = Depends(deps.get_current_user)):
    return current_user
