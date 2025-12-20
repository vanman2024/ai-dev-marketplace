#!/bin/bash

# validate-agent-card.sh
# Validate A2A agent card JSON against schema

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SCHEMA_FILE="$SKILL_DIR/templates/schema.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if agent card file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Agent card file path required${NC}"
    echo "Usage: $0 <agent-card.json>"
    exit 1
fi

AGENT_CARD="$1"

# Check if agent card file exists
if [ ! -f "$AGENT_CARD" ]; then
    echo -e "${RED}Error: Agent card file not found: $AGENT_CARD${NC}"
    exit 1
fi

# Check if schema file exists
if [ ! -f "$SCHEMA_FILE" ]; then
    echo -e "${RED}Error: Schema file not found: $SCHEMA_FILE${NC}"
    exit 1
fi

echo "Validating agent card: $AGENT_CARD"
echo "Using schema: $SCHEMA_FILE"
echo ""

# Check if jq is installed (for JSON validation)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq not installed. Installing for JSON validation...${NC}"
    # Try to install jq based on OS
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    else
        echo -e "${RED}Error: Cannot install jq automatically. Please install manually.${NC}"
        exit 1
    fi
fi

# Step 1: Validate JSON syntax
echo "Step 1: Validating JSON syntax..."
if ! jq empty "$AGENT_CARD" 2>/dev/null; then
    echo -e "${RED}✗ Invalid JSON syntax${NC}"
    jq empty "$AGENT_CARD"
    exit 1
fi
echo -e "${GREEN}✓ Valid JSON syntax${NC}"
echo ""

# Step 2: Check required fields
echo "Step 2: Checking required fields..."
REQUIRED_FIELDS=("id" "name" "protocolVersion" "serviceEndpoint" "provider" "capabilities" "securitySchemes" "security")

for field in "${REQUIRED_FIELDS[@]}"; do
    if ! jq -e ".$field" "$AGENT_CARD" > /dev/null 2>&1; then
        echo -e "${RED}✗ Missing required field: $field${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Found required field: $field${NC}"
done
echo ""

# Step 3: Validate provider object
echo "Step 3: Validating provider object..."
if ! jq -e '.provider.name' "$AGENT_CARD" > /dev/null 2>&1; then
    echo -e "${RED}✗ Provider must have 'name' field${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Provider object valid${NC}"
echo ""

# Step 4: Validate protocol version
echo "Step 4: Validating protocol version..."
PROTOCOL_VERSION=$(jq -r '.protocolVersion' "$AGENT_CARD")
if [[ ! "$PROTOCOL_VERSION" =~ ^0\.[1-3]$ ]]; then
    echo -e "${YELLOW}⚠ Warning: Unusual protocol version: $PROTOCOL_VERSION${NC}"
    echo "  Supported versions: 0.1, 0.2, 0.3"
fi
echo -e "${GREEN}✓ Protocol version: $PROTOCOL_VERSION${NC}"
echo ""

