from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_operations_user, get_db
from app.core.exceptions import NotFoundException
from app.models.invoice import Invoice, PaymentStatus
from app.models.payment import Payment, PaymentMethod, PaymentStatus as PmStatus
from app.models.shipment import Shipment
from app.models.user import User
from app.schemas.invoice import InvoiceCreate, InvoiceResponse, PaymentRecord
from app.utils.pagination import PaginationParams, paginate

router = APIRouter(prefix="/invoices", tags=["Invoices"])


def generate_invoice_number() -> str:
    from datetime import datetime
    import random
    return f"INV-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"


@router.get("/")
async def list_invoices(
    page: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_operations_user),
):
    """List all invoices with customer and shipment info."""
    query = select(Invoice).order_by(Invoice.created_at.desc())
    result = await db.execute(query.offset(page.offset).limit(page.limit))
    invoices = result.scalars().all()
    total_result = await db.execute(select(func.count(Invoice.id)))
    total = total_result.scalar()

    items = []
    for inv in invoices:
        shipment_result = await db.execute(
            select(Shipment).where(Shipment.id == inv.shipment_id)
        )
        shipment = shipment_result.scalar_one_or_none()
        customer_name = None
        if shipment:
            customer_result = await db.execute(
                select(User).where(User.id == shipment.customer_id)
            )
            customer_user = customer_result.scalar_one_or_none()
            customer_name = customer_user.full_name if customer_user else None

        items.append(
            {
                "id": str(inv.id),
                "shipment_id": str(inv.shipment_id),
                "invoice_number": inv.invoice_number,
                "customer_name": customer_name,
                "subtotal": inv.subtotal,
                "tax": inv.tax,
                "insurance": inv.insurance,
                "additional_fees": inv.additional_fees,
                "total": inv.total,
                "payment_status": inv.payment_status.value
                if hasattr(inv.payment_status, "value")
                else inv.payment_status,
                "notes": inv.notes,
                "created_at": inv.created_at.isoformat() if inv.created_at else None,
                "paid_at": inv.paid_at.isoformat() if inv.paid_at else None,
            }
        )

    return paginate(items, total, page)


@router.get("/{invoice_id}", response_model=InvoiceResponse)
async def get_invoice(invoice_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get invoice details."""
    result = await db.execute(select(Invoice).where(Invoice.id == invoice_id))
    invoice = result.scalar_one_or_none()
    if not invoice:
        raise NotFoundException("Invoice not found")
    return InvoiceResponse.model_validate(invoice)


@router.get("/shipment/{shipment_id}", response_model=InvoiceResponse)
async def get_shipment_invoice(shipment_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Get invoice for a shipment."""
    result = await db.execute(select(Invoice).where(Invoice.shipment_id == shipment_id))
    invoice = result.scalar_one_or_none()
    if not invoice:
        raise NotFoundException("Invoice not found for this shipment")
    return InvoiceResponse.model_validate(invoice)


@router.post("/", response_model=InvoiceResponse, status_code=status.HTTP_201_CREATED)
async def create_invoice(data: InvoiceCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Create a new invoice for a shipment."""
    total = data.subtotal + data.tax + data.insurance + data.additional_fees
    invoice = Invoice(
        shipment_id=data.shipment_id,
        invoice_number=generate_invoice_number(),
        subtotal=data.subtotal,
        tax=data.tax,
        insurance=data.insurance,
        additional_fees=data.additional_fees,
        total=total,
        notes=data.notes,
    )
    db.add(invoice)

    shipment_result = await db.execute(select(Shipment).where(Shipment.id == data.shipment_id))
    shipment = shipment_result.scalar_one_or_none()
    if shipment:
        shipment.final_price = total

    await db.flush()
    return InvoiceResponse.model_validate(invoice)


@router.post("/{invoice_id}/pay", response_model=dict)
async def pay_invoice(invoice_id: UUID, data: PaymentRecord, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_operations_user)):
    """Record a payment for an invoice."""
    result = await db.execute(select(Invoice).where(Invoice.id == invoice_id))
    invoice = result.scalar_one_or_none()
    if not invoice:
        raise NotFoundException("Invoice not found")

    payment = Payment(
        invoice_id=invoice_id,
        shipment_id=invoice.shipment_id,
        amount=data.amount,
        payment_method=PaymentMethod(data.payment_method),
        status=PmStatus.completed,
        transaction_id=data.transaction_id,
        collected_by=current_user.id,
    )
    db.add(payment)

    invoice.payment_status = PaymentStatus.paid
    invoice.paid_at = datetime.now(timezone.utc)

    await db.flush()
    return {"message": "Payment recorded successfully", "invoice_id": str(invoice_id)}
