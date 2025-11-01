"""
Application Configuration

Pydantic Settings-based configuration with environment variable support.
"""

from typing import Any
from pydantic import field_validator, AnyHttpUrl
from pydantic_settings import BaseSettings, SettingsConfigDict
import json


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    PROJECT_NAME: str = "FastAPI App"
    VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "development"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Security
    SECRET_KEY: str
    ALLOWED_ORIGINS: list[str] | str = ["*"]
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Database (optional)
    DATABASE_URL: str | None = None
    DB_ECHO_LOG: bool = False

    # Logging
    LOG_LEVEL: str = "INFO"

    # CORS validation
    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: Any) -> list[str] | str:
        """Parse CORS origins from JSON string or comma-separated values."""
        if isinstance(v, str):
            try:
                return json.loads(v)
            except json.JSONDecodeError:
                return [origin.strip() for origin in v.split(",")]
        return v

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore",
    )


# Global settings instance
settings = Settings()


def get_settings() -> Settings:
    """Dependency for retrieving settings."""
    return settings
