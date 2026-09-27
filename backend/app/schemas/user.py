from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    full_name: str
    email: EmailStr
    phone_number: Optional[str] = None
    provider: str = "email" # email or google
    preferred_language: str = "en"
    profile_image: Optional[str] = None

class UserCreate(UserBase):
    password: Optional[str] = None # Optional because google login doesn't have password
    google_id: Optional[str] = None

class UserInDB(UserBase):
    id: str = Field(alias="_id")
    password_hash: Optional[str] = None
    google_id: Optional[str] = None
    profile_completed: bool = False
    status: str = "active"
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True

class UserResponse(UserBase):
    id: str
    profile_completed: bool
    status: str
    digital_twin: Optional[dict] = None
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

class UserUpdateProfile(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    preferred_language: Optional[str] = None
    profile_image: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class GoogleLogin(BaseModel):
    id_token: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class RefreshTokenReq(BaseModel):
    refresh_token: str
