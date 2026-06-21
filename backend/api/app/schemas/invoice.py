from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class InvoiceCreate(BaseModel):
    shipment_id: UUID
    subtotal: float
    tax: float = 0
    insurance: float = 0
    additional_fees: float = 0
    notes: str | None = None


class InvoiceResponse(BaseModel):
    id: UUID
    shipment_id: UUID
    invoice_number: str
    subtotal: float
    tax: float
    insurance: float
    additional_fees: float
    total: float
    payment_status: str
    notes: str | None
    created_at: datetime
    paid_at: datetime | None

    model_config = {"from_attributes": True}


class PaymentRecord(BaseModel):
    invoice_id: UUID
    amount: float
    payment_method: str
    transaction_id: str | None = None
