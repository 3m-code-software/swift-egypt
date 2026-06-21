import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, func
from app.database import GUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

import enum


class UserRole(str, enum.Enum):
    customer = "customer"
    seller = "seller"
    driver = "driver"
    operations = "operations"
    branch_manager = "branch_manager"
    finance = "finance"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    phone: Mapped[str] = mapped_column(String(20), nullable=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), default=UserRole.customer, nullable=False)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(GUID(), ForeignKey("branches.id"), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    customer = relationship("Customer", back_populates="user", uselist=False)
    driver = relationship("Driver", back_populates="user", uselist=False)
    seller = relationship("Seller", back_populates="user", uselist=False)
