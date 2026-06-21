from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class LocationUpdate(BaseModel):
    latitude: float
    longitude: float
    timestamp: str | None = None


class DriverCreate(BaseModel):
    user_id: UUID
    branch_id: UUID | None = None
    vehicle_id: UUID | None = None


class DriverUpdate(BaseModel):
    branch_id: UUID | None = None
    vehicle_id: UUID | None = None
    is_available: bool | None = None


class DriverResponse(BaseModel):
    id: UUID
    user_id: UUID
    branch_id: UUID | None
    vehicle_id: UUID | None
    is_available: bool
    current_latitude: float | None
    current_longitude: float | None
    last_location_update: datetime | None
    total_deliveries: int
    rating: float | None
    created_at: datetime
    user: dict | None = None

    model_config = {"from_attributes": True}


class TaskResponse(BaseModel):
    id: UUID
    tracking_number: str
    status: str
    pickup_address: str | None
    delivery_address: str | None
    recipient_name: str
    recipient_phone: str
    sender_name: str
    sender_phone: str
    weight: float | None
    notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class TaskStatusUpdate(BaseModel):
    status: str
    description: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class ProofOfDeliveryCreate(BaseModel):
    signature_url: str | None = None
    photo_url: str | None = None
    photo_path: str | None = None
    signature_path: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    recipient_name: str | None = None
    notes: str | None = None


class ProofOfPickupCreate(BaseModel):
    item_count: int = 1
    photo_url: str | None = None
    photo_path: str | None = None
    signature_url: str | None = None
    signature_path: str | None = None
    notes: str | None = None


class CollectionCreate(BaseModel):
    amount: float
    payment_method: str = "cash"


class DriverPerformance(BaseModel):
    driver_id: UUID
    driver_name: str
    total_deliveries: int
    completed_today: int
    average_delivery_time: float | None
    rating: float | None
    on_time_rate: float | None
    total_distance: float | None
