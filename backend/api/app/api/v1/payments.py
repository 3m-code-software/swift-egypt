from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, get_db
from app.core.exceptions import BadRequestException, NotFoundException
from app.models.invoice import Invoice, PaymentStatus as InvoicePaymentStatus
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.models.user import User
from pydantic import BaseModel

router = APIRouter(prefix="/payments", tags=["Payments"])


class MockPaymentIntentRequest(BaseModel):
    invoice_id: str | None = None
    amount: float
    payment_method: str = "credit_card"


class MockPaymentConfirmRequest(BaseModel):
    invoice_id: str | None = None
    amount: float
    payment_method: str = "credit_card"
    card_last_four: str = "4242"
    card_holder_name: str = "Test User"


@router.post("/create-intent")
async def create_mock_payment_intent(
    data: MockPaymentIntentRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    transaction_id = f"MOCK-{uuid4().hex[:12].upper()}"

    amount = data.amount
    if data.invoice_id:
        from sqlalchemy import select
        result = await db.execute(select(Invoice).where(Invoice.id == data.invoice_id))
        invoice = result.scalar_one_or_none()
        if not invoice:
            raise NotFoundException("Invoice not found")
        amount = invoice.total

    return {
        "intent_id": transaction_id,
        "amount": round(amount, 2),
        "currency": "EGP",
        "status": "requires_confirmation",
        "message": "Mock payment intent created",
    }


@router.post("/confirm")
async def confirm_mock_payment(
    data: MockPaymentConfirmRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    transaction_id = f"MOCK-{uuid4().hex[:12].upper()}"

    amount = data.amount
    invoice_id = data.invoice_id

    if invoice_id:
        from sqlalchemy import select
        result = await db.execute(select(Invoice).where(Invoice.id == invoice_id))
        invoice = result.scalar_one_or_none()
        if invoice:
            amount = invoice.total
            invoice.payment_status = InvoicePaymentStatus.paid
            invoice.paid_at = datetime.now(timezone.utc)

    payment = Payment(
        invoice_id=invoice_id,
        amount=round(amount, 2),
        payment_method=PaymentMethod(data.payment_method),
        status=PaymentStatus.completed,
        transaction_id=transaction_id,
        collected_by=current_user.id,
    )
    db.add(payment)
    await db.flush()
    await db.commit()

    return {
        "success": True,
        "transaction_id": transaction_id,
        "amount": round(amount, 2),
        "currency": "EGP",
        "status": "completed",
        "message": "Payment completed successfully",
        "receipt": {
            "transaction_id": transaction_id,
            "amount": round(amount, 2),
            "date": datetime.now(timezone.utc).isoformat(),
            "app_name": "Swift Egypt",
            "payment_method": data.payment_method,
        },
    }
