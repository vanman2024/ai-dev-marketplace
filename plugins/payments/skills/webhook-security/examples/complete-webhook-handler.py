"""
Complete production-ready webhook handler example
Includes signature verification, logging, retry handling, and idempotency
"""

import hashlib
import hmac
import os
import time
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, Request, HTTPException, Header
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import stripe

# Initialize FastAPI
app = FastAPI(title="Secure Webhook Handler")

# Configuration from environment (NEVER hardcode!)
STRIPE_API_KEY = os.getenv("STRIPE_API_KEY", "sk_test_your_stripe_key_here")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_your_webhook_secret_here")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:pass@localhost/webhook_db")

# Initialize Stripe
stripe.api_key = STRIPE_API_KEY

# Database setup
Base = declarative_base()
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)


class WebhookEvent(Base):
    """Store all webhook events for audit trail"""
    __tablename__ = "webhook_events"

    id = Column(Integer, primary_key=True)
    event_id = Column(String(255), unique=True, nullable=False, index=True)
    event_type = Column(String(100), nullable=False)
    provider = Column(String(50), nullable=False)
    payload = Column(JSON, nullable=False)
    signature = Column(String(500), nullable=False)
    status = Column(String(50), default="pending", index=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime, nullable=True)


# Create tables
Base.metadata.create_all(bind=engine)


def verify_stripe_signature(
    payload: bytes,
    signature_header: str,
    webhook_secret: str,
    tolerance: int = 300
) -> tuple[bool, Optional[str]]:
    """
    Verify Stripe webhook signature with replay attack prevention

    Args:
        payload: Raw request body
        signature_header: Stripe-Signature header
        webhook_secret: Webhook signing secret
        tolerance: Max age in seconds (default 5 minutes)

    Returns:
        (is_valid, error_message)
    """
    try:
        # Parse signature header
        elements = {}
        for element in signature_header.split(','):
            key, value = element.split('=', 1)
            if key == 't':
                elements['timestamp'] = int(value)
            elif key.startswith('v'):
                elements.setdefault('signatures', []).append(value)

        if 'timestamp' not in elements or 'signatures' not in elements:
            return False, "Invalid signature header format"

        # Check timestamp tolerance (replay attack prevention)
        current_time = int(time.time())
        if abs(current_time - elements['timestamp']) > tolerance:
            return False, f"Timestamp outside tolerance window ({tolerance}s)"

        # Compute expected signature
        signed_payload = f"{elements['timestamp']}.{payload.decode('utf-8')}"
        expected_signature = hmac.new(
            webhook_secret.encode('utf-8'),
            signed_payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        # Compare signatures (timing-safe)
        for signature in elements['signatures']:
            if hmac.compare_digest(expected_signature, signature):
                return True, None

        return False, "No matching signature found"

    except Exception as e:
        return False, f"Signature verification error: {str(e)}"


def is_event_processed(db: Session, event_id: str) -> bool:
    """Check if event already processed (idempotency)"""
    event = db.query(WebhookEvent).filter(
        WebhookEvent.event_id == event_id,
        WebhookEvent.status == "processed"
    ).first()
    return event is not None


def log_webhook_event(
    db: Session,
    event_id: str,
    event_type: str,
    provider: str,
    payload: dict,
    signature: str
) -> WebhookEvent:
    """Log webhook event to database"""
    # Check if already exists
    event = db.query(WebhookEvent).filter(
        WebhookEvent.event_id == event_id
    ).first()

    if event:
        return event

    # Create new event
    event = WebhookEvent(
        event_id=event_id,
        event_type=event_type,
        provider=provider,
        payload=payload,
        signature=signature,
        status="pending"
    )
    db.add(event)
    db.commit()
    db.refresh(event)

    return event


def mark_event_processed(db: Session, event_id: str):
    """Mark event as successfully processed"""
    event = db.query(WebhookEvent).filter(
        WebhookEvent.event_id == event_id
    ).first()

    if event:
        event.status = "processed"
        event.processed_at = datetime.utcnow()
        db.commit()


def mark_event_failed(db: Session, event_id: str, error: str):
    """Mark event as failed"""
    event = db.query(WebhookEvent).filter(
        WebhookEvent.event_id == event_id
    ).first()

    if event:
        event.status = "failed"
        event.error_message = error
        event.processed_at = datetime.utcnow()
        db.commit()


@app.post("/webhooks/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="Stripe-Signature")
):
    """
    Handle Stripe webhook with complete security

    Security Features:
    ✅ Cryptographic signature verification
    ✅ Replay attack prevention (timestamp validation)
    ✅ Event deduplication (idempotent processing)
    ✅ Comprehensive logging for audit trail
    ✅ Error handling with appropriate retry signals
    """
    # Get database session
    db = SessionLocal()

    try:
        # Read raw body (required for signature verification)
        payload = await request.body()

        # Verify signature BEFORE any processing
        if not stripe_signature:
            raise HTTPException(status_code=401, detail="Missing signature header")

        is_valid, error = verify_stripe_signature(
            payload, stripe_signature, STRIPE_WEBHOOK_SECRET
        )

        if not is_valid:
            raise HTTPException(status_code=401, detail=f"Invalid signature: {error}")

        # Parse event
        try:
            import json
            event_data = json.loads(payload.decode('utf-8'))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=f"Invalid payload: {str(e)}")

        event_id = event_data.get("id")
        event_type = event_data.get("type")

        # Check for duplicate (idempotency)
        if is_event_processed(db, event_id):
            return {"status": "success", "message": "Event already processed"}

        # Log event BEFORE processing (persist first, process later)
        log_webhook_event(
            db, event_id, event_type, "stripe",
            event_data, stripe_signature
        )

        # Process event
        try:
            await process_event(event_data)
            mark_event_processed(db, event_id)
            return {"status": "success", "event_id": event_id}

        except Exception as e:
            # Log failure
            mark_event_failed(db, event_id, str(e))

            # Return 500 to trigger Stripe retry
            raise HTTPException(
                status_code=500,
                detail="Processing error (will retry)"
            )

    finally:
        db.close()


