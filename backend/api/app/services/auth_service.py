import secrets
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, ConflictException, NotFoundException, UnauthorizedException
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
    verify_token,
)
from app.models.customer import Customer
from app.models.password_reset import PasswordResetToken
from app.models.user import User, UserRole


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register_user(self, email: str, password: str, full_name: str, phone: str | None = None, company_name: str | None = None, tax_number: str | None = None) -> dict:
        existing = await self.db.execute(select(User).where(User.email == email))
        if existing.scalar_one_or_none():
            raise ConflictException("Email already registered")

        user = User(
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
            phone=phone,
            role=UserRole.customer,
        )
        self.db.add(user)
        await self.db.flush()

        customer = Customer(
            user_id=user.id,
            company_name=company_name,
            tax_number=tax_number,
        )
        self.db.add(customer)
        await self.db.flush()

        access_token = create_access_token(user.id, user.role.value)
        refresh_token = create_refresh_token(user.id)

        return {
            "user": user,
            "access_token": access_token,
            "refresh_token": refresh_token,
        }

    async def authenticate_user(self, email: str, password: str) -> dict:
        result = await self.db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()

        if not user or not verify_password(password, user.hashed_password):
            raise UnauthorizedException("Invalid email or password")

        if not user.is_active:
            raise UnauthorizedException("Account is deactivated")

        access_token = create_access_token(user.id, user.role.value)
        refresh_token = create_refresh_token(user.id)

        return {
            "user": user,
            "access_token": access_token,
            "refresh_token": refresh_token,
        }

    async def refresh_token(self, token: str) -> dict:
        payload = verify_token(token)
        if not payload or payload.get("type") != "refresh":
            raise UnauthorizedException("Invalid refresh token")

        user_id = payload.get("sub")
        if not user_id:
            raise UnauthorizedException("Invalid token payload")

        result = await self.db.execute(select(User).where(User.id == UUID(user_id)))
        user = result.scalar_one_or_none()
        if not user or not user.is_active:
            raise UnauthorizedException("User not found or inactive")

        access_token = create_access_token(user.id, user.role.value)
        refresh_token = create_refresh_token(user.id)

        return {
            "user": user,
            "access_token": access_token,
            "refresh_token": refresh_token,
        }

    async def change_password(self, user: User, current_password: str, new_password: str) -> None:
        if not verify_password(current_password, user.hashed_password):
            raise BadRequestException("Current password is incorrect")
        if len(new_password) < 8:
            raise BadRequestException("New password must be at least 8 characters")
        user.hashed_password = hash_password(new_password)
        await self.db.flush()

    async def get_user_by_id(self, user_id: UUID) -> User:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise NotFoundException("User not found")
        return user

    async def forgot_password(self, email: str) -> dict:
        result = await self.db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if not user:
            return {"message": "If the email exists, a reset code has been sent"}

        otp = f"{secrets.randbelow(900000) + 100000}"
        token = secrets.token_urlsafe(32)
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)

        reset = PasswordResetToken(
            user_id=user.id,
            otp=otp,
            token=token,
            expires_at=expires_at,
        )
        self.db.add(reset)
        await self.db.flush()

        return {
            "message": "If the email exists, a reset code has been sent",
            "otp": otp,
            "token": token,
            "expires_at": expires_at.isoformat(),
        }

    async def verify_reset_otp(self, email: str, otp: str) -> dict:
        result = await self.db.execute(
            select(PasswordResetToken)
            .join(User)
            .where(
                User.email == email,
                PasswordResetToken.otp == otp,
                PasswordResetToken.is_used == False,
                PasswordResetToken.expires_at > datetime.now(timezone.utc),
            )
            .order_by(PasswordResetToken.created_at.desc())
        )
        reset = result.scalar_one_or_none()
        if not reset:
            raise BadRequestException("Invalid or expired OTP")

        return {"token": reset.token, "message": "OTP verified"}

    async def reset_password(self, email: str, otp: str, new_password: str) -> None:
        result = await self.db.execute(
            select(PasswordResetToken)
            .join(User)
            .where(
                User.email == email,
                PasswordResetToken.otp == otp,
                PasswordResetToken.is_used == False,
                PasswordResetToken.expires_at > datetime.now(timezone.utc),
            )
            .order_by(PasswordResetToken.created_at.desc())
        )
        reset = result.scalar_one_or_none()
        if not reset:
            raise BadRequestException("Invalid or expired OTP")

        if len(new_password) < 6:
            raise BadRequestException("Password must be at least 6 characters")

        user_result = await self.db.execute(select(User).where(User.id == reset.user_id))
        user = user_result.scalar_one_or_none()
        if not user:
            raise NotFoundException("User not found")

        user.hashed_password = hash_password(new_password)
        reset.is_used = True
        await self.db.flush()
