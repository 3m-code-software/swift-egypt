from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_admin_user, get_current_active_user, get_db, get_operations_user
from app.core.exceptions import BadRequestException, NotFoundException
from app.models.driver import Driver
from app.models.shipment import Shipment, ShipmentStatus
from app.models.user import User
from app.schemas.driver import (
    CollectionCreate,
    DriverCreate,
    DriverPerformance,
    DriverResponse,
    DriverUpdate,
    LocationUpdate,
    ProofOfDeliveryCreate,
    ProofOfPickupCreate,
    TaskResponse,
    TaskStatusUpdate,
)
from app.services.shipment_service import ShipmentService
from app.utils.pagination import PaginationParams, paginate

router = APIRouter(prefix="/drivers", tags=["Drivers"])


@router.get("/tasks/today", response_model=list[TaskResponse])
async def get_today_tasks(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get today's tasks for the current driver."""
    if not current_user.driver:
        raise BadRequestException("User is not a driver")

    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    result = await db.execute(
        select(Shipment)
        .where(Shipment.driver_id == current_user.driver.id)
        .where(Shipment.status.in_([ShipmentStatus.confirmed, ShipmentStatus.picked_up, ShipmentStatus.in_transit, ShipmentStatus.out_for_delivery]))
        .order_by(Shipment.created_at.desc())
    )
    shipments = result.scalars().all()
    return [TaskResponse.model_validate(s) for s in shipments]


@router.get("/tasks/completed", response_model=list[TaskResponse])
async def get_completed_tasks(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    from_date: str | None = None,
    to_date: str | None = None,
    search: str | None = None,
):
    """Get completed tasks for the current driver."""
    if not current_user.driver:
        raise BadRequestException("User is not a driver")

    query = (
        select(Shipment)
        .where(Shipment.driver_id == current_user.driver.id)
        .where(Shipment.status.in_([ShipmentStatus.delivered, ShipmentStatus.returned, ShipmentStatus.cancelled]))
    )
    if from_date:
        try:
            fd = datetime.fromisoformat(from_date)
            query = query.where(Shipment.updated_at >= fd)
        except ValueError:
            pass
    if to_date:
        try:
            td = datetime.fromisoformat(to_date)
            query = query.where(Shipment.updated_at <= td)
        except ValueError:
            pass
    if search:
        query = query.where(Shipment.tracking_number.ilike(f"%{search}%"))
    query = query.order_by(Shipment.updated_at.desc())
    result = await db.execute(query)
    shipments = result.scalars().all()
    return [TaskResponse.model_validate(s) for s in shipments]


@router.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(task_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get task details."""
    result = await db.execute(select(Shipment).where(Shipment.id == task_id))
    shipment = result.scalar_one_or_none()
    if not shipment:
        raise NotFoundException("Task not found")
    return TaskResponse.model_validate(shipment)


@router.post("/tasks/{task_id}/start", response_model=TaskResponse)
async def start_task(task_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Start a delivery task."""
    service = ShipmentService(db)
    shipment = await service.update_status(task_id, ShipmentStatus.picked_up, "Driver started pickup")
    return TaskResponse.model_validate(shipment)


@router.post("/tasks/{task_id}/status", response_model=TaskResponse)
async def update_task_status(task_id: UUID, data: TaskStatusUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Update task status."""
    service = ShipmentService(db)
    new_status = ShipmentStatus(data.status)
    shipment = await service.update_status(task_id, new_status, data.description)
    return TaskResponse.model_validate(shipment)


@router.post("/tasks/{task_id}/proof-of-delivery", response_model=dict)
async def submit_proof_of_delivery(task_id: UUID, data: ProofOfDeliveryCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Submit proof of delivery for a task."""
    from app.models.proof_of_delivery import ProofOfDelivery
    shipment = await db.execute(select(Shipment).where(Shipment.id == task_id))
    shipment = shipment.scalar_one_or_none()
    if not shipment:
        raise NotFoundException("Shipment not found")

    pod = ProofOfDelivery(
        shipment_id=task_id,
        signature_url=data.signature_url or data.signature_path,
        photo_url=data.photo_url or data.photo_path,
        latitude=data.latitude,
        longitude=data.longitude,
        recipient_name=data.recipient_name,
        notes=data.notes,
        driver_id=current_user.driver.id if current_user.driver else None,
        delivered_at=datetime.now(timezone.utc),
    )
    db.add(pod)

    service = ShipmentService(db)
    await service.update_status(task_id, ShipmentStatus.delivered, "Delivered successfully")

    return {"message": "Proof of delivery submitted successfully"}


@router.post("/tasks/{task_id}/proof-of-pickup", response_model=dict)
async def submit_proof_of_pickup(task_id: UUID, data: ProofOfPickupCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Submit proof of pickup for a task."""
    shipment = await db.execute(select(Shipment).where(Shipment.id == task_id))
    shipment = shipment.scalar_one_or_none()
    if not shipment:
        raise NotFoundException("Shipment not found")

    from app.models.proof_of_delivery import ProofOfDelivery
    pod = ProofOfDelivery(
        shipment_id=task_id,
        signature_url=data.signature_url or data.signature_path,
        photo_url=data.photo_url or data.photo_path,
        notes=data.notes,
        driver_id=current_user.driver.id if current_user.driver else None,
        delivered_at=datetime.now(timezone.utc),
    )
    db.add(pod)

    service = ShipmentService(db)
    await service.update_status(task_id, ShipmentStatus.picked_up, "Driver completed pickup")
    return {"message": "Proof of pickup submitted successfully"}


@router.post("/tasks/{task_id}/collection", response_model=dict)
async def submit_collection(task_id: UUID, data: CollectionCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Submit payment collection for a task."""
    from app.models.payment import Payment, PaymentMethod, PaymentStatus
    payment = Payment(
        shipment_id=task_id,
        amount=data.amount,
        payment_method=PaymentMethod(data.payment_method),
        status=PaymentStatus.completed,
        collected_by=current_user.id,
    )
    db.add(payment)
    await db.flush()
    return {"message": "Collection submitted successfully"}


@router.post("/location", response_model=dict)
async def update_location(data: LocationUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Update driver's current location."""
    if not current_user.driver:
        raise BadRequestException("User is not a driver")

    driver = current_user.driver
    driver.current_latitude = data.latitude
    driver.current_longitude = data.longitude
    driver.last_location_update = datetime.now(timezone.utc)
    await db.flush()

    return {"message": "Location updated"}


@router.get("/", response_model=dict)
async def list_drivers(page: PaginationParams = Depends(), db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """List all drivers."""
    query = select(Driver).options(selectinload(Driver.user)).order_by(Driver.created_at.desc())
    result = await db.execute(query.offset(page.offset).limit(page.limit))
    drivers = result.scalars().all()
    total_result = await db.execute(select(Driver))
    total = len(total_result.scalars().all())
    items = []
    for d in drivers:
        resp = DriverResponse.model_validate(d)
        resp.user = {"id": str(d.user.id), "full_name": d.user.full_name, "email": d.user.email, "phone": d.user.phone}
        items.append(resp)
    return paginate(items, total, page)


@router.get("/{driver_id}", response_model=DriverResponse)
async def get_driver(driver_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get driver details."""
    result = await db.execute(select(Driver).options(selectinload(Driver.user)).where(Driver.id == driver_id))
    driver = result.scalar_one_or_none()
    if not driver:
        raise NotFoundException("Driver not found")
    resp = DriverResponse.model_validate(driver)
    if driver.user:
        resp.user = {"id": str(driver.user.id), "full_name": driver.user.full_name, "email": driver.user.email, "phone": driver.user.phone}
    return resp


@router.put("/{driver_id}", response_model=DriverResponse)
async def update_driver(driver_id: UUID, data: DriverUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_admin_user)):
    """Update driver details (admin only)."""
    result = await db.execute(select(Driver).options(selectinload(Driver.user)).where(Driver.id == driver_id))
    driver = result.scalar_one_or_none()
    if not driver:
        raise NotFoundException("Driver not found")
    if data.branch_id is not None:
        driver.branch_id = data.branch_id
    if data.vehicle_id is not None:
        driver.vehicle_id = data.vehicle_id
    if data.is_available is not None:
        driver.is_available = data.is_available
    await db.flush()
    await db.refresh(driver)
    resp = DriverResponse.model_validate(driver)
    if driver.user:
        resp.user = {"id": str(driver.user.id), "full_name": driver.user.full_name, "email": driver.user.email, "phone": driver.user.phone}
    return resp


@router.get("/{driver_id}/performance", response_model=DriverPerformance)
async def driver_performance(driver_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get driver performance stats."""
    result = await db.execute(select(Driver).where(Driver.id == driver_id))
    driver = result.scalar_one_or_none()
    if not driver:
        raise NotFoundException("Driver not found")

    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    today_result = await db.execute(
        select(Shipment).where(Shipment.driver_id == driver_id, Shipment.status == ShipmentStatus.delivered, Shipment.updated_at >= today_start)
    )
    completed_today = len(today_result.scalars().all())

    return DriverPerformance(
        driver_id=driver.id,
        driver_name=driver.user.full_name if driver.user else "Unknown",
        total_deliveries=driver.total_deliveries,
        completed_today=completed_today,
        average_delivery_time=None,
        rating=driver.rating,
        on_time_rate=None,
        total_distance=None,
    )