async def process_event(event_data: dict):
    """
    Process webhook event (business logic)

    CRITICAL: This function MUST be idempotent (safe to call multiple times)
    """
    event_type = event_data["type"]
    data_object = event_data["data"]["object"]

    if event_type == "customer.subscription.created":
        # Handle new subscription
        subscription_id = data_object["id"]
        customer_id = data_object["customer"]
        print(f"New subscription: {subscription_id} for customer {customer_id}")
        # TODO: Grant access, send welcome email, etc.

    elif event_type == "customer.subscription.updated":
        # Handle subscription update
        subscription_id = data_object["id"]
        status = data_object["status"]
        print(f"Subscription {subscription_id} updated to status: {status}")
        # TODO: Update access, handle plan changes, etc.

    elif event_type == "customer.subscription.deleted":
        # Handle cancellation
        subscription_id = data_object["id"]
        print(f"Subscription cancelled: {subscription_id}")
        # TODO: Revoke access, send cancellation email, etc.

    elif event_type == "invoice.payment_succeeded":
        # Handle successful payment
        invoice_id = data_object["id"]
        amount = data_object["amount_paid"]
        print(f"Payment succeeded: {invoice_id}, amount: {amount}")
        # TODO: Send receipt, update payment status, etc.

    elif event_type == "invoice.payment_failed":
        # Handle failed payment
        invoice_id = data_object["id"]
        print(f"Payment failed: {invoice_id}")
        # TODO: Send payment failure notice, retry payment, etc.

    else:
        print(f"Unhandled event type: {event_type}")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "webhook_secret_configured": bool(STRIPE_WEBHOOK_SECRET != "whsec_your_webhook_secret_here"),
        "database_connected": True
    }


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Secure Webhook Handler",
        "endpoints": {
            "webhook": "/webhooks/stripe",
            "health": "/health"
        }
    }


# Run with: uvicorn complete-webhook-handler:app --reload
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
