import os
import uuid as uuid_lib
from pathlib import Path

from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_admin_user, get_current_active_user, get_db
from app.core.exceptions import NotFoundException
from app.models.branch import Branch
from app.models.user import User, UserRole
from app.schemas.user import ChangePasswordRequest, RoleUpdateRequest, UserResponse, UserUpdate
from app.services.auth_service import AuthService
from app.config import settings
from app.utils.pagination import PaginationParams, paginate

router = APIRouter(prefix="/users", tags=["Users"])


async def _enrich_user_response(user: User, db: AsyncSession) -> dict:
    data = UserResponse.model_validate(user).model_dump()
    if user.branch_id:
        branch = await db.get(Branch, user.branch_id)
        data["branch_name"] = branch.name if branch else None
    return data


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_active_user), db: AsyncSession = Depends(get_db)):
    """Get current authenticated user profile."""
    return await _enrich_user_response(current_user, db)


@router.put("/me", response_model=UserResponse)
async def update_profile(data: UserUpdate, current_user: User = Depends(get_current_active_user), db: AsyncSession = Depends(get_db)):
    """Update current user profile."""
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.phone is not None:
        current_user.phone = data.phone
    if data.email is not None:
        current_user.email = data.email
    await db.flush()
    await db.refresh(current_user)
    return await _enrich_user_response(current_user, db)


@router.put("/me/password")
async def change_password(data: ChangePasswordRequest, current_user: User = Depends(get_current_active_user), db: AsyncSession = Depends(get_db)):
    """Change current user password."""
    service = AuthService(db)
    await service.change_password(current_user, data.current_password, data.new_password)
    return {"message": "Password changed successfully"}


@router.post("/me/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload profile avatar image."""
    ext = Path(file.filename or "avatar.jpg").suffix if file.filename else ".jpg"
    filename = f"{uuid_lib.uuid4().hex}{ext}"
    upload_dir = Path("uploads/avatars")
    upload_dir.mkdir(parents=True, exist_ok=True)
    filepath = upload_dir / filename

    contents = await file.read()
    filepath.write_bytes(contents)

    avatar_url = f"/uploads/avatars/{filename}"
    current_user.avatar_url = avatar_url
    await db.flush()

    return {"avatar_url": avatar_url, "message": "Avatar uploaded successfully"}


@router.get("/")
async def list_users(page: PaginationParams = Depends(), db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """List all users (admin only)."""
    query = select(User).order_by(User.created_at.desc())
    total_result = await db.execute(select(select(User).subquery()))
    count_query = select(User).order_by(User.created_at.desc())
    result = await db.execute(query.offset(page.offset).limit(page.limit))
    users = result.scalars().all()
    total_result = await db.execute(select(User))
    total = len(total_result.scalars().all())
    items = [UserResponse.model_validate(u) for u in users]
    return paginate(items, total, page)


@router.put("/{user_id}/role", response_model=UserResponse)
async def change_user_role(user_id: str, data: RoleUpdateRequest, db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Change user role (admin only)."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")
    user.role = UserRole(data.role)
    await db.flush()
    return UserResponse.model_validate(user)
