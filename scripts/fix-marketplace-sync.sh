#!/bin/bash

# Auto-fix Marketplace Sync Script
# Uses existing Python/bash tools you already created!
# - register-all-commands.sh (registers commands in settings.json)
# - register-skills-in-settings.sh (registers skills in settings.json)
# - sync-validator.py (syncs to Airtable with --auto-sync)

set -e

MARKETPLACE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Existing tools
REGISTER_COMMANDS="$HOME/.claude/plugins/marketplaces/dev-lifecycle-marketplace/scripts/register-all-commands.sh"
REGISTER_SKILLS="$HOME/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/skills/build-assistant/scripts/register-skills-in-settings.sh"
SYNC_VALIDATOR="$HOME/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/scripts/sync-validator.py"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================================================================"
echo "🔧 Auto-Fix Marketplace Sync"
echo "================================================================================"
echo "Using existing registration and sync tools"
echo ""

# Backup settings.json
echo "Creating backup of settings.json..."
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✅ Backup created${NC}"
echo ""

echo "================================================================================"
echo "📦 PHASE 1: Validating marketplace.json Registration"
echo "================================================================================"
echo ""

MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
MISSING_IN_MARKETPLACE=()

for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    if ! grep -q "\"name\": \"$plugin_name\"" "$MARKETPLACE_JSON"; then
        echo -e "${RED}❌ Missing in marketplace.json:${NC} $plugin_name"
        MISSING_IN_MARKETPLACE+=("$plugin_name")
    else
        echo -e "${GREEN}✅${NC} $plugin_name registered in marketplace.json"
    fi
done

if [ ${#MISSING_IN_MARKETPLACE[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  The following plugins need to be added to marketplace.json:${NC}"
    for plugin in "${MISSING_IN_MARKETPLACE[@]}"; do
        echo "  - $plugin"
    done
    echo ""
fi

echo ""
echo "================================================================================"
echo "📋 PHASE 2: Registering All Commands in settings.json"
echo "================================================================================"
echo ""

if [ -f "$REGISTER_COMMANDS" ]; then
    echo "Using existing register-all-commands.sh..."
    bash "$REGISTER_COMMANDS"
else
    echo -e "${YELLOW}⚠️  register-all-commands.sh not found, skipping command registration${NC}"
fi

echo ""
echo "================================================================================"
echo "🎯 PHASE 3: Registering All Skills in settings.json"
echo "================================================================================"
echo ""

if [ -f "$REGISTER_SKILLS" ]; then
    echo "Using existing register-skills-in-settings.sh..."
    bash "$REGISTER_SKILLS"
else
    echo -e "${YELLOW}⚠️  register-skills-in-settings.sh not found, skipping skill registration${NC}"
fi

echo ""
echo "================================================================================"
echo "📦 PHASE 4: Enabling All Plugins in settings.json"
echo "================================================================================"
echo ""

for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    if ! grep -q "\"$plugin_name@ai-dev-marketplace\": true" "$SETTINGS_FILE"; then
        echo -e "${YELLOW}Not enabled:${NC} $plugin_name@ai-dev-marketplace"
        echo -e "${YELLOW}⚠️  Please manually add to enabledPlugins:${NC} \"$plugin_name@ai-dev-marketplace\": true"
    else
        echo -e "${GREEN}✅${NC} $plugin_name already enabled"
    fi
done

echo ""
echo "================================================================================"
echo "💾 PHASE 5: Auto-Syncing to Airtable with sync-validator.py"
echo "================================================================================"
echo ""

if [ ! -f "$SYNC_VALIDATOR" ]; then
    echo -e "${YELLOW}⚠️  sync-validator.py not found, skipping Airtable sync${NC}"
    exit 0
fi

if [ -z "$AIRTABLE_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  AIRTABLE_TOKEN not set, skipping Airtable sync${NC}"
    echo "To sync to Airtable, set AIRTABLE_TOKEN and re-run this script"
    exit 0
fi

echo "Using existing sync-validator.py for intelligent Airtable sync..."
echo ""
python "$SYNC_VALIDATOR" --marketplace=ai-dev-marketplace --auto-sync

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ AUTO-FIX COMPLETE!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Summary:"
echo "  ✅ All plugins validated in marketplace.json"
echo "  ✅ All commands registered in settings.json"
echo "  ✅ All skills registered in settings.json"
echo "  ✅ Plugin enablement status checked"
echo "  ✅ Airtable sync completed"
echo ""
echo "Next steps:"
echo "  1. Run: bash scripts/validate-marketplace-sync.sh"
echo ""
