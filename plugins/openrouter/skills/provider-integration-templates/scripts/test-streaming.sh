#!/bin/bash
# test-streaming.sh
# Tests streaming functionality with OpenRouter

set -e

PROVIDER="openrouter"
MODEL="anthropic/claude-3.5-sonnet"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --provider)
            PROVIDER="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--provider openrouter] [--model <model-id>]"
            exit 1
            ;;
    esac
done

echo "🌊 Testing streaming with OpenRouter..."
echo "Model: $MODEL"

# Check for .env file
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check for API key
if [ -z "$OPENROUTER_API_KEY" ] || [ "$OPENROUTER_API_KEY" = "sk-or-v1-your-key-here" ]; then
    echo "❌ Error: OPENROUTER_API_KEY not set in .env file"
    exit 1
fi

echo ""
echo "📡 Sending streaming request..."
echo "---"

# Test streaming
curl -N https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "HTTP-Referer: http://localhost:3000" \
    -H "X-Title: Streaming Test" \
    -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{
            \"role\": \"user\",
            \"content\": \"Count from 1 to 5, with one number per line.\"
        }],
        \"stream\": true,
        \"max_tokens\": 50
    }" | while IFS= read -r line; do
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi

    # Skip "data: " prefix
    if [[ "$line" == data:* ]]; then
        JSON="${line#data: }"

        # Skip [DONE] marker
        if [ "$JSON" = "[DONE]" ]; then
            echo ""
            echo "---"
            echo "✅ Streaming completed successfully!"
            break
        fi

        # Extract content from delta
        CONTENT=$(echo "$JSON" | grep -o '"delta":{[^}]*"content":"[^"]*"' | grep -o '"content":"[^"]*"' | cut -d'"' -f4)

        if [ -n "$CONTENT" ]; then
            echo -n "$CONTENT"
        fi
    fi
done

echo ""
echo ""
echo "✅ Streaming test completed!"
echo ""
echo "If you saw numbers streaming above, streaming is working correctly."
