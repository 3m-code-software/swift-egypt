from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_operations_user, get_db
from app.models.ai_alert import AiAlert
from app.models.invoice import Invoice, PaymentStatus
from app.models.shipment import Shipment, ShipmentStatus
from app.models.user import User

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/stats")
async def dashboard_stats(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get overview statistics for the dashboard."""
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    total_shipments_result = await db.execute(select(func.count()).select_from(Shipment))
    total_shipments = total_shipments_result.scalar()

    active_result = await db.execute(
        select(func.count()).select_from(Shipment).where(
            Shipment.status.in_([ShipmentStatus.confirmed, ShipmentStatus.picked_up, ShipmentStatus.in_transit, ShipmentStatus.out_for_delivery])
        )
    )
    active_shipments = active_result.scalar()

    delayed_result = await db.execute(
        select(func.count()).select_from(Shipment).where(Shipment.status == ShipmentStatus.delayed)
    )
    delayed = delayed_result.scalar()

    delivered_today_result = await db.execute(
        select(func.count()).select_from(Shipment).where(
            Shipment.status == ShipmentStatus.delivered,
            Shipment.updated_at >= today_start,
        )
    )
    delivered_today = delivered_today_result.scalar()

    revenue_result = await db.execute(
        select(func.coalesce(func.sum(Invoice.total), 0)).where(Invoice.payment_status == PaymentStatus.paid)
    )
    revenue = revenue_result.scalar()

    return {
        "total_shipments": total_shipments or 0,
        "active_shipments": active_shipments or 0,
        "delayed_shipments": delayed or 0,
        "delivered_today": delivered_today or 0,
        "total_revenue": float(revenue or 0),
    }


@router.get("/recent-shipments", response_model=list[dict])
async def recent_shipments(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get recent shipments for dashboard."""
    result = await db.execute(
        select(Shipment).order_by(Shipment.created_at.desc()).limit(10)
    )
    shipments = result.scalars().all()
    return [
        {
            "id": str(s.id),
            "tracking_number": s.tracking_number,
            "status": s.status.value if hasattr(s.status, 'value') else s.status,
            "service_type": s.service_type.value if hasattr(s.service_type, 'value') else s.service_type,
            "recipient_name": s.recipient_name,
            "sender_name": s.sender_name,
            "created_at": s.created_at.isoformat() if s.created_at else None,
        }
        for s in shipments
    ]


@router.get("/alerts", response_model=list[dict])
async def dashboard_alerts(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get AI alerts for dashboard."""
    result = await db.execute(
        select(AiAlert).order_by(AiAlert.created_at.desc()).limit(20)
    )
    alerts = result.scalars().all()
    return [
        {
            "id": str(a.id),
            "alert_type": a.alert_type,
            "severity": a.severity.value if hasattr(a.severity, 'value') else a.severity,
            "title": a.title,
            "description": a.description,
            "is_read": a.is_read,
            "created_at": a.created_at.isoformat() if a.created_at else None,
        }
        for a in alerts
    ]
