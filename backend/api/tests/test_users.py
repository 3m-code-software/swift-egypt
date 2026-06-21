import pytest


@pytest.mark.asyncio
async def test_user_profile_update(client):
    register_resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "profile@test.com",
            "password": "TestPass123",
            "full_name": "Profile Tester",
            "phone": "+201000000030",
        },
    )
    assert register_resp.status_code == 201
    token = register_resp.json()["token"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    update_resp = await client.put(
        "/api/v1/users/me",
        json={"full_name": "Updated Name", "phone": "+201000000099"},
        headers=headers,
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["full_name"] == "Updated Name"

    me_resp = await client.get("/api/v1/users/me", headers=headers)
    assert me_resp.json()["full_name"] == "Updated Name"


@pytest.mark.asyncio
async def test_non_admin_cannot_list_users(client):
    register_resp = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "regular@test.com",
            "password": "TestPass123",
            "full_name": "Regular User",
            "phone": "+201000000040",
        },
    )
    assert register_resp.status_code == 201
    token = register_resp.json()["token"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.get("/api/v1/users/", headers=headers)
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_admin_can_list_users(client):
    admin_reg = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "admin@test.com",
            "password": "TestPass123",
            "full_name": "Test Admin",
            "phone": "+201000000050",
        },
    )
    assert admin_reg.status_code == 201
    admin_token = admin_reg.json()["token"]["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    resp = await client.get("/api/v1/users/", headers=admin_headers)
    assert resp.status_code == 403  # registered users are customers, not admins
