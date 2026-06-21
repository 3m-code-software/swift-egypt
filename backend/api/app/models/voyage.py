import uuid
from datetime import datetime

from sqlalchemy import DateTime, String, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Voyage(Base):
    __tablename__ = "voyages"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    voyage_number: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    origin_port: Mapped[str] = mapped_column(String(255), nullable=False)
    destination_port: Mapped[str] = mapped_column(String(255), nullable=False)
    departure_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    arrival_date_eta: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="scheduled")
    vessel_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
