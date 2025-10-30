#!/usr/bin/env bash
# Configure MCP server integration for ElevenLabs Agents Platform
# Usage: ./configure-mcp.sh [--server-name NAME] [--server-url URL] [--token TOKEN]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CONFIG_FILE=".elevenlabs/mcp-config.json"
INTERACTIVE=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --server-name)
      SERVER_NAME="$2"
      shift 2
      ;;
    --server-url)
      SERVER_URL="$2"
      shift 2
      ;;
    --token)
      SECRET_TOKEN="$2"
      shift 2
      ;;
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    --config-file)
      CONFIG_FILE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ElevenLabs MCP Server Configuration                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Interactive mode - gather configuration
if [[ "$INTERACTIVE" == "true" ]]; then
  echo -e "${YELLOW}This wizard will help you configure an MCP server integration.${NC}"
  echo ""

  # Get server name
  if [[ -z "${SERVER_NAME:-}" ]]; then
    read -p "Enter MCP server name (e.g., 'zapier-mcp', 'custom-tools'): " SERVER_NAME
  fi

  # Get server URL
  if [[ -z "${SERVER_URL:-}" ]]; then
    read -p "Enter MCP server URL (must be HTTPS): " SERVER_URL
  fi

  # Validate HTTPS
  if [[ ! "$SERVER_URL" =~ ^https:// ]]; then
    echo -e "${RED}Error: Server URL must use HTTPS for security${NC}"
    exit 1
  fi

  # Get optional secret token
  if [[ -z "${SECRET_TOKEN:-}" ]]; then
    read -sp "Enter secret token (optional, press Enter to skip): " SECRET_TOKEN
    echo ""
  fi

  # Get server description
  read -p "Enter server description: " SERVER_DESCRIPTION

  # Get transport method
  echo ""
  echo "Select transport method:"
  echo "  1) Server-Sent Events (SSE) - Recommended"
  echo "  2) HTTP Streamable"
  read -p "Choice (1-2): " TRANSPORT_CHOICE

  case $TRANSPORT_CHOICE in
    1) TRANSPORT_METHOD="sse" ;;
    2) TRANSPORT_METHOD="http" ;;
    *)
      echo -e "${RED}Invalid choice. Defaulting to SSE.${NC}"
      TRANSPORT_METHOD="sse"
      ;;
  esac

  # Get approval mode
  echo ""
  echo "Select default approval mode:"
  echo "  1) Always Ask (Recommended - Maximum Security)"
  echo "  2) Fine-Grained Approval (Configure per tool)"
  echo "  3) No Approval (Only for trusted servers)"
  read -p "Choice (1-3): " APPROVAL_CHOICE

  case $APPROVAL_CHOICE in
    1) APPROVAL_MODE="always_ask" ;;
    2) APPROVAL_MODE="fine_grained" ;;
    3)
      echo -e "${YELLOW}Warning: No approval mode reduces security. Use only with trusted servers.${NC}"
      read -p "Are you sure? (yes/no): " CONFIRM
      if [[ "$CONFIRM" != "yes" ]]; then
        APPROVAL_MODE="always_ask"
        echo -e "${GREEN}Defaulting to 'Always Ask' mode.${NC}"
      else
        APPROVAL_MODE="no_approval"
      fi
      ;;
    *)
      echo -e "${RED}Invalid choice. Defaulting to 'Always Ask'.${NC}"
      APPROVAL_MODE="always_ask"
      ;;
  esac
fi

# Validate required fields
if [[ -z "${SERVER_NAME:-}" ]] || [[ -z "${SERVER_URL:-}" ]]; then
  echo -e "${RED}Error: Server name and URL are required${NC}"
  exit 1
fi

# Create config directory
mkdir -p "$(dirname "$CONFIG_FILE")"

# Build configuration JSON
echo -e "${BLUE}Building configuration...${NC}"

# Build headers object
HEADERS='{
  "Content-Type": "application/json",
  "User-Agent": "ElevenLabs-Agent/1.0"
}'

if [[ -n "${SECRET_TOKEN:-}" ]]; then
  HEADERS=$(echo "$HEADERS" | jq --arg token "$SECRET_TOKEN" '. + {"Authorization": ("Bearer " + $token)}')
fi

# Build complete configuration
CONFIG=$(cat <<EOF
{
  "mcpServers": {
    "${SERVER_NAME}": {
      "name": "${SERVER_NAME}",
      "description": "${SERVER_DESCRIPTION:-MCP Server Integration}",
      "url": "${SERVER_URL}",
      "transport": "${TRANSPORT_METHOD:-sse}",
      "approvalMode": "${APPROVAL_MODE:-always_ask}",
      "headers": ${HEADERS},
      "enabled": true,
      "createdAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
  }
}
EOF
)

# If config file exists, merge with existing servers
if [[ -f "$CONFIG_FILE" ]]; then
  echo -e "${YELLOW}Existing configuration found. Merging...${NC}"
  EXISTING_CONFIG=$(cat "$CONFIG_FILE")
  CONFIG=$(echo "$EXISTING_CONFIG" | jq --argjson new "$CONFIG" '.mcpServers += $new.mcpServers')
fi

# Write configuration
echo "$CONFIG" | jq '.' > "$CONFIG_FILE"

echo -e "${GREEN}✓ Configuration saved to: $CONFIG_FILE${NC}"
echo ""

# Display configuration summary
echo -e "${BLUE}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Server Name:      ${GREEN}${SERVER_NAME}${NC}"
echo -e "Server URL:       ${GREEN}${SERVER_URL}${NC}"
echo -e "Transport:        ${GREEN}${TRANSPORT_METHOD:-sse}${NC}"
echo -e "Approval Mode:    ${GREEN}${APPROVAL_MODE:-always_ask}${NC}"
echo -e "Authentication:   ${GREEN}$([ -n "${SECRET_TOKEN:-}" ] && echo "Configured" || echo "None")${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test connection if available
echo ""
read -p "Would you like to test the connection now? (y/n): " TEST_NOW

if [[ "$TEST_NOW" =~ ^[Yy]$ ]]; then
  echo ""
  if [[ -f "$(dirname "$0")/test-mcp-connection.sh" ]]; then
    bash "$(dirname "$0")/test-mcp-connection.sh" "$SERVER_URL"
  else
    echo -e "${YELLOW}Test script not found. Run manually:${NC}"
    echo "  bash scripts/test-mcp-connection.sh \"$SERVER_URL\""
  fi
fi

# Next steps
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Test connection: bash scripts/test-mcp-connection.sh \"$SERVER_URL\""
echo "  2. Configure agent: Use templates/agent-mcp-config.json.template"
echo "  3. Set up security: Use templates/tool-approval-config.json.template"
echo "  4. Attach to agent in ElevenLabs dashboard: https://elevenlabs.io/app/agents/integrations"
echo ""

# Store credentials in environment
if [[ -n "${SECRET_TOKEN:-}" ]]; then
  ENV_VAR_NAME="${SERVER_NAME^^}_MCP_TOKEN"
  ENV_VAR_NAME="${ENV_VAR_NAME//-/_}"

  echo -e "${YELLOW}Security Recommendation:${NC}"
  echo "  Add to .env file (DO NOT commit):"
  echo "  ${ENV_VAR_NAME}=${SECRET_TOKEN}"
  echo ""
fi

echo -e "${GREEN}✓ MCP server configuration complete!${NC}"
