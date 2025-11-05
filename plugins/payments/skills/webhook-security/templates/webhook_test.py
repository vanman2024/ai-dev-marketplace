"""
Webhook testing utilities
Test signature verification, event processing, and error handling
"""

import hashlib
import hmac
import json
import time
from typing import Dict, Optional

import pytest
from httpx import AsyncClient


class WebhookTestHelper:
    """
    Helper class for testing webhooks

    Features:
    - Generate valid webhook signatures
    - Create test webhook payloads
    - Simulate different scenarios (success, failure, replay, etc)
    """

    def __init__(self, webhook_secret: str):
        """
        Initialize webhook test helper

        Args:
            webhook_secret: Webhook signing secret
        """
        self.webhook_secret = webhook_secret

    def generate_stripe_signature(
        self,
        payload: str,
        timestamp: Optional[int] = None
    ) -> str:
        """
        Generate valid Stripe webhook signature

        Args:
            payload: Webhook payload (JSON string)
            timestamp: Unix timestamp (defaults to current time)

        Returns:
            Stripe-Signature header value
        """
        if timestamp is None:
            timestamp = int(time.time())

        # Construct signed payload
        signed_payload = f"{timestamp}.{payload}"

        # Compute signature
        signature = hmac.new(
            self.webhook_secret.encode('utf-8'),
            signed_payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        # Format header
        return f"t={timestamp},v1={signature}"

    def generate_invalid_signature(self, payload: str) -> str:
        """
        Generate invalid signature for testing rejection

        Args:
            payload: Webhook payload

        Returns:
            Invalid signature header
        """
        timestamp = int(time.time())
        return f"t={timestamp},v1=invalidsignature123"

    def generate_expired_signature(
        self,
        payload: str,
        age_seconds: int = 600
    ) -> str:
        """
        Generate expired signature for replay attack testing

        Args:
            payload: Webhook payload
            age_seconds: How old to make the signature (default 10 minutes)

        Returns:
            Expired signature header
        """
        # Create signature from 10+ minutes ago
        old_timestamp = int(time.time()) - age_seconds
        return self.generate_stripe_signature(payload, old_timestamp)

    def create_test_event(
        self,
        event_type: str,
        event_id: Optional[str] = None,
        **data
    ) -> Dict:
        """
        Create test Stripe event payload

        Args:
            event_type: Event type (e.g., customer.subscription.created)
            event_id: Event ID (generated if not provided)
            **data: Additional data for event.data.object

        Returns:
            Dictionary representing Stripe event
        """
        if event_id is None:
            event_id = f"evt_test_{int(time.time())}"

        return {
            "id": event_id,
            "object": "event",
            "type": event_type,
            "created": int(time.time()),
            "data": {
                "object": data
            },
            "livemode": False
        }

    def create_subscription_event(
        self,
        event_type: str = "customer.subscription.created",
        subscription_id: Optional[str] = None,
        customer_id: str = "cus_test",
        plan_id: str = "plan_test",
        status: str = "active"
    ) -> Dict:
        """
        Create test subscription event

        Args:
            event_type: Event type
            subscription_id: Subscription ID
            customer_id: Customer ID
            plan_id: Plan ID
            status: Subscription status

        Returns:
            Subscription event dictionary
        """
        if subscription_id is None:
            subscription_id = f"sub_test_{int(time.time())}"

        return self.create_test_event(
            event_type=event_type,
            id=subscription_id,
            object="subscription",
            customer=customer_id,
            plan=plan_id,
            status=status,
            current_period_start=int(time.time()),
            current_period_end=int(time.time()) + 2592000  # 30 days
        )

    def create_payment_event(
        self,
        event_type: str = "invoice.payment_succeeded",
        invoice_id: Optional[str] = None,
        amount: int = 1000,
        currency: str = "usd",
        status: str = "paid"
    ) -> Dict:
        """
        Create test payment event

        Args:
            event_type: Event type
            invoice_id: Invoice ID
            amount: Amount in cents
            currency: Currency code
            status: Payment status

        Returns:
            Payment event dictionary
        """
        if invoice_id is None:
            invoice_id = f"in_test_{int(time.time())}"

        return self.create_test_event(
            event_type=event_type,
            id=invoice_id,
            object="invoice",
            amount_due=amount,
            amount_paid=amount if status == "paid" else 0,
            currency=currency,
            status=status
        )


# Pytest fixtures and test cases

@pytest.fixture
def webhook_secret():
    """Webhook secret for testing"""
    return "whsec_test_secret_12345678"


@pytest.fixture
def webhook_helper(webhook_secret):
    """Webhook test helper instance"""
    return WebhookTestHelper(webhook_secret)


@pytest.fixture
async def client():
    """HTTP client for testing"""
    from app.main import app
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_valid_signature(client, webhook_helper):
    """Test webhook with valid signature succeeds"""
    # Create test event
    event = webhook_helper.create_subscription_event()
    payload = json.dumps(event)

    # Generate valid signature
    signature = webhook_helper.generate_stripe_signature(payload)

    # Send request
    response = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )

    assert response.status_code == 200
    assert response.json()["status"] == "success"


