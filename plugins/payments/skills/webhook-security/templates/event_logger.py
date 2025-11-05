"""
Webhook event logger with database persistence
Provides audit trail and duplicate detection
"""

import os
from datetime import datetime
from typing import Optional

from sqlalchemy import Column, Integer, String, Text, DateTime, JSON, UniqueConstraint
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.future import select


# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://localhost/webhook_db")

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

Base = declarative_base()


class WebhookEvent(Base):
    """Database model for webhook events"""
    __tablename__ = "webhook_events"

    id = Column(Integer, primary_key=True, autoincrement=True)
    event_id = Column(String(255), unique=True, nullable=False, index=True)
    event_type = Column(String(100), nullable=False)
    provider = Column(String(50), nullable=False)
    payload = Column(JSON, nullable=False)
    signature = Column(String(500), nullable=False)
    status = Column(String(50), default="pending", index=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime, nullable=True)

    __table_args__ = (
        UniqueConstraint('event_id', name='uq_event_id'),
    )


class SecurityEvent(Base):
    """Database model for security events (failed verifications, etc)"""
    __tablename__ = "security_events"

    id = Column(Integer, primary_key=True, autoincrement=True)
    event_type = Column(String(100), nullable=False)
    provider = Column(String(50), nullable=False)
    error = Column(Text, nullable=False)
    payload = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)


class EventLogger:
    """
    Event logger for webhook events

    Features:
    - Persistent storage of all webhook events
    - Duplicate detection (idempotency)
    - Processing status tracking
    - Security event logging
    - Audit trail for compliance
    """

    async def log_event(
        self,
        event_id: str,
        event_type: str,
        provider: str,
        payload: str,
        signature: str
    ) -> WebhookEvent:
        """
        Log webhook event to database

        Args:
            event_id: Unique event identifier from provider
            event_type: Event type (e.g., customer.subscription.created)
            provider: Payment provider (stripe, paypal, square)
            payload: Raw webhook payload (JSON string)
            signature: Signature header value

        Returns:
            Created WebhookEvent instance
        """
        async with AsyncSessionLocal() as session:
            # Check if event already exists (idempotency)
            stmt = select(WebhookEvent).where(WebhookEvent.event_id == event_id)
            result = await session.execute(stmt)
            existing_event = result.scalar_one_or_none()

            if existing_event:
                return existing_event

            # Create new event
            event = WebhookEvent(
                event_id=event_id,
                event_type=event_type,
                provider=provider,
                payload=payload,
                signature=signature,
                status="pending"
            )

            session.add(event)
            await session.commit()
            await session.refresh(event)

            return event

    async def is_event_processed(self, event_id: str) -> bool:
        """
        Check if event has already been processed

        Args:
            event_id: Event identifier to check

        Returns:
            True if event exists and status is 'processed'
        """
        async with AsyncSessionLocal() as session:
            stmt = select(WebhookEvent).where(
                WebhookEvent.event_id == event_id,
                WebhookEvent.status == "processed"
            )
            result = await session.execute(stmt)
            event = result.scalar_one_or_none()

            return event is not None

    async def mark_processed(self, event_id: str):
        """
        Mark event as successfully processed

        Args:
            event_id: Event identifier to update
        """
        async with AsyncSessionLocal() as session:
            stmt = select(WebhookEvent).where(WebhookEvent.event_id == event_id)
            result = await session.execute(stmt)
            event = result.scalar_one_or_none()

            if event:
                event.status = "processed"
                event.processed_at = datetime.utcnow()
                await session.commit()

    async def mark_failed(self, event_id: str, error_message: str):
        """
        Mark event as failed with error message

        Args:
            event_id: Event identifier to update
            error_message: Error description
        """
        async with AsyncSessionLocal() as session:
            stmt = select(WebhookEvent).where(WebhookEvent.event_id == event_id)
            result = await session.execute(stmt)
            event = result.scalar_one_or_none()

            if event:
                event.status = "failed"
                event.error_message = error_message
                event.processed_at = datetime.utcnow()
                await session.commit()

    async def log_security_event(
        self,
        event_type: str,
        provider: str,
        error: str,
        payload: Optional[str] = None,
        ip_address: Optional[str] = None
    ):
        """
        Log security event (failed signature verification, etc)

        Args:
            event_type: Type of security event
            provider: Payment provider
            error: Error description
            payload: Raw payload (optional)
            ip_address: Source IP address (optional)
        """
        async with AsyncSessionLocal() as session:
            security_event = SecurityEvent(
                event_type=event_type,
                provider=provider,
                error=error,
                payload=payload,
                ip_address=ip_address
            )

            session.add(security_event)
            await session.commit()

    async def get_event(self, event_id: str) -> Optional[WebhookEvent]:
        """
        Get event by ID

        Args:
            event_id: Event identifier

        Returns:
            WebhookEvent or None if not found
        """
        async with AsyncSessionLocal() as session:
            stmt = select(WebhookEvent).where(WebhookEvent.event_id == event_id)
            result = await session.execute(stmt)
            return result.scalar_one_or_none()

    async def get_pending_events(self, limit: int = 100) -> list[WebhookEvent]:
        """
        Get pending events for retry processing

        Args:
            limit: Maximum number of events to return

        Returns:
            List of pending WebhookEvent instances
        """
        async with AsyncSessionLocal() as session:
            stmt = (
                select(WebhookEvent)
                .where(WebhookEvent.status == "pending")
                .order_by(WebhookEvent.created_at)
                .limit(limit)
            )
            result = await session.execute(stmt)
            return list(result.scalars().all())

    async def get_failed_events(
        self,
        limit: int = 100,
        provider: Optional[str] = None
    ) -> list[WebhookEvent]:
        """
        Get failed events for investigation

        Args:
            limit: Maximum number of events to return
            provider: Filter by provider (optional)

        Returns:
            List of failed WebhookEvent instances
        """
        async with AsyncSessionLocal() as session:
            stmt = select(WebhookEvent).where(WebhookEvent.status == "failed")

            if provider:
                stmt = stmt.where(WebhookEvent.provider == provider)

            stmt = stmt.order_by(WebhookEvent.created_at.desc()).limit(limit)

            result = await session.execute(stmt)
            return list(result.scalars().all())

    async def get_security_events(
        self,
        limit: int = 100,
        provider: Optional[str] = None
    ) -> list[SecurityEvent]:
        """
        Get recent security events

        Args:
            limit: Maximum number of events to return
            provider: Filter by provider (optional)

        Returns:
            List of SecurityEvent instances
        """
        async with AsyncSessionLocal() as session:
            stmt = select(SecurityEvent)

            if provider:
                stmt = stmt.where(SecurityEvent.provider == provider)

            stmt = stmt.order_by(SecurityEvent.created_at.desc()).limit(limit)

            result = await session.execute(stmt)
            return list(result.scalars().all())


# Database initialization
async def init_db():
    """Create database tables"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


# Usage example
if __name__ == "__main__":
    import asyncio

    async def main():
        # Initialize database
        await init_db()
        print("Database tables created successfully")

    asyncio.run(main())
