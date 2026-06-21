import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, Text, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ServiceType(str, enum.Enum):
    international_road = "international_road"
    maritime = "maritime"
    domestic = "domestic"


class ShipmentStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    picked_up = "picked_up"
    in_transit = "in_transit"
    at_terminal = "at_terminal"
    customs_clearance = "customs_clearance"
    out_for_delivery = "out_for_delivery"
    delivered = "delivered"
    failed_attempt = "failed_attempt"
    delayed = "delayed"
    on_hold = "on_hold"
    cancelled = "cancelled"
    returned = "returned"


class Shipment(Base):
    __tablename__ = "shipments"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    tracking_number: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    service_type: Mapped[ServiceType] = mapped_column(Enum(ServiceType), nullable=False)
    status: Mapped[ShipmentStatus] = mapped_column(Enum(ShipmentStatus), default=ShipmentStatus.pending, nullable=False)
    customer_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("customers.id"), nullable=False)
    driver_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("drivers.id"), nullable=True)
    vehicle_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("vehicles.id"), nullable=True)
    container_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("containers.id"), nullable=True)
    voyage_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("voyages.id"), nullable=True)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("branches.id"), nullable=True)
    pickup_address: Mapped[str | None] = mapped_column(Text, nullable=True)
    delivery_address: Mapped[str | None] = mapped_column(Text, nullable=True)
    pickup_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    pickup_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    delivery_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    delivery_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    sender_name: Mapped[str] = mapped_column(String(255), nullable=False)
    sender_phone: Mapped[str] = mapped_column(String(20), nullable=False)
    recipient_name: Mapped[str] = mapped_column(String(255), nullable=False)
    recipient_phone: Mapped[str] = mapped_column(String(20), nullable=False)
    estimated_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    final_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    weight: Mapped[float | None] = mapped_column(Float, nullable=True)
    volume_weight: Mapped[float | None] = mapped_column(Float, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    items = relationship("ShipmentItem", back_populates="shipment", cascade="all, delete-orphan")
    tracking_events = relationship("TrackingEvent", back_populates="shipment", cascade="all, delete-orphan")
    documents = relationship("Document", back_populates="shipment", cascade="all, delete-orphan")


class ShipmentItem(Base):
    __tablename__ = "shipment_items"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    shipment_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("shipments.id"), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    weight: Mapped[float | None] = mapped_column(Float, nullable=True)
    length: Mapped[float | None] = mapped_column(Float, nullable=True)
    width: Mapped[float | None] = mapped_column(Float, nullable=True)
    height: Mapped[float | None] = mapped_column(Float, nullable=True)
    volume_weight: Mapped[float | None] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    shipment = relationship("Shipment", back_populates="items")
