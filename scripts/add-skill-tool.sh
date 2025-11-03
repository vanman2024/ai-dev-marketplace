#!/bin/bash

# Script to add Skill tool to all agents and commands that are missing it
# Usage: bash scripts/add-skill-tool.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$MARKETPLACE_DIR"

echo "🔍 Adding Skill tool to agents and commands..."
echo ""

# Counters
agents_updated=0
commands_updated=0
agents_skipped=0
commands_skipped=0

# Process all agent files
echo "📝 Processing agents..."
for agent_file in plugins/*/agents/*.md; do
    if [[ -f "$agent_file" ]]; then
        # Check if file has tools: line
        if grep -q "^tools:" "$agent_file"; then
            # Check if Skill is already present
            if grep -q "^tools:.*Skill" "$agent_file"; then
                agents_skipped=$((agents_skipped + 1))
            else
                # Add Skill to the tools line
                sed -i 's/^tools: \(.*\)$/tools: \1, Skill/' "$agent_file"
                echo "  ✅ Updated: $agent_file"
                agents_updated=$((agents_updated + 1))
            fi
        fi
    fi
done

echo ""
echo "📝 Processing commands..."
for command_file in plugins/*/commands/*.md; do
    if [[ -f "$command_file" ]]; then
        # Check if file has allowed-tools: line
        if grep -q "^allowed-tools:" "$command_file"; then
            # Check if Skill is already present
            if grep -q "^allowed-tools:.*Skill" "$command_file"; then
                commands_skipped=$((commands_skipped + 1))
            else
                # Add Skill to the allowed-tools line
                sed -i 's/^allowed-tools: \(.*\)$/allowed-tools: \1, Skill/' "$command_file"
                echo "  ✅ Updated: $command_file"
                commands_updated=$((commands_updated + 1))
            fi
        fi
    fi
done

echo ""
echo "✨ Summary:"
echo "  Agents updated: $agents_updated"
echo "  Agents skipped (already have Skill): $agents_skipped"
echo "  Commands updated: $commands_updated"
echo "  Commands skipped (already have Skill): $commands_skipped"
echo ""
echo "Total updated: $((agents_updated + commands_updated))"
echo ""
echo "✅ Done! Run 'git diff' to review changes."
