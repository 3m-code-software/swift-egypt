from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class TrackingEventCreate(BaseModel):
    shipment_id: UUID
    event_type: str
    new_status: str | None = None
    location: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    description: str | None = None


class TrackingEventResponse(BaseModel):
    id: UUID
    shipment_id: UUID
    event_type: str
    new_status: str | None
    location: str | None
    latitude: float | None
    longitude: float | None
    description: str | None
    user_id: UUID | None
    created_at: datetime

    model_config = {"from_attributes": True}


class LiveLocationResponse(BaseModel):
    shipment_id: UUID
    latitude: float | None
    longitude: float | None
    last_updated: datetime | None
    status: str | None
