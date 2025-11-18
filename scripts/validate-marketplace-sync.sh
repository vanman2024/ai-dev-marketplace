#!/bin/bash

# Comprehensive Marketplace Validation Script
# Validates that all commands, skills, agents are registered in settings.json and synced to Airtable

set -e

MARKETPLACE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SETTINGS_FILE="$HOME/.claude/settings.json"
SYNC_SCRIPT="$HOME/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/scripts/sync-component.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================================================"
echo "🔍 Comprehensive Marketplace Validation"
echo "================================================================================"
echo ""
echo "Marketplace: ai-dev-marketplace"
echo "Location: $MARKETPLACE_DIR"
echo "Settings: $SETTINGS_FILE"
echo ""

# Initialize counters
TOTAL_PLUGINS=0
TOTAL_COMMANDS=0
TOTAL_AGENTS=0
TOTAL_SKILLS=0
MISSING_COMMANDS=0
MISSING_SKILLS=0
MISSING_AGENTS_AIRTABLE=0
MISSING_COMMANDS_AIRTABLE=0
MISSING_SKILLS_AIRTABLE=0
DISABLED_PLUGINS=0

# Validation results
MISSING_ITEMS=()

echo "================================================================================"
echo "📦 PHASE 1: Discovering All Plugins"
echo "================================================================================"
echo ""

for plugin_dir in "$MARKETPLACE_DIR"/plugins/*/; do
    if [ ! -d "$plugin_dir" ]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")
    TOTAL_PLUGINS=$((TOTAL_PLUGINS + 1))

    echo -e "${BLUE}Plugin: $plugin_name${NC}"

    # Check if plugin is enabled in settings.json
    if grep -q "\"$plugin_name@ai-dev-marketplace\": true" "$SETTINGS_FILE"; then
        echo -e "  ${GREEN}✅ Enabled in settings.json${NC}"
    else
        echo -e "  ${RED}❌ NOT enabled in settings.json${NC}"
        DISABLED_PLUGINS=$((DISABLED_PLUGINS + 1))
        MISSING_ITEMS+=("PLUGIN_DISABLED:$plugin_name")
    fi

    # Count commands
    if [ -d "$plugin_dir/commands" ]; then
        cmd_count=$(find "$plugin_dir/commands" -name "*.md" 2>/dev/null | wc -l)
        echo "  📁 Commands: $cmd_count"
        TOTAL_COMMANDS=$((TOTAL_COMMANDS + cmd_count))
    fi

    # Count agents
    if [ -d "$plugin_dir/agents" ]; then
        agent_count=$(find "$plugin_dir/agents" -name "*.md" 2>/dev/null | wc -l)
        echo "  🤖 Agents: $agent_count"
        TOTAL_AGENTS=$((TOTAL_AGENTS + agent_count))
    fi

    # Count skills
    if [ -d "$plugin_dir/skills" ]; then
        skill_count=$(find "$plugin_dir/skills" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l)
        echo "  🎯 Skills: $skill_count"
        TOTAL_SKILLS=$((TOTAL_SKILLS + skill_count))
    fi

    echo ""
done

echo "================================================================================"
echo "📋 PHASE 2: Validating Slash Commands in settings.json"
echo "================================================================================"
echo ""

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

        if grep -q "\"SlashCommand($cmd_path)\"" "$SETTINGS_FILE"; then
            echo -e "${GREEN}✅${NC} $cmd_path"
        else
            echo -e "${RED}❌ MISSING:${NC} $cmd_path"
            MISSING_COMMANDS=$((MISSING_COMMANDS + 1))
            MISSING_ITEMS+=("COMMAND_SETTINGS:$cmd_path")
        fi
    done
done

echo ""
echo "================================================================================"
echo "🎯 PHASE 3: Validating Skills in settings.json"
echo "================================================================================"
echo ""

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

        if grep -q "\"Skill($skill_path)\"" "$SETTINGS_FILE"; then
            echo -e "${GREEN}✅${NC} Skill($skill_path)"
        else
            echo -e "${RED}❌ MISSING:${NC} Skill($skill_path)"
            MISSING_SKILLS=$((MISSING_SKILLS + 1))
            MISSING_ITEMS+=("SKILL_SETTINGS:$skill_path")
        fi
    done
done

echo ""
echo "================================================================================"
echo "📊 PHASE 4: Checking Airtable Sync Status"
echo "================================================================================"
echo ""

# Check if Airtable sync is available
if [ ! -f "$SYNC_SCRIPT" ]; then
    echo -e "${YELLOW}⚠️  Airtable sync script not found, skipping Airtable validation${NC}"
else
    echo "Note: Airtable sync validation requires AIRTABLE_TOKEN environment variable"
    echo "This phase shows what SHOULD be synced, actual sync status requires API access"
    echo ""

    # List what should be in Airtable
    echo "🤖 Agents that should be synced:"
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
            echo "  - $plugin_name:$agent_name"
        done
    done

    echo ""
    echo "📋 Commands that should be synced:"
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
            echo "  - $plugin_name:$cmd_name"
        done
    done

    echo ""
    echo "🎯 Skills that should be synced:"
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
            echo "  - $plugin_name:$skill_name"
        done
    done
fi

echo ""
echo "================================================================================"
echo "📈 VALIDATION SUMMARY"
echo "================================================================================"
echo ""

echo "Discovery:"
echo "  Total Plugins: $TOTAL_PLUGINS"
echo "  Total Commands: $TOTAL_COMMANDS"
echo "  Total Agents: $TOTAL_AGENTS"
echo "  Total Skills: $TOTAL_SKILLS"
echo ""

echo "Settings.json Validation:"
if [ $DISABLED_PLUGINS -eq 0 ]; then
    echo -e "  ${GREEN}✅ All plugins enabled${NC}"
else
    echo -e "  ${RED}❌ $DISABLED_PLUGINS plugins NOT enabled${NC}"
fi

if [ $MISSING_COMMANDS -eq 0 ]; then
    echo -e "  ${GREEN}✅ All commands registered${NC}"
else
    echo -e "  ${RED}❌ $MISSING_COMMANDS commands NOT registered${NC}"
fi

if [ $MISSING_SKILLS -eq 0 ]; then
    echo -e "  ${GREEN}✅ All skills registered${NC}"
else
    echo -e "  ${RED}❌ $MISSING_SKILLS skills NOT registered${NC}"
fi

echo ""

if [ ${#MISSING_ITEMS[@]} -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ ALL VALIDATIONS PASSED!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}❌ VALIDATION FAILURES DETECTED${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Missing Items:"
    for item in "${MISSING_ITEMS[@]}"; do
        echo "  - $item"
    done
    echo ""
    echo "Next Steps:"
    echo "  1. Run auto-fix script: bash scripts/fix-marketplace-sync.sh"
    echo "  2. Or manually register missing items in ~/.claude/settings.json"
    echo ""
    exit 1
fi
