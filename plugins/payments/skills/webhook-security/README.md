# Webhook Security Skill

Comprehensive webhook security patterns for payment integrations with signature verification, event logging, replay attack prevention, and testing tools.

## Overview

This skill provides production-ready webhook security implementations for payment providers (Stripe, PayPal, Square). It covers all aspects of secure webhook handling from cryptographic signature verification to idempotent event processing.

## Features

- **Signature Verification**: Cryptographic validation of webhook signatures
- **Replay Attack Prevention**: Timestamp validation to prevent event replay
- **Event Logging**: Complete audit trail with database persistence
- **Idempotency**: Safe duplicate event handling
- **Retry Logic**: Configurable retry strategies per event type
- **Local Testing**: Stripe CLI integration for development
- **Multi-Provider Support**: Stripe, PayPal, Square patterns

## Structure

```
webhook-security/
├── SKILL.md                         # Main skill documentation
├── README.md                        # This file
├── scripts/                         # Setup and testing scripts
│   ├── setup-webhook-endpoint.sh    # Create webhook endpoint
│   ├── verify-signature.py          # Signature verification utility
│   ├── test-webhook-locally.sh      # Local testing with Stripe CLI
│   └── generate-webhook-secret.sh   # Generate webhook secrets
├── templates/                       # Production code templates
│   ├── webhook_handler.py           # FastAPI webhook handler
│   ├── event_logger.py              # Event logging with SQLAlchemy
│   ├── retry_handler.py             # Retry logic and backoff
│   └── webhook_test.py              # Pytest test utilities
└── examples/                        # Complete implementations
    ├── complete-webhook-handler.py  # Full webhook implementation
    ├── event-processing-example.py  # Idempotent event processing
    └── webhook-testing-example.sh   # Complete testing workflow
```

## Quick Start

### 1. Set Up Webhook Endpoint

```bash
# Create webhook endpoint for Stripe
bash scripts/setup-webhook-endpoint.sh stripe

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
```

### 2. Configure Webhook Secret

```bash
# Get webhook secret from Stripe
bash scripts/generate-webhook-secret.sh stripe

# Update .env with your webhook secret
# STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
```

### 3. Test Locally

```bash
# Start your application
uvicorn app.main:app --reload

# In another terminal, test webhooks
bash scripts/test-webhook-locally.sh
```

### 4. Run Test Suite

```bash
# Run complete testing workflow
bash examples/webhook-testing-example.sh

# Or run unit tests
pytest tests/webhooks/
```

## Security Features

### Signature Verification

All webhook requests are verified using HMAC-SHA256 signatures:

```python
# Automatic signature verification
is_valid, error = verify_stripe_signature(
    payload=raw_body,
    signature_header=stripe_signature,
    webhook_secret=STRIPE_WEBHOOK_SECRET,
    tolerance=300  # 5 minutes
)
```

### Replay Attack Prevention

Two-layer protection against replay attacks:

1. **Timestamp Validation**: Reject events older than 5 minutes
2. **Event ID Tracking**: Database-backed duplicate detection

```python
# Check if event already processed
if await event_logger.is_event_processed(event_id):
    return {"status": "success", "message": "Already processed"}
```

### Event Logging

Complete audit trail with database persistence:

- Raw webhook payload (for re-verification)
- Signature header value
- Processing status (pending, processed, failed)
- Error messages for failed events
- Timestamps for compliance

### Idempotency

All event handlers are idempotent (safe to call multiple times):

```python
# Idempotent event processing
async def process_subscription_created(event_id, subscription_data):
    # Check if already processed
    if self._is_processed(event_id):
        return

    # Process event
    # ...

    # Mark as processed (atomic operation)
    self._mark_processed(event_id)
```

## Supported Providers

### Stripe

- Signature verification with HMAC-SHA256
- Timestamp-based replay protection
- Event types: subscriptions, payments, disputes
- Test mode support with Stripe CLI

### PayPal

- Certificate-based signature verification
- Webhook ID validation
- Event types: billing, payments, disputes

### Square

- HMAC-SHA256 signature verification
- URL-based signed payload
- Event types: payments, refunds, disputes

