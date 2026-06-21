import pytest


@pytest.mark.asyncio
async def test_register_and_login(client):
    register_resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "test@test.com",
            "password": "TestPass123",
            "full_name": "Test User",
            "phone": "+201000000000",
        },
    )
    assert register_resp.status_code == 201
    data = register_resp.json()
    assert "access_token" in data["token"]
    assert data["user"]["email"] == "test@test.com"

    token = data["token"]["access_token"]

    login_resp = await client.post(
        "/api/v1/auth/login",
        json={"email": "test@test.com", "password": "TestPass123"},
    )
    assert login_resp.status_code == 200

    me_resp = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_resp.status_code == 200
    assert me_resp.json()["email"] == "test@test.com"


@pytest.mark.asyncio
async def test_refresh_token(client):
    register_resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "refresh@test.com",
            "password": "TestPass123",
            "full_name": "Refresh User",
            "phone": "+201000000001",
        },
    )
    assert register_resp.status_code == 201
    refresh_token = register_resp.json()["token"]["refresh_token"]

    refresh_resp = await client.post(
        "/api/v1/auth/refresh-token",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 200
    assert "access_token" in refresh_resp.json()
