from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_admin_user, get_db
from app.models.user import User
from app.schemas.pricing import (
    PriceEstimateRequest,
    PriceEstimateResponse,
    PricingRuleCreate,
    PricingRuleResponse,
)
from app.services.pricing_service import PricingService

router = APIRouter(prefix="/pricing", tags=["Pricing"])


@router.post("/estimate", response_model=PriceEstimateResponse)
async def estimate_price(data: PriceEstimateRequest, db: AsyncSession = Depends(get_db)):
    """Calculate estimated price for a shipment."""
    service = PricingService(db)
    result = await service.estimate_price(
        service_type=data.service_type,
        weight=data.weight,
        volume_weight=data.volume_weight,
        origin_country=data.origin_country,
        destination_country=data.destination_country,
    )
    return PriceEstimateResponse(**result)


@router.get("/rules", response_model=list[PricingRuleResponse])
async def list_rules(db: AsyncSession = Depends(get_db)):
    """List all pricing rules."""
    service = PricingService(db)
    rules = await service.list_rules()
    return [PricingRuleResponse.model_validate(r) for r in rules]


@router.post("/rules", response_model=PricingRuleResponse, status_code=status.HTTP_201_CREATED)
async def create_rule(data: PricingRuleCreate, db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Create a new pricing rule (admin only)."""
    service = PricingService(db)
    rule = await service.create_rule(data.model_dump())
    return PricingRuleResponse.model_validate(rule)


@router.put("/rules/{rule_id}", response_model=PricingRuleResponse)
async def update_rule(rule_id: str, data: PricingRuleCreate, db: AsyncSession = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Update a pricing rule (admin only)."""
    service = PricingService(db)
    rule = await service.update_rule(rule_id, data.model_dump())
    return PricingRuleResponse.model_validate(rule)
