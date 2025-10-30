#!/usr/bin/env bash
# Quick setup for Zapier MCP server integration
# Usage: ./setup-zapier-mcp.sh [--token TOKEN]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ZAPIER_TOKEN=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --token)
      ZAPIER_TOKEN="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Zapier MCP Server Setup                                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Zapier MCP provides access to hundreds of tools and services!${NC}"
echo ""

# Get Zapier MCP URL
echo -e "${BLUE}Step 1: Zapier MCP Configuration${NC}"
echo ""

if [[ -z "$ZAPIER_TOKEN" ]]; then
  echo "To get your Zapier MCP server URL and token:"
  echo "  1. Visit: https://zapier.com/mcp"
  echo "  2. Sign in to your Zapier account"
  echo "  3. Create or access your MCP server"
  echo "  4. Copy the server URL and authentication token"
  echo ""

  read -p "Enter your Zapier MCP server URL: " ZAPIER_URL
  read -sp "Enter your Zapier MCP token: " ZAPIER_TOKEN
  echo ""
else
  read -p "Enter your Zapier MCP server URL: " ZAPIER_URL
fi

# Validate URL
if [[ ! "$ZAPIER_URL" =~ ^https:// ]]; then
  echo -e "${RED}Error: Zapier MCP URL must use HTTPS${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Security Configuration${NC}"
echo ""

# Recommend Always Ask for Zapier
echo "Zapier provides access to many powerful tools."
echo "Recommended approval mode: Always Ask (maximum security)"
echo ""
echo "Available modes:"
echo "  1) Always Ask (Recommended)"
echo "  2) Fine-Grained (Configure specific tools)"
echo "  3) No Approval (Not recommended for Zapier)"
read -p "Choice (1-3, default=1): " APPROVAL_CHOICE

case ${APPROVAL_CHOICE:-1} in
  1) APPROVAL_MODE="always_ask" ;;
  2) APPROVAL_MODE="fine_grained" ;;
  3)
    echo -e "${YELLOW}Warning: No approval mode is risky for Zapier integration${NC}"
    read -p "Are you absolutely sure? (type 'yes' to confirm): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
      APPROVAL_MODE="always_ask"
      echo -e "${GREEN}Using 'Always Ask' mode for safety${NC}"
    else
      APPROVAL_MODE="no_approval"
    fi
    ;;
  *)
    APPROVAL_MODE="always_ask"
    echo -e "${GREEN}Using default 'Always Ask' mode${NC}"
    ;;
esac

echo ""
echo -e "${BLUE}Step 3: Creating Configuration${NC}"
echo ""

# Create config directory
CONFIG_DIR=".elevenlabs"
CONFIG_FILE="$CONFIG_DIR/zapier-mcp-config.json"
mkdir -p "$CONFIG_DIR"

# Build Zapier MCP configuration
cat > "$CONFIG_FILE" <<EOF
{
  "mcpServers": {
    "zapier-mcp": {
      "name": "zapier-mcp",
      "description": "Access to hundreds of tools via Zapier",
      "url": "${ZAPIER_URL}",
      "transport": "sse",
      "approvalMode": "${APPROVAL_MODE}",
      "headers": {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${ZAPIER_TOKEN}",
        "User-Agent": "ElevenLabs-Agent/1.0"
      },
      "enabled": true,
      "createdAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "zapierConfig": {
        "rateLimiting": {
          "requestsPerMinute": 60,
          "burstLimit": 10
        },
        "caching": {
          "enabled": true,
          "ttlSeconds": 300
        }
      }
    }
  },
  "security": {
    "defaultApprovalMode": "${APPROVAL_MODE}",
    "recommendedToolSettings": {
      "readOnlyTools": {
        "approval": "auto_approved",
        "examples": ["zapier_weather_get", "zapier_calendar_read", "zapier_search"]
      },
      "dataModificationTools": {
        "approval": "requires_approval",
        "examples": ["zapier_email_send", "zapier_calendar_create", "zapier_spreadsheet_update"]
      },
      "restrictedTools": {
        "approval": "disabled",
        "examples": ["zapier_file_delete", "zapier_admin_action"]
      }
    }
  }
}
EOF

echo -e "${GREEN}✓ Configuration saved to: $CONFIG_FILE${NC}"
echo ""

# Store token securely
echo -e "${BLUE}Step 4: Secure Token Storage${NC}"
echo ""

ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
  touch "$ENV_FILE"
fi

