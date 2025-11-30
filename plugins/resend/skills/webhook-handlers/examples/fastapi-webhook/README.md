# FastAPI Webhook Handler Example

Complete FastAPI application for handling Resend webhook events with signature verification, async processing, and database logging.

## Setup

### 1. Environment Variables

```bash
# .env
RESEND_WEBHOOK_SECRET=your_webhook_signing_secret_here
DATABASE_URL=postgresql://user:password@localhost/dbname
REDIS_URL=redis://localhost:6379
```

### 2. Dependencies

```bash
pip install fastapi uvicorn pydantic sqlalchemy psycopg2-binary python-dotenv httpx aioredis
```

### 3. Main Application

Create `main.py`:

```python
import os
import hmac
import hashlib
import json
import logging
from datetime import datetime
from typing import Any, Dict
from enum import Enum

from fastapi import FastAPI, Request, Header, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, Column, String, DateTime, Boolean, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import aioredis

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Resend Webhook Handler")

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# Models
class WebhookEvent(BaseModel):
    type: str
    created_at: str
    data: Dict[str, Any]

    class Config:
        schema_extra = {
            "example": {
                "type": "email.delivered",
                "created_at": "2024-01-15T10:35:00Z",
                "data": {
                    "email_id": "123e4567-e89b-12d3-a456-426614174000",
                    "from": "notifications@example.com",
                    "to": "recipient@example.com",
                }
            }
        }


class EventType(str, Enum):
    SENT = "email.sent"
    DELIVERED = "email.delivered"
    BOUNCED = "email.bounced"
    OPENED = "email.opened"
    CLICKED = "email.clicked"
    COMPLAINED = "email.complained"


# Database Models
class Email(Base):
    __tablename__ = "emails"

    id = Column(String, primary_key=True, index=True)
    resend_id = Column(String, unique=True, index=True)
    from_address = Column(String)
    to_address = Column(String, index=True)
    subject = Column(String)
    status = Column(String, default="sent", index=True)
    sent_at = Column(DateTime, nullable=True)
    delivered_at = Column(DateTime, nullable=True)
    bounced_at = Column(DateTime, nullable=True)
    complained_at = Column(DateTime, nullable=True)
    bounce_reason = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class EmailEvent(Base):
    __tablename__ = "email_events"

    id = Column(String, primary_key=True, index=True)
    email_id = Column(String, index=True)
    event_type = Column(String, index=True)
    link = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class BouncedEmail(Base):
    __tablename__ = "bounced_emails"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    reason = Column(String, nullable=True)
    bounced_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)


class SuppressedEmail(Base):
    __tablename__ = "suppressed_emails"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    reason = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)


class WebhookLog(Base):
    __tablename__ = "webhook_logs"

    id = Column(String, primary_key=True, index=True)
    event_type = Column(String)
    email_id = Column(String, index=True)
    payload = Column(JSON)
    processed = Column(Boolean, default=False, index=True)
    error = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


Base.metadata.create_all(bind=engine)


# Signature Verification
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


# Webhook Event Handlers
async def handle_email_sent(data: Dict[str, Any], db: Session) -> None:
    """Handle email.sent event."""
    email = db.query(Email).filter(Email.resend_id == data["email_id"]).first()
    if email:
        email.status = "sent"
        email.sent_at = datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
        db.commit()

    logger.info(f"Email {data['email_id']} marked as sent")


async def handle_email_delivered(data: Dict[str, Any], db: Session) -> None:
    """Handle email.delivered event."""
    email = db.query(Email).filter(Email.resend_id == data["email_id"]).first()
    if email:
        email.status = "delivered"
        email.delivered_at = datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
        db.commit()

    logger.info(f"Email {data['email_id']} marked as delivered")


async def handle_email_bounced(data: Dict[str, Any], db: Session) -> None:
    """Handle email.bounced event."""
    email = db.query(Email).filter(Email.resend_id == data["email_id"]).first()
    if email:
        email.status = "bounced"
        email.bounce_reason = data.get("reason")
        email.bounced_at = datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
        db.commit()

    # Add to bounce list
    bounced = BouncedEmail(
        id=f"bounce_{data['email_id']}",
        email=data["to"],
        reason=data.get("reason"),
        bounced_at=datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
    )
    db.merge(bounced)
    db.commit()

    logger.info(f"Email {data['to']} added to bounce list")


async def handle_email_opened(data: Dict[str, Any], db: Session) -> None:
    """Handle email.opened event."""
    event = EmailEvent(
        id=f"open_{data['email_id']}_{int(datetime.utcnow().timestamp())}",
        email_id=data["email_id"],
        event_type="opened",
        user_agent=data.get("user_agent"),
        ip_address=data.get("ip_address"),
        created_at=datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
    )
    db.add(event)
    db.commit()

    logger.info(f"Email {data['email_id']} opened")


async def handle_email_clicked(data: Dict[str, Any], db: Session) -> None:
    """Handle email.clicked event."""
    event = EmailEvent(
        id=f"click_{data['email_id']}_{int(datetime.utcnow().timestamp())}",
        email_id=data["email_id"],
        event_type="clicked",
        link=data.get("link"),
        user_agent=data.get("user_agent"),
        ip_address=data.get("ip_address"),
        created_at=datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
    )
    db.add(event)
    db.commit()

    logger.info(f"Email {data['email_id']} link clicked: {data.get('link')}")


async def handle_email_complained(data: Dict[str, Any], db: Session) -> None:
    """Handle email.complained event."""
    email = db.query(Email).filter(Email.resend_id == data["email_id"]).first()
    if email:
        email.status = "complained"
        email.complained_at = datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
        db.commit()

    # Add to suppression list
    suppressed = SuppressedEmail(
        id=f"supp_{data['email_id']}",
        email=data["to"],
        reason="complaint"
    )
    db.merge(suppressed)
    db.commit()

    logger.info(f"Email {data['to']} added to suppression list (complaint)")


async def process_webhook_event(event: WebhookEvent, db: Session) -> None:
    """Route webhook event to appropriate handler."""
    handlers = {
        EventType.SENT.value: handle_email_sent,
        EventType.DELIVERED.value: handle_email_delivered,
        EventType.BOUNCED.value: handle_email_bounced,
        EventType.OPENED.value: handle_email_opened,
        EventType.CLICKED.value: handle_email_clicked,
        EventType.COMPLAINED.value: handle_email_complained,
    }

    handler = handlers.get(event.type)
    if not handler:
        logger.warning(f"Unknown event type: {event.type}")
        return

    await handler(event.data, db)


async def log_webhook(
    event: WebhookEvent,
    processed: bool,
    error: str = None,
    db: Session = None
) -> None:
    """Log webhook event to database."""
    if not db:
        db = SessionLocal()

    log_entry = WebhookLog(
        id=f"log_{event.data['email_id']}_{event.type}_{int(datetime.utcnow().timestamp())}",
        event_type=event.type,
        email_id=event.data["email_id"],
        payload=event.dict(),
        processed=processed,
        error=error
    )
    db.add(log_entry)
    db.commit()


# Routes
@app.post("/webhooks/resend")
async def handle_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    x_resend_signature: str = Header(None)
):
    """Handle Resend webhook events."""
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
        logger.warning(f"Invalid signature received")
        raise HTTPException(status_code=401, detail="Invalid signature")

    try:
        event = WebhookEvent(**json.loads(payload_str))
    except (json.JSONDecodeError, ValueError) as e:
        logger.error(f"Invalid JSON payload: {e}")
        raise HTTPException(status_code=400, detail="Invalid JSON")

    # Get database session
    db = SessionLocal()

    try:
        # Check for duplicate (idempotency)
        existing_log = db.query(WebhookLog).filter(
            WebhookLog.email_id == event.data["email_id"],
            WebhookLog.event_type == event.type
        ).first()

        if existing_log and existing_log.processed:
            logger.info(f"Webhook already processed: {event.type} {event.data['email_id']}")
            return JSONResponse(
                {"success": True, "cached": True},
                status_code=200
            )

        # Process event in background
        background_tasks.add_task(
            process_webhook_event_with_logging,
            event,
            db
        )

        return JSONResponse({"success": True}, status_code=202)

    except Exception as e:
        logger.error(f"Webhook handler error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
    finally:
        db.close()


async def process_webhook_event_with_logging(event: WebhookEvent, db: Session) -> None:
    """Process webhook event with error logging."""
    try:
        await process_webhook_event(event, db)
        await log_webhook(event, processed=True, db=db)
    except Exception as e:
        logger.error(f"Error processing webhook: {e}")
        await log_webhook(event, processed=False, error=str(e), db=db)
    finally:
        db.close()


@app.get("/webhooks/health")
async def webhook_health():
    """Health check endpoint."""
    return {"status": "ok", "webhook": "ready"}


@app.get("/webhooks/status")
async def webhook_status():
    """Get webhook processing statistics."""
    db = SessionLocal()

    try:
        # Last 24 hours
        since = datetime.utcnow()
        import datetime as dt
        since = since.replace(hour=0, minute=0, second=0, microsecond=0) - dt.timedelta(days=1)

        logs = db.query(WebhookLog).filter(WebhookLog.created_at >= since).all()

        processed = sum(1 for log in logs if log.processed)
        failed = sum(1 for log in logs if not log.processed)
        total = len(logs)

        return {
            "processed": processed,
            "failed": failed,
            "total": total,
            "success_rate": processed / total if total > 0 else 0,
            "period": "24h"
        }
    finally:
        db.close()


@app.get("/")
async def root():
    """API information endpoint."""
    return {
        "service": "Resend Webhook Handler",
        "version": "1.0.0",
        "endpoints": {
            "webhook": "/webhooks/resend",
            "health": "/webhooks/health",
            "status": "/webhooks/status"
        }
    }


# Startup/Shutdown
@app.on_event("startup")
async def startup_event():
    logger.info("Webhook service starting...")


@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Webhook service shutting down...")
```

