from app.models.notification import Notification
from app.ws_manager import manager


class NotificationService:

    @staticmethod
    async def send_push_notification(user_id: str, title: str, body: str, data: dict | None = None) -> bool:
        try:
            payload = {
                "type": "new_notification",
                "data": {
                    "title": title,
                    "message": body,
                    "data": data or {},
                },
            }
            await manager.send_to_user(user_id, payload)
            return True
        except Exception as e:
            print(f"[WS] Failed to send notification: {e}")
            return False

    @staticmethod
    async def send_shipment_status_notification(shipment, new_status: str) -> None:
        title = f"Shipment {shipment.tracking_number}"
        body = f"Status updated to: {new_status}"
        await NotificationService.send_push_notification(
            user_id=str(shipment.customer_id),
            title=title,
            body=body,
            data={"shipment_id": str(shipment.id), "tracking_number": shipment.tracking_number, "status": new_status},
        )

    @staticmethod
    async def send_email(to: str, subject: str, body: str) -> bool:
        try:
            print(f"[EMAIL] Sending to {to}: {subject}")
            return True
        except Exception as e:
            print(f"[EMAIL] Failed: {e}")
            return False

    @staticmethod
    async def create_and_send(
        db_session,
        user_id: str,
        title: str,
        message: str,
        notification_type: str = "info",
    ) -> Notification:
        from uuid import UUID
        notification = Notification(
            user_id=UUID(user_id),
            title=title,
            message=message,
            type=notification_type,
        )
        db_session.add(notification)
        await db_session.flush()

        await NotificationService.send_push_notification(
            user_id=user_id,
            title=title,
            body=message,
            data={"notification_id": str(notification.id), "type": notification_type},
        )
        return notification
