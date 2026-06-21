import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Container(Base):
    __tablename__ = "containers"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    container_number: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    size: Mapped[str] = mapped_column(String(20), nullable=False)
    type: Mapped[str] = mapped_column(String(100), nullable=False)
    voyage_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("voyages.id"), nullable=True)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
