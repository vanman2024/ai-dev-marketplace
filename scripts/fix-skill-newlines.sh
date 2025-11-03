#!/bin/bash

# Script to fix literal \n in skill descriptions
# Usage: bash fix-skill-newlines.sh (can be run from anywhere)

set -e

# Find marketplace root by looking for plugins/ directory
find_marketplace_root() {
    local current_dir="$PWD"

    # Check if we're already in marketplace root
    if [ -d "$current_dir/plugins" ] && [ -d "$current_dir/scripts" ]; then
        echo "$current_dir"
        return 0
    fi

    # Check if script is in scripts/ subdirectory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local parent_dir="$(dirname "$script_dir")"
    if [ -d "$parent_dir/plugins" ] && [ -d "$parent_dir/scripts" ]; then
        echo "$parent_dir"
        return 0
    fi

    # Search upwards for marketplace root
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/plugins" ] && [ -d "$current_dir/scripts" ] && [ -f "$current_dir/.claude-plugin/marketplace.json" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    echo "ERROR: Could not find ai-dev-marketplace root directory" >&2
    echo "Please run this script from within the marketplace directory" >&2
    return 1
}

MARKETPLACE_DIR=$(find_marketplace_root)
if [ $? -ne 0 ]; then
    exit 1
fi

cd "$MARKETPLACE_DIR"
echo "📍 Working in: $MARKETPLACE_DIR"
echo ""

echo "🔧 Fixing literal \\n in skill descriptions..."
echo ""

# Counters
files_fixed=0

# Function to fix \n in a file
fix_newlines() {
    local file="$1"

    # Check if file has the issue (literal \n in skill descriptions)
    if grep -q "## Available Skills" "$file"; then
        # Replace literal \n with actual newlines in the skill list section
        # Only between "## Available Skills" and "**To use a skill:**"

        # Use perl for more complex replacement
        perl -i -pe '
            if (/^## Available Skills/../^\*\*To use a skill:\*\*/) {
                s/\\n/\n/g unless /^\*\*To use a skill:\*\*/;
            }
        ' "$file"

        return 0
    fi

    return 1
}

# Process all agent files
echo "📝 Processing agents..."
for agent_file in plugins/*/agents/*.md; do
    if [[ -f "$agent_file" ]]; then
        if fix_newlines "$agent_file"; then
            echo "  ✅ Fixed: $agent_file"
            files_fixed=$((files_fixed + 1))
        fi
    fi
done

echo ""
echo "📝 Processing commands..."
for command_file in plugins/*/commands/*.md; do
    if [[ -f "$command_file" ]]; then
        if fix_newlines "$command_file"; then
            echo "  ✅ Fixed: $command_file"
            files_fixed=$((files_fixed + 1))
        fi
    fi
done

echo ""
echo "✨ Summary:"
echo "  Files fixed: $files_fixed"
echo ""
echo "✅ Done! Run 'git diff' to review changes."
