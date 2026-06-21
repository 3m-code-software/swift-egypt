import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Float, String, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models.shipment import ServiceType


class PricingRule(Base):
    __tablename__ = "pricing_rules"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    service_type: Mapped[ServiceType] = mapped_column(Enum(ServiceType), nullable=False)
    base_price: Mapped[float] = mapped_column(Float, nullable=False)
    price_per_kg: Mapped[float] = mapped_column(Float, default=0)
    price_per_volume: Mapped[float] = mapped_column(Float, default=0)
    min_price: Mapped[float] = mapped_column(Float, default=0)
    origin_country: Mapped[str | None] = mapped_column(String(100), nullable=True)
    destination_country: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
