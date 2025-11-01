#!/bin/bash
# Checks if a specific model is available via OpenRouter

set -e

MODEL_ID="$1"
API_KEY="${2:-$OPENROUTER_API_KEY}"

if [ -z "$MODEL_ID" ]; then
    echo "❌ Error: No model ID provided"
    echo "Usage: $0 <model-id> [api-key]"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo "❌ Error: No API key provided"
    echo "Set OPENROUTER_API_KEY or provide as second argument"
    exit 1
fi

echo "🔍 Checking model availability: $MODEL_ID"
echo ""

# Fetch available models
echo "1. Fetching model list from OpenRouter..."
RESPONSE=$(curl -s -w "\n%{http_code}" https://openrouter.ai/api/v1/models \
    -H "Authorization: Bearer $API_KEY" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" != "200" ]; then
    echo "   ❌ Failed to fetch models (HTTP $HTTP_CODE)"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "   ⚠️  jq not installed - cannot parse response"
    echo "   Install jq to enable full validation"
    exit 1
fi

# Check if model exists
echo "2. Searching for model: $MODEL_ID"
MODEL_INFO=$(echo "$BODY" | jq -r --arg model "$MODEL_ID" '
    .data[] | select(.id == $model)
')

if [ -z "$MODEL_INFO" ]; then
    echo "   ❌ Model not found: $MODEL_ID"
    echo ""
    echo "   Suggestions:"

    # Find similar models
    SIMILAR=$(echo "$BODY" | jq -r --arg model "$MODEL_ID" '
        .data[] | select(.id | contains($model[0:10])) | .id
    ' | head -5)

    if [ -n "$SIMILAR" ]; then
        echo "   Similar models available:"
        echo "$SIMILAR" | while read -r line; do
            echo "   - $line"
        done
    else
        echo "   Try searching OpenRouter docs for correct model ID"
    fi
    exit 1
fi

# Display model information
echo "   ✅ Model found and available"
echo ""
echo "3. Model Information"
echo "$MODEL_INFO" | jq -r '
    "   Name: \(.name)",
    "   Context Length: \(.context_length) tokens",
    "   Pricing:",
    "     - Prompt: $\(.pricing.prompt) per token",
    "     - Completion: $\(.pricing.completion) per token",
    "   Created: \(.created | strftime("%Y-%m-%d"))"
'

# Check if model supports features
echo ""
echo "4. Supported Features"
echo "$MODEL_INFO" | jq -r '
    if .supported_features then
        .supported_features | to_entries[] | "   - \(.key): \(.value)"
    else
        "   (Feature information not available)"
    end
'

echo ""
echo "✅ Model $MODEL_ID is available and ready to use"
