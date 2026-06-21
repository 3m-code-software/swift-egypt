from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi

from app.config import settings
from app.database import create_tables
from app.ws_manager import manager


if settings.sentry_dsn:
    sentry_sdk.init(dsn=settings.sentry_dsn, traces_sample_rate=1.0)
from app.api.v1 import (
    auth,
    users,
    shipments,
    tracking,
    drivers,
    pricing,
    documents,
    invoices,
    support,
    branches,
    vehicles,
    dashboard,
    ai,
    reports,
    notifications,
    customers,
    sellers,
    batches,
    ws,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    await manager.start_redis()
    yield
    await manager.stop_redis()


app = FastAPI(
    title="Swift Egypt API",
    description="Shipping and logistics management API for Swift Egypt",
    version="1.0.0",
    lifespan=lifespan,
    swagger_ui_parameters={"persistAuthorization": True},
)


def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title="Swift Egypt API",
        version="1.0.0",
        description="Shipping and logistics management API for Swift Egypt",
        routes=app.routes,
    )
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        }
    }
    for path in openapi_schema["paths"].values():
        for method in path.values():
            method.setdefault("security", []).append({"BearerAuth": []})
    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(shipments.router, prefix="/api/v1")
app.include_router(tracking.router, prefix="/api/v1")
app.include_router(drivers.router, prefix="/api/v1")
app.include_router(pricing.router, prefix="/api/v1")
app.include_router(documents.router, prefix="/api/v1")
app.include_router(invoices.router, prefix="/api/v1")
app.include_router(support.router, prefix="/api/v1")
app.include_router(branches.router, prefix="/api/v1")
app.include_router(vehicles.router, prefix="/api/v1")
app.include_router(dashboard.router, prefix="/api/v1")
app.include_router(ai.router, prefix="/api/v1")
app.include_router(reports.router, prefix="/api/v1")
app.include_router(notifications.router, prefix="/api/v1")
app.include_router(customers.router, prefix="/api/v1")
app.include_router(sellers.router, prefix="/api/v1")
app.include_router(batches.router, prefix="/api/v1")
app.include_router(ws.router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "Swift Egypt API", "version": "1.0.0"}
