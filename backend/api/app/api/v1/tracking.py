from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, get_db, get_operations_user
from app.models.user import User
from app.schemas.tracking import LiveLocationResponse, TrackingEventCreate, TrackingEventResponse
from app.services.tracking_service import TrackingService

router = APIRouter(prefix="/tracking", tags=["Tracking"])


@router.get("/shipment/{shipment_id}", response_model=list[TrackingEventResponse])
async def get_tracking_events(shipment_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get all tracking events for a shipment."""
    service = TrackingService(db)
    events = await service.get_events(shipment_id)
    return [TrackingEventResponse.model_validate(e) for e in events]


@router.post("/", response_model=TrackingEventResponse, status_code=status.HTTP_201_CREATED)
async def create_tracking_event(data: TrackingEventCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Create a new tracking event."""
    service = TrackingService(db)
    event = await service.create_event(
        shipment_id=data.shipment_id,
        event_type=data.event_type,
        new_status=data.new_status,
        location=data.location,
        latitude=data.latitude,
        longitude=data.longitude,
        description=data.description,
        user_id=current_user.id,
    )
    return TrackingEventResponse.model_validate(event)


@router.get("/live/{shipment_id}", response_model=LiveLocationResponse)
async def get_live_location(shipment_id: UUID, db: AsyncSession = Depends(get_db)):
    """Get latest live location for a shipment."""
    service = TrackingService(db)
    location = await service.get_live_location(shipment_id)
    return LiveLocationResponse(**location)
