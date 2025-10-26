#!/usr/bin/env bash
# Script: sync-settings-permissions.sh
# Purpose: Automatically sync all plugin commands to .claude/settings.local.json
# Usage: ./sync-settings-permissions.sh
# This ensures all commands are registered and can be invoked

set -euo pipefail

SETTINGS_FILE=".claude/settings.local.json"
BACKUP_FILE=".claude/settings.local.json.backup"

echo "[INFO] Syncing plugin commands to settings.local.json"

# Find all plugins
PLUGINS=$(find plugins -mindepth 1 -maxdepth 1 -type d | sort)

# Build command list
COMMANDS=()

for plugin in $PLUGINS; do
    PLUGIN_NAME=$(basename "$plugin")

    # Check if plugin has commands
    if [[ -d "$plugin/commands" ]]; then
        # Add wildcard permission for the plugin
        COMMANDS+=("      \"SlashCommand(/$PLUGIN_NAME:*)\"")

        # Find all command files
        COMMAND_FILES=$(find "$plugin/commands" -name "*.md" -type f | sort)

        for cmd_file in $COMMAND_FILES; do
            CMD_NAME=$(basename "$cmd_file" .md)
            COMMANDS+=("      \"SlashCommand(/$PLUGIN_NAME:$CMD_NAME)\"")
        done
    fi
done

# Add base tools
BASE_TOOLS=(
    "Bash"
    "Write"
    "Read"
    "Edit"
    "WebFetch"
    "WebSearch"
    "AskUserQuestion"
    "Glob"
    "Grep"
    "Task"
    "Skill"
)

for tool in "${BASE_TOOLS[@]}"; do
    COMMANDS+=("      \"$tool\"")
done

# Build JSON
cat > "$SETTINGS_FILE" <<EOF
{
  "permissions": {
    "allow": [
$(IFS=$',\n'; echo "${COMMANDS[*]}")
    ]
  },
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": [
    "filesystem",
    "playwright",
    "context7",
    "postman"
  ]
}
EOF

echo "✅ Updated settings.local.json with $(echo "${COMMANDS[@]}" | wc -w) permissions"
echo "[INFO] All plugin commands are now registered"

# Show summary
echo ""
echo "Registered plugins:"
for plugin in $PLUGINS; do
    PLUGIN_NAME=$(basename "$plugin")
    CMD_COUNT=$(find "$plugin/commands" -name "*.md" -type f 2>/dev/null | wc -l || echo "0")
    if [[ $CMD_COUNT -gt 0 ]]; then
        echo "  - $PLUGIN_NAME ($CMD_COUNT commands)"
    fi
done
