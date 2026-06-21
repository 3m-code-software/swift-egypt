import asyncio
from datetime import datetime, timezone

import httpx

NOMINATIM_URL = "https://nominatim.openstreetmap.org"


async def geocode_address(address: str, city: str | None = None, country: str = "Egypt") -> dict | None:
    q = address
    if city:
        q = f"{q}, {city}"
    if country:
        q = f"{q}, {country}"

    await asyncio.sleep(1)

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            f"{NOMINATIM_URL}/search",
            params={"q": q, "format": "json", "limit": 1, "addressdetails": 1},
            headers={"User-Agent": "SwiftEgypt/1.0"},
        )
        if resp.status_code != 200:
            return None

        data = resp.json()
        if not data:
            return None

        result = data[0]
        return {
            "latitude": float(result["lat"]),
            "longitude": float(result["lon"]),
            "display_name": result.get("display_name", ""),
            "city": (result.get("address") or {}).get("city") or (result.get("address") or {}).get("town", ""),
            "province": (result.get("address") or {}).get("state", ""),
        }


async def reverse_geocode(lat: float, lng: float) -> dict | None:
    await asyncio.sleep(1)

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            f"{NOMINATIM_URL}/reverse",
            params={"lat": lat, "lon": lng, "format": "json", "addressdetails": 1},
            headers={"User-Agent": "SwiftEgypt/1.0"},
        )
        if resp.status_code != 200:
            return None

        data = resp.json()
        if not data:
            return None

        return {
            "latitude": lat,
            "longitude": lng,
            "display_name": data.get("display_name", ""),
            "city": (data.get("address") or {}).get("city") or (data.get("address") or {}).get("town", ""),
            "province": (data.get("address") or {}).get("state", ""),
        }


async def batch_geocode_orders(orders: list) -> list:
    results = []
    for order in orders:
        if order.get("latitude") and order.get("longitude"):
            results.append(order)
            continue
        address = order.get("address", "")
        city = order.get("city")
        geo = await geocode_address(address, city)
        if geo:
            order["latitude"] = geo["latitude"]
            order["longitude"] = geo["longitude"]
        results.append(order)
    return results
