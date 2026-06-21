from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_operations_user, get_db
from app.models.customer import Customer
from app.models.shipment import Shipment
from app.models.user import User
from app.utils.pagination import PaginationParams, paginate

router = APIRouter(prefix="/customers", tags=["Customers"])


@router.get("/")
async def list_customers(
    page: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    """List all customers with user info and shipment counts."""
    query = (
        select(Customer)
        .options(selectinload(Customer.user))
        .order_by(Customer.created_at.desc())
    )
    result = await db.execute(query.offset(page.offset).limit(page.limit))
    customers = result.scalars().all()

    total_result = await db.execute(select(func.count(Customer.id)))
    total = total_result.scalar()

    items = []
    for c in customers:
        shipment_count_result = await db.execute(
            select(func.count(Shipment.id)).where(Shipment.customer_id == c.id)
        )
        shipment_count = shipment_count_result.scalar()
        items.append(
            {
                "id": str(c.id),
                "user_id": str(c.user_id),
                "company_name": c.company_name,
                "tax_number": c.tax_number,
                "commercial_register": c.commercial_register,
                "full_name": c.user.full_name if c.user else None,
                "email": c.user.email if c.user else None,
                "phone": c.user.phone if c.user else None,
                "total_shipments": shipment_count or 0,
                "created_at": c.created_at.isoformat() if c.created_at else None,
            }
        )

    return paginate(items, total, page)


@router.get("/{customer_id}", response_model=dict)
async def get_customer(
    customer_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    """Get customer details."""
    result = await db.execute(
        select(Customer)
        .options(selectinload(Customer.user))
        .where(Customer.id == customer_id)
    )
    c = result.scalar_one_or_none()
    if not c:
        from app.core.exceptions import NotFoundException

        raise NotFoundException("Customer not found")

    shipment_count_result = await db.execute(
        select(func.count(Shipment.id)).where(Shipment.customer_id == c.id)
    )
    shipment_count = shipment_count_result.scalar()

    return {
        "id": str(c.id),
        "user_id": str(c.user_id),
        "company_name": c.company_name,
        "tax_number": c.tax_number,
        "commercial_register": c.commercial_register,
        "address": c.address,
        "full_name": c.user.full_name if c.user else None,
        "email": c.user.email if c.user else None,
        "phone": c.user.phone if c.user else None,
        "total_shipments": shipment_count or 0,
        "created_at": c.created_at.isoformat() if c.created_at else None,
        "updated_at": c.updated_at.isoformat() if c.updated_at else None,
    }