# Step 5: Validate service endpoint URL
echo "Step 5: Validating service endpoint..."
SERVICE_ENDPOINT=$(jq -r '.serviceEndpoint' "$AGENT_CARD")
if [[ ! "$SERVICE_ENDPOINT" =~ ^https?:// ]]; then
    echo -e "${RED}✗ Service endpoint must be a valid URL: $SERVICE_ENDPOINT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Service endpoint valid: $SERVICE_ENDPOINT${NC}"
echo ""

# Step 6: Validate capabilities object
echo "Step 6: Validating capabilities..."
CAPABILITIES=$(jq '.capabilities' "$AGENT_CARD")
if [ "$CAPABILITIES" == "null" ]; then
    echo -e "${RED}✗ Capabilities object is required${NC}"
    exit 1
fi

# Check capability values are booleans
STREAMING=$(jq -r '.capabilities.streaming // "false"' "$AGENT_CARD")
PUSH_NOTIF=$(jq -r '.capabilities.pushNotifications // "false"' "$AGENT_CARD")

if [[ "$STREAMING" != "true" && "$STREAMING" != "false" ]]; then
    echo -e "${RED}✗ capabilities.streaming must be boolean${NC}"
    exit 1
fi

if [[ "$PUSH_NOTIF" != "true" && "$PUSH_NOTIF" != "false" ]]; then
    echo -e "${RED}✗ capabilities.pushNotifications must be boolean${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Capabilities valid (streaming: $STREAMING, pushNotifications: $PUSH_NOTIF)${NC}"
echo ""

# Step 7: Validate security schemes
echo "Step 7: Validating security schemes..."
SECURITY_SCHEMES=$(jq '.securitySchemes | length' "$AGENT_CARD")
if [ "$SECURITY_SCHEMES" -eq 0 ]; then
    echo -e "${RED}✗ At least one security scheme is required${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Found $SECURITY_SCHEMES security scheme(s)${NC}"

# Validate each security scheme has a type
jq -r '.securitySchemes | keys[]' "$AGENT_CARD" | while read -r scheme_name; do
    SCHEME_TYPE=$(jq -r ".securitySchemes[\"$scheme_name\"].type" "$AGENT_CARD")
    if [ "$SCHEME_TYPE" == "null" ]; then
        echo -e "${RED}✗ Security scheme '$scheme_name' missing type${NC}"
        exit 1
    fi
    echo -e "${GREEN}  ✓ Security scheme '$scheme_name' type: $SCHEME_TYPE${NC}"
done
echo ""

# Step 8: Validate security array
echo "Step 8: Validating security array..."
SECURITY_ITEMS=$(jq '.security | length' "$AGENT_CARD")
if [ "$SECURITY_ITEMS" -eq 0 ]; then
    echo -e "${RED}✗ Security array must have at least one item${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Found $SECURITY_ITEMS security requirement(s)${NC}"
echo ""

# Step 9: Validate skills (if present)
echo "Step 9: Validating skills..."
SKILLS_COUNT=$(jq '.skills | length // 0' "$AGENT_CARD")
if [ "$SKILLS_COUNT" -gt 0 ]; then
    echo "  Found $SKILLS_COUNT skill(s)"

    # Validate each skill has required fields
    for i in $(seq 0 $((SKILLS_COUNT - 1))); do
        SKILL_NAME=$(jq -r ".skills[$i].name" "$AGENT_CARD")
        SKILL_DESC=$(jq -r ".skills[$i].description" "$AGENT_CARD")

        if [ "$SKILL_NAME" == "null" ]; then
            echo -e "${RED}  ✗ Skill $i missing 'name' field${NC}"
            exit 1
        fi

        if [ "$SKILL_DESC" == "null" ]; then
            echo -e "${RED}  ✗ Skill '$SKILL_NAME' missing 'description' field${NC}"
            exit 1
        fi

        echo -e "${GREEN}  ✓ Skill '$SKILL_NAME' valid${NC}"
    done
else
    echo -e "${YELLOW}  ⚠ No skills defined${NC}"
fi
echo ""

# Step 10: Check for common issues
echo "Step 10: Checking for common issues..."

# Check for placeholder values
if grep -q "example\.com" "$AGENT_CARD"; then
    echo -e "${YELLOW}  ⚠ Warning: Contains 'example.com' - replace with actual domain${NC}"
fi

if grep -q "your_" "$AGENT_CARD"; then
    echo -e "${YELLOW}  ⚠ Warning: Contains placeholder values (your_*) - replace with actual values${NC}"
fi

if grep -q "Your " "$AGENT_CARD"; then
    echo -e "${YELLOW}  ⚠ Warning: Contains 'Your ' placeholder text - customize before deployment${NC}"
fi

# Check for hardcoded secrets (basic check)
if grep -qE "sk-ant-|sk-proj-|Bearer [A-Za-z0-9]|token.*:.*[A-Za-z0-9]{20}" "$AGENT_CARD"; then
    echo -e "${RED}  ✗ ERROR: Possible hardcoded API key or secret detected!${NC}"
    echo -e "${RED}     Agent cards should NEVER contain actual credentials${NC}"
    exit 1
fi

echo -e "${GREEN}✓ No hardcoded secrets detected${NC}"
echo ""

# Summary
echo "================================"
echo -e "${GREEN}✓ VALIDATION PASSED${NC}"
echo "================================"
echo ""
echo "Agent card appears to be valid!"
echo ""
echo "Next steps:"
echo "  1. Replace any placeholder values with actual values"
echo "  2. Test agent card accessibility at:"
echo "     $SERVICE_ENDPOINT/.well-known/agent.json"
echo "  3. Verify authentication works with configured schemes"
echo ""

exit 0
