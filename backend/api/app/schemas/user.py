from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: str | None = None
    company_name: str | None = None
    tax_number: str | None = None


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    email: EmailStr | None = None


class UserResponse(BaseModel):
    id: UUID
    email: str
    phone: str | None
    full_name: str
    role: str
    branch_id: UUID | None
    branch_name: str | None = None
    is_active: bool
    is_verified: bool
    avatar_url: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserWithToken(BaseModel):
    user: UserResponse
    token: TokenResponse


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    otp: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class RoleUpdateRequest(BaseModel):
    role: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
