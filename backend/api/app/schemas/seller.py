from datetime import datetime
from pydantic import BaseModel


class SellerResponse(BaseModel):
    id: str
    user_id: str
    company_name: str | None = None
    tax_number: str | None = None
    commercial_register: str | None = None
    address: str | None = None
    wallet_balance: float = 0.0
    total_orders: int = 0
    total_delivered: int = 0
    total_returned: int = 0
    full_name: str | None = None
    email: str | None = None
    phone: str | None = None
    created_at: str | None = None

    model_config = {"from_attributes": True}


class SellerWalletResponse(BaseModel):
    wallet_balance: float
    pending_amount: float = 0.0
    total_earned: float = 0.0
    total_commission: float = 0.0


class SellerAnalyticsResponse(BaseModel):
    total_orders: int
    total_delivered: int
    total_returned: int
    pending_orders: int
    delivery_rate: float
    return_rate: float
    total_revenue: float
    period_days: int = 30
