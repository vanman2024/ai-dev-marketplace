#!/usr/bin/env bash
# validate-env.sh - Validate .env file has required ELEVENLABS_API_KEY
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "ElevenLabs Environment Validation"
echo "=================================="
echo ""

# Check if .env file exists
if [[ ! -f ".env" ]]; then
    echo -e "${RED}✗ .env file not found${NC}"
    echo ""
    echo "Please create a .env file by running:"
    echo "  bash scripts/setup-auth.sh"
    exit 1
fi

echo -e "${GREEN}✓ .env file exists${NC}"

# Check if ELEVENLABS_API_KEY is set
if ! grep -q "^ELEVENLABS_API_KEY=" ".env"; then
    echo -e "${RED}✗ ELEVENLABS_API_KEY not found in .env${NC}"
    echo ""
    echo "Please add your API key by running:"
    echo "  bash scripts/setup-auth.sh"
    exit 1
fi

echo -e "${GREEN}✓ ELEVENLABS_API_KEY found in .env${NC}"

# Load and validate the API key
source .env

if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
    echo -e "${RED}✗ ELEVENLABS_API_KEY is empty${NC}"
    echo ""
    echo "Please set your API key by running:"
    echo "  bash scripts/setup-auth.sh"
    exit 1
fi

echo -e "${GREEN}✓ ELEVENLABS_API_KEY is set${NC}"

# Validate API key format
if [[ ! "$ELEVENLABS_API_KEY" =~ ^sk_ ]]; then
    echo -e "${YELLOW}⚠ Warning: API key doesn't start with 'sk_'${NC}"
    echo "  This may not be a valid ElevenLabs API key"
fi

# Check API key length
KEY_LENGTH=${#ELEVENLABS_API_KEY}
if [[ "$KEY_LENGTH" -lt 20 ]]; then
    echo -e "${YELLOW}⚠ Warning: API key seems too short (length: $KEY_LENGTH)${NC}"
fi

# Mask API key for display
MASKED_KEY="${ELEVENLABS_API_KEY:0:10}...${ELEVENLABS_API_KEY: -4}"
echo -e "${BLUE}API Key: $MASKED_KEY${NC}"

# Check if .env is in .gitignore
if [[ -f ".gitignore" ]]; then
    if grep -q "^\.env$" ".gitignore"; then
        echo -e "${GREEN}✓ .env is in .gitignore${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: .env not found in .gitignore${NC}"
        echo "  Add it to prevent committing secrets:"
        echo "  echo '.env' >> .gitignore"
    fi
else
    echo -e "${YELLOW}⚠ Warning: .gitignore not found${NC}"
    echo "  Create one to prevent committing .env file"
fi

# Optional: Check for other common environment variables
echo ""
echo "Optional environment variables:"

if grep -q "^ELEVENLABS_DEFAULT_VOICE_ID=" ".env"; then
    echo -e "${GREEN}✓ ELEVENLABS_DEFAULT_VOICE_ID configured${NC}"
else
    echo -e "${BLUE}  ELEVENLABS_DEFAULT_VOICE_ID not set (optional)${NC}"
fi

if grep -q "^ELEVENLABS_DEFAULT_MODEL_ID=" ".env"; then
    echo -e "${GREEN}✓ ELEVENLABS_DEFAULT_MODEL_ID configured${NC}"
else
    echo -e "${BLUE}  ELEVENLABS_DEFAULT_MODEL_ID not set (optional)${NC}"
fi

echo ""
echo "=================================="
echo -e "${GREEN}Environment validation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Test connection: bash scripts/test-connection.sh"
echo "2. Install SDK: bash scripts/install-sdk.sh [typescript|python]"
echo "3. Generate client: bash scripts/generate-client.sh [typescript|python] [output-path]"
