#!/usr/bin/env bash
# Rotate MCP server authentication tokens securely
# Usage: ./rotate-mcp-tokens.sh <server-name> [--new-token TOKEN]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <server-name> [--new-token TOKEN]${NC}"
  echo ""
  echo "Examples:"
  echo "  $0 zapier-mcp"
  echo "  $0 custom-server --new-token sk_new_token_here"
  exit 1
fi

SERVER_NAME="$1"
NEW_TOKEN=""
CONFIG_FILE=".elevenlabs/mcp-config.json"

# Parse optional new token
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --new-token)
      NEW_TOKEN="$2"
      shift 2
      ;;
    --config-file)
      CONFIG_FILE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  MCP Token Rotation                                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
  exit 1
fi

# Check if server exists
if ! jq -e ".mcpServers[\"$SERVER_NAME\"]" "$CONFIG_FILE" >/dev/null 2>&1; then
  echo -e "${RED}✗ Server '$SERVER_NAME' not found in configuration${NC}"
  echo ""
  echo "Available servers:"
  jq -r '.mcpServers | keys[]' "$CONFIG_FILE" | sed 's/^/  • /'
  exit 1
fi

echo -e "Rotating token for server: ${YELLOW}$SERVER_NAME${NC}"
echo ""

# Get current token (masked)
CURRENT_TOKEN=$(jq -r ".mcpServers[\"$SERVER_NAME\"].headers.Authorization // \"none\"" "$CONFIG_FILE")

if [[ "$CURRENT_TOKEN" == "none" ]]; then
  echo -e "${YELLOW}⚠ No authentication token currently configured${NC}"
  echo ""
else
  # Mask current token
  if [[ "$CURRENT_TOKEN" =~ ^Bearer\ (.+)$ ]]; then
    TOKEN_VALUE="${BASH_REMATCH[1]}"
    MASKED_TOKEN="Bearer ${TOKEN_VALUE:0:8}...${TOKEN_VALUE: -4}"
    echo -e "Current token: ${YELLOW}$MASKED_TOKEN${NC}"
  else
    echo -e "Current token: ${YELLOW}[configured]${NC}"
  fi
  echo ""
fi

# Get new token if not provided
if [[ -z "$NEW_TOKEN" ]]; then
  echo "Enter new authentication token:"
  echo "(This will replace the current token for $SERVER_NAME)"
  echo ""
  read -sp "New token: " NEW_TOKEN
  echo ""
  echo ""

  if [[ -z "$NEW_TOKEN" ]]; then
    echo -e "${RED}✗ No token provided${NC}"
    exit 1
  fi
fi

# Validate token format (basic check)
if [[ ${#NEW_TOKEN} -lt 10 ]]; then
  echo -e "${YELLOW}⚠ Warning: Token seems unusually short${NC}"
  read -p "Continue anyway? (y/n): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Token rotation cancelled"
    exit 0
  fi
fi

# Backup current configuration
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Configuration backed up to: $BACKUP_FILE${NC}"
echo ""

# Update token in configuration
TEMP_FILE=$(mktemp)

jq --arg server "$SERVER_NAME" --arg token "$NEW_TOKEN" '
  .mcpServers[$server].headers.Authorization = ("Bearer " + $token) |
  .mcpServers[$server].lastTokenRotation = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
' "$CONFIG_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$CONFIG_FILE"

echo -e "${GREEN}✓ Token updated in configuration${NC}"
echo ""

# Update .env file if exists
ENV_FILE=".env"
ENV_VAR_NAME="${SERVER_NAME^^}_MCP_TOKEN"
ENV_VAR_NAME="${ENV_VAR_NAME//-/_}"

if [[ -f "$ENV_FILE" ]]; then
  echo "Updating environment variable: $ENV_VAR_NAME"

  if grep -q "^${ENV_VAR_NAME}=" "$ENV_FILE"; then
    # Update existing
    sed -i.bak "s/^${ENV_VAR_NAME}=.*/${ENV_VAR_NAME}=${NEW_TOKEN}/" "$ENV_FILE"
    echo -e "${GREEN}✓ Updated $ENV_VAR_NAME in .env${NC}"
  else
    # Add new
    echo "${ENV_VAR_NAME}=${NEW_TOKEN}" >> "$ENV_FILE"
    echo -e "${GREEN}✓ Added $ENV_VAR_NAME to .env${NC}"
  fi
  echo ""
fi

# Test new token
echo -e "${BLUE}Testing new token...${NC}"
echo ""

SERVER_URL=$(jq -r ".mcpServers[\"$SERVER_NAME\"].url" "$CONFIG_FILE")

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $NEW_TOKEN" \
  --connect-timeout 5 \
  --max-time 10 \
  "${SERVER_URL}" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" =~ ^(200|201|204)$ ]]; then
  echo -e "${GREEN}✓ New token is valid and working!${NC}"
  echo "  Server responded with HTTP $HTTP_CODE"
elif [[ "$HTTP_CODE" =~ ^(401|403)$ ]]; then
  echo -e "${RED}✗ Authentication failed with new token${NC}"
  echo "  Server responded with HTTP $HTTP_CODE"
  echo ""
  echo "Rolling back to previous configuration..."
  cp "$BACKUP_FILE" "$CONFIG_FILE"
  echo -e "${YELLOW}✓ Configuration restored from backup${NC}"
  exit 1
elif [[ "$HTTP_CODE" == "000" ]]; then
  echo -e "${YELLOW}⚠ Cannot reach server (connection failed)${NC}"
  echo "  Token updated but could not verify"
else
  echo -e "${YELLOW}⚠ Server responded with HTTP $HTTP_CODE${NC}"
  echo "  Token updated but response unexpected"
fi

echo ""

# Display rotation summary
echo -e "${BLUE}Token Rotation Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Server:           ${GREEN}$SERVER_NAME${NC}"
echo -e "Status:           ${GREEN}Token rotated${NC}"
echo -e "Backup:           $BACKUP_FILE"
echo -e "Config:           $CONFIG_FILE"
if [[ -f "$ENV_FILE" ]]; then
  echo -e "Environment:      ${GREEN}Updated${NC}"
fi
echo -e "Timestamp:        $(date)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Security recommendations
echo -e "${BLUE}Security Recommendations:${NC}"
echo ""
echo "1. Immediately revoke the old token in your MCP provider dashboard"
echo "2. Update any other applications using the old token"
echo "3. Test your ElevenLabs agents to ensure they work with new token"
echo "4. Schedule next token rotation (recommended: every 90 days)"
echo "5. Monitor logs for any authentication failures"
echo ""

# Log the rotation
LOG_FILE=".elevenlabs/mcp-security.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] Token rotated for $SERVER_NAME" >> "$LOG_FILE"

echo -e "${GREEN}✓ Token rotation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Revoke old token at your MCP provider"
echo "  2. Test agent functionality"
echo "  3. Monitor: bash scripts/monitor-mcp-health.sh"
