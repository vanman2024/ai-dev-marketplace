#!/bin/bash
# Pre-commit hook for nextjs-frontend plugin
# Validates design system compliance before commits

set -e

echo "🔍 Running Next.js Frontend pre-commit validation..."

# Get the plugin directory
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if design system skill exists
if [ ! -f "$PLUGIN_DIR/skills/design-system-enforcement/scripts/validate-design-system.sh" ]; then
  echo "⚠️  Design system validation script not found, skipping..."
  exit 0
fi

# Find all staged .tsx and .ts files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(tsx?|jsx?)$' || true)

if [ -z "$STAGED_FILES" ]; then
  echo "✅ No TypeScript/React files to validate"
  exit 0
fi

echo "📋 Validating ${STAGED_FILES} files..."

# Run design system validation
bash "$PLUGIN_DIR/skills/design-system-enforcement/scripts/validate-design-system.sh" || {
  echo ""
  echo "❌ Design system validation failed!"
  echo ""
  echo "To fix automatically, run:"
  echo "  /nextjs-frontend:enforce-design-system --fix"
  echo ""
  echo "Or bypass this check with:"
  echo "  git commit --no-verify"
  echo ""
  exit 1
}

echo "✅ Design system validation passed!"
exit 0
