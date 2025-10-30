#!/usr/bin/env bash
# test-connection.sh - Test ElevenLabs API connectivity
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "ElevenLabs API Connection Test"
echo "==============================="
echo ""

# Load environment variables from .env if it exists
if [[ -f ".env" ]]; then
    echo -e "${BLUE}Loading environment from .env file...${NC}"
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
    echo ""
fi

# Check if API key is set
if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
    echo -e "${RED}Error: ELEVENLABS_API_KEY not set${NC}"
    echo ""
    echo "Please set your API key by either:"
    echo "1. Running: bash scripts/setup-auth.sh"
    echo "2. Setting environment variable: export ELEVENLABS_API_KEY=your_key"
    echo "3. Adding to .env file: ELEVENLABS_API_KEY=your_key"
    exit 1
fi

# Mask API key for display
MASKED_KEY="${ELEVENLABS_API_KEY:0:10}...${ELEVENLABS_API_KEY: -4}"
echo -e "${BLUE}Using API key: $MASKED_KEY${NC}"
echo ""

# Test 1: Models endpoint (basic connectivity)
echo "Test 1: Testing basic connectivity (GET /v1/models)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -H "xi-api-key: $ELEVENLABS_API_KEY" \
    'https://api.elevenlabs.io/v1/models' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
    echo -e "${GREEN}✓ Connection successful${NC}"
    echo -e "${GREEN}✓ API key is valid${NC}"

    # Parse and display available models
    MODEL_COUNT=$(echo "$BODY" | grep -o '"model_id"' | wc -l | tr -d ' ')
    echo -e "${GREEN}✓ Found $MODEL_COUNT available models${NC}"

    # Display first few model IDs
    echo ""
    echo "Available models:"
    echo "$BODY" | grep -o '"model_id":"[^"]*"' | head -5 | sed 's/"model_id":"/  - /g' | sed 's/"//g'

elif [[ "$HTTP_CODE" == "401" ]]; then
    echo -e "${RED}✗ Authentication failed${NC}"
    echo -e "${RED}✗ API key is invalid or expired${NC}"
    echo ""
    echo "Please check your API key at: https://elevenlabs.io/app/settings/api-keys"
    exit 1

elif [[ "$HTTP_CODE" == "429" ]]; then
    echo -e "${YELLOW}✗ Rate limit exceeded${NC}"
    echo "Your API key has hit the rate limit. Please wait and try again."
    exit 1

else
    echo -e "${RED}✗ Connection failed${NC}"
    echo -e "${RED}HTTP Status: $HTTP_CODE${NC}"
    echo "Response: $BODY"
    exit 1
fi

echo ""

# Test 2: Voices endpoint (permissions check)
echo "Test 2: Testing permissions (GET /v1/voices)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -H "xi-api-key: $ELEVENLABS_API_KEY" \
    'https://api.elevenlabs.io/v1/voices' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
    echo -e "${GREEN}✓ Voices endpoint accessible${NC}"

    # Parse and display available voices
    VOICE_COUNT=$(echo "$BODY" | grep -o '"voice_id"' | wc -l | tr -d ' ')
    echo -e "${GREEN}✓ Found $VOICE_COUNT available voices${NC}"

    # Display first few voice names
    if command -v jq &> /dev/null; then
        echo ""
        echo "Sample voices:"
        echo "$BODY" | jq -r '.voices[:3] | .[] | "  - \(.name) (ID: \(.voice_id))"' 2>/dev/null || true
    fi

elif [[ "$HTTP_CODE" == "403" ]]; then
    echo -e "${YELLOW}⚠ Voices endpoint restricted${NC}"
    echo "Your API key may have endpoint restrictions configured."

else
    echo -e "${YELLOW}⚠ Could not access voices endpoint (HTTP $HTTP_CODE)${NC}"
fi

echo ""

# Test 3: User subscription info
echo "Test 3: Checking subscription info (GET /v1/user/subscription)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -H "xi-api-key: $ELEVENLABS_API_KEY" \
    'https://api.elevenlabs.io/v1/user/subscription' 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "200" ]]; then
    echo -e "${GREEN}✓ Subscription info retrieved${NC}"

    if command -v jq &> /dev/null; then
        TIER=$(echo "$BODY" | jq -r '.tier // "unknown"' 2>/dev/null || echo "unknown")
        CHARACTER_COUNT=$(echo "$BODY" | jq -r '.character_count // 0' 2>/dev/null || echo "0")
        CHARACTER_LIMIT=$(echo "$BODY" | jq -r '.character_limit // 0' 2>/dev/null || echo "0")

        echo "  Tier: $TIER"
        echo "  Characters used: $CHARACTER_COUNT / $CHARACTER_LIMIT"

        if [[ "$CHARACTER_COUNT" -gt 0 ]] && [[ "$CHARACTER_LIMIT" -gt 0 ]]; then
            USAGE_PERCENT=$((CHARACTER_COUNT * 100 / CHARACTER_LIMIT))
            if [[ "$USAGE_PERCENT" -gt 80 ]]; then
                echo -e "  ${YELLOW}⚠ Usage at ${USAGE_PERCENT}% of limit${NC}"
            else
                echo -e "  ${GREEN}✓ Usage at ${USAGE_PERCENT}% of limit${NC}"
            fi
        fi
    fi
fi

echo ""
echo "==============================="
echo -e "${GREEN}Connection test complete!${NC}"
echo ""
echo "Your ElevenLabs API is properly configured and ready to use."
echo ""
echo "Next steps:"
echo "1. Install SDK: bash scripts/install-sdk.sh [typescript|python]"
echo "2. Generate client: bash scripts/generate-client.sh [typescript|python] [output-path]"
echo "3. Explore examples: ls examples/"
