#!/bin/bash

# Fix script issues across marketplaces:
# 1. Make all .sh scripts executable
# 2. Verify script references use absolute paths (they should!)
# Usage: bash fix-script-issues.sh <marketplace-directory>

MARKETPLACE_DIR="${1:-$(pwd)}"

echo "Fixing script issues in: $MARKETPLACE_DIR"
echo "========================================================"
echo ""

# Counter
FIXED_PERMS=0
WRONG_REFS=0

echo "## Phase 1: Making all .sh scripts executable"
echo ""

# Find all .sh files and make them executable
find "$MARKETPLACE_DIR" -type f -name "*.sh" | while read -r SCRIPT; do
    if [ ! -x "$SCRIPT" ]; then
        echo "Making executable: $SCRIPT"
        chmod +x "$SCRIPT"
        ((FIXED_PERMS++))
    fi
done

echo "✅ Fixed permissions on $FIXED_PERMS scripts"
echo ""

echo "## Phase 2: Checking script references in markdown files"
echo ""

# Find markdown files with script references that DON'T use absolute paths
find "$MARKETPLACE_DIR" -type f -name "*.md" -exec grep -l '!{bash .*\.sh' {} \; | while read -r FILE; do
    # Check for relative script paths (bad)
    if grep -q '!{bash plugins/.*\.sh' "$FILE" 2>/dev/null; then
        echo "⚠️  Found RELATIVE script path in: $FILE"
        grep -n '!{bash plugins/.*\.sh' "$FILE"
        ((WRONG_REFS++))
    fi

    # Check for $HOME variable usage (bad - should be ~)
    if grep -q '!{bash \$HOME/.claude/.*\.sh' "$FILE" 2>/dev/null; then
        echo "⚠️  Found \$HOME instead of ~ in: $FILE"
        grep -n '!{bash \$HOME/.claude/.*\.sh' "$FILE"
        ((WRONG_REFS++))
    fi
done

echo ""
echo "========================================================"
echo "✅ Made $FIXED_PERMS scripts executable"
echo ""

if [ $WRONG_REFS -gt 0 ]; then
    echo "⚠️  Found $WRONG_REFS files with incorrect script references"
    echo ""
    echo "Script references should use ABSOLUTE paths:"
    echo "  ✅ !{bash ~/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-agent.sh}"
    echo "  ❌ !{bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-agent.sh}"
    echo "  ❌ !{bash \$HOME/.claude/plugins/...}"
    echo ""
    echo "Why: Scripts must be callable from ANY working directory"
else
    echo "✅ All script references use absolute paths correctly"
fi

echo ""
echo "## Summary"
echo ""
echo "Executable scripts:"
find "$MARKETPLACE_DIR" -type f -name "*.sh" -executable | wc -l
echo ""
echo "Non-executable scripts:"
find "$MARKETPLACE_DIR" -type f -name "*.sh" ! -executable | wc -l
echo ""
