from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class MonthlyReportItem(BaseModel):
    month: str
    shipments: int
    revenue: float


class StatusDistributionItem(BaseModel):
    name: str
    value: int
    color: str


class DriverPerformanceItem(BaseModel):
    name: str
    rating: float
    trips: int


class CustomerReportItem(BaseModel):
    customer_name: str
    company_name: str | None = None
    total_shipments: int
    total_revenue: float
    avg_shipment_value: float


class ReportResponse(BaseModel):
    monthly: list[MonthlyReportItem]
    status_distribution: list[StatusDistributionItem]
    driver_performance: list[DriverPerformanceItem]
    customers: list[CustomerReportItem]
