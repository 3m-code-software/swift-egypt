from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_active_user, get_db
from app.core.exceptions import NotFoundException
from app.models.support_ticket import SupportTicket, TicketStatus
from app.models.user import User
from app.schemas.support import ChatRequest, ChatResponse, SupportTicketCreate, SupportTicketResponse
from app.utils.pagination import PaginationParams, paginate

router = APIRouter(prefix="/support", tags=["Support"])


@router.post("/tickets", response_model=SupportTicketResponse, status_code=status.HTTP_201_CREATED)
async def create_ticket(data: SupportTicketCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Create a support ticket."""
    customer_id = current_user.customer.id if current_user.customer else None
    ticket = SupportTicket(
        customer_id=customer_id,
        shipment_id=data.shipment_id,
        subject=data.subject,
        message=data.message,
    )
    db.add(ticket)
    await db.flush()
    return SupportTicketResponse.model_validate(ticket)


@router.get("/tickets")
async def list_tickets(page: PaginationParams = Depends(), db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """List support tickets."""
    query = select(SupportTicket).order_by(SupportTicket.created_at.desc())
    await db.refresh(current_user, ['customer'])
    if current_user.customer:
        query = query.where(SupportTicket.customer_id == current_user.customer.id)

    result = await db.execute(query.offset(page.offset).limit(page.limit))
    tickets = result.scalars().all()
    total_result = await db.execute(select(SupportTicket))
    total = len(total_result.scalars().all())
    items = [SupportTicketResponse.model_validate(t) for t in tickets]
    return paginate(items, total, page)


@router.get("/tickets/{ticket_id}", response_model=SupportTicketResponse)
async def get_ticket(ticket_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get ticket details."""
    result = await db.execute(select(SupportTicket).where(SupportTicket.id == ticket_id))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise NotFoundException("Ticket not found")
    return SupportTicketResponse.model_validate(ticket)


@router.post("/tickets/{ticket_id}/reply", response_model=dict)
async def reply_ticket(ticket_id: UUID, data: ChatRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Reply to a support ticket."""
    result = await db.execute(select(SupportTicket).where(SupportTicket.id == ticket_id))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise NotFoundException("Ticket not found")
    return {"message": "Reply sent", "ticket_id": str(ticket_id)}


@router.post("/chat", response_model=ChatResponse)
async def chat_query(data: ChatRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Send a chatbot query for support."""
    # Stub: In production, this would call an AI chatbot service
    return ChatResponse(
        response=f"I understand you're asking about '{data.query}'. A support agent will follow up with you shortly.",
        session_id=data.session_id or str(current_user.id),
    )
