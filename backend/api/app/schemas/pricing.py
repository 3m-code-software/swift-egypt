from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class PriceEstimateRequest(BaseModel):
    service_type: str
    weight: float | None = None
    volume_weight: float | None = None
    origin_country: str | None = None
    destination_country: str | None = None


class PriceEstimateResponse(BaseModel):
    base_price: float
    weight_charge: float
    volume_charge: float
    total_estimate: float
    currency: str = "EGP"


class PricingRuleCreate(BaseModel):
    name: str
    service_type: str
    base_price: float
    price_per_kg: float = 0
    price_per_volume: float = 0
    min_price: float = 0
    origin_country: str | None = None
    destination_country: str | None = None
    is_active: bool = True


class PricingRuleResponse(BaseModel):
    id: UUID
    name: str
    service_type: str
    base_price: float
    price_per_kg: float
    price_per_volume: float
    min_price: float
    origin_country: str | None
    destination_country: str | None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
