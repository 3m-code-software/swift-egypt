from contextlib import asynccontextmanager
from datetime import datetime
from math import asin, cos, radians, sin, sqrt
from random import uniform

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Swift Egypt AI Service", version="1.0.0", lifespan=lifespan)


def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    c = 2 * asin(sqrt(a))
    return R * c


SPEED_KMH = {
    "domestic": 60.0,
    "international_road": 50.0,
    "maritime": 30.0,
}

CUSTOMS_HOURS = 24.0
BASE_DAYS = {
    "domestic": 1,
    "international_road": 5,
    "maritime": 14,
}

PRICE_PER_KG = {
    "domestic": 15.0,
    "international_road": 45.0,
    "maritime": 8.0,
}

PRICE_PER_KM = {
    "domestic": 2.0,
    "international_road": 5.0,
    "maritime": 0.5,
}


class EtaRequest(BaseModel):
    pickup_lat: float
    pickup_lon: float
    delivery_lat: float
    delivery_lon: float
    service_type: str = "domestic"


class EtaResponse(BaseModel):
    estimated_hours: float
    estimated_days: float
    confidence: float
    distance_km: float


class RouteOptimizeRequest(BaseModel):
    waypoints: list[dict]


class RouteResponse(BaseModel):
    ordered_waypoints: list[dict]
    total_distance_km: float
    estimated_minutes: float


class PricingRequest(BaseModel):
    distance_km: float
    weight_kg: float
    service_type: str = "domestic"


class PricingResponse(BaseModel):
    base_price: float
    weight_charge: float
    distance_charge: float
    total_price: float
    currency: str = "EGP"


class DriverScoreRequest(BaseModel):
    on_time_rate: float = 0.0
    rating: float = 0.0
    total_deliveries: int = 0
    accidents: int = 0
    complaints: int = 0


class DriverScoreResponse(BaseModel):
    score: float
    rating: float
    on_time_rate: float
    level: str


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "Swift Egypt AI Service"}


@app.post("/eta", response_model=EtaResponse)
async def predict_eta(req: EtaRequest):
    distance = haversine(req.pickup_lat, req.pickup_lon, req.delivery_lat, req.delivery_lon)
    speed = SPEED_KMH.get(req.service_type, 50.0)
    driving_hours = distance / speed
    base_days = BASE_DAYS.get(req.service_type, 3)
    total_hours = driving_hours + base_days * 24 + CUSTOMS_HOURS

    return EtaResponse(
        estimated_hours=round(total_hours, 1),
        estimated_days=round(total_hours / 24, 1),
        confidence=round(uniform(0.75, 0.95), 2),
        distance_km=round(distance, 1),
    )


@app.post("/route-optimize", response_model=RouteResponse)
async def optimize_route(req: RouteOptimizeRequest):
    points = req.waypoints
    if len(points) < 2:
        raise HTTPException(400, "Need at least 2 waypoints")

    ordered = [points[0]]
    remaining = list(points[1:])
    total_distance = 0.0

    while remaining:
        last = ordered[-1]
        nearest_idx = 0
        nearest_dist = float("inf")
        for i, pt in enumerate(remaining):
            d = haversine(
                last.get("lat", 0), last.get("lon", 0),
                pt.get("lat", 0), pt.get("lon", 0),
            )
            if d < nearest_dist:
                nearest_dist = d
                nearest_idx = i
        total_distance += nearest_dist
        ordered.append(remaining.pop(nearest_idx))

    return RouteResponse(
        ordered_waypoints=ordered,
        total_distance_km=round(total_distance, 1),
        estimated_minutes=round(total_distance / 50 * 60, 0),
    )


@app.post("/pricing", response_model=PricingResponse)
async def pricing_suggestion(req: PricingRequest):
    weight_charge = req.weight_kg * PRICE_PER_KG.get(req.service_type, 15.0)
    distance_charge = req.distance_km * PRICE_PER_KM.get(req.service_type, 2.0)
    base_price = weight_charge + distance_charge

    return PricingResponse(
        base_price=round(base_price, 2),
        weight_charge=round(weight_charge, 2),
        distance_charge=round(distance_charge, 2),
        total_price=round(base_price * 1.14, 2),
    )


@app.post("/driver-score", response_model=DriverScoreResponse)
async def driver_score(req: DriverScoreRequest):
    score = (
        min(req.on_time_rate, 1.0) * 40 +
        min(req.rating / 5.0, 1.0) * 30 +
        min(req.total_deliveries / 1000, 1.0) * 20 -
        req.accidents * 5 -
        req.complaints * 3
    )
    score = max(0, min(100, round(score, 1)))

    if score >= 80:
        level = "excellent"
    elif score >= 60:
        level = "good"
    elif score >= 40:
        level = "average"
    else:
        level = "needs_improvement"

    return DriverScoreResponse(
        score=score,
        rating=round(req.rating, 1),
        on_time_rate=round(req.on_time_rate, 2),
        level=level,
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
