from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, get_db, get_operations_user
from app.models.user import User
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

router = APIRouter(prefix="/ai", tags=["AI"])


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
    from uuid import UUID
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
