from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    database_url: str = "sqlite+aiosqlite:///./swift_egypt.db"
    secret_key: str = "super-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 480
    refresh_token_expire_days: int = 7

    redis_url: str = "redis://localhost:6379/0"

    firebase_credentials: str | None = None

    aws_access_key: str | None = None
    aws_secret_key: str | None = None
    aws_bucket_name: str = "swift-egypt-documents"
    aws_region: str = "us-east-1"
    aws_endpoint_url: str | None = None

    ai_service_url: str = "http://localhost:8001"
    ocr_service_url: str = "http://localhost:8002"

    sentry_dsn: str | None = None


settings = Settings()
