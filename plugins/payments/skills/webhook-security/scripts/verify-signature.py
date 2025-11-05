#!/usr/bin/env python3

"""
Webhook signature verification utility
Supports Stripe, PayPal, and Square signature verification
"""

import hashlib
import hmac
import time
import os
from typing import Optional, Tuple


def verify_stripe_signature(
    payload: bytes,
    signature_header: str,
    webhook_secret: str,
    tolerance: int = 300
) -> Tuple[bool, Optional[str]]:
    """
    Verify Stripe webhook signature

    Args:
        payload: Raw request body (bytes)
        signature_header: Stripe-Signature header value
        webhook_secret: Webhook signing secret from Stripe
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


def verify_paypal_signature(
    payload: bytes,
    transmission_id: str,
    transmission_time: str,
    cert_url: str,
    auth_algo: str,
    transmission_sig: str,
    webhook_id: str
) -> Tuple[bool, Optional[str]]:
    """
    Verify PayPal webhook signature

    Note: PayPal signature verification requires their SDK
    This is a simplified example showing the concept

    Args:
        payload: Raw request body
        transmission_id: PayPal-Transmission-Id header
        transmission_time: PayPal-Transmission-Time header
        cert_url: PayPal-Cert-Url header
        auth_algo: PayPal-Auth-Algo header
        transmission_sig: PayPal-Transmission-Sig header
        webhook_id: Your webhook ID from PayPal

    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        # In production, use PayPal SDK's verify_webhook_signature
        # This is a placeholder showing required headers

        # Construct expected message
        expected_message = f"{transmission_id}|{transmission_time}|{webhook_id}|{hashlib.sha256(payload).hexdigest()}"

        # Note: Actual verification requires downloading cert from cert_url
        # and using it to verify the signature
        # Use paypalrestsdk.WebhookEvent.verify() in production

        return True, None  # Placeholder - use PayPal SDK in production

    except Exception as e:
        return False, f"PayPal signature verification error: {str(e)}"


def verify_square_signature(
    payload: bytes,
    signature_header: str,
    signature_key: str,
    url: str
) -> Tuple[bool, Optional[str]]:
    """
    Verify Square webhook signature

    Args:
        payload: Raw request body
        signature_header: X-Square-Signature header value
        signature_key: Signature key from Square developer dashboard
        url: The webhook notification URL

    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        # Construct signed payload
        signed_payload = url + payload.decode('utf-8')

        # Compute expected signature
        expected_signature = hmac.new(
            signature_key.encode('utf-8'),
            signed_payload.encode('utf-8'),
            hashlib.sha256
        ).digest()

        # Base64 encode for comparison
        import base64
        expected_signature_b64 = base64.b64encode(expected_signature).decode('utf-8')

        # Compare signatures (timing-safe)
        if hmac.compare_digest(expected_signature_b64, signature_header):
            return True, None

        return False, "Signature mismatch"

    except Exception as e:
        return False, f"Square signature verification error: {str(e)}"


def main():
    """CLI for testing signature verification"""
    import sys
    import json

    if len(sys.argv) < 2:
        print("Usage: python verify-signature.py <provider>")
        print("Providers: stripe, paypal, square")
        sys.exit(1)

    provider = sys.argv[1].lower()

    if provider == "stripe":
        # Example Stripe verification
        print("Testing Stripe signature verification...")

        # Get from environment
        webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_test_secret")

        # Example payload and signature (replace with actual values for testing)
        payload = b'{"id": "evt_test", "type": "customer.created"}'
        timestamp = int(time.time())

        # Generate signature for testing
        signed_payload = f"{timestamp}.{payload.decode('utf-8')}"
        signature = hmac.new(
            webhook_secret.encode('utf-8'),
            signed_payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        signature_header = f"t={timestamp},v1={signature}"

        is_valid, error = verify_stripe_signature(
            payload, signature_header, webhook_secret
        )

        print(f"Valid: {is_valid}")
        if error:
            print(f"Error: {error}")

    elif provider == "paypal":
        print("PayPal verification requires PayPal SDK")
        print("Install: pip install paypalrestsdk")
        print("Use: paypalrestsdk.WebhookEvent.verify()")

    elif provider == "square":
        print("Testing Square signature verification...")

        signature_key = os.getenv("SQUARE_SIGNATURE_KEY", "test_signature_key")
        url = "https://example.com/webhooks/square"

        payload = b'{"merchant_id": "test", "type": "payment.updated"}'

        # Generate signature for testing
        import base64
        signed_payload = url + payload.decode('utf-8')
        signature = hmac.new(
            signature_key.encode('utf-8'),
            signed_payload.encode('utf-8'),
            hashlib.sha256
        ).digest()
        signature_header = base64.b64encode(signature).decode('utf-8')

        is_valid, error = verify_square_signature(
            payload, signature_header, signature_key, url
        )

        print(f"Valid: {is_valid}")
        if error:
            print(f"Error: {error}")

    else:
        print(f"Unknown provider: {provider}")
        sys.exit(1)


if __name__ == "__main__":
    main()