## Usage Examples

### Example 1: Complete Webhook Handler

```python
# Use the complete webhook handler example
python examples/complete-webhook-handler.py

# Features:
# - Signature verification
# - Event logging to database
# - Retry handling
# - Idempotent processing
```

### Example 2: Event Processing with Transactions

```python
# Idempotent event processing with database transactions
python examples/event-processing-example.py

# Features:
# - Database transactions (atomic operations)
# - Duplicate event detection
# - Safe retry handling
```

### Example 3: Complete Testing Workflow

```bash
# Run comprehensive test suite
bash examples/webhook-testing-example.sh

# Tests:
# - Valid signatures
# - Invalid signatures (rejection)
# - Expired signatures (replay prevention)
# - Duplicate events (idempotency)
# - All event types
```

## Configuration

### Environment Variables

```bash
# Stripe Configuration
STRIPE_API_KEY=sk_test_your_stripe_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# PayPal Configuration
PAYPAL_CLIENT_ID=your_paypal_client_id_here
PAYPAL_CLIENT_SECRET=your_paypal_client_secret_here
PAYPAL_WEBHOOK_ID=your_webhook_id_here

# Database Configuration
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# Application Configuration
ENVIRONMENT=development
LOG_LEVEL=INFO
WEBHOOK_MAX_RETRIES=3
WEBHOOK_RETRY_DELAY=300
```

### Database Schema

```sql
-- Webhook events table
CREATE TABLE webhook_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    signature VARCHAR(500) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP
);

CREATE INDEX idx_event_id ON webhook_events(event_id);
CREATE INDEX idx_status ON webhook_events(status);
```

## Dependencies

```bash
# Web Framework
fastapi>=0.104.1
uvicorn[standard]>=0.24.0
pydantic>=2.5.0

# Payment Providers
stripe>=7.4.0
httpx>=0.25.2

# Database
sqlalchemy>=2.0.23
psycopg2-binary>=2.9.9
alembic>=1.13.0

# Development
pytest>=7.4.3
pytest-asyncio>=0.21.1
stripe-cli  # Download from Stripe
```

## Best Practices

### Security

1. **Never hardcode secrets**: Always use environment variables
2. **Verify all signatures**: No exceptions, verify before processing
3. **Log security events**: Track failed verification attempts
4. **Use HTTPS**: Required in production
5. **Rotate secrets**: Quarterly rotation recommended

### Event Processing

1. **Persist first**: Log event before processing
2. **Idempotent handlers**: Safe to call multiple times
3. **Use transactions**: Atomic database operations
4. **Return quickly**: Respond within 5 seconds
5. **Handle retries**: Appropriate HTTP status codes

### Testing

1. **Test locally first**: Use Stripe CLI before production
2. **Test all scenarios**: Valid, invalid, expired, duplicate
3. **Verify idempotency**: Process same event twice
4. **Check error handling**: Invalid payloads, processing failures
5. **Monitor in production**: Track failed events and security incidents

## Troubleshooting

### Signature Verification Failing

1. Check webhook secret is correct
2. Verify using raw request body (not parsed JSON)
3. Check timestamp tolerance (default 5 minutes)
4. Ensure secret matches endpoint in provider dashboard
5. Test with Stripe CLI to isolate issue

### Events Not Reaching Endpoint

1. Check endpoint URL is publicly accessible
2. Verify HTTPS is configured (required in production)
3. Check firewall/security group rules
4. Review webhook logs in provider dashboard
5. Use ngrok/localtunnel for local development

### Duplicate Events

1. Ensure event_id stored before processing
2. Check UNIQUE constraint on event_id column
3. Verify idempotency logic implemented
4. Review transaction handling

## Additional Resources

- [Stripe Webhooks Documentation](https://stripe.com/docs/webhooks)
- [Stripe CLI](https://stripe.com/docs/stripe-cli)
- [PayPal Webhooks](https://developer.paypal.com/docs/api/webhooks/)
- [Square Webhooks](https://developer.squareup.com/docs/webhooks)

## License

Part of the AI Dev Marketplace - Payments Plugin

## Version

1.0.0
