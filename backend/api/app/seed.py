import asyncio
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.database import async_session_factory, create_tables
from app.models.branch import Branch
from app.models.pricing_rule import PricingRule
from app.models.seller import Seller
from app.models.batch import Batch, BatchOrder, BatchStatus, OrderStatus
from app.models.user import User, UserRole
from app.models.customer import Customer
from app.models.driver import Driver
from app.models.vehicle import Vehicle
from app.models.shipment import ServiceType, Shipment, ShipmentItem, ShipmentStatus
from app.models.tracking_event import TrackingEvent
from app.models.ai_alert import AiAlert, AlertSeverity
from app.models.notification import Notification


async def seed():
    await create_tables()

    async with async_session_factory() as db:
        existing_admin = await db.execute(select(User).where(User.email == "admin@swiftegypt.com"))
        if existing_admin.scalar_one_or_none():
            print("Seed data already exists, skipping.")
            return

        # Create default branch
        branch = Branch(
            name="Cairo Main Hub",
            name_ar="المركز الرئيسي - القاهرة",
            address="25 Cairo International Airport Road, Cairo",
            phone="+202-1234-5678",
            latitude=30.0444,
            longitude=31.2357,
            is_active=True,
        )
        db.add(branch)

        # Create Alex branch
        branch2 = Branch(
            name="Alexandria Port Branch",
            name_ar="فرع ميناء الإسكندرية",
            address="15 Port Said Street, Alexandria",
            phone="+203-5678-9012",
            latitude=31.2001,
            longitude=29.9187,
            is_active=True,
        )
        db.add(branch2)
        await db.flush()

        # Create admin user
        admin = User(
            email="admin@swiftegypt.com",
            hashed_password=hash_password("admin123"),
            full_name="Admin User",
            phone="+201001234567",
            role=UserRole.admin,
            branch_id=branch.id,
            is_active=True,
            is_verified=True,
        )
        db.add(admin)

        # Create operations user
        ops = User(
            email="operations@swiftegypt.com",
            hashed_password=hash_password("admin123"),
            full_name="Omar Mahmoud",
            phone="+201009876543",
            role=UserRole.operations,
            branch_id=branch.id,
            is_active=True,
            is_verified=True,
        )
        db.add(ops)

        # Create branch manager
        bm = User(
            email="manager@swiftegypt.com",
            hashed_password=hash_password("admin123"),
            full_name="Ali Hassan",
            phone="+201005554433",
            role=UserRole.branch_manager,
            branch_id=branch2.id,
            is_active=True,
            is_verified=True,
        )
        db.add(bm)
        await db.flush()

        # Create customer profile for admin
        admin_customer = Customer(user_id=admin.id, company_name="Swift Egypt HQ")
        db.add(admin_customer)

        # Create customer accounts
        customers_data = [
            ("Ahmed Ali", "ahmed@example.com", "+201001001001", "El-Nasr Trading"),
            ("Sara Mostafa", "sara@example.com", "+201001001002", "Sara Imports"),
            ("Nour El-Din", "nour@example.com", "+201001001003", "Nour Logistics"),
            ("Laila Ibrahim", "laila@example.com", "+201001001004", "Laila Exports"),
        ]
        customers = []
        for name, email, phone, company in customers_data:
            u = User(
                email=email,
                hashed_password=hash_password("admin123"),
                full_name=name,
                phone=phone,
                role=UserRole.customer,
                branch_id=branch.id,
                is_active=True,
                is_verified=True,
            )
            db.add(u)
            await db.flush()
            c = Customer(user_id=u.id, company_name=company)
            db.add(c)
            customers.append(u)

        # Create seller users and profiles
        sellers_data = [
            ("Mostafa Ali", "seller1@swiftegypt.com", "+201003003001", "Mostafa Electronics"),
            ("Heba Nour", "seller2@swiftegypt.com", "+201003003002", "Heba Fashion House"),
        ]
        for name, email, phone, company in sellers_data:
            u = User(
                email=email,
                hashed_password=hash_password("admin123"),
                full_name=name,
                phone=phone,
                role=UserRole.seller,
                branch_id=branch.id,
                is_active=True,
                is_verified=True,
            )
            db.add(u)
            await db.flush()
            seller = Seller(user_id=u.id, company_name=company)
            db.add(seller)

        await db.flush()

        # Create driver users and profiles
        drivers_data = [
            ("Mohamed Kamel", "driver1@swiftegypt.com", "+201002002001"),
            ("Hassan Youssef", "driver2@swiftegypt.com", "+201002002002"),
            ("Khaled Said", "driver3@swiftegypt.com", "+201002002003"),
        ]
        driver_objects = []
        for name, email, phone in drivers_data:
            u = User(
                email=email,
                hashed_password=hash_password("admin123"),
                full_name=name,
                phone=phone,
                role=UserRole.driver,
                branch_id=branch.id,
                is_active=True,
                is_verified=True,
            )
            db.add(u)
            await db.flush()
            d = Driver(user_id=u.id, branch_id=branch.id, is_available=True, total_deliveries=0, rating=4.5)
            db.add(d)
            driver_objects.append((u, d))

        await db.flush()

        # Create vehicles
        vehicles = [
            Vehicle(plate_number="ABC-1234", model="Toyota Hiace 2024", type="van", max_weight=1500.0, max_volume=8.0, branch_id=branch.id, is_available=True),
            Vehicle(plate_number="DEF-5678", model="Mercedes Sprinter 2023", type="truck", max_weight=3500.0, max_volume=18.0, branch_id=branch.id, is_available=True),
            Vehicle(plate_number="GHI-9012", model="Mitsubishi Canter 2024", type="truck", max_weight=5000.0, max_volume=25.0, branch_id=branch2.id, is_available=True),
        ]
        for v in vehicles:
            db.add(v)
        await db.flush()

        # Assign first driver to first vehicle
        driver_objects[0][1].vehicle_id = vehicles[0].id
        driver_objects[0][1].is_available = False  # on a trip

        # Set branch manager for branch2
        branch2.manager_id = bm.id
        branch.manager_id = admin.id

        # Create pricing rules
        rules = [
            PricingRule(name="International Road - Standard", service_type=ServiceType.international_road, base_price=500.0, price_per_kg=2.5, price_per_volume=1.0, min_price=500.0, origin_country="Egypt", destination_country=None, is_active=True),
            PricingRule(name="Maritime - Standard", service_type=ServiceType.maritime, base_price=1500.0, price_per_kg=0.8, price_per_volume=0.3, min_price=1500.0, origin_country="Egypt", destination_country=None, is_active=True),
            PricingRule(name="Domestic - Standard", service_type=ServiceType.domestic, base_price=100.0, price_per_kg=1.5, price_per_volume=0.5, min_price=100.0, origin_country="Egypt", destination_country="Egypt", is_active=True),
        ]
        for rule in rules:
            db.add(rule)

        await db.flush()

        # Create shipments
        now = datetime.now(timezone.utc)
        shipment_configs = [
            {"tracking_number": "SE-2026-00001", "service_type": ServiceType.domestic, "status": ShipmentStatus.delivered,
             "sender": ("Ahmed Ali", "+201001001001"), "recipient": ("Mostafa Galal", "+201003003001"),
             "pickup": "15 Tahrir St, Cairo", "delivery": "22 Saad Zaghloul St, Alexandria",
             "weight": 25.0, "items": [{"desc": "Electronics", "qty": 3, "w": 8.0}, {"desc": "Documents", "qty": 1, "w": 1.0}],
             "created_offset": timedelta(days=30), "price": 450.0},
            {"tracking_number": "SE-2026-00002", "service_type": ServiceType.international_road, "status": ShipmentStatus.in_transit,
             "sender": ("Sara Mostafa", "+201001001002"), "recipient": ("George Nader", "+971504443322"),
             "pickup": "5 Nile St, Giza", "delivery": "Al Rigga St, Dubai, UAE",
             "weight": 120.0, "items": [{"desc": "Textiles", "qty": 10, "w": 120.0}],
             "created_offset": timedelta(days=14), "price": 2500.0},
            {"tracking_number": "SE-2026-00003", "service_type": ServiceType.maritime, "status": ShipmentStatus.pending,
             "sender": ("Nour El-Din", "+201001001003"), "recipient": ("Carlos Mendez", "+34911223344"),
             "pickup": "8 Corniche St, Alexandria", "delivery": "Puerto de Valencia, Spain",
             "weight": 5000.0, "items": [{"desc": "Furniture", "qty": 50, "w": 3000.0}, {"desc": "Home Decor", "qty": 40, "w": 2000.0}],
             "created_offset": timedelta(days=2), "price": 8500.0},
            {"tracking_number": "SE-2026-00004", "service_type": ServiceType.domestic, "status": ShipmentStatus.out_for_delivery,
             "sender": ("Laila Ibrahim", "+201001001004"), "recipient": ("Heba Nour", "+201006006001"),
             "pickup": "12 Abbas St, Mansoura", "delivery": "8 El-Kornish St, Hurghada",
             "weight": 15.0, "items": [{"desc": "Clothing", "qty": 5, "w": 15.0}],
             "created_offset": timedelta(days=7), "price": 280.0},
            {"tracking_number": "SE-2026-00005", "service_type": ServiceType.domestic, "status": ShipmentStatus.delayed,
             "sender": ("Ahmed Ali", "+201001001001"), "recipient": ("Yasser Fathy", "+201007007001"),
             "pickup": "15 Tahrir St, Cairo", "delivery": "33 El-Mahatta St, Aswan",
             "weight": 50.0, "items": [{"desc": "Machine Parts", "qty": 2, "w": 50.0}],
             "created_offset": timedelta(days=5), "price": 650.0},
            {"tracking_number": "SE-2026-00006", "service_type": ServiceType.international_road, "status": ShipmentStatus.confirmed,
             "sender": ("Sara Mostafa", "+201001001002"), "recipient": ("Ali Al-Amoudi", "+966501112233"),
             "pickup": "5 Nile St, Giza", "delivery": "Olaya St, Riyadh, KSA",
             "weight": 80.0, "items": [{"desc": "Medical Supplies", "qty": 20, "w": 80.0}],
             "created_offset": timedelta(days=1), "price": 1800.0},
            {"tracking_number": "SE-2026-00007", "service_type": ServiceType.maritime, "status": ShipmentStatus.picked_up,
             "sender": ("Nour El-Din", "+201001001003"), "recipient": ("John Smith", "+12025551234"),
             "pickup": "8 Corniche St, Alexandria", "delivery": "Port of Newark, NJ, USA",
             "weight": 12000.0, "items": [{"desc": "Steel Coils", "qty": 100, "w": 12000.0}],
             "created_offset": timedelta(days=3), "price": 15000.0},
        ]

        shipment_objects: list[Shipment] = []
        for idx, cfg in enumerate(shipment_configs):
            customer_user = next(u for u in customers if u.full_name == cfg["sender"][0])
            customer_result = await db.execute(select(Customer).where(Customer.user_id == customer_user.id))
            customer = customer_result.scalar_one()

            shipment = Shipment(
                tracking_number=cfg["tracking_number"],
                service_type=cfg["service_type"],
                status=cfg["status"],
                customer_id=customer.id,
                sender_name=cfg["sender"][0],
                sender_phone=cfg["sender"][1],
                recipient_name=cfg["recipient"][0],
                recipient_phone=cfg["recipient"][1],
                pickup_address=cfg["pickup"],
                delivery_address=cfg["delivery"],
                weight=cfg["weight"],
                estimated_price=cfg["price"],
                branch_id=branch.id,
                created_at=now - cfg["created_offset"],
                updated_at=now - cfg["created_offset"],
            )
            if idx == 0:
                shipment.driver_id = driver_objects[0][1].id
                shipment.vehicle_id = vehicles[0].id
            elif idx == 3:
                shipment.driver_id = driver_objects[1][1].id
                shipment.vehicle_id = vehicles[1].id
            db.add(shipment)
            await db.flush()
            shipment_objects.append(shipment)

            for item_data in cfg["items"]:
                item = ShipmentItem(
                    shipment_id=shipment.id,
                    description=item_data["desc"],
                    quantity=item_data["qty"],
                    weight=item_data["w"],
                )
                db.add(item)

            db.add(TrackingEvent(
                shipment_id=shipment.id,
                event_type="created",
                new_status=ShipmentStatus.pending.value,
                description="Shipment created",
                created_at=shipment.created_at,
            ))

            if cfg["status"] in [ShipmentStatus.confirmed, ShipmentStatus.picked_up, ShipmentStatus.in_transit, ShipmentStatus.out_for_delivery, ShipmentStatus.delivered, ShipmentStatus.delayed]:
                db.add(TrackingEvent(
                    shipment_id=shipment.id,
                    event_type="status_change",
                    new_status=ShipmentStatus.confirmed.value,
                    description="Shipment confirmed",
                    created_at=shipment.created_at + timedelta(hours=2),
                ))

            if cfg["status"] in [ShipmentStatus.picked_up, ShipmentStatus.in_transit, ShipmentStatus.out_for_delivery, ShipmentStatus.delivered, ShipmentStatus.delayed]:
                db.add(TrackingEvent(
                    shipment_id=shipment.id,
                    event_type="picked_up",
                    new_status=ShipmentStatus.picked_up.value,
                    description=f"Package picked up from {cfg['pickup']}",
                    created_at=shipment.created_at + timedelta(hours=6),
                ))

            if cfg["status"] in [ShipmentStatus.in_transit, ShipmentStatus.out_for_delivery, ShipmentStatus.delivered, ShipmentStatus.delayed]:
                loc = "In transit to destination"
                if cfg["service_type"] == ServiceType.maritime:
                    loc = "Departed from Alexandria Port"
                elif cfg["service_type"] == ServiceType.international_road:
                    loc = "Crossing border checkpoint"
                db.add(TrackingEvent(
                    shipment_id=shipment.id,
                    event_type="in_transit",
                    new_status=ShipmentStatus.in_transit.value,
                    description=loc,
                    created_at=shipment.created_at + timedelta(days=1),
                ))

            if cfg["status"] == ShipmentStatus.delayed:
                db.add(TrackingEvent(
                    shipment_id=shipment.id,
                    event_type="delayed",
                    new_status=ShipmentStatus.delayed.value,
                    description="Shipment delayed due to customs inspection",
                    created_at=shipment.created_at + timedelta(days=2),
                ))

            if cfg["status"] == ShipmentStatus.out_for_delivery:
                db.add(TrackingEvent(
                    shipment_id=shipment.id,
                    event_type="out_for_delivery",
                    new_status=ShipmentStatus.out_for_delivery.value,
                    description="Package out for delivery",
                    created_at=shipment.created_at + timedelta(days=3),
                ))

            if cfg["status"] == ShipmentStatus.delivered:
                db.add(TrackingEvent(
                    shipment_id=shipment.id,
                    event_type="out_for_delivery",
                    new_status=ShipmentStatus.out_for_delivery.value,
                    description="Package out for delivery",
                    created_at=shipment.created_at + timedelta(days=3),
                ))
                db.add(TrackingEvent(
                    shipment_id=shipment.id,
                    event_type="delivered",
                    new_status=ShipmentStatus.delivered.value,
                    description="Package delivered successfully. Signed by Mostafa Galal",
                    created_at=shipment.created_at + timedelta(days=4),
                ))

        # AI Alerts
        now = datetime.now(timezone.utc)
        ai_alerts_data = [
            {"shipment_id": shipment_objects[4].id, "alert_type": "delay_prediction", "severity": AlertSeverity.critical, "title": "Shipment SE-2026-00005 delayed by 48 hours", "description": "Estimated time of arrival recalculated due to customs delay in Aswan", "created_offset": timedelta(hours=2)},
            {"shipment_id": None, "alert_type": "driver_fatigue", "severity": AlertSeverity.high, "title": "Driver approaching driving limit", "description": "Driver Mohamed Kamel has been on duty for 9.5 hours", "created_offset": timedelta(hours=6)},
            {"shipment_id": shipment_objects[5].id, "alert_type": "route_optimization", "severity": AlertSeverity.medium, "title": "Route optimization available", "description": "Cairo → Riyadh route has a 23% faster alternative via Duba port", "created_offset": timedelta(hours=12)},
            {"shipment_id": None, "alert_type": "customer_insight", "severity": AlertSeverity.medium, "title": "Customer has pending shipments", "description": "Sara Mostafa has 3 pending shipments — potential churn risk", "created_offset": timedelta(days=1)},
            {"shipment_id": None, "alert_type": "forecast", "severity": AlertSeverity.low, "title": "Volume forecast", "description": "Shipment volume expected to increase 15% next week", "created_offset": timedelta(days=2)},
            {"shipment_id": None, "alert_type": "vehicle_issue", "severity": AlertSeverity.high, "title": "Vehicle maintenance required", "description": "Vehicle 345-TRK engine warning light reported", "created_offset": timedelta(days=3)},
            {"shipment_id": shipment_objects[0].id, "alert_type": "delivery_confirmation", "severity": AlertSeverity.low, "title": "Delivery confirmed", "description": "Shipment SE-2026-00001 delivered and signed for", "created_offset": timedelta(days=4)},
        ]
        for a in ai_alerts_data:
            db.add(AiAlert(
                shipment_id=a["shipment_id"],
                alert_type=a["alert_type"],
                severity=a["severity"],
                title=a["title"],
                description=a["description"],
                created_at=now - a["created_offset"],
            ))

        # Notifications for admin
        admin_user = (await db.execute(select(User).where(User.email == "admin@swiftegypt.com"))).scalar_one()
        notification_data = [
            {"title": "Shipment SE-2026-00001 delivered", "message": "Package delivered successfully to Mostafa Galal", "type": "shipment", "created_offset": timedelta(days=1)},
            {"title": "New driver registered", "message": "A new driver has been registered in the system", "type": "system", "created_offset": timedelta(hours=12)},
            {"title": "Monthly report ready", "message": "Your monthly shipment report is now available for download", "type": "report", "created_offset": timedelta(hours=6)},
            {"title": "Payment received", "message": "Payment of EGP 2,500.00 received for shipment SE-2026-00002", "type": "payment", "created_offset": timedelta(hours=3)},
            {"title": "Maintenance alert", "message": "Vehicle 345-TRK is due for maintenance", "type": "alert", "created_offset": timedelta(hours=1)},
        ]
        for n in notification_data:
            db.add(Notification(
                user_id=admin_user.id,
                title=n["title"],
                message=n["message"],
                type=n["type"],
                created_at=now - n["created_offset"],
            ))

        await db.commit()
        print("Seed data created successfully!")
        print("- Admin user: admin@swiftegypt.com / admin123")
        print("- Operations: operations@swiftegypt.com / admin123")
        print("- Branch Manager: manager@swiftegypt.com / admin123")
        print("- 4 Customer accounts")
        print("- 2 Seller accounts")
        print("- 3 Driver accounts")
        print("- 3 Vehicles")
        print("- 2 Branches")
        print("- 7 Shipments with tracking events")
        print("- 3 Pricing rules")
        print("- 7 AI alerts")
print("- 5 Notifications")


if __name__ == "__main__":
    asyncio.run(seed())
