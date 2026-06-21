from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AiAlertResponse(BaseModel):
    id: UUID
    shipment_id: UUID | None = None
    alert_type: str
    severity: str
    title: str
    description: str | None = None
    is_read: bool = False
    created_at: datetime | None = None

    model_config = {"from_attributes": True}


class EtaResponse(BaseModel):
    shipment_id: UUID
    tracking_number: str
    estimated_arrival: datetime
    confidence: float
    current_status: str


class RouteOptimizeRequest(BaseModel):
    origin_lat: float
    origin_lng: float
    dest_lat: float
    dest_lng: float
    waypoints: list[dict] | None = None


class RouteResponse(BaseModel):
    optimized_route: list[dict]
    estimated_duration_minutes: float
    estimated_distance_km: float
    fuel_estimate_liters: float


class PricingSuggestionRequest(BaseModel):
    service_type: str
    weight: float | None = None
    volume_weight: float | None = None
    origin_country: str | None = None
    destination_country: str | None = None


class PricingSuggestionResponse(BaseModel):
    suggested_price: float
    min_price: float
    max_price: float
    confidence: float
    factors: list[str]


class DriverAnalysisResponse(BaseModel):
    driver_id: UUID
    driver_name: str
    overall_score: float
    strengths: list[str]
    improvements: list[str]
    efficiency_rating: float
    safety_score: float
    timeliness_score: float
