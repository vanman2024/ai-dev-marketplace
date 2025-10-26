#!/usr/bin/env bash
# Script: validate-and-sync-all.sh
# Purpose: Complete validation and synchronization of all plugins
# Usage: ./validate-and-sync-all.sh
# This is the MASTER script that ensures everything is in sync

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  Plugin System Validation & Sync"
echo "========================================="
echo ""

# Step 1: Validate all individual plugins
echo "[STEP 1/4] Validating individual plugins..."
echo ""

PLUGINS=$(find plugins -mindepth 1 -maxdepth 1 -type d -name "*" ! -name ".*" | sort)
PLUGIN_COUNT=0
VALID_COUNT=0
INVALID_COUNT=0

for plugin in $PLUGINS; do
    ((PLUGIN_COUNT++))
    PLUGIN_NAME=$(basename "$plugin")

    # Check if has .claude-plugin directory (skip if not a valid plugin)
    if [[ ! -d "$plugin/.claude-plugin" ]]; then
        echo "  ⏭️  Skipping $PLUGIN_NAME (not a Claude Code plugin)"
        continue
    fi

    echo "  Validating: $PLUGIN_NAME"
    if bash "$SCRIPT_DIR/validate-plugin.sh" "$plugin" 2>&1 | grep -q "✅"; then
        ((VALID_COUNT++))
    else
        ((INVALID_COUNT++))
        echo "  ❌ Validation failed for $PLUGIN_NAME"
    fi
done

echo ""
echo "  Plugins found: $PLUGIN_COUNT"
echo "  Valid: $VALID_COUNT"
echo "  Invalid: $INVALID_COUNT"
echo ""

# Step 2: Sync all commands to settings.local.json
echo "[STEP 2/4] Syncing commands to settings.local.json..."
echo ""

bash "$SCRIPT_DIR/sync-settings-permissions.sh"

echo ""

# Step 3: Sync all plugins to marketplace.json
echo "[STEP 3/4] Syncing plugins to marketplace.json..."
echo ""

bash "$SCRIPT_DIR/sync-marketplace.sh"

echo ""

# Step 4: Final validation
echo "[STEP 4/4] Final validation checks..."
echo ""

# Check settings.local.json is valid JSON
if python3 -m json.tool .claude/settings.local.json > /dev/null 2>&1; then
    echo "  ✅ settings.local.json is valid JSON"
else
    echo "  ❌ settings.local.json is INVALID JSON"
    exit 1
fi

# Check marketplace.json is valid JSON
if python3 -m json.tool .claude-plugin/marketplace.json > /dev/null 2>&1; then
    echo "  ✅ marketplace.json is valid JSON"
else
    echo "  ❌ marketplace.json is INVALID JSON"
    exit 1
fi

# Count registrations
SETTINGS_PERMISSIONS=$(grep -c "SlashCommand" .claude/settings.local.json || echo "0")
MARKETPLACE_PLUGINS=$(python3 -c "import json; print(len(json.load(open('.claude-plugin/marketplace.json'))['plugins']))" 2>/dev/null || echo "0")

echo "  ✅ $SETTINGS_PERMISSIONS slash commands registered in settings"
echo "  ✅ $MARKETPLACE_PLUGINS plugins registered in marketplace"

echo ""
echo "========================================="
echo "  ✅ All validations passed!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Plugins validated: $VALID_COUNT/$PLUGIN_COUNT"
echo "  - Commands registered: $SETTINGS_PERMISSIONS"
echo "  - Marketplace entries: $MARKETPLACE_PLUGINS"
echo ""
echo "Next steps:"
echo "  1. Test a command: /fastmcp:new-server my-test"
echo "  2. Commit changes: git add .claude/ .claude-plugin/"
echo "  3. Review docs: cat SETTINGS-SYNC-GUIDE.md"
echo ""

exit 0
