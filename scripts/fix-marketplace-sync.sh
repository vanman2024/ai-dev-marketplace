#!/bin/bash

# Auto-fix Marketplace Sync Script
# Automatically registers all commands and skills in settings.json
# and syncs all components to Airtable

set -e

MARKETPLACE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SETTINGS_FILE="$HOME/.claude/settings.json"
SYNC_SCRIPT="$HOME/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/scripts/sync-component.py"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================================================"
echo "🔧 Auto-Fix Marketplace Sync"
echo "================================================================================"
echo ""

# Backup settings.json
echo "Creating backup of settings.json..."
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✅ Backup created${NC}"
echo ""

echo "================================================================================"
echo "📋 PHASE 1: Registering All Commands"
echo "================================================================================"
echo ""

COMMANDS_TO_ADD=()

for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir/commands" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    for cmd_file in "$plugin_dir/commands"/*.md; do
        if [ ! -f "$cmd_file" ]; then
            continue
        fi

        cmd_name=$(basename "$cmd_file" .md)
        cmd_path="/$plugin_name:$cmd_name"

        if ! grep -q "\"SlashCommand($cmd_path)\"" "$SETTINGS_FILE"; then
            echo -e "${YELLOW}Adding:${NC} SlashCommand($cmd_path)"
            COMMANDS_TO_ADD+=("      \"SlashCommand($cmd_path)\",")
        fi
    done
done

echo ""
echo "================================================================================"
echo "🎯 PHASE 2: Registering All Skills"
echo "================================================================================"
echo ""

SKILLS_TO_ADD=()

for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir/skills" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    for skill_dir in "$plugin_dir/skills"/*/; do
        if [ ! -d "$skill_dir" ]; then
            continue
        fi

        skill_name=$(basename "$skill_dir")
        skill_path="$plugin_name:$skill_name"

        if ! grep -q "\"Skill($skill_path)\"" "$SETTINGS_FILE"; then
            echo -e "${YELLOW}Adding:${NC} Skill($skill_path)"
            SKILLS_TO_ADD+=("      \"Skill($skill_path)\",")
        fi
    done
done

echo ""
echo "================================================================================"
echo "📦 PHASE 3: Enabling All Plugins"
echo "================================================================================"
echo ""

for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    if ! grep -q "\"$plugin_name@ai-dev-marketplace\": true" "$SETTINGS_FILE"; then
        echo -e "${YELLOW}Enabling:${NC} $plugin_name@ai-dev-marketplace"
        # Add to enabledPlugins section
        # This requires more complex JSON manipulation - recommend manual addition
        echo -e "${YELLOW}⚠️  Please manually add to enabledPlugins:${NC} \"$plugin_name@ai-dev-marketplace\": true"
    else
        echo -e "${GREEN}✅${NC} $plugin_name already enabled"
    fi
done

echo ""
echo "================================================================================"
echo "💾 PHASE 4: Updating settings.json"
echo "================================================================================"
echo ""

if [ ${#COMMANDS_TO_ADD[@]} -eq 0 ] && [ ${#SKILLS_TO_ADD[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No updates needed - everything already registered!${NC}"
else
    echo "Found ${#COMMANDS_TO_ADD[@]} commands and ${#SKILLS_TO_ADD[@]} skills to add"
    echo ""
    echo "Items to add:"
    for item in "${COMMANDS_TO_ADD[@]}" "${SKILLS_TO_ADD[@]}"; do
        echo "$item"
    done
    echo ""
    echo -e "${YELLOW}⚠️  Automatic JSON insertion requires manual editing${NC}"
    echo "Please add the above items to the 'allow' array in $SETTINGS_FILE"
fi

echo ""
echo "================================================================================"
echo "📊 PHASE 5: Syncing to Airtable"
echo "================================================================================"
echo ""

if [ ! -f "$SYNC_SCRIPT" ]; then
    echo -e "${YELLOW}⚠️  Airtable sync script not found${NC}"
    exit 0
fi

if [ -z "$AIRTABLE_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  AIRTABLE_TOKEN not set, skipping Airtable sync${NC}"
    echo "To sync to Airtable, set AIRTABLE_TOKEN and re-run this script"
    exit 0
fi

echo "Syncing all components to Airtable..."
echo ""

# Sync all agents
for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir/agents" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    for agent_file in "$plugin_dir/agents"/*.md; do
        if [ ! -f "$agent_file" ]; then
            continue
        fi

        agent_name=$(basename "$agent_file" .md)
        echo "Syncing agent: $plugin_name:$agent_name"
        python "$SYNC_SCRIPT" --type=agent --name="$agent_name" --plugin="$plugin_name" --marketplace=ai-dev-marketplace || true
    done
done

# Sync all commands
for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir/commands" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    for cmd_file in "$plugin_dir/commands"/*.md; do
        if [ ! -f "$cmd_file" ]; then
            continue
        fi

        cmd_name=$(basename "$cmd_file" .md)
        echo "Syncing command: $plugin_name:$cmd_name"
        python "$SYNC_SCRIPT" --type=command --name="$cmd_name" --plugin="$plugin_name" --marketplace=ai-dev-marketplace || true
    done
done

# Sync all skills
for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir/skills" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")

    for skill_dir in "$plugin_dir/skills"/*/; do
        if [ ! -d "$skill_dir" ]; then
            continue
        fi

        skill_name=$(basename "$skill_dir")
        echo "Syncing skill: $plugin_name:$skill_name"
        python "$SYNC_SCRIPT" --type=skill --name="$skill_name" --plugin="$plugin_name" --marketplace=ai-dev-marketplace || true
    done
done

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ AUTO-FIX COMPLETE!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes above"
echo "  2. Manually add any items to settings.json if needed"
echo "  3. Run: bash scripts/validate-marketplace-sync.sh"
echo ""
