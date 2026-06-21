from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_admin_user, get_current_active_user, get_db
from app.models.user import User
from app.models.vehicle import Vehicle

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])


@router.get("/", response_model=list[dict])
async def list_vehicles(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """List all vehicles."""
    result = await db.execute(select(Vehicle).order_by(Vehicle.created_at.desc()))
    vehicles = result.scalars().all()
    return [
        {
            "id": str(v.id),
            "plate_number": v.plate_number,
            "model": v.model,
            "type": v.type,
            "max_weight": v.max_weight,
            "max_volume": v.max_volume,
            "branch_id": str(v.branch_id) if v.branch_id else None,
            "is_available": v.is_available,
            "created_at": v.created_at.isoformat() if v.created_at else None,
        }
        for v in vehicles
    ]


@router.get("/available", response_model=list[dict])
async def list_available_vehicles(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """List all available vehicles."""
    result = await db.execute(select(Vehicle).where(Vehicle.is_available == True).order_by(Vehicle.plate_number))
    vehicles = result.scalars().all()
    return [
        {
            "id": str(v.id),
            "plate_number": v.plate_number,
            "model": v.model,
            "type": v.type,
        }
        for v in vehicles
    ]


@router.post("/", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_vehicle(data: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Create a new vehicle (admin only)."""
    vehicle = Vehicle(**data)
    db.add(vehicle)
    await db.flush()
    return {"id": str(vehicle.id), "plate_number": vehicle.plate_number, "message": "Vehicle created"}


@router.get("/{vehicle_id}", response_model=dict)
async def get_vehicle(vehicle_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get vehicle details."""
    result = await db.execute(select(Vehicle).where(Vehicle.id == vehicle_id))
    vehicle = result.scalar_one_or_none()
    if not vehicle:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Vehicle not found")
    return {
        "id": str(vehicle.id),
        "plate_number": vehicle.plate_number,
        "model": vehicle.model,
        "type": vehicle.type,
        "max_weight": vehicle.max_weight,
        "max_volume": vehicle.max_volume,
        "branch_id": str(vehicle.branch_id) if vehicle.branch_id else None,
        "is_available": vehicle.is_available,
        "created_at": vehicle.created_at.isoformat() if vehicle.created_at else None,
    }


@router.put("/{vehicle_id}", response_model=dict)
async def update_vehicle(vehicle_id: str, data: dict, db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Update a vehicle (admin only)."""
    result = await db.execute(select(Vehicle).where(Vehicle.id == vehicle_id))
    vehicle = result.scalar_one_or_none()
    if not vehicle:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Vehicle not found")

    for key, value in data.items():
        if hasattr(vehicle, key):
            setattr(vehicle, key, value)

    await db.flush()
    return {"message": "Vehicle updated", "id": str(vehicle.id)}
