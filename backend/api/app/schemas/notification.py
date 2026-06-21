from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: UUID
    user_id: UUID
    title: str
    message: str | None = None
    type: str
    is_read: bool = False
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class NotificationCreate(BaseModel):
    user_id: UUID
    title: str
    message: str | None = None
    type: str = "info"


class UnreadCountResponse(BaseModel):
    count: int
