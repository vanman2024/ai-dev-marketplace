#!/bin/bash

# generate-test-payload.sh - Generate test webhook payloads for different event types
# Usage: ./generate-test-payload.sh [event-type] [output-file]

set -e

EVENT_TYPE="${1:-email.delivered}"
OUTPUT_FILE="${2:-.}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EMAIL_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Generate payloads for different event types
case "$EVENT_TYPE" in
    email.sent)
        PAYLOAD=$(cat <<EOF
{
  "type": "email.sent",
  "created_at": "$TIMESTAMP",
  "data": {
    "email_id": "$EMAIL_ID",
    "from": "notifications@example.com",
    "to": "recipient@example.com",
    "subject": "Welcome to Example",
    "created_at": "$TIMESTAMP"
  }
}
EOF
)
        ;;
    email.delivered)
        PAYLOAD=$(cat <<EOF
{
  "type": "email.delivered",
  "created_at": "$TIMESTAMP",
  "data": {
    "email_id": "$EMAIL_ID",
    "from": "notifications@example.com",
    "to": "recipient@example.com",
    "created_at": "$TIMESTAMP"
  }
}
EOF
)
        ;;
    email.bounced)
        PAYLOAD=$(cat <<EOF
{
  "type": "email.bounced",
  "created_at": "$TIMESTAMP",
  "data": {
    "email_id": "$EMAIL_ID",
    "from": "notifications@example.com",
    "to": "invalid@example.com",
    "reason": "Mailbox does not exist",
    "created_at": "$TIMESTAMP"
  }
}
EOF
)
        ;;
    email.opened)
        PAYLOAD=$(cat <<EOF
{
  "type": "email.opened",
  "created_at": "$TIMESTAMP",
  "data": {
    "email_id": "$EMAIL_ID",
    "from": "notifications@example.com",
    "to": "recipient@example.com",
    "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "ip_address": "192.168.1.1",
    "created_at": "$TIMESTAMP"
  }
}
EOF
)
        ;;
    email.clicked)
        PAYLOAD=$(cat <<EOF
{
  "type": "email.clicked",
  "created_at": "$TIMESTAMP",
  "data": {
    "email_id": "$EMAIL_ID",
    "from": "marketing@example.com",
    "to": "recipient@example.com",
    "link": "https://example.com/promo",
    "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    "ip_address": "192.168.1.1",
    "created_at": "$TIMESTAMP"
  }
}
EOF
)
        ;;
    email.complained)
        PAYLOAD=$(cat <<EOF
{
  "type": "email.complained",
  "created_at": "$TIMESTAMP",
  "data": {
    "email_id": "$EMAIL_ID",
    "from": "newsletter@example.com",
    "to": "recipient@example.com",
    "created_at": "$TIMESTAMP"
  }
}
EOF
)
        ;;
    *)
        echo "Unknown event type: $EVENT_TYPE"
        echo ""
        echo "Supported event types:"
        echo "  email.sent"
        echo "  email.delivered"
        echo "  email.bounced"
        echo "  email.opened"
        echo "  email.clicked"
        echo "  email.complained"
        exit 1
        ;;
esac

# Output payload
if [ "$OUTPUT_FILE" = "." ]; then
    # Print to stdout
    echo "$PAYLOAD"
else
    # Save to file
    echo "$PAYLOAD" > "$OUTPUT_FILE"
    echo "Payload saved to: $OUTPUT_FILE"
fi
