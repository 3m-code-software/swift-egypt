import random
import string
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import BadRequestException, NotFoundException
from app.models.driver import Driver
from app.models.shipment import ServiceType, Shipment, ShipmentItem, ShipmentStatus
from app.models.tracking_event import TrackingEvent
from app.models.vehicle import Vehicle
from app.models.container import Container
from app.services.notification_service import NotificationService


def generate_tracking_number() -> str:
    year = datetime.now().year
    random_part = "".join(random.choices(string.digits, k=5))
    return f"SE-{year}-{random_part}"


class ShipmentService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_shipment(self, customer_id: UUID, data: dict) -> Shipment:
        tracking_number = generate_tracking_number()

        shipment = Shipment(
            tracking_number=tracking_number,
            service_type=data["service_type"],
            customer_id=customer_id,
            pickup_address=data.get("pickup_address"),
            delivery_address=data.get("delivery_address"),
            pickup_latitude=data.get("pickup_latitude"),
            pickup_longitude=data.get("pickup_longitude"),
            delivery_latitude=data.get("delivery_latitude"),
            delivery_longitude=data.get("delivery_longitude"),
            sender_name=data["sender_name"],
            sender_phone=data["sender_phone"],
            recipient_name=data["recipient_name"],
            recipient_phone=data["recipient_phone"],
            weight=data.get("weight"),
            notes=data.get("notes"),
            status=ShipmentStatus.pending,
        )
        self.db.add(shipment)
        await self.db.flush()

        for item_data in data.get("items", []):
            volume_weight = None
            if item_data.get("length") and item_data.get("width") and item_data.get("height"):
                volume_weight = (item_data["length"] * item_data["width"] * item_data["height"]) / 5000

            item = ShipmentItem(
                shipment_id=shipment.id,
                description=item_data["description"],
                quantity=item_data.get("quantity", 1),
                weight=item_data.get("weight"),
                length=item_data.get("length"),
                width=item_data.get("width"),
                height=item_data.get("height"),
                volume_weight=volume_weight,
            )
            self.db.add(item)

        self.db.add(TrackingEvent(
            shipment_id=shipment.id,
            event_type="created",
            new_status=ShipmentStatus.pending.value,
            description="Shipment created",
        ))

        await self.db.flush()
        result = await self.db.execute(
            select(Shipment)
            .options(selectinload(Shipment.items), selectinload(Shipment.tracking_events))
            .where(Shipment.id == shipment.id)
        )
        return result.scalar_one()

    async def get_shipment(self, shipment_id: UUID) -> Shipment:
        result = await self.db.execute(
            select(Shipment)
            .options(selectinload(Shipment.items), selectinload(Shipment.tracking_events))
            .where(Shipment.id == shipment_id)
        )
        shipment = result.scalar_one_or_none()
        if not shipment:
            raise NotFoundException("Shipment not found")
        return shipment

    async def list_shipments(
        self,
        customer_id: UUID | None = None,
        status: str | None = None,
        service_type: str | None = None,
        date_from: datetime | None = None,
        date_to: datetime | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Shipment], int]:
        query = select(Shipment).options(selectinload(Shipment.items), selectinload(Shipment.tracking_events))

        if customer_id:
            query = query.where(Shipment.customer_id == customer_id)
        if status:
            query = query.where(Shipment.status == ShipmentStatus(status))
        if service_type:
            query = query.where(Shipment.service_type == ServiceType(service_type))
        if date_from:
            query = query.where(Shipment.created_at >= date_from)
        if date_to:
            query = query.where(Shipment.created_at <= date_to)

        count_query = select(func.count()).select_from(query.subquery())
        total_result = await self.db.execute(count_query)
        total = total_result.scalar()

        query = query.order_by(Shipment.created_at.desc())
        query = query.offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(query)
        shipments = list(result.scalars().all())

        return shipments, total

    async def update_shipment(self, shipment_id: UUID, data: dict) -> Shipment:
        shipment = await self.get_shipment(shipment_id)

        for field in ["pickup_address", "delivery_address", "recipient_name", "recipient_phone", "weight", "notes"]:
            if field in data:
                setattr(shipment, field, data[field])

        await self.db.flush()
        return shipment

    async def assign_driver(self, shipment_id: UUID, driver_id: UUID) -> Shipment:
        shipment = await self.get_shipment(shipment_id)

        driver_result = await self.db.execute(select(Driver).where(Driver.id == driver_id))
        driver = driver_result.scalar_one_or_none()
        if not driver:
            raise NotFoundException("Driver not found")

        shipment.driver_id = driver_id
        self.db.add(TrackingEvent(
            shipment_id=shipment.id,
            event_type="driver_assigned",
            description=f"Driver assigned to shipment",
        ))

        await self.db.flush()
        return shipment

    async def assign_vehicle(self, shipment_id: UUID, vehicle_id: UUID) -> Shipment:
        shipment = await self.get_shipment(shipment_id)

        vehicle_result = await self.db.execute(select(Vehicle).where(Vehicle.id == vehicle_id))
        vehicle = vehicle_result.scalar_one_or_none()
        if not vehicle:
            raise NotFoundException("Vehicle not found")

        shipment.vehicle_id = vehicle_id
        self.db.add(TrackingEvent(
            shipment_id=shipment.id,
            event_type="vehicle_assigned",
            description=f"Vehicle assigned to shipment",
        ))

        await self.db.flush()
        return shipment

    async def assign_container(self, shipment_id: UUID, container_id: UUID) -> Shipment:
        shipment = await self.get_shipment(shipment_id)

        container_result = await self.db.execute(select(Container).where(Container.id == container_id))
        container = container_result.scalar_one_or_none()
        if not container:
            raise NotFoundException("Container not found")

        shipment.container_id = container_id
        self.db.add(TrackingEvent(
            shipment_id=shipment.id,
            event_type="container_assigned",
            description=f"Container assigned to shipment",
        ))

        await self.db.flush()
        return shipment

    async def update_status(self, shipment_id: UUID, new_status: ShipmentStatus, description: str | None = None) -> Shipment:
        shipment = await self.get_shipment(shipment_id)
        old_status = shipment.status
        shipment.status = new_status

        self.db.add(TrackingEvent(
            shipment_id=shipment.id,
            event_type="status_change",
            new_status=new_status.value,
            description=description or f"Status changed from {old_status.value} to {new_status.value}",
        ))

        await self.db.flush()

        await NotificationService.send_shipment_status_notification(shipment, new_status.value)
        return shipment

    async def cancel_shipment(self, shipment_id: UUID) -> Shipment:
        return await self.update_status(shipment_id, ShipmentStatus.cancelled, "Shipment cancelled")

    async def approve_shipment(self, shipment_id: UUID) -> Shipment:
        return await self.update_status(shipment_id, ShipmentStatus.confirmed, "Shipment approved")

    async def get_by_tracking_number(self, tracking_number: str) -> Shipment:
        result = await self.db.execute(
            select(Shipment)
            .options(selectinload(Shipment.items), selectinload(Shipment.tracking_events))
            .where(Shipment.tracking_number == tracking_number)
        )
        shipment = result.scalar_one_or_none()
        if not shipment:
            raise NotFoundException("Shipment not found")
        return shipment
