import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, Text, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Seller(Base):
    __tablename__ = "sellers"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("users.id"), nullable=False, unique=True)
    company_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    tax_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    commercial_register: Mapped[str | None] = mapped_column(String(50), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    wallet_balance: Mapped[float] = mapped_column(Float, default=0.0)
    total_orders: Mapped[int] = mapped_column(default=0)
    total_delivered: Mapped[int] = mapped_column(default=0)
    total_returned: Mapped[int] = mapped_column(default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="seller")
    batches = relationship("Batch", back_populates="seller", cascade="all, delete-orphan")
