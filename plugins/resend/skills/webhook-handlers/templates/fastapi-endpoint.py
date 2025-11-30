import hmac
import hashlib
import json
import logging
from typing import Any, Dict
from datetime import datetime

from fastapi import FastAPI, Request, Header, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel

logger = logging.getLogger(__name__)
app = FastAPI()


class WebhookEvent(BaseModel):
    type: str
    created_at: str
    data: Dict[str, Any]


def verify_signature(
    payload: str,
    signature: str,
    signing_secret: str
) -> bool:
    """Verify Resend webhook signature using HMAC-SHA256."""
    expected_signature = hmac.new(
        signing_secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(signature, expected_signature)


async def handle_webhook_event(event: WebhookEvent) -> None:
    """Process webhook event based on type."""
    event_type = event.type
    data = event.data

    if event_type == "email.sent":
        logger.info(f"Email sent: {data['email_id']}")
        # Handle sent event

    elif event_type == "email.delivered":
        logger.info(f"Email delivered: {data['email_id']}")
        # Handle delivered event

    elif event_type == "email.bounced":
        logger.info(f"Email bounced: {data['email_id']} - {data.get('reason')}")
        # Handle bounce event

    elif event_type == "email.opened":
        logger.info(f"Email opened: {data['email_id']}")
        # Handle open event

    elif event_type == "email.clicked":
        logger.info(f"Email clicked: {data['email_id']} - {data.get('link')}")
        # Handle click event

    elif event_type == "email.complained":
        logger.info(f"Email complained: {data['email_id']}")
        # Handle complaint event

    else:
        logger.warning(f"Unknown event type: {event_type}")


@app.post("/webhooks/resend")
async def handle_resend_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    x_resend_signature: str = Header(None)
):
    """Handle Resend webhook events."""
    import os

    if not x_resend_signature:
        raise HTTPException(status_code=401, detail="Missing signature header")

    # Get and verify payload
    payload = await request.body()
    payload_str = payload.decode('utf-8')

    signing_secret = os.getenv("RESEND_WEBHOOK_SECRET")
    if not signing_secret:
        logger.error("RESEND_WEBHOOK_SECRET not configured")
        raise HTTPException(status_code=500, detail="Server configuration error")

    if not verify_signature(payload_str, x_resend_signature, signing_secret):
        logger.warning("Invalid signature received")
        raise HTTPException(status_code=401, detail="Invalid signature")

    try:
        event = WebhookEvent(**json.loads(payload_str))
    except (json.JSONDecodeError, ValueError) as e:
        logger.error(f"Invalid JSON payload: {e}")
        raise HTTPException(status_code=400, detail="Invalid JSON")

    # Process event in background
    background_tasks.add_task(handle_webhook_event, event)

    return JSONResponse({"success": True}, status_code=202)


@app.get("/webhooks/health")
async def webhook_health():
    """Health check endpoint."""
    return {"status": "ok", "webhook": "ready"}


@app.get("/")
async def root():
    """API information endpoint."""
    return {
        "service": "Resend Webhook Handler",
        "version": "1.0.0",
        "endpoints": {
            "webhook": "/webhooks/resend",
            "health": "/webhooks/health",
        }
    }
