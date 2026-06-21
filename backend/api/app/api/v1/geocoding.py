from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_active_user
from app.models.user import User
from app.services.geocoding import batch_geocode_orders, geocode_address, reverse_geocode

router = APIRouter(prefix="/geocode", tags=["Geocoding"])


@router.get("/search")
async def search_address(
    q: str = Query(..., min_length=3),
    city: str | None = Query(None),
    current_user: User = Depends(get_current_active_user),
):
    result = await geocode_address(q, city)
    if not result:
        return {"result": None, "message": "Address not found"}
    return {"result": result}


@router.get("/reverse")
async def reverse_geocode_endpoint(
    lat: float = Query(...),
    lng: float = Query(...),
    current_user: User = Depends(get_current_active_user),
):
    result = await reverse_geocode(lat, lng)
    if not result:
        return {"result": None, "message": "Location not found"}
    return {"result": result}


@router.post("/batch")
async def geocode_batch_orders(
    orders: list[dict],
    current_user: User = Depends(get_current_active_user),
):
    enriched = await batch_geocode_orders(orders)
    return {"results": enriched}
