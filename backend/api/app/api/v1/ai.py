from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, get_db, get_operations_user
from app.models.user import User, UserRole
from app.models.ai_alert import AiAlert
from app.schemas.ai import (
    AiAlertResponse,
    DriverAnalysisResponse,
    EtaResponse,
    PricingSuggestionRequest,
    PricingSuggestionResponse,
    RouteOptimizeRequest,
    RouteResponse,
)
from app.services.ai_service import AIService
from sqlalchemy import select

router = APIRouter(prefix="/ai", tags=["AI"])


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    reply: str


@router.post("/chat", response_model=ChatResponse)
async def ai_chat(
    data: ChatRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AIService(db)

    role_map = {
        UserRole.admin: "admin",
        UserRole.seller: "seller",
        UserRole.driver: "driver",
        UserRole.customer: "customer",
    }
    role = role_map.get(current_user.role, "default")

    context_data = None
    if role == "admin":
        context_data = await service.get_admin_context()
    elif role == "seller":
        from app.models.seller import Seller
        result = await db.execute(select(Seller).where(Seller.user_id == current_user.id))
        seller = result.scalar_one_or_none()
        if seller:
            context_data = await service.get_seller_context(seller.id)
    elif role == "driver":
        from app.models.driver import Driver
        result = await db.execute(select(Driver).where(Driver.user_id == current_user.id))
        driver = result.scalar_one_or_none()
        if driver:
            context_data = await service.get_driver_context(driver.id)
    elif role == "customer":
        context_data = {"shipments_count": 0}

    reply = await service.chat(data.message, role, context_data)
    return ChatResponse(reply=reply)


@router.get("/eta/{shipment_id}", response_model=EtaResponse)
async def predict_eta(shipment_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Predict estimated time of arrival for a shipment using AI."""
    service = AIService(db)
    result = await service.predict_eta(shipment_id)
    return EtaResponse(**result)


@router.post("/route-optimize", response_model=RouteResponse)
async def optimize_route(data: RouteOptimizeRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Optimize delivery route using AI."""
    service = AIService(db)
    result = await service.optimize_route(
        origin_lat=data.origin_lat,
        origin_lng=data.origin_lng,
        dest_lat=data.dest_lat,
        dest_lng=data.dest_lng,
        waypoints=data.waypoints,
    )
    return RouteResponse(**result)


@router.get("/alerts", response_model=list[AiAlertResponse])
async def get_ai_alerts(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get AI-generated alerts for shipments."""
    service = AIService(db)
    alerts = await service.detect_risks()
    return [AiAlertResponse.model_validate(a) for a in alerts]


@router.put("/alerts/{alert_id}/read", response_model=AiAlertResponse)
async def mark_alert_read(alert_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Mark an AI alert as read."""
    result = await db.execute(select(AiAlert).where(AiAlert.id == UUID(alert_id)))
    alert = result.scalar_one_or_none()
    if not alert:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Alert not found")
    alert.is_read = True
    await db.commit()
    await db.refresh(alert)
    return AiAlertResponse.model_validate(alert)


@router.post("/pricing-suggestion", response_model=PricingSuggestionResponse)
async def get_pricing_suggestion(data: PricingSuggestionRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get AI-powered pricing suggestion."""
    service = AIService(db)
    result = await service.pricing_suggestion(
        service_type=data.service_type,
        weight=data.weight,
        volume_weight=data.volume_weight,
        origin_country=data.origin_country,
        destination_country=data.destination_country,
    )
    return PricingSuggestionResponse(**result)


@router.get("/performance/driver/{driver_id}", response_model=DriverAnalysisResponse)
async def driver_performance_analysis(driver_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get AI-powered driver performance analysis."""
    service = AIService(db)
    result = await service.analyze_driver_performance(driver_id)
    return DriverAnalysisResponse(**result)
