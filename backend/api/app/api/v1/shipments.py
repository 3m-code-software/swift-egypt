from datetime import datetime

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, get_db, get_operations_user
from app.models.shipment import ShipmentStatus
from app.models.user import User, UserRole
from app.schemas.shipment import (
    AssignContainerRequest,
    AssignDriverRequest,
    AssignVehicleRequest,
    ShipmentCreate,
    ShipmentResponse,
    ShipmentUpdate,
)
from app.services.shipment_service import ShipmentService
from app.utils.pagination import PaginationParams, paginate

router = APIRouter(prefix="/shipments", tags=["Shipments"])


@router.post("/", response_model=ShipmentResponse, status_code=status.HTTP_201_CREATED)
async def create_shipment(data: ShipmentCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Create a new shipment."""
    service = ShipmentService(db)
    customer_id = current_user.customer.id if current_user.customer else current_user.id
    shipment = await service.create_shipment(customer_id=customer_id, data=data.model_dump())
    return ShipmentResponse.model_validate(shipment)


@router.get("/")
async def list_shipments(
    status_filter: str | None = Query(None, alias="status"),
    service_type: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    page: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """List shipments with filters and pagination."""
    service = ShipmentService(db)
    customer_id = current_user.customer.id if current_user.role == UserRole.customer and current_user.customer else None
    shipments, total = await service.list_shipments(
        customer_id=customer_id,
        status=status_filter,
        service_type=service_type,
        date_from=date_from,
        date_to=date_to,
        page=page.page,
        page_size=page.page_size,
    )
    items = [ShipmentResponse.model_validate(s) for s in shipments]
    return paginate(items, total, page)


@router.get("/{shipment_id}", response_model=ShipmentResponse)
async def get_shipment(shipment_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get shipment details with items and tracking events."""
    service = ShipmentService(db)
    shipment = await service.get_shipment(shipment_id)
    return ShipmentResponse.model_validate(shipment)


@router.put("/{shipment_id}", response_model=ShipmentResponse)
async def update_shipment(shipment_id: str, data: ShipmentUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Update shipment details."""
    service = ShipmentService(db)
    shipment = await service.update_shipment(shipment_id, data.model_dump(exclude_none=True))
    return ShipmentResponse.model_validate(shipment)


@router.post("/{shipment_id}/assign-driver", response_model=ShipmentResponse)
async def assign_driver(shipment_id: str, data: AssignDriverRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_operations_user)):
    """Assign a driver to shipment."""
    service = ShipmentService(db)
    shipment = await service.assign_driver(shipment_id, data.driver_id)
    return ShipmentResponse.model_validate(shipment)


@router.post("/{shipment_id}/assign-vehicle", response_model=ShipmentResponse)
async def assign_vehicle(shipment_id: str, data: AssignVehicleRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_operations_user)):
    """Assign a vehicle to shipment."""
    service = ShipmentService(db)
    shipment = await service.assign_vehicle(shipment_id, data.vehicle_id)
    return ShipmentResponse.model_validate(shipment)


@router.post("/{shipment_id}/assign-container", response_model=ShipmentResponse)
async def assign_container(shipment_id: str, data: AssignContainerRequest, db: AsyncSession = Depends(get_db), user: User = Depends(get_operations_user)):
    """Assign a container to shipment."""
    service = ShipmentService(db)
    shipment = await service.assign_container(shipment_id, data.container_id)
    return ShipmentResponse.model_validate(shipment)


@router.post("/{shipment_id}/approve", response_model=ShipmentResponse)
async def approve_shipment(shipment_id: str, db: AsyncSession = Depends(get_db), user: User = Depends(get_operations_user)):
    """Approve and confirm a shipment."""
    service = ShipmentService(db)
    shipment = await service.approve_shipment(shipment_id)
    return ShipmentResponse.model_validate(shipment)


@router.post("/{shipment_id}/cancel", response_model=ShipmentResponse)
async def cancel_shipment(shipment_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Cancel a shipment."""
    service = ShipmentService(db)
    shipment = await service.cancel_shipment(shipment_id)
    return ShipmentResponse.model_validate(shipment)


@router.get("/tracking/{tracking_number}", response_model=ShipmentResponse)
async def track_by_number(tracking_number: str, db: AsyncSession = Depends(get_db)):
    """Public tracking endpoint - get shipment by tracking number."""
    service = ShipmentService(db)
    shipment = await service.get_by_tracking_number(tracking_number)
    resp = ShipmentResponse.model_validate(shipment)
    resp.tracking_events = [{"id": str(e.id), "event_type": e.event_type, "new_status": e.new_status, "location": e.location, "description": e.description, "created_at": e.created_at.isoformat()} for e in shipment.tracking_events]
    return resp
