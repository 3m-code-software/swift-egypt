from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_branch_manager_user, get_db
from app.models.batch import BatchOrder, OrderStatus
from app.models.driver import Driver
from app.models.user import User

router = APIRouter(prefix="/control-room", tags=["Control Room"])


@router.get("/stats")
async def get_control_room_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_branch_manager_user),
):
    today = datetime.now(timezone.utc).date()
    today_start = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)
    today_end = today_start + timedelta(days=1)

    active_agents_result = await db.execute(
        select(func.count(Driver.id)).where(
            Driver.is_available == True,
            Driver.current_latitude.isnot(None),
            Driver.current_longitude.isnot(None),
        )
    )
    active_agents = active_agents_result.scalar() or 0

    total_agents_result = await db.execute(select(func.count(Driver.id)))
    total_agents = total_agents_result.scalar() or 0

    today_delivered_result = await db.execute(
        select(func.count(BatchOrder.id)).where(
            BatchOrder.status == OrderStatus.delivered,
            BatchOrder.delivery_date >= today_start,
            BatchOrder.delivery_date < today_end,
        )
    )
    today_delivered = today_delivered_result.scalar() or 0

    today_collected_result = await db.execute(
        select(func.coalesce(func.sum(BatchOrder.collected_amount), 0)).where(
            BatchOrder.status.in_([OrderStatus.delivered, OrderStatus.partial]),
            BatchOrder.delivery_date >= today_start,
            BatchOrder.delivery_date < today_end,
        )
    )
    today_collected = today_collected_result.scalar() or 0.0

    pending_result = await db.execute(
        select(func.count(BatchOrder.id)).where(BatchOrder.status == OrderStatus.pending)
    )
    pending = pending_result.scalar() or 0

    no_answer_today_result = await db.execute(
        select(func.count(BatchOrder.id)).where(
            BatchOrder.status == OrderStatus.no_answer,
            BatchOrder.delivery_date >= today_start,
            BatchOrder.delivery_date < today_end,
        )
    )
    no_answer_today = no_answer_today_result.scalar() or 0

    return {
        "active_agents": active_agents,
        "total_agents": total_agents,
        "today_delivered": today_delivered,
        "today_collected": round(float(today_collected), 2),
        "pending_orders": pending,
        "no_answer_today": no_answer_today,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/agents/locations")
async def get_agent_locations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_branch_manager_user),
):
    result = await db.execute(
        select(Driver).options(selectinload(Driver.user)).where(
            Driver.current_latitude.isnot(None),
            Driver.current_longitude.isnot(None),
        )
    )
    drivers = result.scalars().all()

    return [
        {
            "id": str(d.id),
            "name": d.user.full_name if d.user else "Unknown",
            "latitude": d.current_latitude,
            "longitude": d.current_longitude,
            "is_available": d.is_available,
            "last_update": d.last_location_update.isoformat() if d.last_location_update else None,
        }
        for d in drivers
    ]


@router.get("/recent-activity")
async def get_recent_activity(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_branch_manager_user),
):
    today = datetime.now(timezone.utc).date()
    today_start = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)

    result = await db.execute(
        select(BatchOrder)
        .where(
            BatchOrder.delivery_date >= today_start,
            BatchOrder.status.in_([
                OrderStatus.delivered,
                OrderStatus.partial,
                OrderStatus.returned,
                OrderStatus.no_answer,
            ]),
        )
        .order_by(BatchOrder.delivery_date.desc())
        .limit(20)
    )
    orders = result.scalars().all()

    return [
        {
            "id": str(o.id),
            "customer_name": o.customer_name,
            "customer_phone": o.customer_phone,
            "status": o.status.value,
            "collected_amount": o.collected_amount,
            "delivery_date": o.delivery_date.isoformat() if o.delivery_date else None,
            "assigned_agent_id": str(o.assigned_agent_id) if o.assigned_agent_id else None,
        }
        for o in orders
    ]
