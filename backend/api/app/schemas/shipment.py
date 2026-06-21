from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class ShipmentItemCreate(BaseModel):
    description: str
    quantity: int = 1
    weight: float | None = None
    length: float | None = None
    width: float | None = None
    height: float | None = None


class ShipmentItemResponse(BaseModel):
    id: UUID
    shipment_id: UUID
    description: str
    quantity: int
    weight: float | None
    length: float | None
    width: float | None
    height: float | None
    volume_weight: float | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ShipmentCreate(BaseModel):
    service_type: str
    pickup_address: str | None = None
    delivery_address: str | None = None
    pickup_latitude: float | None = None
    pickup_longitude: float | None = None
    delivery_latitude: float | None = None
    delivery_longitude: float | None = None
    sender_name: str
    sender_phone: str
    recipient_name: str
    recipient_phone: str
    weight: float | None = None
    notes: str | None = None
    items: list[ShipmentItemCreate] = []


class ShipmentUpdate(BaseModel):
    pickup_address: str | None = None
    delivery_address: str | None = None
    recipient_name: str | None = None
    recipient_phone: str | None = None
    weight: float | None = None
    notes: str | None = None


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


class ShipmentResponse(BaseModel):
    id: UUID
    tracking_number: str
    service_type: str
    status: str
    customer_id: UUID
    driver_id: UUID | None
    vehicle_id: UUID | None
    container_id: UUID | None
    voyage_id: UUID | None
    branch_id: UUID | None
    pickup_address: str | None
    delivery_address: str | None
    pickup_latitude: float | None
    pickup_longitude: float | None
    delivery_latitude: float | None
    delivery_longitude: float | None
    sender_name: str
    sender_phone: str
    recipient_name: str
    recipient_phone: str
    estimated_price: float | None
    final_price: float | None
    weight: float | None
    volume_weight: float | None
    notes: str | None
    created_at: datetime
    updated_at: datetime
    items: list[ShipmentItemResponse] = []
    tracking_events: list[TrackingEventResponse] | None = None

    model_config = {"from_attributes": True}


class AssignDriverRequest(BaseModel):
    driver_id: UUID


class AssignVehicleRequest(BaseModel):
    vehicle_id: UUID


class AssignContainerRequest(BaseModel):
    container_id: UUID


class ShipmentListResponse(BaseModel):
    items: list[ShipmentResponse]
    total: int
    page: int
    page_size: int
    total_pages: int
