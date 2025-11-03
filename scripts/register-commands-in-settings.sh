#!/usr/bin/env bash

# Register plugin commands in .claude/settings.local.json
# Usage: ./register-commands-in-settings.sh <plugin-name>

set -e

PLUGIN_NAME=$1
SETTINGS_FILE="$HOME/.claude/settings.local.json"

if [ -z "$PLUGIN_NAME" ]; then
    echo "Usage: $0 <plugin-name>"
    echo "Example: $0 elevenlabs"
    exit 1
fi

if [ ! -d "plugins/$PLUGIN_NAME" ]; then
    echo "ERROR: Plugin directory plugins/$PLUGIN_NAME does not exist"
    exit 1
fi

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "ERROR: Settings file $SETTINGS_FILE does not exist"
    exit 1
fi

echo "[INFO] Registering commands for plugin: $PLUGIN_NAME"

# Get list of commands
COMMANDS=$(ls plugins/$PLUGIN_NAME/commands/*.md 2>/dev/null | sed 's|plugins/||; s|/commands/|:|; s|.md||' || true)

if [ -z "$COMMANDS" ]; then
    echo "[WARN] No commands found for plugin $PLUGIN_NAME"
    exit 0
fi

echo "[INFO] Found commands:"
echo "$COMMANDS"

# Check if wildcard already registered
if grep -q "\"SlashCommand(/$PLUGIN_NAME:\*)\"" "$SETTINGS_FILE"; then
    echo "[INFO] Commands already registered for $PLUGIN_NAME"
    exit 0
fi

echo "[INFO] Adding commands to $SETTINGS_FILE"

# Create temp file with commands to add
TEMP_COMMANDS=$(mktemp)
echo "      \"SlashCommand(/$PLUGIN_NAME:*)\"," > "$TEMP_COMMANDS"
while IFS= read -r cmd; do
    echo "      \"SlashCommand(/$cmd)\"," >> "$TEMP_COMMANDS"
done <<< "$COMMANDS"

# Find the line before "Bash" and insert commands there
LINE_NUM=$(grep -n '"Bash"' "$SETTINGS_FILE" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "ERROR: Could not find 'Bash' entry in $SETTINGS_FILE"
    rm "$TEMP_COMMANDS"
    exit 1
fi

# Insert before Bash line
head -n $((LINE_NUM - 1)) "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
cat "$TEMP_COMMANDS" >> "${SETTINGS_FILE}.tmp"
tail -n +$LINE_NUM "$SETTINGS_FILE" >> "${SETTINGS_FILE}.tmp"

# Replace original file
mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
rm "$TEMP_COMMANDS"

echo "[SUCCESS] Commands registered for $PLUGIN_NAME"
echo "[INFO] Added $(echo "$COMMANDS" | wc -l) commands plus wildcard"
