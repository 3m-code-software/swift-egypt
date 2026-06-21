import pytest


@pytest.mark.asyncio
async def test_create_and_list_shipments(client):
    register_resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "ship@test.com",
            "password": "TestPass123",
            "full_name": "Ship Tester",
            "phone": "+201000000010",
        },
    )
    assert register_resp.status_code == 201
    token = register_resp.json()["token"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    create_resp = await client.post(
        "/api/v1/shipments/",
        json={
            "service_type": "domestic",
            "sender_name": "Sender",
            "sender_phone": "+201000000011",
            "recipient_name": "Recipient",
            "recipient_phone": "+201000000012",
            "pickup_address": "Cairo",
            "delivery_address": "Alex",
            "items": [{"description": "Box of goods", "quantity": 1, "weight": 5.0}],
        },
        headers=headers,
    )
    assert create_resp.status_code == 201, await create_resp.text()
    shipment = create_resp.json()
    assert shipment["tracking_number"] is not None
    assert shipment["status"] == "pending"

    list_resp = await client.get("/api/v1/shipments/", headers=headers)
    assert list_resp.status_code == 200
    assert len(list_resp.json()["items"]) >= 1

    detail_resp = await client.get(
        f"/api/v1/shipments/{shipment['id']}", headers=headers
    )
    assert detail_resp.status_code == 200
    assert detail_resp.json()["id"] == shipment["id"]


@pytest.mark.asyncio
async def test_public_tracking(client):
    register_resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "track@test.com",
            "password": "TestPass123",
            "full_name": "Track Tester",
            "phone": "+201000000020",
        },
    )
    assert register_resp.status_code == 201
    token = register_resp.json()["token"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    create_resp = await client.post(
        "/api/v1/shipments/",
        json={
            "service_type": "domestic",
            "sender_name": "S",
            "sender_phone": "+201000000021",
            "recipient_name": "R",
            "recipient_phone": "+201000000022",
            "pickup_address": "Cairo",
            "delivery_address": "Giza",
            "items": [{"description": "Documents", "quantity": 1}],
        },
        headers=headers,
    )
    assert create_resp.status_code == 201, await create_resp.text()
    tn = create_resp.json()["tracking_number"]

    track_resp = await client.get(f"/api/v1/shipments/tracking/{tn}")
    assert track_resp.status_code == 200
    assert track_resp.json()["tracking_number"] == tn
