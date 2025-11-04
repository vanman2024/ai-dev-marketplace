#!/bin/bash

# Script to remove the tools: field from all agent markdown files
# This allows agents to inherit all MCP tools automatically

MARKETPLACE_DIR="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace"

echo "Removing tools: field from all agents..."
echo ""

# Find all agent .md files
find "$MARKETPLACE_DIR/plugins" -type f -path "*/agents/*.md" | while read -r agent_file; do
    # Check if the file has a tools: line in the frontmatter
    if grep -q "^tools:" "$agent_file"; then
        echo "Processing: $agent_file"

        # Remove the tools: line from the frontmatter
        # This uses sed to delete lines starting with "tools:" in the YAML frontmatter
        sed -i '/^---$/,/^---$/ { /^tools:/d; }' "$agent_file"

        echo "  ✓ Removed tools: field"
    fi
done

echo ""
echo "Done! All tools: fields removed from agent definitions."
echo ""
echo "Agents will now inherit all MCP tools automatically."
echo "Next step: Add explicit MCP server usage instructions to agent prompts."
