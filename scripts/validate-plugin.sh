#!/usr/bin/env bash
# Script: validate-plugin.sh
# Purpose: Validate plugin directory compliance with Claude Code standards
# Subsystem: build-system
# Called by: /build:plugin command after generation
# Outputs: Validation report to stdout

set -euo pipefail

PLUGIN_DIR="${1:?Usage: $0 <plugin-directory>}"
SETTINGS_FILE="$HOME/.claude/settings.local.json"

echo "[INFO] Validating plugin directory: $PLUGIN_DIR"

# Check directory exists
if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "❌ ERROR: Directory not found: $PLUGIN_DIR"
    exit 1
fi

# Check .claude-plugin directory exists
if [[ ! -d "$PLUGIN_DIR/.claude-plugin" ]]; then
    echo "❌ ERROR: Missing .claude-plugin directory"
    exit 1
fi

# Check plugin.json exists
if [[ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
    echo "❌ ERROR: Missing plugin.json manifest"
    exit 1
fi

# Validate JSON syntax
if ! python3 -m json.tool "$PLUGIN_DIR/.claude-plugin/plugin.json" > /dev/null 2>&1; then
    echo "❌ ERROR: Invalid JSON in plugin.json"
    exit 1
fi

# Validate plugin.json schema (only allowed fields)
ALLOWED_FIELDS=("name" "version" "description" "author" "homepage" "repository" "license" "keywords" "category" "tags" "strict" "commands" "agents" "hooks" "mcpServers")
INVALID_FIELDS=$(python3 -c "
import json, sys
with open('$PLUGIN_DIR/.claude-plugin/plugin.json') as f:
    data = json.load(f)
allowed = set($( printf "'%s', " "${ALLOWED_FIELDS[@]}" | sed 's/, $//' ))
invalid = [k for k in data.keys() if k not in allowed]
if invalid:
    print(' '.join(invalid))
" 2>/dev/null)

if [[ -n "$INVALID_FIELDS" ]]; then
    echo "❌ ERROR: Invalid fields in plugin.json: $INVALID_FIELDS"
    echo "[INFO] Allowed fields: ${ALLOWED_FIELDS[*]}"
    echo "[INFO] Move custom metadata to keywords array for discoverability"
    exit 1
fi

# Check required fields in plugin.json
REQUIRED_FIELDS=("name" "version" "description")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "\"$field\":" "$PLUGIN_DIR/.claude-plugin/plugin.json"; then
        echo "❌ ERROR: Missing required field: $field"
        exit 1
    fi
done

# Validate author field structure if present
if grep -q "\"author\":" "$PLUGIN_DIR/.claude-plugin/plugin.json"; then
    AUTHOR_VALID=$(python3 -c "
import json
with open('$PLUGIN_DIR/.claude-plugin/plugin.json') as f:
    data = json.load(f)
author = data.get('author')
if isinstance(author, dict):
    if 'name' in author:
        print('valid')
    else:
        print('missing_name')
elif isinstance(author, str):
    print('string')
" 2>/dev/null)

    if [[ "$AUTHOR_VALID" == "string" ]]; then
        echo "❌ ERROR: author field must be an object with 'name' and 'email' fields, not a string"
        exit 1
    elif [[ "$AUTHOR_VALID" == "missing_name" ]]; then
        echo "❌ ERROR: author object must include 'name' field"
        exit 1
    fi
fi

# Check component directories are at root (not inside .claude-plugin)
if [[ -d "$PLUGIN_DIR/.claude-plugin/commands" ]] || \
   [[ -d "$PLUGIN_DIR/.claude-plugin/skills" ]] || \
   [[ -d "$PLUGIN_DIR/.claude-plugin/hooks" ]]; then
    echo "❌ ERROR: Component directories must be at plugin root, not inside .claude-plugin/"
    exit 1
fi

# NEW: Check if plugin commands are registered in settings.local.json
PLUGIN_NAME=$(basename "$PLUGIN_DIR")

if [[ -f "$SETTINGS_FILE" ]]; then
    if [[ -d "$PLUGIN_DIR/commands" ]]; then
        # Check for wildcard permission
        if ! grep -q "SlashCommand(/$PLUGIN_NAME:\\*)" "$SETTINGS_FILE"; then
            echo "⚠️  WARNING: Plugin commands not registered in settings.local.json"
            echo "[INFO] Run: bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh"
        else
            echo "✅ Plugin commands registered in settings.local.json"
        fi
    fi
else
    echo "⚠️  WARNING: No settings.local.json found"
    echo "[INFO] Run: bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-settings-permissions.sh"
fi

echo "✅ Plugin validation passed"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 NEXT STEP: Install Plugin to Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To make the plugin available for use:"
echo ""
echo "  1. Update marketplace in ~/.claude:"
echo "     cp -r $PLUGIN_DIR ~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/"
echo "     cp .claude-plugin/marketplace.json ~/.claude/plugins/marketplaces/ai-dev-marketplace/.claude-plugin/"
echo ""
echo "  2. Install the plugin:"
echo "     /plugin install $PLUGIN_NAME@ai-dev-marketplace"
echo ""
echo "  3. Verify installation:"
echo "     /$PLUGIN_NAME:init  (or any command from the plugin)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0
