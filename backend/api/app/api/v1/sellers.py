from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_active_user, get_db, get_operations_user
from app.models.batch import Batch, BatchOrder, BatchStatus, OrderStatus
from app.models.seller import Seller
from app.models.user import User, UserRole
from app.schemas.seller import SellerAnalyticsResponse, SellerResponse, SellerWalletResponse

router = APIRouter(prefix="/sellers", tags=["Sellers"])


@router.get("/")
async def list_sellers(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    query = (
        select(Seller)
        .options(selectinload(Seller.user))
        .order_by(Seller.created_at.desc())
    )
    result = await db.execute(query)
    sellers = result.scalars().all()

    items = []
    for s in sellers:
        orders_count = await db.execute(
            select(func.count(BatchOrder.id)).where(
                BatchOrder.batch_id.in_(
                    select(Batch.id).where(Batch.seller_id == s.id)
                )
            )
        )
        total_orders = orders_count.scalar() or 0
        items.append({
            "id": str(s.id),
            "user_id": str(s.user_id),
            "company_name": s.company_name,
            "tax_number": s.tax_number,
            "commercial_register": s.commercial_register,
            "address": s.address,
            "wallet_balance": s.wallet_balance,
            "total_orders": total_orders,
            "total_delivered": s.total_delivered,
            "total_returned": s.total_returned,
            "full_name": s.user.full_name if s.user else None,
            "email": s.user.email if s.user else None,
            "phone": s.user.phone if s.user else None,
            "created_at": s.created_at.isoformat() if s.created_at else None,
        })

    return items


@router.get("/{seller_id}")
async def get_seller(
    seller_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    result = await db.execute(
        select(Seller)
        .options(selectinload(Seller.user))
        .where(Seller.id == seller_id)
    )
    s = result.scalar_one_or_none()
    if not s:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Seller not found")

    return {
        "id": str(s.id),
        "user_id": str(s.user_id),
        "company_name": s.company_name,
        "tax_number": s.tax_number,
        "commercial_register": s.commercial_register,
        "address": s.address,
        "wallet_balance": s.wallet_balance,
        "total_orders": s.total_orders,
        "total_delivered": s.total_delivered,
        "total_returned": s.total_returned,
        "full_name": s.user.full_name if s.user else None,
        "email": s.user.email if s.user else None,
        "phone": s.user.phone if s.user else None,
        "created_at": s.created_at.isoformat() if s.created_at else None,
        "updated_at": s.updated_at.isoformat() if s.updated_at else None,
    }


@router.get("/{seller_id}/wallet")
async def get_seller_wallet(
    seller_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    result = await db.execute(select(Seller).where(Seller.id == seller_id))
    s = result.scalar_one_or_none()
    if not s:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Seller not found")

    approved_batches = await db.execute(
        select(func.sum(Batch.total_amount), func.sum(Batch.commission_amount))
        .where(Batch.seller_id == seller_id, Batch.status == BatchStatus.approved)
    )
    total_amount, total_commission = approved_batches.one() or (0, 0)

    return SellerWalletResponse(
        wallet_balance=s.wallet_balance,
        total_earned=float(total_amount or 0),
        total_commission=float(total_commission or 0),
    )


@router.get("/{seller_id}/analytics")
async def get_seller_analytics(
    seller_id: str,
    days: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    result = await db.execute(select(Seller).where(Seller.id == seller_id))
    s = result.scalar_one_or_none()
    if not s:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Seller not found")

    batch_ids = (
        select(Batch.id).where(Batch.seller_id == seller_id)
    )
    total_orders = await db.execute(
        select(func.count(BatchOrder.id)).where(
            BatchOrder.batch_id.in_(batch_ids)
        )
    )
    total = total_orders.scalar() or 0

    delivered = await db.execute(
        select(func.count(BatchOrder.id)).where(
            BatchOrder.batch_id.in_(batch_ids),
            BatchOrder.status == OrderStatus.delivered,
        )
    )
    delivered_count = delivered.scalar() or 0

    returned = await db.execute(
        select(func.count(BatchOrder.id)).where(
            BatchOrder.batch_id.in_(batch_ids),
            BatchOrder.status == OrderStatus.returned,
        )
    )
    returned_count = returned.scalar() or 0

    pending = await db.execute(
        select(func.count(BatchOrder.id)).where(
            BatchOrder.batch_id.in_(batch_ids),
            BatchOrder.status == OrderStatus.pending,
        )
    )
    pending_count = pending.scalar() or 0

    revenue = await db.execute(
        select(func.coalesce(func.sum(BatchOrder.total), 0)).where(
            BatchOrder.batch_id.in_(batch_ids),
            BatchOrder.status == OrderStatus.delivered,
        )
    )
    total_revenue = revenue.scalar() or 0.0

    return SellerAnalyticsResponse(
        total_orders=total,
        total_delivered=delivered_count,
        total_returned=returned_count,
        pending_orders=pending_count,
        delivery_rate=(delivered_count / total * 100) if total > 0 else 0,
        return_rate=(returned_count / total * 100) if total > 0 else 0,
        total_revenue=float(total_revenue),
        period_days=days,
    )


# Seller self-service endpoints
@router.get("/me/wallet")
async def get_my_wallet(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(Seller).where(Seller.user_id == current_user.id)
    )
    s = result.scalar_one_or_none()
    if not s:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Seller profile not found")

    return SellerWalletResponse(
        wallet_balance=s.wallet_balance,
        total_earned=float(s.total_orders * 100),
        total_commission=0.0,
    )


@router.get("/me/stats")
async def get_my_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    result = await db.execute(
        select(Seller).where(Seller.user_id == current_user.id)
    )
    s = result.scalar_one_or_none()
    if not s:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Seller profile not found")

    return SellerAnalyticsResponse(
        total_orders=s.total_orders,
        total_delivered=s.total_delivered,
        total_returned=s.total_returned,
        pending_orders=s.total_orders - s.total_delivered - s.total_returned,
        delivery_rate=(s.total_delivered / s.total_orders * 100) if s.total_orders > 0 else 0,
        return_rate=(s.total_returned / s.total_orders * 100) if s.total_orders > 0 else 0,
        total_revenue=float(s.total_orders * 100),
    )
