from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SupportTicketCreate(BaseModel):
    subject: str
    message: str
    shipment_id: UUID | None = None


class SupportTicketResponse(BaseModel):
    id: UUID
    customer_id: UUID | None
    shipment_id: UUID | None
    subject: str
    message: str
    status: str
    assigned_to: UUID | None
    created_at: datetime
    resolved_at: datetime | None

    model_config = {"from_attributes": True}


class TicketReply(BaseModel):
    message: str


class ChatRequest(BaseModel):
    query: str
    session_id: str | None = None


class ChatResponse(BaseModel):
    response: str
    session_id: str
