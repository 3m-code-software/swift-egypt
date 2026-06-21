from fastapi import APIRouter, Depends, status
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_admin_user, get_current_active_user, get_db
from app.models.user import User
from app.models.notification import Notification
from app.schemas.notification import NotificationResponse, NotificationCreate, UnreadCountResponse
from app.ws_manager import manager

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def _serialize(notification: Notification) -> dict:
    return {
        "id": str(notification.id),
        "user_id": str(notification.user_id),
        "title": notification.title,
        "message": notification.message,
        "type": notification.type,
        "is_read": notification.is_read,
        "created_at": notification.created_at.isoformat() if notification.created_at else None,
    }


@router.get("/", response_model=list[NotificationResponse])
async def list_notifications(limit: int = 20, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    result = await db.execute(
        select(Notification).where(Notification.user_id == current_user.id).order_by(Notification.created_at.desc()).limit(limit)
    )
    return [NotificationResponse.model_validate(n) for n in result.scalars().all()]


@router.get("/unread-count", response_model=UnreadCountResponse)
async def unread_count(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    result = await db.execute(
        select(func.count()).select_from(Notification).where(Notification.user_id == current_user.id, Notification.is_read == False)
    )
    return UnreadCountResponse(count=result.scalar() or 0)


@router.post("/", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
async def create_notification(payload: NotificationCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_admin_user)):
    notification = Notification(
        user_id=payload.user_id,
        title=payload.title,
        message=payload.message,
        type=payload.type,
    )
    db.add(notification)
    await db.commit()
    await db.refresh(notification)
    data = _serialize(notification)
    await manager.send_to_user(str(payload.user_id), {"type": "new_notification", "data": data})
    return NotificationResponse.model_validate(notification)


@router.put("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_read(notification_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    from uuid import UUID
    result = await db.execute(select(Notification).where(Notification.id == UUID(notification_id), Notification.user_id == current_user.id))
    notification = result.scalar_one_or_none()
    if not notification:
        from app.core.exceptions import NotFoundException
        raise NotFoundException("Notification not found")
    notification.is_read = True
    await db.commit()
    await db.refresh(notification)
    return NotificationResponse.model_validate(notification)


@router.put("/read-all")
async def mark_all_read(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    await db.execute(
        update(Notification).where(Notification.user_id == current_user.id, Notification.is_read == False).values(is_read=True)
    )
    await db.commit()
    await manager.send_to_user(str(current_user.id), {"type": "all_read"})
    return {"message": "All notifications marked as read"}
