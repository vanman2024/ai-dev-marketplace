#!/usr/bin/env bash
# Monitor MCP server health and availability
# Usage: ./monitor-mcp-health.sh [config-file] [--continuous] [--interval SECONDS]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="${1:-.elevenlabs/mcp-config.json}"
CONTINUOUS=false
INTERVAL=30
LOG_FILE=".elevenlabs/mcp-health.log"

# Parse arguments
shift || true
while [[ $# -gt 0 ]]; do
  case $1 in
    --continuous)
      CONTINUOUS=true
      shift
      ;;
    --interval)
      INTERVAL="$2"
      shift 2
      ;;
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log_event() {
  echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $1" >> "$LOG_FILE"
}

check_server_health() {
  local SERVER_NAME=$1
  local SERVER_URL=$2
  local TOKEN=$3

  # Build headers
  local HEADERS=(-H "Content-Type: application/json")
  if [[ -n "$TOKEN" ]] && [[ "$TOKEN" != "null" ]]; then
    HEADERS+=(-H "Authorization: Bearer $TOKEN")
  fi

  # Check connectivity
  local START_TIME=$(date +%s%N)
  local HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 5 \
    --max-time 10 \
    "${HEADERS[@]}" \
    "${SERVER_URL}" 2>/dev/null || echo "000")
  local END_TIME=$(date +%s%N)
  local LATENCY=$(( (END_TIME - START_TIME) / 1000000 ))

  # Determine status
  local STATUS="DOWN"
  local COLOR=$RED

  if [[ "$HTTP_CODE" =~ ^(200|201|204)$ ]]; then
    STATUS="UP"
    COLOR=$GREEN
  elif [[ "$HTTP_CODE" =~ ^(401|403)$ ]]; then
    STATUS="AUTH_REQUIRED"
    COLOR=$YELLOW
  elif [[ "$HTTP_CODE" =~ ^(500|502|503|504)$ ]]; then
    STATUS="ERROR"
    COLOR=$RED
  fi

  # Log event
  log_event "$SERVER_NAME: $STATUS (HTTP $HTTP_CODE, ${LATENCY}ms)"

  # Display status
  echo -e "  ${COLOR}●${NC} $SERVER_NAME"
  echo "    Status: ${COLOR}${STATUS}${NC}"
  echo "    HTTP Code: $HTTP_CODE"
  echo "    Latency: ${LATENCY}ms"

  # Try to list tools for more detailed health check
  if [[ "$STATUS" == "UP" ]]; then
    local TOOLS_RESPONSE=$(curl -s -X POST \
      "${HEADERS[@]}" \
      --connect-timeout 5 \
      --max-time 10 \
      -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
      "${SERVER_URL}" 2>/dev/null || echo '{"error":"failed"}')

    if echo "$TOOLS_RESPONSE" | jq -e '.result.tools' >/dev/null 2>&1; then
      local TOOL_COUNT=$(echo "$TOOLS_RESPONSE" | jq '.result.tools | length')
      echo "    Tools Available: $TOOL_COUNT"
      log_event "$SERVER_NAME: $TOOL_COUNT tools available"
    else
      echo -e "    Tools: ${YELLOW}Cannot list${NC}"
    fi
  fi

  echo ""

  # Return status code
  [[ "$STATUS" == "UP" ]] && return 0 || return 1
}

run_health_check() {
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  MCP Server Health Check                                ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Time: $(date)"
  echo ""

  # Check if config file exists
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
    return 1
  fi

  # Get server count
  local SERVER_COUNT=$(jq '.mcpServers | length' "$CONFIG_FILE" 2>/dev/null || echo "0")

  if [[ "$SERVER_COUNT" -eq 0 ]]; then
    echo -e "${YELLOW}⚠ No MCP servers configured${NC}"
    return 0
  fi

  echo "Checking $SERVER_COUNT MCP server(s)..."
  echo ""

  local HEALTHY=0
  local UNHEALTHY=0

  # Check each server
  for SERVER in $(jq -r '.mcpServers | keys[]' "$CONFIG_FILE"); do
    SERVER_URL=$(jq -r ".mcpServers[\"$SERVER\"].url" "$CONFIG_FILE")
    TOKEN=$(jq -r ".mcpServers[\"$SERVER\"].headers.Authorization // \"null\"" "$CONFIG_FILE" | sed 's/Bearer //')

    if check_server_health "$SERVER" "$SERVER_URL" "$TOKEN"; then
      HEALTHY=$((HEALTHY + 1))
    else
      UNHEALTHY=$((UNHEALTHY + 1))
    fi
  done

  # Summary
  echo -e "${BLUE}Health Check Summary${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "  Total Servers:    $SERVER_COUNT"
  echo -e "  Healthy:          ${GREEN}$HEALTHY${NC}"
  echo -e "  Unhealthy:        $([ $UNHEALTHY -eq 0 ] && echo -e "${GREEN}$UNHEALTHY${NC}" || echo -e "${RED}$UNHEALTHY${NC}")"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  log_event "Health check complete: $HEALTHY healthy, $UNHEALTHY unhealthy"

  return $([[ $UNHEALTHY -eq 0 ]] && echo 0 || echo 1)
}

# Main execution
if [[ "$CONTINUOUS" == true ]]; then
  echo -e "${BLUE}Starting continuous health monitoring (interval: ${INTERVAL}s)${NC}"
  echo "Press Ctrl+C to stop"
  echo ""
  echo "Logs: $LOG_FILE"
  echo ""

  log_event "=== Continuous monitoring started (interval: ${INTERVAL}s) ==="

  while true; do
    run_health_check
    echo ""
    echo -e "${YELLOW}Next check in ${INTERVAL}s...${NC}"
    echo ""
    sleep "$INTERVAL"
  done
else
  run_health_check

  echo "To monitor continuously, run:"
  echo "  $0 $CONFIG_FILE --continuous --interval $INTERVAL"
  echo ""
  echo "View logs:"
  echo "  tail -f $LOG_FILE"
fi
