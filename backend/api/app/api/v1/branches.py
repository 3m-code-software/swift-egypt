from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_admin_user, get_db
from app.models.branch import Branch
from app.models.user import User

router = APIRouter(prefix="/branches", tags=["Branches"])


@router.get("/", response_model=list[dict])
async def list_branches(db: AsyncSession = Depends(get_db)):
    """List all branches."""
    result = await db.execute(select(Branch).where(Branch.is_active == True).order_by(Branch.name))
    branches = result.scalars().all()
    return [
        {
            "id": str(b.id),
            "name": b.name,
            "name_ar": b.name_ar,
            "address": b.address,
            "phone": b.phone,
            "latitude": b.latitude,
            "longitude": b.longitude,
            "is_active": b.is_active,
            "created_at": b.created_at.isoformat() if b.created_at else None,
        }
        for b in branches
    ]


@router.post("/", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_branch(data: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Create a new branch (admin only)."""
    branch = Branch(**data)
    db.add(branch)
    await db.flush()
    return {"id": str(branch.id), "name": branch.name, "message": "Branch created"}


@router.get("/{branch_id}", response_model=dict)
async def get_branch(branch_id: str, db: AsyncSession = Depends(get_db)):
    """Get branch details."""
    result = await db.execute(select(Branch).where(Branch.id == branch_id))
    branch = result.scalar_one_or_none()
    if not branch:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Branch not found")
    return {
        "id": str(branch.id),
        "name": branch.name,
        "name_ar": branch.name_ar,
        "address": branch.address,
        "phone": branch.phone,
        "manager_id": str(branch.manager_id) if branch.manager_id else None,
        "latitude": branch.latitude,
        "longitude": branch.longitude,
        "is_active": branch.is_active,
        "created_at": branch.created_at.isoformat() if branch.created_at else None,
    }


@router.put("/{branch_id}", response_model=dict)
async def update_branch(branch_id: str, data: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Update a branch (admin only)."""
    result = await db.execute(select(Branch).where(Branch.id == branch_id))
    branch = result.scalar_one_or_none()
    if not branch:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Branch not found")

    for key, value in data.items():
        if hasattr(branch, key):
            setattr(branch, key, value)

    await db.flush()
    return {"message": "Branch updated", "id": str(branch.id)}
