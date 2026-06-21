from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import NotFoundException
from app.models.shipment import Shipment
from app.models.tracking_event import TrackingEvent


class TrackingService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_events(self, shipment_id: UUID) -> list[TrackingEvent]:
        result = await self.db.execute(
            select(TrackingEvent)
            .where(TrackingEvent.shipment_id == shipment_id)
            .order_by(TrackingEvent.created_at.desc())
        )
        return list(result.scalars().all())

    async def create_event(self, shipment_id: UUID, event_type: str, new_status: str | None = None, location: str | None = None, latitude: float | None = None, longitude: float | None = None, description: str | None = None, user_id: UUID | None = None) -> TrackingEvent:
        event = TrackingEvent(
            shipment_id=shipment_id,
            event_type=event_type,
            new_status=new_status,
            location=location,
            latitude=latitude,
            longitude=longitude,
            description=description,
            user_id=user_id,
        )
        self.db.add(event)
        await self.db.flush()
        return event

    async def get_live_location(self, shipment_id: UUID) -> dict:
        result = await self.db.execute(
            select(Shipment).options(selectinload(Shipment.tracking_events)).where(Shipment.id == shipment_id)
        )
        shipment = result.scalar_one_or_none()
        if not shipment:
            raise NotFoundException("Shipment not found")

        latest = None
        for event in shipment.tracking_events:
            if event.latitude and event.longitude:
                if not latest or event.created_at > latest.created_at:
                    latest = event

        return {
            "shipment_id": shipment.id,
            "latitude": latest.latitude if latest else None,
            "longitude": latest.longitude if latest else None,
            "last_updated": latest.created_at if latest else None,
            "status": shipment.status.value if hasattr(shipment.status, 'value') else shipment.status,
        }
