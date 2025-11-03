#!/bin/bash

# List all available agents across plugins and global directory
# Searches: plugins/*/agents/*.md and ~/.claude/agents/*.md

# Portable: Use current directory or argument (works from any location)
MARKETPLACE_DIR="${1:-$(pwd)}"
GLOBAL_AGENTS_DIR="$HOME/.claude/agents"

echo "=== Available Agents ==="
echo ""

# Track total count
TOTAL=0

# Function to extract agent info from frontmatter
extract_agent_info() {
    local file="$1"
    local location="$2"

    # Extract name and description from frontmatter
    local name=$(grep -m1 "^name:" "$file" | cut -d: -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    local desc=$(grep -m1 "^description:" "$file" | cut -d: -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [ -n "$name" ]; then
        echo "  - $name"
        [ -n "$desc" ] && echo "    $desc"
        echo "    Location: $location"
        echo ""
        ((TOTAL++))
    fi
}

# Find all plugin agents
echo "Plugin Agents:"
while IFS= read -r agent_file; do
    plugin_name=$(echo "$agent_file" | sed -E 's|.*/plugins/([^/]+)/agents/.*|\1|')
    extract_agent_info "$agent_file" "$plugin_name plugin"
done < <(find "$MARKETPLACE_DIR/plugins" -type f -path "*/agents/*.md" 2>/dev/null | sort)

# Find global agents
if [ -d "$GLOBAL_AGENTS_DIR" ]; then
    echo "Global Agents:"
    while IFS= read -r agent_file; do
        extract_agent_info "$agent_file" "global"
    done < <(find "$GLOBAL_AGENTS_DIR" -type f -name "*.md" 2>/dev/null | sort)
fi

echo "---"
echo "Total: $TOTAL agents available"
echo ""
echo "Built-in agents (always available):"
echo "  - general-purpose: Multi-step tasks and complex questions"
echo "  - Explore: Fast codebase exploration and search"
