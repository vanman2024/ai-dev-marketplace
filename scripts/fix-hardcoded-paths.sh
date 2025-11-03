#!/usr/bin/env bash
# Script: fix-hardcoded-paths.sh
# Purpose: Fix hardcoded multiagent-core paths to use simple project-relative paths
# Usage: ./fix-hardcoded-paths.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "DRY RUN MODE - No files will be changed"
  echo ""
fi

PLUGINS_DIR="$HOME/.claude/marketplaces/multiagent-dev/plugins"

echo "=== Fixing Hardcoded Paths in Plugins ==="
echo ""

# Complex path pattern that needs replacement
COMPLEX_CONFIG_PATH='$([ -f "$([ -d "$HOME/.claude/marketplaces/multiagent-dev/plugins/*/skills/*/config" ] && echo "$HOME/.claude/marketplaces/multiagent-dev/plugins/*/skills/*/config" || find "$HOME/.claude/marketplaces/multiagent-dev/plugins/multiagent-config" -type d -path "*/skills/*" -name "config" 2>/dev/null | head -1).json" ] && echo "$([ -d "$HOME/.claude/marketplaces/multiagent-dev/plugins/*/skills/*/config" ] && echo "$HOME/.claude/marketplaces/multiagent-dev/plugins/*/skills/*/config" || find "$HOME/.claude/marketplaces/multiagent-dev/plugins/multiagent-config" -type d -path "*/skills/*" -name "config" 2>/dev/null | head -1).json" || find "$HOME/.claude/marketplaces/multiagent-dev/plugins/multiagent-core/skills/*" -name "config.json" -type f 2>/dev/null | head -1)'

SIMPLE_CONFIG_PATH='.multiagent/config.json'

# Count before
COMPLEX_PATHS_BEFORE=$(grep -r "multiagent-core/skills" "$PLUGINS_DIR"/*/commands/*.md "$PLUGINS_DIR"/*/agents/*.md 2>/dev/null | wc -l)

echo "Before:"
echo "  - Complex multiagent-core paths: $COMPLEX_PATHS_BEFORE"
echo ""

if $DRY_RUN; then
  echo "[DRY RUN] Would perform these replacements:"
  echo ""
fi

FIXED_FILES=0

# Fix all agent and command files
for file in "$PLUGINS_DIR"/*/agents/*.md "$PLUGINS_DIR"/*/commands/*.md; do
  [ -f "$file" ] || continue

  # Check if file has hardcoded multiagent-core references
  if grep -q "multiagent-core" "$file" 2>/dev/null; then
    if $DRY_RUN; then
      echo "[DRY RUN] Would fix: $file"
      grep -n "multiagent-core" "$file" | head -3
      echo ""
    else
      # Create backup
      cp "$file" "$file.backup"

      # Replace all complex config paths with simple .multiagent/config.json
      sed -i 's|\$HOME/\.\(claude\|multiagent\)/[^"]*config\.json|.multiagent/config.json|g' "$file"
      sed -i 's|\$(find[^)]*multiagent-core[^)]*)|.multiagent/config.json|g' "$file"
      sed -i 's|\$(find[^)]*multiagent-config[^)]*)|.multiagent/config.json|g' "$file"

      # Fix script references
      sed -i 's|\$HOME/\.\(claude\|multiagent\)/[^"]*\.sh|.multiagent/scripts/\$(basename \$0)|g' "$file"
      sed -i 's|\$(find[^)]*multiagent-core[^)]*\.sh[^)]*)|.multiagent/scripts/\$(basename \$0)|g' "$file"

      # Fix template references
      sed -i 's|\$HOME/\.\(claude\|multiagent\)/[^"]*templates|.multiagent/templates|g' "$file"
      sed -i 's|\$(find[^)]*multiagent-core[^)]*templates[^)]*)|.multiagent/templates|g' "$file"

      # Fix specific worktree reference
      sed -i 's|../multiagent-core-worktrees/|../PROJECT-worktrees/|g' "$file"

      # Fix validation reference
      sed -i 's|--plugin multiagent-core|--plugin \$(basename \$(git rev-parse --show-toplevel))|g' "$file"

      echo "✓ Fixed: $file"
      ((FIXED_FILES++))
    fi
  fi
done

echo ""

if $DRY_RUN; then
  echo "[DRY RUN] Would fix $FIXED_FILES files"
else
  echo "✓ Fixed $FIXED_FILES files"

  # Count after
  COMPLEX_PATHS_AFTER=$(grep -r "multiagent-core" "$PLUGINS_DIR"/*/commands/*.md "$PLUGINS_DIR"/*/agents/*.md 2>/dev/null | wc -l || echo 0)

  echo ""
  echo "After:"
  echo "  - Complex multiagent-core paths: $COMPLEX_PATHS_AFTER (was $COMPLEX_PATHS_BEFORE)"
  echo ""

  if [ "$COMPLEX_PATHS_AFTER" -eq 0 ]; then
    echo "🎉 All hardcoded paths fixed!"
  else
    echo "⚠️  Some references remain - may need manual review"
    echo ""
    echo "Remaining issues:"
    grep -rn "multiagent-core" "$PLUGINS_DIR"/*/commands/*.md "$PLUGINS_DIR"/*/agents/*.md 2>/dev/null | head -5
  fi

  echo ""
  echo "Backups saved with .backup extension"
  echo "To restore: find $PLUGINS_DIR -name '*.backup' -exec bash -c 'mv \"\$0\" \"\${0%.backup}\"' {} \\;"
fi
