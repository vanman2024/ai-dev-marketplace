#!/bin/bash

# fix-argument-hints.sh
# Fixes argument hint formatting issues found by validate-argument-hints.sh

PLUGIN_DIR="${1:-.}"
FIXES_APPLIED=0

echo "=== Fixing Argument Hints ==="
echo ""

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

echo "Scanning and fixing command files..."
echo ""

while IFS= read -r file; do
  # Check if argument-hint is missing
  if ! grep -q "^argument-hint:" "$file"; then
    echo "📝 Adding missing argument-hint to: $file"
    # Add after description line
    sed -i '/^description:/a argument-hint: none' "$file"
    ((FIXES_APPLIED++))
  fi

  # Fix improper format (quoted strings without brackets)
  HINT=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^argument-hint:" | sed 's/argument-hint: *//')

  # Check if it's a quoted string like "Spec directory (e.g., 002-system-context-we)"
  if echo "$HINT" | grep -qE '^".*\(e\.g\.'; then
    echo "🔧 Fixing format in: $file"
    # Extract the main part before (e.g.,
    MAIN_PART=$(echo "$HINT" | sed 's/".*(\(e\.g\.,.*\))".*/<\1>/' | sed 's/Spec directory/<spec-directory>/')
    sed -i "s|^argument-hint:.*|argument-hint: <spec-directory>|" "$file"
    ((FIXES_APPLIED++))
  fi

  # Fix legacy subsystem references
  if grep -q "^argument-hint:.*subsystem" "$file"; then
    echo "🔄 Replacing 'subsystem' with 'plugin' in: $file"
    sed -i 's/argument-hint:.*subsystem/argument-hint: <plugin-name>/' "$file"
    ((FIXES_APPLIED++))
  fi

done <<< "$COMMAND_FILES"

echo ""
echo "=== Summary ==="
if [ $FIXES_APPLIED -eq 0 ]; then
  echo "✅ No fixes needed"
  exit 0
else
  echo "✅ Applied $FIXES_APPLIED fix(es)"
  exit 0
fi
