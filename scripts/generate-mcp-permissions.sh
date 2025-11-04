#!/bin/bash
# Generate MCP server permissions for settings.local.json
# Usage: bash scripts/generate-mcp-permissions.sh

set -e

echo "Generating MCP server permissions from plugin .mcp.json files..."
echo ""

PERMISSIONS=()

# Find all .mcp.json files in plugins
for mcp_file in plugins/*/.mcp.json; do
    if [ ! -f "$mcp_file" ]; then
        continue
    fi

    # Extract plugin name from path
    plugin_name=$(dirname "$mcp_file" | xargs basename)

    # Extract server names from .mcp.json
    server_names=$(jq -r '.mcpServers | keys[]' "$mcp_file" 2>/dev/null || echo "")

    if [ -z "$server_names" ]; then
        continue
    fi

    echo "Plugin: $plugin_name"

    # Generate permission for each server
    while IFS= read -r server; do
        permission="mcp__plugin_${plugin_name}_${server}"
        echo "  - $permission"
        PERMISSIONS+=("$permission")
    done <<< "$server_names"

    echo ""
done

# Output JSON array format
echo "=================================="
echo "Add these to settings.local.json permissions.allow:"
echo ""
for perm in "${PERMISSIONS[@]}"; do
    echo "      \"$perm\","
done
echo ""
echo "Total: ${#PERMISSIONS[@]} MCP server permissions"
