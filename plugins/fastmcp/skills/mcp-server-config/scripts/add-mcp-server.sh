#!/usr/bin/env bash
# add-mcp-server.sh - Add MCP server to .mcp.json
# Usage: add-mcp-server.sh <server-name> <command> [args...]

set -euo pipefail

SERVER_NAME="${1:?Server name required}"
COMMAND="${2:?Command required}"
shift 2
ARGS=("$@")

MCP_FILE=".mcp.json"

# Create .mcp.json if it doesn't exist
if [ ! -f "$MCP_FILE" ]; then
    echo '{"mcpServers":{}}' > "$MCP_FILE"
fi

# Build args JSON array
ARGS_JSON="[]"
if [ ${#ARGS[@]} -gt 0 ]; then
    ARGS_JSON=$(printf '%s\n' "${ARGS[@]}" | jq -R . | jq -s .)
fi

# Add server using jq
jq --arg name "$SERVER_NAME" \
   --arg cmd "$COMMAND" \
   --argjson args "$ARGS_JSON" \
   '.mcpServers[$name] = {"command": $cmd, "args": $args}' \
   "$MCP_FILE" > "$MCP_FILE.tmp"

mv "$MCP_FILE.tmp" "$MCP_FILE"

echo "✅ Added MCP server: $SERVER_NAME"
echo "  Command: $COMMAND"
echo "  Args: ${ARGS[*]:-none}"
