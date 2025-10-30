#!/usr/bin/env bash
# Test MCP server connection and discover available tools
# Usage: ./test-mcp-connection.sh <server-url> [--token TOKEN]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <server-url> [--token TOKEN]${NC}"
  exit 1
fi

SERVER_URL="$1"
TOKEN=""

# Parse optional token
if [[ $# -eq 3 ]] && [[ "$2" == "--token" ]]; then
  TOKEN="$3"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  MCP Server Connection Test                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Testing connection to: ${YELLOW}$SERVER_URL${NC}"
echo ""

# Validate URL format
if [[ ! "$SERVER_URL" =~ ^https?:// ]]; then
  echo -e "${RED}✗ Invalid URL format. Must start with http:// or https://${NC}"
  exit 1
fi

# Security warning for HTTP
if [[ "$SERVER_URL" =~ ^http:// ]]; then
  echo -e "${YELLOW}⚠ Warning: Using HTTP (not HTTPS). This is insecure for production.${NC}"
  echo ""
fi

# Test 1: Basic connectivity
echo -e "${BLUE}[1/4] Testing basic connectivity...${NC}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --connect-timeout 10 \
  --max-time 30 \
  "${SERVER_URL}" || echo "000")

if [[ "$HTTP_CODE" == "000" ]]; then
  echo -e "${RED}✗ Connection failed - server unreachable${NC}"
  echo "  Possible causes:"
  echo "  - Server is down or URL is incorrect"
  echo "  - Network/firewall blocking connection"
  echo "  - DNS resolution failure"
  exit 1
elif [[ "$HTTP_CODE" =~ ^(401|403)$ ]]; then
  echo -e "${YELLOW}✓ Server reachable but requires authentication${NC}"
  echo "  HTTP Status: $HTTP_CODE"
elif [[ "$HTTP_CODE" =~ ^(200|201|204)$ ]]; then
  echo -e "${GREEN}✓ Server reachable and responding${NC}"
  echo "  HTTP Status: $HTTP_CODE"
else
  echo -e "${YELLOW}⚠ Server responded with status: $HTTP_CODE${NC}"
fi
echo ""

# Test 2: MCP protocol support
echo -e "${BLUE}[2/4] Checking MCP protocol support...${NC}"

# Build headers
HEADERS=(-H "Content-Type: application/json")
if [[ -n "$TOKEN" ]]; then
  HEADERS+=(-H "Authorization: Bearer $TOKEN")
fi

# Try to list tools (MCP protocol endpoint)
TOOLS_RESPONSE=$(curl -s -X POST \
  "${HEADERS[@]}" \
  --connect-timeout 10 \
  --max-time 30 \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  "${SERVER_URL}" 2>&1 || echo '{"error":"request_failed"}')

# Check if response is valid JSON
if echo "$TOOLS_RESPONSE" | jq empty 2>/dev/null; then
  echo -e "${GREEN}✓ Server supports MCP protocol${NC}"

  # Check for error in response
  if echo "$TOOLS_RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$TOOLS_RESPONSE" | jq -r '.error.message // .error')
    echo -e "${YELLOW}⚠ Server returned error: $ERROR_MSG${NC}"
  fi
else
  echo -e "${YELLOW}⚠ Could not verify MCP protocol support${NC}"
  echo "  Response may not be valid JSON-RPC"
fi
echo ""

# Test 3: Tool discovery
echo -e "${BLUE}[3/4] Discovering available tools...${NC}"

if echo "$TOOLS_RESPONSE" | jq -e '.result.tools' >/dev/null 2>&1; then
  TOOL_COUNT=$(echo "$TOOLS_RESPONSE" | jq '.result.tools | length')
  echo -e "${GREEN}✓ Found $TOOL_COUNT tools${NC}"
  echo ""

  # Display tools in formatted table
  echo "Available Tools:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo "$TOOLS_RESPONSE" | jq -r '.result.tools[] |
    "  • \(.name)\n    Description: \(.description // "N/A")\n    Schema: \(.inputSchema.type // "N/A")"' | head -n 50

  if [[ $TOOL_COUNT -gt 10 ]]; then
    echo ""
    echo -e "${YELLOW}(Showing first 10 tools. Total: $TOOL_COUNT)${NC}"
  fi
else
  echo -e "${YELLOW}⚠ No tools discovered${NC}"
  echo "  This may be normal for some MCP servers"
fi
echo ""

# Test 4: Authentication check
echo -e "${BLUE}[4/4] Checking authentication...${NC}"

if [[ -n "$TOKEN" ]]; then
  echo -e "${GREEN}✓ Authentication token provided${NC}"

  # Test with and without token to verify it's being used
  NO_AUTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Content-Type: application/json" \
    --connect-timeout 5 \
    "${SERVER_URL}" || echo "000")

  if [[ "$NO_AUTH_CODE" =~ ^(401|403)$ ]] && [[ "$HTTP_CODE" =~ ^(200|201|204)$ ]]; then
    echo -e "${GREEN}✓ Token authentication working correctly${NC}"
  else
    echo -e "${YELLOW}⚠ Could not verify token effectiveness${NC}"
  fi
else
  echo -e "${YELLOW}⚠ No authentication token provided${NC}"
  echo "  If server requires auth, provide with: --token YOUR_TOKEN"
fi
echo ""

# Connection summary
echo -e "${BLUE}Connection Test Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CONNECTIVITY="✓"
PROTOCOL="✓"
TOOLS="✓"
AUTH="✓"

if [[ "$HTTP_CODE" == "000" ]]; then
  CONNECTIVITY="✗"
fi

if ! echo "$TOOLS_RESPONSE" | jq empty 2>/dev/null; then
  PROTOCOL="⚠"
fi

if ! echo "$TOOLS_RESPONSE" | jq -e '.result.tools' >/dev/null 2>&1; then
  TOOLS="⚠"
fi

if [[ -z "$TOKEN" ]] && [[ "$HTTP_CODE" =~ ^(401|403)$ ]]; then
  AUTH="✗"
fi

echo -e "  Connectivity:     $CONNECTIVITY"
echo -e "  MCP Protocol:     $PROTOCOL"
echo -e "  Tool Discovery:   $TOOLS"
echo -e "  Authentication:   $AUTH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Overall result
if [[ "$CONNECTIVITY" == "✓" ]] && [[ "$PROTOCOL" == "✓" ]]; then
  echo -e "${GREEN}✓ MCP server is ready for integration!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Configure in ElevenLabs: https://elevenlabs.io/app/agents/integrations"
  echo "  2. Set up approval modes: bash scripts/configure-mcp.sh"
  echo "  3. Attach to agent: Use templates/agent-mcp-config.json.template"
  exit 0
else
  echo -e "${YELLOW}⚠ MCP server has issues that need attention${NC}"
  echo ""
  echo "Troubleshooting steps:"
  echo "  1. Verify server URL is correct"
  echo "  2. Check server is running and accessible"
  echo "  3. Verify authentication token if required"
  echo "  4. Review server logs for errors"
  exit 1
fi
