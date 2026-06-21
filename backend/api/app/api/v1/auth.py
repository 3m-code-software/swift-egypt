from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.schemas.user import (
    ForgotPasswordRequest,
    LoginRequest,
    RefreshTokenRequest,
    ResetPasswordRequest,
    TokenResponse,
    UserCreate,
    UserResponse,
    UserWithToken,
    VerifyOtpRequest,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserWithToken, status_code=status.HTTP_201_CREATED)
async def register(data: UserCreate, db: AsyncSession = Depends(get_db)):
    """Register a new user with customer profile."""
    service = AuthService(db)
    result = await service.register_user(
        email=data.email,
        password=data.password,
        full_name=data.full_name,
        phone=data.phone,
        company_name=data.company_name,
        tax_number=data.tax_number,
    )
    return UserWithToken(
        user=UserResponse.model_validate(result["user"]),
        token=TokenResponse(
            access_token=result["access_token"],
            refresh_token=result["refresh_token"],
        ),
    )


@router.post("/login", response_model=UserWithToken)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Authenticate user and return tokens."""
    service = AuthService(db)
    result = await service.authenticate_user(email=data.email, password=data.password)
    return UserWithToken(
        user=UserResponse.model_validate(result["user"]),
        token=TokenResponse(
            access_token=result["access_token"],
            refresh_token=result["refresh_token"],
        ),
    )


@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    """Generate password reset OTP sent to email."""
    service = AuthService(db)
    result = await service.forgot_password(data.email)
    return result


@router.post("/verify-reset-otp")
async def verify_reset_otp(data: VerifyOtpRequest, db: AsyncSession = Depends(get_db)):
    """Verify OTP for password reset."""
    service = AuthService(db)
    result = await service.verify_reset_otp(data.email, data.otp)
    return result


@router.post("/reset-password")
async def reset_password(data: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    """Reset password using OTP."""
    service = AuthService(db)
    await service.reset_password(data.email, data.otp, data.new_password)
    return {"message": "Password reset successfully"}


@router.post("/refresh-token", response_model=TokenResponse)
async def refresh_token(data: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    """Refresh access token using refresh token."""
    service = AuthService(db)
    result = await service.refresh_token(token=data.refresh_token)
    return TokenResponse(
        access_token=result["access_token"],
        refresh_token=result["refresh_token"],
    )


@router.post("/logout")
async def logout():
    """Logout the current user (client-side token invalidation)."""
    return {"message": "Logged out successfully"}
