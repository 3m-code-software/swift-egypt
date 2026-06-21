from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_admin_user, get_current_active_user, get_db
from app.models.batch import BatchOrder, BatchStatus, OrderStatus
from app.models.driver import Driver
from app.models.seller import Seller
from app.models.settlement import (
    DriverSettlement,
    SellerSettlement,
    SettlementStatus,
)
from app.models.user import User, UserRole
from pydantic import BaseModel

router = APIRouter(prefix="/settlements", tags=["Settlements"])


class PaySettlementRequest(BaseModel):
    notes: str | None = None


@router.get("/seller/list")
async def list_seller_settlements(
    seller_id: str | None = Query(None),
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    query = select(SellerSettlement).options(selectinload(SellerSettlement.seller))

    if current_user.role == UserRole.seller:
        seller_result = await db.execute(
            select(Seller).where(Seller.user_id == current_user.id)
        )
        seller = seller_result.scalar_one_or_none()
        if not seller:
            from app.core.exceptions import NotFoundException
            raise NotFoundException("Seller profile not found")
        query = query.where(SellerSettlement.seller_id == seller.id)
    elif seller_id:
        query = query.where(SellerSettlement.seller_id == UUID(seller_id))

    if status:
        try:
            query = query.where(SellerSettlement.status == SettlementStatus(status))
        except ValueError:
            pass

    total = await db.execute(select(func.count()).select_from(query.subquery()))
    total_count = total.scalar() or 0

    query = query.order_by(SellerSettlement.created_at.desc())
    query = query.offset((page - 1) * per_page).limit(per_page)

    result = await db.execute(query)
    settlements = result.scalars().all()

    return {
        "settlements": [
            {
                "id": str(s.id),
                "seller_id": str(s.seller_id),
                "seller_name": s.seller.company_name if s.seller else None,
                "period_start": s.period_start.isoformat(),
                "period_end": s.period_end.isoformat(),
                "total_orders": s.total_orders,
                "total_delivered": s.total_delivered,
                "total_returned": s.total_returned,
                "total_amount": s.total_amount,
                "total_commission": s.total_commission,
                "net_amount": s.net_amount,
                "status": s.status.value,
                "notes": s.notes,
                "paid_at": s.paid_at.isoformat() if s.paid_at else None,
                "created_at": s.created_at.isoformat(),
            }
            for s in settlements
        ],
        "total": total_count,
        "page": page,
        "per_page": per_page,
    }


@router.get("/seller/current")
async def get_seller_current_settlement(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    seller_result = await db.execute(
        select(Seller).where(Seller.user_id == current_user.id)
    )
    seller = seller_result.scalar_one_or_none()
    if not seller:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Seller profile not found")

    approved_orders = await db.execute(
        select(BatchOrder)
        .join(BatchOrder.batch)
        .where(
            BatchOrder.batch.has(seller_id=seller.id),
            BatchOrder.status.in_([OrderStatus.delivered, OrderStatus.partial, OrderStatus.returned]),
        )
    )
    orders = approved_orders.scalars().all()

    total_orders = len(orders)
    total_delivered = sum(1 for o in orders if o.status == OrderStatus.delivered)
    total_returned = sum(1 for o in orders if o.status == OrderStatus.returned)
    total_amount = sum(o.collected_amount or o.total for o in orders if o.status in [OrderStatus.delivered, OrderStatus.partial])
    total_commission = sum(o.commission for o in orders)

    return {
        "total_orders": total_orders,
        "total_delivered": total_delivered,
        "total_returned": total_returned,
        "total_amount": round(total_amount, 2),
        "total_commission": round(total_commission, 2),
        "net_amount": round(total_amount - total_commission, 2),
    }


@router.post("/seller/generate")
async def generate_seller_settlement(
    seller_id: str | None = None,
    period_start: str = Query(...),
    period_end: str = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_admin_user),
):
    from datetime import date as date_type

    try:
        start = datetime.combine(date_type.fromisoformat(period_start), datetime.min.time()).replace(tzinfo=timezone.utc)
        end = datetime.combine(date_type.fromisoformat(period_end), datetime.min.time()).replace(tzinfo=timezone.utc)
    except ValueError as e:
        from app.core.exceptions import BadRequestException
        raise BadRequestException(f"Invalid date format: {e}")

    sellers_query = select(Seller)
    if seller_id:
        sellers_query = sellers_query.where(Seller.id == UUID(seller_id))

    sellers_result = await db.execute(sellers_query)
    sellers = sellers_result.scalars().all()

    created = []
    for seller in sellers:
        orders_result = await db.execute(
            select(BatchOrder)
            .join(BatchOrder.batch)
            .where(
                BatchOrder.batch.has(seller_id=seller.id),
                BatchOrder.delivery_date >= start,
                BatchOrder.delivery_date < end,
                BatchOrder.status.in_([
                    OrderStatus.delivered,
                    OrderStatus.partial,
                    OrderStatus.returned,
                    OrderStatus.no_answer,
                ]),
            )
        )
        orders = orders_result.scalars().all()

        if not orders:
            continue

        total_orders = len(orders)
        total_delivered = sum(1 for o in orders if o.status == OrderStatus.delivered)
        total_returned = sum(1 for o in orders if o.status == OrderStatus.returned)
        total_amount = sum(o.collected_amount or o.total for o in orders if o.status in [OrderStatus.delivered, OrderStatus.partial])
        total_commission = sum(o.commission for o in orders)
        net_amount = total_amount - total_commission

        settlement = SellerSettlement(
            seller_id=seller.id,
            period_start=start,
            period_end=end,
            total_orders=total_orders,
            total_delivered=total_delivered,
            total_returned=total_returned,
            total_amount=round(total_amount, 2),
            total_commission=round(total_commission, 2),
            net_amount=round(net_amount, 2),
        )
        db.add(settlement)
        created.append(str(settlement.id))

    await db.commit()

    return {"message": f"Generated {len(created)} settlements", "settlement_ids": created}


@router.post("/seller/{settlement_id}/pay")
async def pay_seller_settlement(
    settlement_id: str,
    data: PaySettlementRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_admin_user),
):
    result = await db.execute(
        select(SellerSettlement).where(SellerSettlement.id == settlement_id)
    )
    settlement = result.scalar_one_or_none()
    if not settlement:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Settlement not found")

    if settlement.status == SettlementStatus.paid:
        from app.core.exceptions import BadRequestException
        raise BadRequestException("Settlement already paid")

    settlement.status = SettlementStatus.paid
    settlement.paid_at = datetime.now(timezone.utc)
    settlement.paid_by = current_user.id
    if data.notes:
        settlement.notes = data.notes

    seller_result = await db.execute(
        select(Seller).where(Seller.id == settlement.seller_id)
    )
    seller = seller_result.scalar_one_or_none()
    if seller:
        seller.wallet_balance -= settlement.net_amount

    await db.commit()

    return {"message": "Settlement paid", "settlement_id": settlement_id}


