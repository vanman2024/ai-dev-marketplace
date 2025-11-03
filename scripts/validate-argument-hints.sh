#!/bin/bash

# validate-argument-hints.sh
# Validates command argument-hint frontmatter for proper formatting

PLUGIN_DIR="${1:-.}"
ISSUES_FOUND=0

echo "=== Validating Command Argument Hints ==="
echo ""

# Check if directory exists
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "❌ ERROR: Directory not found: $PLUGIN_DIR"
  exit 1
fi

# Find all command files
COMMAND_FILES=$(find "$PLUGIN_DIR" -type f -path "*/commands/*.md" 2>/dev/null)

if [ -z "$COMMAND_FILES" ]; then
  echo "⚠️  No command files found in $PLUGIN_DIR"
  exit 0
fi

echo "Scanning command files..."
echo ""

while IFS= read -r file; do
  # Extract argument-hint from frontmatter
  HINT=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^argument-hint:" | sed 's/argument-hint: *//')

  if [ -z "$HINT" ]; then
    echo "⚠️  MISSING argument-hint: $file"
    ((ISSUES_FOUND++))
    continue
  fi

  # Check for old "subsystem" terminology
  if echo "$HINT" | grep -qi "subsystem"; then
    echo "❌ LEGACY TERM 'subsystem': $file"
    echo "   Current: $HINT"
    echo "   Should use: <plugin-name>, <spec-directory>, or specific argument"
    echo ""
    ((ISSUES_FOUND++))
  fi

  # Check for proper formatting patterns
  # Valid patterns: <required>, [optional], <arg1> <arg2>, [--flag]

  # Check if using proper brackets
  if ! echo "$HINT" | grep -qE '(<[^>]+>|\[.*\]|--[a-z-]+)'; then
    # If no brackets at all and not empty
    if [ "$HINT" != "none" ] && [ "$HINT" != "" ]; then
      echo "⚠️  IMPROPER FORMAT (missing brackets): $file"
      echo "   Current: $HINT"
      echo "   Should use: <required-arg> or [optional-arg] or [--flag]"
      echo ""
      ((ISSUES_FOUND++))
    fi
  fi

  # Check for common bad patterns
  if echo "$HINT" | grep -qE '\$[0-9]|\$ARGUMENTS|multiagent_core'; then
    echo "❌ CONTAINS VARIABLES/LEGACY: $file"
    echo "   Current: $HINT"
    echo "   Should be: Plain text description, not variable references"
    echo ""
    ((ISSUES_FOUND++))
  fi

  # Check for overly generic hints
  if [ "$HINT" = "<args>" ] || [ "$HINT" = "[args]" ] || [ "$HINT" = "args" ]; then
    echo "⚠️  TOO GENERIC: $file"
    echo "   Current: $HINT"
    echo "   Should be: Specific argument names (e.g., <spec-directory> [--type=TYPE])"
    echo ""
    ((ISSUES_FOUND++))
  fi

done <<< "$COMMAND_FILES"

echo ""
echo "=== Summary ==="
if [ $ISSUES_FOUND -eq 0 ]; then
  echo "✅ All argument hints are properly formatted"
  exit 0
else
  echo "❌ Found $ISSUES_FOUND issue(s) with argument hints"
  echo ""
  echo "Valid formats:"
  echo "  <required-arg>           - Required argument"
  echo "  [optional-arg]           - Optional argument"
  echo "  <arg1> <arg2>            - Multiple arguments"
  echo "  [--flag]                 - Optional flag"
  echo "  <spec> [--type=TYPE]     - Mixed required/optional"
  echo "  none                     - No arguments"
  echo ""
  echo "Bad patterns:"
  echo "  ❌ subsystem            - Use 'plugin-name' or 'spec-directory'"
  echo "  ❌ \$1, \$ARGUMENTS      - No variable references"
  echo "  ❌ args                  - Too generic, be specific"
  echo "  ❌ No brackets           - Must use <> or [] or --"
  exit 1
fi
