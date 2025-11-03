#!/bin/bash

# Fix hardcoded documentation references to use @ symbol
# Usage: bash fix-hardcoded-doc-refs.sh <marketplace-directory>

MARKETPLACE_DIR="${1:-$(pwd)}"

echo "Fixing hardcoded documentation references in: $MARKETPLACE_DIR"
echo "========================================================"

# Counter
FIXED=0

# Find all markdown files
find "$MARKETPLACE_DIR" -type f -name "*.md" | while read -r FILE; do
    # Skip CLAUDE.md script path examples (those should stay absolute)
    if [[ "$FILE" == *"/CLAUDE.md" ]]; then
        # Only fix @ references in CLAUDE.md, not bash script paths
        if grep -q "@plugins/domain-plugin-builder/" "$FILE" 2>/dev/null; then
            echo "Fixing @ references in: $FILE"

            # Fix template references
            sed -i 's|@plugins/domain-plugin-builder/skills/build-assistant/templates/commands/template-command-patterns.md|@template-command-patterns.md|g' "$FILE"
            sed -i 's|@plugins/domain-plugin-builder/skills/build-assistant/templates/agents/agent-with-phased-webfetch.md|@agent-with-phased-webfetch.md|g' "$FILE"

            # Fix framework doc references
            sed -i 's|@plugins/domain-plugin-builder/docs/frameworks/claude/component-decision-framework.md|@component-decision-framework.md|g' "$FILE"
            sed -i 's|@plugins/domain-plugin-builder/docs/sdks/|@|g' "$FILE"

            ((FIXED++))
        fi
        continue
    fi

    # For all other files, fix @ references
    if grep -q "@plugins/" "$FILE" 2>/dev/null; then
        echo "Fixing: $FILE"

        # Template references
        sed -i 's|@plugins/domain-plugin-builder/skills/build-assistant/templates/commands/template-command-patterns.md|@template-command-patterns.md|g' "$FILE"
        sed -i 's|@plugins/domain-plugin-builder/skills/build-assistant/templates/agents/agent-with-phased-webfetch.md|@agent-with-phased-webfetch.md|g' "$FILE"

        # Framework docs
        sed -i 's|@plugins/domain-plugin-builder/docs/frameworks/claude/component-decision-framework.md|@component-decision-framework.md|g' "$FILE"
        sed -i 's|@plugins/domain-plugin-builder/docs/frameworks/claude/dans-composition-pattern.md|@dans-composition-pattern.md|g' "$FILE"
        sed -i 's|@plugins/domain-plugin-builder/docs/frameworks/claude/agent-skills-architecture.md|@agent-skills-architecture.md|g' "$FILE"

        # SDK docs (simplified)
        sed -i 's|@plugins/domain-plugin-builder/docs/sdks/claude-agent-sdk-documentation.md|@claude-agent-sdk-documentation.md|g' "$FILE"
        sed -i 's|@plugins/domain-plugin-builder/docs/sdks/\([^/]*\)|@\1|g' "$FILE"

        # Plugin-specific docs (keep relative @plugins/PLUGIN_NAME/docs/)
        # These are OK and should stay as-is for cross-plugin references

        ((FIXED++))
    fi
done

echo ""
echo "========================================================"
echo "✅ Fixed $FIXED files"
echo ""
echo "Files with @ references should now use short names:"
echo "  @template-command-patterns.md"
echo "  @component-decision-framework.md"
echo "  @dans-composition-pattern.md"
echo ""
echo "Cross-plugin references stay as:"
echo "  @plugins/PLUGIN_NAME/docs/file.md"
echo ""
