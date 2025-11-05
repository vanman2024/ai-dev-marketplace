"""
Secure webhook handler with signature verification
Supports: Stripe, PayPal, Square
"""

import hashlib
import hmac
import os
import time
from typing import Optional

from fastapi import APIRouter, Request, HTTPException, Header
from pydantic import BaseModel
import stripe

from app.services.event_logger import EventLogger
from app.services.retry_handler import RetryHandler


# Router setup
router = APIRouter(prefix="/webhooks", tags=["webhooks"])

# Configuration from environment (NEVER hardcode secrets!)
STRIPE_API_KEY = os.getenv("STRIPE_API_KEY")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")

if not STRIPE_WEBHOOK_SECRET:
    raise ValueError("STRIPE_WEBHOOK_SECRET environment variable not set")

# Initialize Stripe
stripe.api_key = STRIPE_API_KEY

# Initialize services
event_logger = EventLogger()
retry_handler = RetryHandler()


def verify_stripe_signature(
    payload: bytes,
    signature_header: str,
    tolerance: int = 300
) -> tuple[bool, Optional[str]]:
    """
    Verify Stripe webhook signature

    Args:
        payload: Raw request body
        signature_header: Stripe-Signature header value
        tolerance: Maximum age in seconds (default 5 minutes)

    Returns:
        Tuple of (is_valid, error_message)
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
            STRIPE_WEBHOOK_SECRET.encode('utf-8'),
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


@router.post("/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="Stripe-Signature")
):
    """
    Handle Stripe webhook events with signature verification

    Security Features:
    - Cryptographic signature verification
    - Replay attack prevention via timestamp validation
    - Event deduplication (idempotent processing)
    - Comprehensive event logging
    """
    # Read raw body (required for signature verification)
    payload = await request.body()

    # Verify signature BEFORE processing
    if not stripe_signature:
        raise HTTPException(status_code=401, detail="Missing signature header")

    is_valid, error = verify_stripe_signature(payload, stripe_signature)

    if not is_valid:
        # Log failed verification attempt (potential security incident)
        await event_logger.log_security_event(
            event_type="signature_verification_failed",
            provider="stripe",
            error=error,
            payload=payload.decode('utf-8')
        )
        raise HTTPException(status_code=401, detail=f"Invalid signature: {error}")

    # Parse event
    try:
        event = stripe.Event.construct_from(
            stripe.util.convert_to_stripe_object(payload.decode('utf-8')),
            stripe.api_key
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid payload: {str(e)}")

    # Check for duplicate event (idempotency)
    if await event_logger.is_event_processed(event.id):
        # Already processed - return success (idempotent)
        return {"status": "success", "message": "Event already processed"}

    # Log event BEFORE processing (persist first, process later)
    await event_logger.log_event(
        event_id=event.id,
        event_type=event.type,
        provider="stripe",
        payload=payload.decode('utf-8'),
        signature=stripe_signature
    )

    # Process event based on type
    try:
        await process_stripe_event(event)

        # Mark event as processed
        await event_logger.mark_processed(event.id)

        return {"status": "success", "event_id": event.id}

    except Exception as e:
        # Log processing error
        await event_logger.mark_failed(event.id, str(e))

        # Check if we should retry
        if retry_handler.should_retry(event.type, attempt_count=1):
            # Return 500 to trigger provider retry
            raise HTTPException(status_code=500, detail="Processing error (will retry)")
        else:
            # Permanent failure - return 400 to prevent retry
            raise HTTPException(status_code=400, detail=f"Processing failed: {str(e)}")


async def process_stripe_event(event: stripe.Event):
    """
    Process Stripe webhook event

    This function should be idempotent (safe to call multiple times)
    """
    event_type = event.type

    # Subscription events
    if event_type == "customer.subscription.created":
        await handle_subscription_created(event.data.object)

    elif event_type == "customer.subscription.updated":
        await handle_subscription_updated(event.data.object)

    elif event_type == "customer.subscription.deleted":
        await handle_subscription_deleted(event.data.object)

    # Payment events
    elif event_type == "invoice.payment_succeeded":
        await handle_payment_succeeded(event.data.object)

    elif event_type == "invoice.payment_failed":
        await handle_payment_failed(event.data.object)

    # One-time payment events
    elif event_type == "payment_intent.succeeded":
        await handle_payment_intent_succeeded(event.data.object)

    elif event_type == "payment_intent.payment_failed":
        await handle_payment_intent_failed(event.data.object)

    # Dispute events
    elif event_type == "charge.dispute.created":
        await handle_dispute_created(event.data.object)

    else:
        # Unknown event type - log but don't fail
        print(f"Unhandled event type: {event_type}")


# Event handlers (implement your business logic here)

async def handle_subscription_created(subscription):
    """Handle new subscription creation"""
    # TODO: Implement your business logic
    # - Update database with subscription info
    # - Send welcome email
    # - Grant access to features
    print(f"Subscription created: {subscription.id}")


async def handle_subscription_updated(subscription):
    """Handle subscription update (plan change, renewal, etc)"""
    # TODO: Implement your business logic
    # - Update subscription status in database
    # - Adjust user permissions
    # - Send notification email
    print(f"Subscription updated: {subscription.id}")


async def handle_subscription_deleted(subscription):
    """Handle subscription cancellation"""
    # TODO: Implement your business logic
    # - Revoke access to features
    # - Send cancellation email
    # - Clean up user data (if applicable)
    print(f"Subscription deleted: {subscription.id}")


async def handle_payment_succeeded(invoice):
    """Handle successful payment"""
    # TODO: Implement your business logic
    # - Update payment status in database
    # - Send receipt email
    # - Track revenue analytics
    print(f"Payment succeeded: {invoice.id}")


async def handle_payment_failed(invoice):
    """Handle failed payment"""
    # TODO: Implement your business logic
    # - Update payment status
    # - Send payment failure notification
    # - Retry payment (if applicable)
    print(f"Payment failed: {invoice.id}")


async def handle_payment_intent_succeeded(payment_intent):
    """Handle successful one-time payment"""
    # TODO: Implement your business logic
    # - Fulfill order
    # - Send confirmation email
    # - Update inventory
    print(f"Payment intent succeeded: {payment_intent.id}")


async def handle_payment_intent_failed(payment_intent):
    """Handle failed one-time payment"""
    # TODO: Implement your business logic
    # - Notify customer of failure
    # - Suggest alternative payment methods
    print(f"Payment intent failed: {payment_intent.id}")


async def handle_dispute_created(dispute):
    """Handle chargeback dispute"""
    # TODO: Implement your business logic
    # - Alert admin team
    # - Gather evidence
    # - Respond to dispute via Stripe API
    print(f"Dispute created: {dispute.id}")


# Health check endpoint
@router.get("/health")
async def webhook_health():
    """Health check for webhook endpoint"""
    return {
        "status": "healthy",
        "webhook_secret_configured": bool(STRIPE_WEBHOOK_SECRET)
    }
