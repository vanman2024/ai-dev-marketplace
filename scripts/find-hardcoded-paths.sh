#!/bin/bash

# Find hardcoded paths in plugin files
# Usage: bash find-hardcoded-paths.sh [directory]

DIR="${1:-$HOME/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder}"

echo "Scanning for hardcoded paths in: $DIR"
echo "================================================"
echo ""

# Find markdown files with hardcoded paths (excluding URLs)
echo "## Hardcoded paths in markdown files:"
echo ""

# Look for absolute paths that aren't URLs
grep -rn \
  --include="*.md" \
  -E '(~/.claude/|/home/[^/]+/|\.claude/plugins/marketplaces/|plugins/[^/]+/)' \
  "$DIR" \
  | grep -v 'http://' \
  | grep -v 'https://' \
  | grep -v 'bash ~/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/skills/build-assistant/scripts/' \
  | grep -v '# ' \
  | grep -v 'CRITICAL: Script Paths Must Be Absolute' \
  | grep -v 'Example:' \
  | grep -v '```'

echo ""
echo "================================================"
echo ""
echo "## What should be fixed:"
echo ""
echo "For documentation references in agents/commands/skills:"
echo "  ❌ ~/.claude/plugins/.../docs/frameworks/claude/dans-composition-pattern.md"
echo "  ✅ @dans-composition-pattern.md"
echo ""
echo "For bash validation scripts (these SHOULD stay absolute):"
echo "  ✅ bash ~/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-agent.sh"
echo ""
echo "For @ references in prompts:"
echo "  ✅ @agent-color-decision.md"
echo "  ✅ @docs/frameworks/claude/dans-composition-pattern.md"
echo ""
