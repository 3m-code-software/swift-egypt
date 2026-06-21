from datetime import datetime
from pydantic import BaseModel


class BatchOrderResponse(BaseModel):
    id: str
    batch_id: str
    customer_name: str
    customer_phone: str
    customer_phone2: str | None = None
    address: str
    province: str | None = None
    city: str | None = None
    product_name: str | None = None
    quantity: int = 1
    product_price: float = 0.0
    shipping_cost: float = 0.0
    commission: float = 0.0
    total: float = 0.0
    notes: str | None = None
    status: str = "pending"
    delivery_notes: str | None = None
    returned_reason: str | None = None
    collected_amount: float | None = None
    latitude: float | None = None
    longitude: float | None = None
    assigned_agent_id: str | None = None
    created_at: str | None = None
    updated_at: str | None = None

    model_config = {"from_attributes": True}


class BatchOrderUpdate(BaseModel):
    customer_name: str | None = None
    customer_phone: str | None = None
    customer_phone2: str | None = None
    address: str | None = None
    province: str | None = None
    city: str | None = None
    product_name: str | None = None
    quantity: int | None = None
    product_price: float | None = None
    shipping_cost: float | None = None
    commission: float | None = None
    total: float | None = None
    notes: str | None = None


class BatchResponse(BaseModel):
    id: str
    seller_id: str
    branch_id: str | None = None
    batch_number: str
    status: str = "pending"
    total_orders: int = 0
    total_amount: float = 0.0
    commission_percent: float = 0.0
    commission_amount: float = 0.0
    notes: str | None = None
    reviewed_by: str | None = None
    reviewed_at: str | None = None
    file_name: str | None = None
    seller_name: str | None = None
    orders: list[BatchOrderResponse] = []
    created_at: str | None = None
    updated_at: str | None = None

    model_config = {"from_attributes": True}


class BatchListResponse(BaseModel):
    id: str
    seller_id: str
    batch_number: str
    status: str
    total_orders: int
    total_amount: float
    commission_percent: float
    seller_name: str | None = None
    file_name: str | None = None
    created_at: str | None = None

    model_config = {"from_attributes": True}


class BatchApproveRequest(BaseModel):
    commission_percent: float = 0.0
    notes: str | None = None


class BatchRejectRequest(BaseModel):
    reason: str