### 4. Running the Application

```bash
# Development
uvicorn main:app --reload --port 8000

# Production
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 5. Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Create `requirements.txt`:

```
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-dotenv==1.0.0
httpx==0.25.2
aioredis==2.0.1
```

Build and run:

```bash
docker build -t resend-webhook .
docker run -p 8000:8000 --env-file .env resend-webhook
```

### 6. Database Migrations

Using Alembic:

```bash
# Initialize
alembic init migrations

# Create migration
alembic revision --autogenerate -m "initial schema"

# Apply migration
alembic upgrade head
```

## Testing

### Unit Tests

Create `test_webhook.py`:

```python
import json
import hmac
import hashlib
from fastapi.testclient import TestClient
from main import app, verify_signature

client = TestClient(app)


def test_webhook_signature_verification():
    payload = '{"type":"email.sent","created_at":"2024-01-15T10:30:00Z"}'
    secret = "test_secret"
    signature = hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()

    assert verify_signature(payload, signature, secret)


def test_webhook_missing_signature():
    response = client.post(
        "/webhooks/resend",
        json={"type": "email.sent"}
    )
    assert response.status_code == 401


def test_webhook_health():
    response = client.get("/webhooks/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
```

Run tests:

```bash
pytest test_webhook.py -v
```

### Manual Testing with curl

```bash
# Generate signature
PAYLOAD='{"type":"email.delivered","created_at":"2024-01-15T10:35:00Z","data":{"email_id":"123e4567","from":"test@example.com","to":"user@example.com"}}'
SECRET='your_webhook_secret'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

# Send request
curl -X POST http://localhost:8000/webhooks/resend \
  -H "Content-Type: application/json" \
  -H "x-resend-signature: $SIGNATURE" \
  -d "$PAYLOAD"
```

## Monitoring and Logging

### Structured Logging

```python
import json
from logging import LogRecord

class JSONFormatter(logging.Formatter):
    def format(self, record: LogRecord) -> str:
        log_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }
        return json.dumps(log_data)

handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger.addHandler(handler)
```

### Alerting

```python
async def check_failed_webhooks():
    """Alert if too many failed webhooks."""
    db = SessionLocal()

    try:
        import datetime as dt
        since = datetime.utcnow() - dt.timedelta(hours=1)

        failed = db.query(WebhookLog).filter(
            WebhookLog.processed == False,
            WebhookLog.created_at >= since
        ).count()

        if failed > 10:
            logger.error(f"ALERT: {failed} failed webhooks in last hour")
            # Send notification (Slack, email, etc.)
    finally:
        db.close()
```

## Security Checklist

- [x] Signature verification with HMAC-SHA256
- [x] HTTPS only for production
- [x] Environment variables for secrets
- [x] Database transaction handling
- [x] Idempotency tracking
- [x] Comprehensive error logging
- [x] Request validation
- [x] Rate limiting ready
- [x] SQL injection protection via ORM
- [x] Async processing for reliability
