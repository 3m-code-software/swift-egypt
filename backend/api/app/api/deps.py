from uuid import UUID

from fastapi import Depends, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

security_scheme = HTTPBearer()
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.core.security import verify_token
from app.database import get_db
from app.models.user import User, UserRole


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    payload = verify_token(token)

    if not payload or payload.get("type") != "access":
        raise UnauthorizedException("Invalid or expired token")

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Invalid token payload")

    result = await db.execute(
        select(User).options(selectinload(User.customer), selectinload(User.driver)).where(User.id == UUID(user_id))
    )
    user = result.scalar_one_or_none()

    if not user:
        raise UnauthorizedException("User not found")

    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_active:
        raise ForbiddenException("Account is deactivated")
    return current_user


async def get_admin_user(
    current_user: User = Depends(get_current_active_user),
) -> User:
    if current_user.role != UserRole.admin:
        raise ForbiddenException("Admin privileges required")
    return current_user


async def get_operations_user(
    current_user: User = Depends(get_current_active_user),
) -> User:
    if current_user.role not in [UserRole.admin, UserRole.operations]:
        raise ForbiddenException("Operations privileges required")
    return current_user


async def get_branch_manager_user(
    current_user: User = Depends(get_current_active_user),
) -> User:
    if current_user.role not in [UserRole.admin, UserRole.operations, UserRole.branch_manager]:
        raise ForbiddenException("Branch manager privileges required")
    return current_user
