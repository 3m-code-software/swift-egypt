import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, String, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base

import enum


class PaymentMethod(str, enum.Enum):
    cash = "cash"
    credit_card = "credit_card"
    bank_transfer = "bank_transfer"
    online = "online"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    completed = "completed"
    failed = "failed"
    refunded = "refunded"


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("invoices.id"), nullable=True)
    shipment_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("shipments.id"), nullable=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    payment_method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod), nullable=False)
    status: Mapped[PaymentStatus] = mapped_column(Enum(PaymentStatus), default=PaymentStatus.pending)
    transaction_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    collected_by: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
