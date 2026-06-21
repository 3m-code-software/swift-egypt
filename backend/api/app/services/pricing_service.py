from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.pricing_rule import PricingRule
from app.models.shipment import ServiceType


class PricingService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def estimate_price(self, service_type: str, weight: float | None = None, volume_weight: float | None = None, origin_country: str | None = None, destination_country: str | None = None) -> dict:
        result = await self.db.execute(
            select(PricingRule).where(
                PricingRule.service_type == ServiceType(service_type),
                PricingRule.is_active == True,
            )
        )
        rules = list(result.scalars().all())

        if not rules:
            return {
                "base_price": 0,
                "weight_charge": 0,
                "volume_charge": 0,
                "total_estimate": 0,
                "currency": "EGP",
            }

        rule = rules[0]
        weight_charge = (weight or 0) * rule.price_per_kg
        volume_charge = (volume_weight or 0) * rule.price_per_volume
        total = rule.base_price + weight_charge + volume_charge

        if total < rule.min_price:
            total = rule.min_price

        return {
            "base_price": rule.base_price,
            "weight_charge": round(weight_charge, 2),
            "volume_charge": round(volume_charge, 2),
            "total_estimate": round(total, 2),
            "currency": "EGP",
        }

    async def list_rules(self) -> list[PricingRule]:
        result = await self.db.execute(select(PricingRule).order_by(PricingRule.created_at.desc()))
        return list(result.scalars().all())

    async def create_rule(self, data: dict) -> PricingRule:
        rule = PricingRule(**data)
        self.db.add(rule)
        await self.db.flush()
        return rule

    async def update_rule(self, rule_id, data: dict) -> PricingRule:
        result = await self.db.execute(select(PricingRule).where(PricingRule.id == rule_id))
        rule = result.scalar_one_or_none()
        if not rule:
            raise ValueError("Pricing rule not found")

        for key, value in data.items():
            setattr(rule, key, value)

        await self.db.flush()
        return rule
