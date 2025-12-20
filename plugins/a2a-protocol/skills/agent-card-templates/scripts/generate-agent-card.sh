#!/bin/bash

# generate-agent-card.sh
# Interactive agent card generator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
TEMPLATE="basic"
OUTPUT_FILE="agent-card.json"
INTERACTIVE=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --template TYPE       Template type (basic|multi-capability|authenticated|streaming)"
            echo "  --output FILE         Output file path (default: agent-card.json)"
            echo "  --non-interactive     Use template defaults without prompts"
            echo "  --help                Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate template type
case $TEMPLATE in
    basic)
        TEMPLATE_FILE="$TEMPLATES_DIR/basic-agent-card.json"
        ;;
    multi-capability|multi)
        TEMPLATE_FILE="$TEMPLATES_DIR/multi-capability-agent-card.json"
        ;;
    authenticated|auth)
        TEMPLATE_FILE="$TEMPLATES_DIR/authenticated-agent-card.json"
        ;;
    streaming|stream)
        TEMPLATE_FILE="$TEMPLATES_DIR/streaming-agent-card.json"
        ;;
    *)
        echo -e "${YELLOW}Error: Invalid template type: $TEMPLATE${NC}"
        echo "Valid types: basic, multi-capability, authenticated, streaming"
        exit 1
        ;;
esac

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found: $TEMPLATE_FILE"
    exit 1
fi

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}A2A Agent Card Generator${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Template: $TEMPLATE"
echo "Output: $OUTPUT_FILE"
echo ""

if [ "$INTERACTIVE" = true ]; then
    # Interactive mode - prompt for values
    echo -e "${GREEN}Please provide the following information:${NC}"
    echo ""

    read -p "Agent ID (e.g., urn:example:agent:my-agent): " AGENT_ID
    read -p "Agent Name: " AGENT_NAME
    read -p "Agent Description: " AGENT_DESC
    read -p "Agent Version (e.g., 1.0.0): " AGENT_VERSION
    read -p "Service Endpoint (e.g., https://api.example.com/agent): " SERVICE_ENDPOINT
    echo ""

    read -p "Provider Name: " PROVIDER_NAME
    read -p "Provider Email: " PROVIDER_EMAIL
    read -p "Provider URL: " PROVIDER_URL
    echo ""

    read -p "Support streaming? (yes/no) [no]: " STREAMING
    STREAMING=${STREAMING:-no}
    if [[ "$STREAMING" =~ ^[Yy] ]]; then
        STREAMING_VALUE="true"
    else
        STREAMING_VALUE="false"
    fi

    read -p "Support push notifications? (yes/no) [no]: " PUSH_NOTIF
    PUSH_NOTIF=${PUSH_NOTIF:-no}
    if [[ "$PUSH_NOTIF" =~ ^[Yy] ]]; then
        PUSH_NOTIF_VALUE="true"
    else
        PUSH_NOTIF_VALUE="false"
    fi

    echo ""
    echo "Generating agent card..."

    # Copy template and replace values
    cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

    # Use sed to replace placeholder values (works on both macOS and Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|urn:example:agent:.*\"|$AGENT_ID\"|" "$OUTPUT_FILE"
        sed -i '' "s|\"name\": \".*Agent.*\"|\"name\": \"$AGENT_NAME\"|" "$OUTPUT_FILE"
        sed -i '' "s|\"description\": \".*\"|\"description\": \"$AGENT_DESC\"|g" "$OUTPUT_FILE"
        sed -i '' "s|\"version\": \".*\"|\"version\": \"$AGENT_VERSION\"|" "$OUTPUT_FILE"
        sed -i '' "s|https://api.*example.com/[^\"]*|$SERVICE_ENDPOINT|g" "$OUTPUT_FILE"
        sed -i '' "s|\"name\": \"Your.*\"|\"name\": \"$PROVIDER_NAME\"|" "$OUTPUT_FILE"
        sed -i '' "s|support@.*example.com|$PROVIDER_EMAIL|g" "$OUTPUT_FILE"
        sed -i '' "s|https://.*example.com\"|\"$PROVIDER_URL\"|" "$OUTPUT_FILE"
        sed -i '' "s|\"streaming\": [^,]*|\"streaming\": $STREAMING_VALUE|" "$OUTPUT_FILE"
        sed -i '' "s|\"pushNotifications\": [^}]*|\"pushNotifications\": $PUSH_NOTIF_VALUE|" "$OUTPUT_FILE"
    else
        # Linux
        sed -i "s|urn:example:agent:.*\"|$AGENT_ID\"|" "$OUTPUT_FILE"
        sed -i "s|\"name\": \".*Agent.*\"|\"name\": \"$AGENT_NAME\"|" "$OUTPUT_FILE"
        sed -i "s|\"description\": \".*\"|\"description\": \"$AGENT_DESC\"|g" "$OUTPUT_FILE"
        sed -i "s|\"version\": \".*\"|\"version\": \"$AGENT_VERSION\"|" "$OUTPUT_FILE"
        sed -i "s|https://api.*example.com/[^\"]*|$SERVICE_ENDPOINT|g" "$OUTPUT_FILE"
        sed -i "s|\"name\": \"Your.*\"|\"name\": \"$PROVIDER_NAME\"|" "$OUTPUT_FILE"
        sed -i "s|support@.*example.com|$PROVIDER_EMAIL|g" "$OUTPUT_FILE"
        sed -i "s|https://.*example.com\"|\"$PROVIDER_URL\"|" "$OUTPUT_FILE"
        sed -i "s|\"streaming\": [^,]*|\"streaming\": $STREAMING_VALUE|" "$OUTPUT_FILE"
        sed -i "s|\"pushNotifications\": [^}]*|\"pushNotifications\": $PUSH_NOTIF_VALUE|" "$OUTPUT_FILE"
    fi

else
    # Non-interactive mode - just copy template
    echo "Copying template to $OUTPUT_FILE..."
    cp "$TEMPLATE_FILE" "$OUTPUT_FILE"
    echo -e "${YELLOW}Note: Template placeholders preserved. Edit manually or run in interactive mode.${NC}"
fi

echo ""
echo -e "${GREEN}✓ Agent card generated successfully!${NC}"
echo ""
echo "Output file: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Review and customize the generated agent card"
echo "  2. Replace any remaining placeholder values"
echo "  3. Define your agent's skills in the 'skills' array"
echo "  4. Validate: ./scripts/validate-agent-card.sh $OUTPUT_FILE"
echo "  5. Test: ./scripts/test-agent-card.sh $OUTPUT_FILE"
echo "  6. Deploy to: \$SERVICE_ENDPOINT/.well-known/agent.json"
echo ""
echo -e "${BLUE}================================${NC}"
echo ""

exit 0