@pytest.mark.asyncio
async def test_invalid_signature(client, webhook_helper):
    """Test webhook with invalid signature is rejected"""
    event = webhook_helper.create_subscription_event()
    payload = json.dumps(event)

    # Generate invalid signature
    signature = webhook_helper.generate_invalid_signature(payload)

    # Send request
    response = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )

    assert response.status_code == 401
    assert "Invalid signature" in response.json()["detail"]


@pytest.mark.asyncio
async def test_expired_signature(client, webhook_helper):
    """Test webhook with expired signature is rejected (replay attack prevention)"""
    event = webhook_helper.create_subscription_event()
    payload = json.dumps(event)

    # Generate expired signature (10 minutes old)
    signature = webhook_helper.generate_expired_signature(payload, age_seconds=600)

    # Send request
    response = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )

    assert response.status_code == 401
    assert "Timestamp outside tolerance" in response.json()["detail"]


@pytest.mark.asyncio
async def test_duplicate_event(client, webhook_helper):
    """Test duplicate event is handled idempotently"""
    event = webhook_helper.create_subscription_event(
        event_id="evt_test_duplicate"
    )
    payload = json.dumps(event)
    signature = webhook_helper.generate_stripe_signature(payload)

    # Send first request
    response1 = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )
    assert response1.status_code == 200

    # Send duplicate request
    response2 = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )

    assert response2.status_code == 200
    assert "already processed" in response2.json()["message"].lower()


@pytest.mark.asyncio
async def test_malformed_payload(client, webhook_helper):
    """Test malformed payload is rejected"""
    payload = "not valid json"
    signature = webhook_helper.generate_stripe_signature(payload)

    response = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )

    assert response.status_code == 400
    assert "Invalid payload" in response.json()["detail"]


@pytest.mark.asyncio
async def test_missing_signature(client, webhook_helper):
    """Test request without signature header is rejected"""
    event = webhook_helper.create_subscription_event()
    payload = json.dumps(event)

    response = await client.post(
        "/webhooks/stripe",
        content=payload
    )

    assert response.status_code == 401
    assert "Missing signature" in response.json()["detail"]


@pytest.mark.asyncio
async def test_subscription_events(client, webhook_helper):
    """Test different subscription event types"""
    event_types = [
        "customer.subscription.created",
        "customer.subscription.updated",
        "customer.subscription.deleted"
    ]

    for event_type in event_types:
        event = webhook_helper.create_subscription_event(event_type=event_type)
        payload = json.dumps(event)
        signature = webhook_helper.generate_stripe_signature(payload)

        response = await client.post(
            "/webhooks/stripe",
            content=payload,
            headers={"Stripe-Signature": signature}
        )

        assert response.status_code == 200, f"Failed for {event_type}"


@pytest.mark.asyncio
async def test_payment_events(client, webhook_helper):
    """Test payment event processing"""
    # Test successful payment
    event = webhook_helper.create_payment_event(
        event_type="invoice.payment_succeeded"
    )
    payload = json.dumps(event)
    signature = webhook_helper.generate_stripe_signature(payload)

    response = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )

    assert response.status_code == 200

    # Test failed payment
    event = webhook_helper.create_payment_event(
        event_type="invoice.payment_failed",
        status="open"
    )
    payload = json.dumps(event)
    signature = webhook_helper.generate_stripe_signature(payload)

    response = await client.post(
        "/webhooks/stripe",
        content=payload,
        headers={"Stripe-Signature": signature}
    )

    assert response.status_code == 200


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
