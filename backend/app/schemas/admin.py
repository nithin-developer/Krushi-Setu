from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class AdminBase(BaseModel):
    full_name: str
    email: EmailStr
    role: str = "admin"  # admin, super_admin

class AdminCreate(AdminBase):
    password: str

class AdminInDB(AdminBase):
    id: str = Field(alias="_id")
    password_hash: str
    status: str = "active"
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True

class AdminResponse(AdminBase):
    id: str
    status: str
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

class AdminLogin(BaseModel):
    email: EmailStr
    password: str

class AdminToken(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class RefreshTokenReq(BaseModel):
    refresh_token: str