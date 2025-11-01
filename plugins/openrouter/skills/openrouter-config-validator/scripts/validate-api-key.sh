#!/bin/bash
# Validates OpenRouter API key format and tests connectivity

set -e

API_KEY="${1:-$OPENROUTER_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: No API key provided"
    echo "Usage: $0 <api-key>"
    echo "Or set OPENROUTER_API_KEY environment variable"
    exit 1
fi

echo "🔍 Validating OpenRouter API Key..."
echo ""

# Check format
echo "1. Format Validation"
if [[ $API_KEY =~ ^sk-or-v1-[a-f0-9]{64}$ ]]; then
    echo "   ✅ Format is correct (sk-or-v1-*)"
else
    echo "   ⚠️  Format may be incorrect"
    echo "   Expected: sk-or-v1-{64 hex characters}"
    echo "   Received: ${API_KEY:0:20}..."
fi
echo ""

# Test connectivity
echo "2. Connectivity Test"
RESPONSE=$(curl -s -w "\n%{http_code}" https://openrouter.ai/api/v1/auth/key \
    -H "Authorization: Bearer $API_KEY" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ API key is valid and active"

    # Parse response for additional info
    if command -v jq &> /dev/null; then
        echo ""
        echo "3. Key Information"
        echo "$BODY" | jq -r '
            "   Label: \(.data.label // "N/A")",
            "   Usage: \(.data.usage // 0) requests",
            "   Limit: \(.data.limit // "unlimited") requests",
            "   Rate Limit: \(.data.rate_limit.requests // "N/A") req/min"
        ' 2>/dev/null || echo "   (Unable to parse details)"
    fi
elif [ "$HTTP_CODE" = "401" ]; then
    echo "   ❌ Authentication failed - Invalid API key"
    exit 1
elif [ "$HTTP_CODE" = "403" ]; then
    echo "   ❌ Access forbidden - Key may be revoked"
    exit 1
elif [ "$HTTP_CODE" = "429" ]; then
    echo "   ⚠️  Rate limited - Try again later"
    exit 1
else
    echo "   ❌ Unexpected response (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
    exit 1
fi

echo ""
echo "✅ Validation complete - API key is functional"
