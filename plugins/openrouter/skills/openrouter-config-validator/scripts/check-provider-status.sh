#!/bin/bash
# Checks OpenRouter provider status and availability

set -e

PROVIDER="${1:-all}"
API_KEY="${2:-$OPENROUTER_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: No API key provided"
    echo "Usage: $0 [provider-name] [api-key]"
    echo "Set OPENROUTER_API_KEY or provide as argument"
    exit 1
fi

echo "🔍 Checking OpenRouter Provider Status"
echo ""

# Fetch models to determine provider status
echo "1. Fetching provider information..."
RESPONSE=$(curl -s -w "\n%{http_code}" https://openrouter.ai/api/v1/models \
    -H "Authorization: Bearer $API_KEY" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" != "200" ]; then
    echo "   ❌ Failed to fetch provider data (HTTP $HTTP_CODE)"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "   ⚠️  jq not installed - cannot parse response"
    exit 1
fi

echo "   ✅ Data fetched successfully"
echo ""

# Extract provider information
if [ "$PROVIDER" = "all" ]; then
    echo "2. Available Providers"
    echo "$BODY" | jq -r '
        [.data[] | .id | split("/")[0]] |
        unique |
        sort |
        .[] |
        "   - \(.)"
    '

    echo ""
    echo "3. Provider Model Count"
    echo "$BODY" | jq -r '
        [.data[] | {provider: (.id | split("/")[0])}] |
        group_by(.provider) |
        map({provider: .[0].provider, count: length}) |
        sort_by(.count) |
        reverse |
        .[] |
        "   \(.provider): \(.count) models"
    '
else
    echo "2. Checking provider: $PROVIDER"

    MODELS=$(echo "$BODY" | jq -r --arg prov "$PROVIDER" '
        [.data[] | select(.id | startswith($prov + "/"))]
    ')

    MODEL_COUNT=$(echo "$MODELS" | jq 'length')

    if [ "$MODEL_COUNT" -eq 0 ]; then
        echo "   ❌ Provider not found or no models available"
        echo ""
        echo "   Available providers:"
        echo "$BODY" | jq -r '
            [.data[] | .id | split("/")[0]] |
            unique |
            sort |
            .[] |
            "   - \(.)"
        ' | head -10
        exit 1
    fi

    echo "   ✅ Provider active with $MODEL_COUNT models"
    echo ""

    echo "3. Available Models"
    echo "$MODELS" | jq -r '
        .[] |
        "   - \(.id) (\(.context_length) tokens)"
    '

    echo ""
    echo "4. Pricing Range"
    echo "$MODELS" | jq -r '
        [.[] | {
            model: .id,
            prompt: .pricing.prompt,
            completion: .pricing.completion
        }] |
        "   Prompt tokens: $\(map(.prompt) | min) - $\(map(.prompt) | max)",
        "   Completion tokens: $\(map(.completion) | min) - $\(map(.completion) | max)"
    '
fi

echo ""
echo "✅ Provider status check complete"
