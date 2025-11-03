#!/bin/bash

# Script to fix literal \n in skill descriptions
# Usage: bash scripts/fix-skill-newlines.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_DIR="$(dirname "$SCRIPT_DIR")"
cd "$MARKETPLACE_DIR"

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
