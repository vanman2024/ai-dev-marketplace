#!/bin/bash

# test-webhook.sh - Send test webhook requests to a webhook endpoint
# Usage: ./test-webhook.sh <url> <event-type> <secret>
#
# Examples:
#   ./test-webhook.sh http://localhost:3000/api/webhooks/resend email.sent your_secret
#   ./test-webhook.sh https://myapp.com/webhooks/resend email.delivered your_secret

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <webhook-url> <event-type> <webhook-secret>"
    echo ""
    echo "Arguments:"
    echo "  webhook-url   - The webhook endpoint URL (http://localhost:3000/api/webhooks/resend)"
    echo "  event-type    - Type of event to test (email.sent|email.delivered|email.bounced|email.opened|email.clicked|email.complained)"
    echo "  webhook-secret - The webhook signing secret"
    echo ""
    echo "Examples:"
    echo "  $0 http://localhost:3000/api/webhooks/resend email.sent 'your_webhook_secret'"
    echo "  $0 https://myapp.com/webhooks/resend email.delivered 'your_webhook_secret'"
    echo ""
    exit 1
fi

WEBHOOK_URL="$1"
EVENT_TYPE="$2"
SECRET="$3"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EMAIL_ID=$(uuidgen | tr '[:upper:]' '[:lower:]' || echo "123e4567-e89b-12d3-a456-426614174000")

# Generate payload based on event type
case "$EVENT_TYPE" in
    email.sent)
        PAYLOAD="{\"type\":\"email.sent\",\"created_at\":\"$TIMESTAMP\",\"data\":{\"email_id\":\"$EMAIL_ID\",\"from\":\"test@example.com\",\"to\":\"user@example.com\",\"subject\":\"Test Email\",\"created_at\":\"$TIMESTAMP\"}}"
        ;;
    email.delivered)
        PAYLOAD="{\"type\":\"email.delivered\",\"created_at\":\"$TIMESTAMP\",\"data\":{\"email_id\":\"$EMAIL_ID\",\"from\":\"test@example.com\",\"to\":\"user@example.com\",\"created_at\":\"$TIMESTAMP\"}}"
        ;;
    email.bounced)
        PAYLOAD="{\"type\":\"email.bounced\",\"created_at\":\"$TIMESTAMP\",\"data\":{\"email_id\":\"$EMAIL_ID\",\"from\":\"test@example.com\",\"to\":\"invalid@example.com\",\"reason\":\"Mailbox does not exist\",\"created_at\":\"$TIMESTAMP\"}}"
        ;;
    email.opened)
        PAYLOAD="{\"type\":\"email.opened\",\"created_at\":\"$TIMESTAMP\",\"data\":{\"email_id\":\"$EMAIL_ID\",\"from\":\"test@example.com\",\"to\":\"user@example.com\",\"user_agent\":\"Mozilla/5.0\",\"ip_address\":\"192.168.1.1\",\"created_at\":\"$TIMESTAMP\"}}"
        ;;
    email.clicked)
        PAYLOAD="{\"type\":\"email.clicked\",\"created_at\":\"$TIMESTAMP\",\"data\":{\"email_id\":\"$EMAIL_ID\",\"from\":\"test@example.com\",\"to\":\"user@example.com\",\"link\":\"https://example.com\",\"user_agent\":\"Mozilla/5.0\",\"ip_address\":\"192.168.1.1\",\"created_at\":\"$TIMESTAMP\"}}"
        ;;
    email.complained)
        PAYLOAD="{\"type\":\"email.complained\",\"created_at\":\"$TIMESTAMP\",\"data\":{\"email_id\":\"$EMAIL_ID\",\"from\":\"test@example.com\",\"to\":\"user@example.com\",\"created_at\":\"$TIMESTAMP\"}}"
        ;;
    *)
        echo "Unknown event type: $EVENT_TYPE"
        exit 1
        ;;
esac

# Calculate signature
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

echo "Sending webhook test..."
echo "  URL: $WEBHOOK_URL"
echo "  Event Type: $EVENT_TYPE"
echo "  Email ID: $EMAIL_ID"
echo "  Timestamp: $TIMESTAMP"
echo ""

# Send request
RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "x-resend-signature: $SIGNATURE" \
  -d "$PAYLOAD" \
  -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "Response Status: $HTTP_CODE"
echo "Response Body:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo ""
    echo "✓ Webhook test successful"
    exit 0
else
    echo ""
    echo "✗ Webhook test failed (HTTP $HTTP_CODE)"
    exit 1
fi
