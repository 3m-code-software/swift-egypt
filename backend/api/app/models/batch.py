import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, Text, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class BatchStatus(str, enum.Enum):
    pending = "pending"
    under_review = "under_review"
    approved = "approved"
    rejected = "rejected"
    partially_approved = "partially_approved"


class Batch(Base):
    __tablename__ = "batches"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    seller_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("sellers.id"), nullable=False)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("branches.id"), nullable=True)
    batch_number: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    status: Mapped[BatchStatus] = mapped_column(Enum(BatchStatus), default=BatchStatus.pending, nullable=False)
    total_orders: Mapped[int] = mapped_column(Integer, default=0)
    total_amount: Mapped[float] = mapped_column(Float, default=0.0)
    commission_percent: Mapped[float] = mapped_column(Float, default=0.0)
    commission_amount: Mapped[float] = mapped_column(Float, default=0.0)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("users.id"), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    file_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    seller = relationship("Seller", back_populates="batches")
    branch = relationship("Branch")
    reviewer = relationship("User", foreign_keys=[reviewed_by])
    orders = relationship("BatchOrder", back_populates="batch", cascade="all, delete-orphan")


class OrderStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    delivered = "delivered"
    partial = "partial"
    returned = "returned"
    no_answer = "no_answer"


class BatchOrder(Base):
    __tablename__ = "batch_orders"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    batch_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("batches.id"), nullable=False)
    customer_name: Mapped[str] = mapped_column(String(255), nullable=False)
    customer_phone: Mapped[str] = mapped_column(String(20), nullable=False)
    customer_phone2: Mapped[str | None] = mapped_column(String(20), nullable=True)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    province: Mapped[str | None] = mapped_column(String(100), nullable=True)
    city: Mapped[str | None] = mapped_column(String(100), nullable=True)
    product_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    product_price: Mapped[float] = mapped_column(Float, default=0.0)
    shipping_cost: Mapped[float] = mapped_column(Float, default=0.0)
    commission: Mapped[float] = mapped_column(Float, default=0.0)
    total: Mapped[float] = mapped_column(Float, default=0.0)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[OrderStatus] = mapped_column(Enum(OrderStatus), default=OrderStatus.pending, nullable=False)
    delivery_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    returned_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    collected_amount: Mapped[float | None] = mapped_column(Float, nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    assigned_agent_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("drivers.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    batch = relationship("Batch", back_populates="orders")
    assigned_agent = relationship("Driver")
