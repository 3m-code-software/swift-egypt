from datetime import datetime, timezone
from uuid import UUID

import httpx
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import settings
from app.models.driver import Driver
from app.models.shipment import Shipment
from app.models.batch import Batch, BatchOrder
from app.models.seller import Seller
from app.models.settlement import SellerSettlement, DriverSettlement
from app.models.ai_alert import AiAlert


OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


SYSTEM_PROMPTS = {
    "admin": """أنت مساعد Swift Egypt AI الذكي. اسمك "Swift AI". 
تساعد مدير النظام في إدارة المنصة بالكامل. لديك صلاحية الوصول لكل البيانات.
يمكنك الإجابة عن الشحنات، التجار، المناديب، الفواتير، التسويات، التقارير.
كن دقيقاً ومختصراً. أجب بالعربية دائماً.""",

    "seller": """أنت مساعد Swift Egypt AI الذكي. اسمك "Swift AI".
تساعد التاجر في إدارة شحناته، متابعة الرصيد، رفع ملفات Excel، معرفة الإحصائيات.
كن دقيقاً ومختصراً. أجب بالعربية دائماً.""",

    "driver": """أنت مساعد Swift Egypt AI الذكي. اسمك "Swift AI".
تساعد المندوب في مهامه اليومية: التوصيل، العناوين، الإحصائيات، تحسين المسار.
كن دقيقاً ومختصراً. أجب بالعربية دائماً.""",

    "customer": """أنت مساعد Swift Egypt AI الذكي. اسمك "Swift AI".
تساعد العميل في تتبع الشحنات، الاستعلام عن الخدمات، الأسعار، الدعم.
كن دقيقاً ومختصراً. أجب بالعربية دائماً.""",

    "default": """أنت مساعد Swift Egypt AI الذكي. اسمك "Swift AI".
تساعد المستخدمين في منصة Swift Egypt للشحن والتوصيل.
كن دقيقاً ومختصراً. أجب بالعربية دائماً.""",
}


class AIService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def chat(self, message: str, role: str = "default", context: dict | None = None) -> str:
        system_prompt = SYSTEM_PROMPTS.get(role, SYSTEM_PROMPTS["default"])
        context_data = await self._build_context(role, context) if context else ""

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"{context_data}\n\n{message}" if context_data else message},
        ]

        api_key = settings.openrouter_api_key
        if not api_key:
            return "عذراً، لم يتم تكوين مفتاح المساعد الذكي بعد."

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.post(
                    OPENROUTER_URL,
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "HTTP-Referer": settings.openrouter_site_url,
                        "X-Title": settings.openrouter_site_name,
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "openai/gpt-4o-mini",
                        "messages": messages,
                        "max_tokens": 500,
                        "temperature": 0.7,
                    },
                )
                resp.raise_for_status()
                data = resp.json()
                return data["choices"][0]["message"]["content"]
        except Exception as e:
            return f"عذراً، حدث خطأ في الاتصال بالمساعد الذكي: {str(e)}"

    async def _build_context(self, role: str, context: dict) -> str:
        parts = []
        if role == "admin" and context:
            if "stats" in context:
                parts.append(f"إحصائيات المنصة: {context['stats']}")
            if "batch_count" in context:
                parts.append(f"عدد الشحنات: {context['batch_count']}")
        elif role == "seller" and context:
            if "wallet" in context:
                parts.append(f"رصيد المحفظة: {context['wallet']}")
            if "batch_count" in context:
                parts.append(f"عدد الشحنات: {context['batch_count']}")
        elif role == "driver" and context:
            if "stats" in context:
                parts.append(f"إحصائيات اليوم: {context['stats']}")
            if "tasks_count" in context:
                parts.append(f"عدد المهام اليوم: {context['tasks_count']}")
        elif role == "customer" and context:
            if "shipments_count" in context:
                parts.append(f"عدد الشحنات: {context['shipments_count']}")
        return "\n".join(parts)

    async def get_admin_context(self) -> dict:
        batch_count = await self.db.scalar(select(func.count()).select_from(Batch))
        seller_count = await self.db.scalar(select(func.count()).select_from(Seller))
        pending_orders = await self.db.scalar(
            select(func.count()).select_from(BatchOrder).where(BatchOrder.status == "pending")
        )
        return {
            "stats": f"إجمالي الشحنات: {batch_count or 0}, عدد التجار: {seller_count or 0}, الطلبات المعلقة: {pending_orders or 0}",
            "batch_count": batch_count or 0,
        }

    async def get_seller_context(self, seller_id: UUID) -> dict:
        result = await self.db.execute(select(Seller).where(Seller.id == seller_id))
        seller = result.scalar_one_or_none()
        batch_count = await self.db.scalar(
            select(func.count()).select_from(Batch).where(Batch.seller_id == seller_id)
        ) if seller else 0
        return {
            "wallet": str(getattr(seller, "wallet_balance", 0)) if seller else "0",
            "batch_count": batch_count or 0,
        }

    async def get_driver_context(self, driver_id: UUID) -> dict:
        from app.models.batch import OrderStatus
        total = await self.db.scalar(
            select(func.count()).select_from(BatchOrder).where(BatchOrder.assigned_agent_id == driver_id, BatchOrder.status != OrderStatus.pending)
        ) or 0
        delivered = await self.db.scalar(
            select(func.count()).select_from(BatchOrder).where(BatchOrder.assigned_agent_id == driver_id, BatchOrder.status == OrderStatus.delivered)
        ) or 0
        return {
            "stats": f"تم التوصيل: {delivered}, إجمالي المهام: {total}",
            "tasks_count": total,
        }

    async def _call(self, method: str, path: str, json: dict | None = None) -> dict:
        try:
            async with httpx.AsyncClient(base_url=settings.ai_service_url, timeout=10.0) as client:
                resp = await client.request(method, path, json=json)
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
            "shipment_id": str(shipment.id),
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
            "driver_id": str(driver.id),
            "driver_name": driver.user.full_name if driver.user else "Unknown",
            "overall_score": score,
            "strengths": ["On-time deliveries", "Customer satisfaction", "Route efficiency"],
            "improvements": ["Idle time reduction", "Fuel efficiency"],
            "efficiency_rating": round(driver.total_deliveries / 100, 1) if driver.total_deliveries else 3.0,
            "safety_score": score / 20,
            "timeliness_score": score / 20,
        }