# Check if token already exists in .env
if grep -q "ZAPIER_MCP_TOKEN=" "$ENV_FILE" 2>/dev/null; then
  echo -e "${YELLOW}ZAPIER_MCP_TOKEN already exists in .env${NC}"
  read -p "Replace with new token? (y/n): " REPLACE
  if [[ "$REPLACE" =~ ^[Yy]$ ]]; then
    sed -i.bak '/ZAPIER_MCP_TOKEN=/d' "$ENV_FILE"
    echo "ZAPIER_MCP_TOKEN=${ZAPIER_TOKEN}" >> "$ENV_FILE"
    echo -e "${GREEN}✓ Token updated in .env${NC}"
  fi
else
  echo "ZAPIER_MCP_TOKEN=${ZAPIER_TOKEN}" >> "$ENV_FILE"
  echo -e "${GREEN}✓ Token added to .env${NC}"
fi

# Ensure .env is in .gitignore
if [[ ! -f ".gitignore" ]] || ! grep -q "^\.env$" ".gitignore" 2>/dev/null; then
  echo ".env" >> .gitignore
  echo -e "${GREEN}✓ Added .env to .gitignore${NC}"
fi

echo ""

# Test connection
echo -e "${BLUE}Step 5: Testing Zapier MCP Connection${NC}"
echo ""

TEST_SCRIPT="$(dirname "$0")/test-mcp-connection.sh"

if [[ -f "$TEST_SCRIPT" ]]; then
  bash "$TEST_SCRIPT" "$ZAPIER_URL" --token "$ZAPIER_TOKEN"
else
  echo -e "${YELLOW}⚠ Test script not found, skipping connection test${NC}"
  echo "  Test manually: bash scripts/test-mcp-connection.sh \"$ZAPIER_URL\" --token \"$ZAPIER_TOKEN\""
fi

echo ""

# Configuration summary
echo -e "${BLUE}Zapier MCP Configuration Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Server Name:       ${GREEN}zapier-mcp${NC}"
echo -e "Server URL:        ${GREEN}${ZAPIER_URL}${NC}"
echo -e "Approval Mode:     ${GREEN}${APPROVAL_MODE}${NC}"
echo -e "Authentication:    ${GREEN}Configured${NC}"
echo -e "Config File:       ${GREEN}${CONFIG_FILE}${NC}"
echo -e "Token Storage:     ${GREEN}.env (secured)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Display common Zapier tools
echo -e "${BLUE}Common Zapier MCP Tools:${NC}"
echo ""
echo "Email & Communication:"
echo "  • zapier_gmail_send - Send emails via Gmail"
echo "  • zapier_slack_message - Post Slack messages"
echo "  • zapier_discord_message - Send Discord messages"
echo ""
echo "Calendar & Scheduling:"
echo "  • zapier_calendar_create - Create calendar events"
echo "  • zapier_calendar_read - Read calendar entries"
echo "  • zapier_calendar_update - Update existing events"
echo ""
echo "Data & Spreadsheets:"
echo "  • zapier_sheets_append - Add rows to Google Sheets"
echo "  • zapier_sheets_read - Read spreadsheet data"
echo "  • zapier_airtable_create - Create Airtable records"
echo ""
echo "Search & Knowledge:"
echo "  • zapier_search_web - Web search"
echo "  • zapier_weather_get - Weather information"
echo "  • zapier_knowledge_base - Knowledge base queries"
echo ""

# Next steps
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Add to ElevenLabs Dashboard:"
echo "   • Visit: https://elevenlabs.io/app/agents/integrations"
echo "   • Add Custom MCP Server"
echo "   • Use configuration from: $CONFIG_FILE"
echo ""
echo "2. Create Agent with Zapier Tools:"
echo "   • Use template: templates/agent-mcp-config.json.template"
echo "   • Reference server: 'zapier-mcp'"
echo ""
echo "3. Configure Tool Approvals (if Fine-Grained):"
echo "   • Use template: templates/tool-approval-config.json.template"
echo "   • Auto-approve safe read-only tools"
echo "   • Require approval for data modification"
echo ""
echo "4. Test with Example Agent:"
echo "   • See: examples/zapier-mcp-agent/"
echo "   • Includes common use cases and workflows"
echo ""

if [[ "$APPROVAL_MODE" == "always_ask" ]]; then
  echo -e "${GREEN}✓ Using 'Always Ask' mode - Maximum security enabled!${NC}"
  echo "  All tool uses will require your explicit approval"
elif [[ "$APPROVAL_MODE" == "fine_grained" ]]; then
  echo -e "${YELLOW}⚠ Fine-Grained mode requires additional configuration${NC}"
  echo "  Configure tool-specific approvals: templates/tool-approval-config.json.template"
else
  echo -e "${RED}⚠ No Approval mode - Ensure you trust all Zapier workflows${NC}"
fi

echo ""
echo -e "${GREEN}✓ Zapier MCP setup complete!${NC}"
echo ""
echo "Access hundreds of tools through voice agents with Zapier MCP!"
