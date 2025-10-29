#!/bin/bash
# Validate that all plugin skills have sufficient content in templates, scripts, and examples

set -e

PLUGIN_DIR="${1:-/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/website-builder}"
MIN_EXAMPLES=3
MIN_SCRIPTS=3
MIN_TEMPLATES_PER_DIR=2

echo "🔍 Validating Plugin Completeness: $(basename $PLUGIN_DIR)"
echo "================================================"

ISSUES_FOUND=0

# Find all skills
for SKILL_DIR in "$PLUGIN_DIR/skills"/*; do
  if [ ! -d "$SKILL_DIR" ]; then
    continue
  fi

  SKILL_NAME=$(basename "$SKILL_DIR")
  echo ""
  echo "📦 Skill: $SKILL_NAME"
  echo "----------------------------------------"

  # Check SKILL.md exists
  if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
    echo "  ❌ SKILL.md is missing"
    ((ISSUES_FOUND++))
  else
    echo "  ✅ SKILL.md exists"
  fi

  # Check scripts directory
  if [ -d "$SKILL_DIR/scripts" ]; then
    SCRIPT_COUNT=$(find "$SKILL_DIR/scripts" -type f -name "*.sh" | wc -l)
    echo "  📜 Scripts: $SCRIPT_COUNT files"
    if [ $SCRIPT_COUNT -lt $MIN_SCRIPTS ]; then
      echo "     ⚠️  Warning: Less than $MIN_SCRIPTS scripts"
      ((ISSUES_FOUND++))
    fi
  else
    echo "  ❌ scripts/ directory missing"
    ((ISSUES_FOUND++))
  fi

  # Check templates directory
  if [ -d "$SKILL_DIR/templates" ]; then
    echo "  📄 Templates:"

    # Find all template subdirectories
    EMPTY_DIRS=0
    for TEMPLATE_DIR in "$SKILL_DIR/templates"/*; do
      if [ -d "$TEMPLATE_DIR" ]; then
        DIR_NAME=$(basename "$TEMPLATE_DIR")
        FILE_COUNT=$(find "$TEMPLATE_DIR" -type f | wc -l)

        if [ $FILE_COUNT -eq 0 ]; then
          echo "     ❌ $DIR_NAME/ is EMPTY"
          ((EMPTY_DIRS++))
          ((ISSUES_FOUND++))
        elif [ $FILE_COUNT -lt $MIN_TEMPLATES_PER_DIR ]; then
          echo "     ⚠️  $DIR_NAME/ has only $FILE_COUNT file(s)"
          find "$TEMPLATE_DIR" -type f -exec basename {} \; | sed 's/^/        - /'
        else
          echo "     ✅ $DIR_NAME/ has $FILE_COUNT files"
          find "$TEMPLATE_DIR" -type f -exec basename {} \; | sed 's/^/        - /'
        fi
      fi
    done

    if [ $EMPTY_DIRS -gt 0 ]; then
      echo "     ⚠️  Total empty template directories: $EMPTY_DIRS"
    fi
  else
    echo "  ❌ templates/ directory missing"
    ((ISSUES_FOUND++))
  fi

  # Check examples directory
  if [ -d "$SKILL_DIR/examples" ]; then
    EXAMPLE_COUNT=$(find "$SKILL_DIR/examples" -type f -name "*.md" | wc -l)
    echo "  📚 Examples: $EXAMPLE_COUNT files"

    if [ $EXAMPLE_COUNT -lt $MIN_EXAMPLES ]; then
      echo "     ❌ Less than $MIN_EXAMPLES examples"
      ((ISSUES_FOUND++))
    fi

    # List examples
    find "$SKILL_DIR/examples" -type f -name "*.md" -exec basename {} \; | sed 's/^/     - /'
  else
    echo "  ❌ examples/ directory missing"
    ((ISSUES_FOUND++))
  fi
done

echo ""
echo "================================================"
if [ $ISSUES_FOUND -eq 0 ]; then
  echo "✅ All validations passed! Plugin is complete."
  exit 0
else
  echo "❌ Found $ISSUES_FOUND issue(s) that need to be addressed."
  exit 1
fi