@router.get("/driver/list")
async def list_driver_settlements(
    driver_id: str | None = Query(None),
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    query = select(DriverSettlement).options(selectinload(DriverSettlement.driver))

    if current_user.role == UserRole.driver:
        driver_result = await db.execute(
            select(Driver).where(Driver.user_id == current_user.id)
        )
        driver = driver_result.scalar_one_or_none()
        if not driver:
            from app.core.exceptions import NotFoundException
            raise NotFoundException("Driver profile not found")
        query = query.where(DriverSettlement.driver_id == driver.id)
    elif driver_id:
        query = query.where(DriverSettlement.driver_id == UUID(driver_id))

    if status:
        try:
            query = query.where(DriverSettlement.status == SettlementStatus(status))
        except ValueError:
            pass

    total = await db.execute(select(func.count()).select_from(query.subquery()))
    total_count = total.scalar() or 0

    query = query.order_by(DriverSettlement.created_at.desc())
    query = query.offset((page - 1) * per_page).limit(per_page)

    result = await db.execute(query)
    settlements = result.scalars().all()

    return {
        "settlements": [
            {
                "id": str(s.id),
                "driver_id": str(s.driver_id),
                "driver_name": s.driver.user.full_name if s.driver and s.driver.user else None,
                "period_start": s.period_start.isoformat(),
                "period_end": s.period_end.isoformat(),
                "total_assigned": s.total_assigned,
                "total_delivered": s.total_delivered,
                "total_returned": s.total_returned,
                "total_no_answer": s.total_no_answer,
                "total_collected": s.total_collected,
                "delivery_fees": s.delivery_fees,
                "bonus": s.bonus,
                "net_amount": s.net_amount,
                "status": s.status.value,
                "notes": s.notes,
                "paid_at": s.paid_at.isoformat() if s.paid_at else None,
                "created_at": s.created_at.isoformat(),
            }
            for s in settlements
        ],
        "total": total_count,
        "page": page,
        "per_page": per_page,
    }


@router.post("/driver/generate")
async def generate_driver_settlement(
    driver_id: str | None = None,
    period_start: str = Query(...),
    period_end: str = Query(...),
    delivery_fee_per_order: float = Query(10.0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_admin_user),
):
    from datetime import date as date_type

    try:
        start = datetime.combine(date_type.fromisoformat(period_start), datetime.min.time()).replace(tzinfo=timezone.utc)
        end = datetime.combine(date_type.fromisoformat(period_end), datetime.min.time()).replace(tzinfo=timezone.utc)
    except ValueError as e:
        from app.core.exceptions import BadRequestException
        raise BadRequestException(f"Invalid date format: {e}")

    drivers_query = select(Driver)
    if driver_id:
        drivers_query = drivers_query.where(Driver.id == UUID(driver_id))

    drivers_result = await db.execute(drivers_query)
    drivers = drivers_result.scalars().all()

    created = []
    for driver in drivers:
        orders_result = await db.execute(
            select(BatchOrder)
            .where(
                BatchOrder.assigned_agent_id == driver.id,
                BatchOrder.delivery_date >= start,
                BatchOrder.delivery_date < end,
            )
        )
        orders = orders_result.scalars().all()

        if not orders:
            continue

        total_assigned = len(orders)
        total_delivered = sum(1 for o in orders if o.status == OrderStatus.delivered)
        total_returned = sum(1 for o in orders if o.status == OrderStatus.returned)
        total_no_answer = sum(1 for o in orders if o.status == OrderStatus.no_answer)
        total_collected = sum(o.collected_amount or 0 for o in orders if o.collected_amount)
        delivery_fees = total_delivered * delivery_fee_per_order

        settlement = DriverSettlement(
            driver_id=driver.id,
            period_start=start,
            period_end=end,
            total_assigned=total_assigned,
            total_delivered=total_delivered,
            total_returned=total_returned,
            total_no_answer=total_no_answer,
            total_collected=round(total_collected, 2),
            delivery_fees=round(delivery_fees, 2),
            bonus=0.0,
            net_amount=round(delivery_fees, 2),
        )
        db.add(settlement)
        created.append(str(settlement.id))

    await db.commit()

    return {"message": f"Generated {len(created)} driver settlements", "settlement_ids": created}


@router.post("/driver/{settlement_id}/pay")
async def pay_driver_settlement(
    settlement_id: str,
    data: PaySettlementRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_admin_user),
):
    result = await db.execute(
        select(DriverSettlement).where(DriverSettlement.id == settlement_id)
    )
    settlement = result.scalar_one_or_none()
    if not settlement:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Settlement not found")

    if settlement.status == SettlementStatus.paid:
        from app.core.exceptions import BadRequestException
        raise BadRequestException("Settlement already paid")

    settlement.status = SettlementStatus.paid
    settlement.paid_at = datetime.now(timezone.utc)
    settlement.paid_by = current_user.id
    if data.notes:
        settlement.notes = data.notes

    await db.commit()

    return {"message": "Driver settlement paid", "settlement_id": settlement_id}
