from datetime import date as date_type, datetime, timedelta, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy import case, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_branch_manager_user, get_current_active_user, get_db
from app.models.batch import Batch, BatchOrder, BatchStatus, OrderStatus, ReturnReason
from app.models.driver import Driver
from app.models.user import User, UserRole
from pydantic import BaseModel

router = APIRouter(prefix="/agent", tags=["Agent"])


class OrderStatusUpdate(BaseModel):
    status: str
    delivery_notes: str | None = None
    returned_reason: str | None = None
    collected_amount: float | None = None
    call_attempts: int | None = None
    delivered_quantity: int | None = None
    latitude: float | None = None
    longitude: float | None = None


class AssignOrdersRequest(BaseModel):
    order_ids: list[str]
    agent_id: str


@router.get("/tasks")
async def get_agent_tasks(
    date: str | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if current_user.role not in [UserRole.admin, UserRole.operations, UserRole.driver]:
        from app.core.exceptions import ForbiddenException
        raise ForbiddenException("Agent access required")

    if current_user.role == UserRole.driver:
        driver_result = await db.execute(
            select(Driver).where(Driver.user_id == current_user.id)
        )
        driver = driver_result.scalar_one_or_none()
        if not driver:
            from app.core.exceptions import NotFoundException
            raise NotFoundException("Driver profile not found")
        agent_id = driver.id
    else:
        agent_id = None

    query = select(BatchOrder).options(
        selectinload(BatchOrder.batch),
        selectinload(BatchOrder.assigned_agent),
    ).order_by(BatchOrder.created_at.asc())

    if agent_id:
        query = query.where(BatchOrder.assigned_agent_id == agent_id)
    elif current_user.role in [UserRole.admin, UserRole.operations]:
        if date:
            try:
                target = date_type.fromisoformat(date)
                gte = datetime.combine(target, datetime.min.time()).replace(tzinfo=timezone.utc)
                lt = gte + timedelta(days=1)
                query = query.where(BatchOrder.created_at >= gte, BatchOrder.created_at < lt)
            except ValueError:
                pass
    else:
        from app.core.exceptions import ForbiddenException
        raise ForbiddenException("Not authorized")

    result = await db.execute(query)
    orders = result.scalars().all()

    return [
        {
            "id": str(o.id),
            "batch_id": str(o.batch_id),
            "batch_number": o.batch.batch_number if o.batch else None,
            "customer_name": o.customer_name,
            "customer_phone": o.customer_phone,
            "customer_phone2": o.customer_phone2,
            "address": o.address,
            "province": o.province,
            "city": o.city,
            "product_name": o.product_name,
            "quantity": o.quantity,
            "product_price": o.product_price,
            "shipping_cost": o.shipping_cost,
            "total": o.total,
            "notes": o.notes,
            "status": o.status.value if o.status else "pending",
            "delivery_notes": o.delivery_notes,
            "returned_reason": o.returned_reason,
            "collected_amount": o.collected_amount,
            "call_attempts": o.call_attempts,
            "delivered_quantity": o.delivered_quantity,
            "latitude": o.latitude,
            "longitude": o.longitude,
            "created_at": o.created_at.isoformat() if o.created_at else None,
            "assigned_at": o.assigned_at.isoformat() if o.assigned_at else None,
        }
        for o in orders
    ]


@router.get("/tasks/stats")
async def get_agent_tasks_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if current_user.role not in [UserRole.admin, UserRole.operations, UserRole.driver]:
        from app.core.exceptions import ForbiddenException
        raise ForbiddenException("Agent access required")

    if current_user.role == UserRole.driver:
        driver_result = await db.execute(
            select(Driver).where(Driver.user_id == current_user.id)
        )
        driver = driver_result.scalar_one_or_none()
        if not driver:
            from app.core.exceptions import NotFoundException
            raise NotFoundException("Driver profile not found")
        agent_id = driver.id
    else:
        agent_id = None

    base_filter = [BatchOrder.assigned_agent_id == agent_id] if agent_id else []

    total_q = select(func.count(BatchOrder.id))
    if base_filter:
        total_q = total_q.where(*base_filter)
    total = await db.execute(total_q)
    total_count = total.scalar() or 0

    stats_result = await db.execute(
        select(
            func.sum(case((BatchOrder.status == OrderStatus.pending, 1), else_=0)),
            func.sum(case((BatchOrder.status == OrderStatus.delivered, 1), else_=0)),
            func.sum(case((BatchOrder.status == OrderStatus.partial, 1), else_=0)),
            func.sum(case((BatchOrder.status == OrderStatus.returned, 1), else_=0)),
            func.sum(case((BatchOrder.status == OrderStatus.no_answer, 1), else_=0)),
        ).where(*base_filter)
    )
    pending, delivered, partial, returned, no_answer = stats_result.first() or (0, 0, 0, 0, 0)

    return {
        "total": total_count,
        "pending": pending or 0,
        "delivered": delivered or 0,
        "partial": partial or 0,
        "returned": returned or 0,
        "no_answer": no_answer or 0,
    }


@router.post("/tasks/{order_id}/status")
async def update_order_status(
    order_id: str,
    data: OrderStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(BatchOrder).options(selectinload(BatchOrder.batch)).where(BatchOrder.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Order not found")

    if current_user.role == UserRole.driver:
        driver_result = await db.execute(
            select(Driver).where(Driver.user_id == current_user.id)
        )
        driver = driver_result.scalar_one_or_none()
        if not driver or order.assigned_agent_id != driver.id:
            from app.core.exceptions import ForbiddenException
            raise ForbiddenException("This order is not assigned to you")

    try:
        new_status = OrderStatus(data.status)
    except ValueError:
        from app.core.exceptions import BadRequestException
        raise BadRequestException(f"Invalid status: {data.status}")

    order.status = new_status
    order.delivery_notes = data.delivery_notes
    order.collected_amount = data.collected_amount
    order.delivered_quantity = data.delivered_quantity
    order.latitude = data.latitude
    order.longitude = data.longitude

    if data.returned_reason:
        order.returned_reason = data.returned_reason

    if data.call_attempts is not None:
        order.call_attempts = data.call_attempts

    if new_status in [OrderStatus.delivered, OrderStatus.partial, OrderStatus.returned, OrderStatus.no_answer]:
        order.delivery_date = datetime.now(timezone.utc)

    if new_status == OrderStatus.delivered:
        batch = order.batch
        seller_result = await db.execute(
            select(Batch).where(Batch.id == order.batch_id)
        )
        seller_id = order.batch.seller_id
        if seller_id:
            from app.models.seller import Seller
            await db.execute(
                update(Seller)
                .where(Seller.id == seller_id)
                .values(total_delivered=Seller.total_delivered + 1)
            )

    if new_status == OrderStatus.returned:
        seller_id = order.batch.seller_id
        if seller_id:
            from app.models.seller import Seller
            await db.execute(
                update(Seller)
                .where(Seller.id == seller_id)
                .values(total_returned=Seller.total_returned + 1)
            )

    if new_status == OrderStatus.no_answer:
        order.call_attempts = (order.call_attempts or 0) + 1

    await db.flush()

    batch_result = await db.execute(select(Batch).where(Batch.id == order.batch_id))
    batch = batch_result.scalar_one()
    batch.updated_at = datetime.now(timezone.utc)

    await db.commit()

    return {"message": f"Order marked as {data.status}", "order_id": order_id}


@router.post("/assign")
async def assign_orders_to_agent(
    data: AssignOrdersRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_branch_manager_user),
):
    agent_result = await db.execute(
        select(Driver).where(Driver.id == data.agent_id)
    )
    agent = agent_result.scalar_one_or_none()
    if not agent:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Agent not found")

    now = datetime.now(timezone.utc)
    for oid in data.order_ids:
        result = await db.execute(select(BatchOrder).where(BatchOrder.id == oid))
        order = result.scalar_one_or_none()
        if order:
            order.assigned_agent_id = UUID(data.agent_id)
            order.assigned_at = now

    await db.commit()

    return {"message": f"Assigned {len(data.order_ids)} orders to agent", "agent_id": data.agent_id}


@router.post("/batches/{batch_id}/end-day")
async def end_of_day(
    batch_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_branch_manager_user),
):
    result = await db.execute(
        select(Batch).options(selectinload(Batch.orders)).where(Batch.id == batch_id)
    )
    batch = result.scalar_one_or_none()
    if not batch:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Batch not found")

    converted = 0
    for order in batch.orders:
        if order.status == OrderStatus.pending:
            order.status = OrderStatus.returned
            order.returned_reason = "end_of_day"
            order.delivery_notes = "Auto-converted at end of day"
            converted += 1

    batch.end_of_day_done = True
    batch.updated_at = datetime.now(timezone.utc)

    await db.commit()

    return {
        "message": f"End of day completed. {converted} pending orders converted to returned.",
        "batch_id": batch_id,
        "converted": converted,
    }


@router.get("/return-reasons")
async def list_return_reasons():
    return {
        "reasons": [
            {"key": "customer_refused", "label": "Customer refused"},
            {"key": "wrong_address", "label": "Wrong address"},
            {"key": "customer_not_found", "label": "Customer not found"},
            {"key": "cancelled_by_seller", "label": "Cancelled by seller"},
            {"key": "damaged_product", "label": "Damaged product"},
            {"key": "wrong_product", "label": "Wrong product"},
            {"key": "delayed_delivery", "label": "Delayed delivery"},
            {"key": "other", "label": "Other"},
        ]
    }
