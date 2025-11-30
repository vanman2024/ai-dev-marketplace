#!/bin/bash

# verify-signature.sh - Test and validate Resend webhook signatures
# Usage: ./verify-signature.sh <payload> <signature> <secret>

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <payload> <signature> <secret>"
    echo ""
    echo "Example:"
    echo "  $0 '{\"type\":\"email.sent\"}' 'abc123...' 'your_webhook_secret'"
    echo ""
    echo "Generate test payload:"
    echo "  PAYLOAD='{\"type\":\"email.sent\",\"created_at\":\"2024-01-15T10:30:00Z\",\"data\":{\"email_id\":\"123e4567\",\"from\":\"test@example.com\",\"to\":\"user@example.com\"}}'"
    echo "  SECRET='your_webhook_secret'"
    echo "  SIGNATURE=\$(echo -n \"\$PAYLOAD\" | openssl dgst -sha256 -hmac \"\$SECRET\" | sed 's/^.* //')"
    echo "  $0 \"\$PAYLOAD\" \"\$SIGNATURE\" \"\$SECRET\""
    exit 1
fi

PAYLOAD="$1"
SIGNATURE="$2"
SECRET="$3"

# Calculate expected signature
EXPECTED_SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

echo "Payload: $(echo "$PAYLOAD" | head -c 100)..."
echo ""
echo "Provided signature:  $SIGNATURE"
echo "Expected signature:  $EXPECTED_SIGNATURE"
echo ""

if [ "$SIGNATURE" = "$EXPECTED_SIGNATURE" ]; then
    echo "✓ Signature is VALID"
    exit 0
else
    echo "✗ Signature is INVALID"
    exit 1
fi
