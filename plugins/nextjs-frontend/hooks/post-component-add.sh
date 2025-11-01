#!/bin/bash
# Post-component-add hook for nextjs-frontend plugin
# Enforces design system after adding new components

set -e

COMPONENT_PATH="$1"

if [ -z "$COMPONENT_PATH" ]; then
  echo "⚠️  No component path provided, skipping validation..."
  exit 0
fi

echo "🎨 Running design system enforcement on new component..."

# Get the plugin directory
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if component file exists
if [ ! -f "$COMPONENT_PATH" ]; then
  echo "⚠️  Component file not found: $COMPONENT_PATH"
  exit 0
fi

# Run validation on the specific component
if [ -f "$PLUGIN_DIR/skills/design-system-enforcement/scripts/validate-design-system.sh" ]; then
  bash "$PLUGIN_DIR/skills/design-system-enforcement/scripts/validate-design-system.sh" "$COMPONENT_PATH" || {
    echo ""
    echo "⚠️  New component has design system violations"
    echo "   Run: /nextjs-frontend:enforce-design-system $COMPONENT_PATH --fix"
    echo ""
    # Don't fail, just warn
    exit 0
  }
  echo "✅ Component follows design system guidelines!"
else
  echo "⚠️  Design system validation script not found"
fi

exit 0
