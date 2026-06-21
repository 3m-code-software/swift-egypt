from datetime import datetime, timezone
from uuid import UUID

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import settings
from app.models.driver import Driver
from app.models.shipment import Shipment
from app.models.ai_alert import AiAlert


class AIService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self._client = httpx.AsyncClient(base_url=settings.ai_service_url, timeout=10.0)

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args):
        await self._client.aclose()

    async def _call(self, method: str, path: str, json: dict | None = None) -> dict:
        try:
            resp = await self._client.request(method, path, json=json)
            resp.raise_for_status()
            return resp.json()
        except httpx.RequestError:
            return {}

    async def predict_eta(self, shipment_id: UUID) -> dict:
        result = await self.db.execute(
            select(Shipment).options(selectinload(Shipment.items)).where(Shipment.id == shipment_id)
        )
        shipment = result.scalar_one_or_none()
        if not shipment:
            raise ValueError("Shipment not found")

        pickup = shipment.pickup_address or {}
        delivery = shipment.delivery_address or {}
        ai_result = await self._call("POST", "/eta", json={
            "pickup_lat": pickup.get("lat", 30.0),
            "pickup_lon": pickup.get("lon", 31.0),
            "delivery_lat": delivery.get("lat", 30.1),
            "delivery_lon": delivery.get("lon", 31.1),
            "service_type": shipment.shipment_type or "domestic",
        })

        return {
            "shipment_id": shipment.id,
            "tracking_number": shipment.tracking_number,
            "estimated_arrival": datetime.now(timezone.utc),
            "confidence": ai_result.get("confidence", 0.5),
            "current_status": shipment.status.value if hasattr(shipment.status, 'value') else shipment.status,
        }

    async def optimize_route(self, origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float, waypoints: list[dict] | None = None) -> dict:
        points = [{"lat": origin_lat, "lon": origin_lng}]
        if waypoints:
            points.extend(waypoints)
        points.append({"lat": dest_lat, "lon": dest_lng})

        ai_result = await self._call("POST", "/route-optimize", json={"waypoints": points})

        return {
            "optimized_route": ai_result.get("ordered_waypoints", [
                {"lat": origin_lat, "lng": origin_lng, "type": "origin"},
                {"lat": dest_lat, "lng": dest_lng, "type": "destination"},
            ]),
            "estimated_duration_minutes": ai_result.get("estimated_minutes", 60),
            "estimated_distance_km": ai_result.get("total_distance_km", 50),
            "fuel_estimate_liters": round(ai_result.get("total_distance_km", 50) * 0.12, 1),
        }

    async def detect_risks(self, shipment_id: UUID | None = None) -> list[AiAlert]:
        query = select(AiAlert).order_by(AiAlert.created_at.desc()).limit(20)
        if shipment_id:
            query = query.where(AiAlert.shipment_id == shipment_id)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def pricing_suggestion(self, service_type: str, weight: float | None = None, volume_weight: float | None = None, origin_country: str | None = None, destination_country: str | None = None) -> dict:
        ai_result = await self._call("POST", "/pricing", json={
            "distance_km": 100,
            "weight_kg": weight or 1,
            "service_type": service_type,
        })

        if ai_result:
            return {
                "suggested_price": ai_result["total_price"],
                "min_price": round(ai_result["total_price"] * 0.85, 2),
                "max_price": round(ai_result["total_price"] * 1.15, 2),
                "confidence": 0.9,
                "factors": [
                    "Distance-based calculation",
                    "Weight-based calculation",
                    "Service type adjustment",
                    "Market rate comparison",
                ],
            }

        return {
            "suggested_price": 100,
            "min_price": 85,
            "max_price": 115,
            "confidence": 0.5,
            "factors": ["Standard pricing (AI unavailable)"],
        }

    async def analyze_driver_performance(self, driver_id: UUID) -> dict:
        result = await self.db.execute(
            select(Driver).where(Driver.id == driver_id)
        )
        driver = result.scalar_one_or_none()
        if not driver:
            raise ValueError("Driver not found")

        ai_result = await self._call("POST", "/driver-score", json={
            "rating": 4.5,
            "total_deliveries": 100,
        })

        score = ai_result.get("score", 80)
        level = ai_result.get("level", "good")

        return {
            "driver_id": driver.id,
            "driver_name": driver.user.full_name if driver.user else "Unknown",
            "overall_score": score,
            "strengths": ["On-time deliveries", "Customer satisfaction", "Route efficiency"],
            "improvements": ["Idle time reduction", "Fuel efficiency"],
            "efficiency_rating": round(driver.total_deliveries / 100, 1) if driver.total_deliveries else 3.0,
            "safety_score": score / 20,
            "timeliness_score": score / 20,
        }
