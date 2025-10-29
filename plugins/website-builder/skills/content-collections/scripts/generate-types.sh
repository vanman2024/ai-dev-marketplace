#!/bin/bash
# generate-types.sh
# Generate TypeScript types from content collection schemas

set -e

PROJECT_PATH="${1:-.}"
CONFIG_FILE="$PROJECT_PATH/src/content/config.ts"
TYPES_DIR="$PROJECT_PATH/.astro"

echo "Generating TypeScript types for content collections..."
echo "Project: $PROJECT_PATH"
echo ""

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Content config not found at $CONFIG_FILE"
  echo "Run setup-content-collections.sh first"
  exit 1
fi

# Check if Astro is installed
PACKAGE_JSON="$PROJECT_PATH/package.json"
if [ ! -f "$PACKAGE_JSON" ]; then
  echo "Error: package.json not found in $PROJECT_PATH"
  exit 1
fi

if ! grep -q '"astro"' "$PACKAGE_JSON"; then
  echo "Error: Astro not found in package.json"
  echo "Install with: npm install astro"
  exit 1
fi

# Create types directory
mkdir -p "$TYPES_DIR"

echo "Running Astro type generation..."
cd "$PROJECT_PATH"

# Check if we can use npx
if command -v npx &> /dev/null; then
  echo "Using npx astro sync..."
  npx astro sync
elif command -v npm &> /dev/null; then
  echo "Using npm run astro sync..."
  npm run astro sync
else
  echo "Error: Neither npx nor npm found"
  exit 1
fi

# Verify types were generated
TYPES_FILE="$TYPES_DIR/types.d.ts"
if [ -f "$TYPES_FILE" ]; then
  echo ""
  echo "✓ Types generated successfully!"
  echo ""
  echo "Generated type file: $TYPES_FILE"
  echo ""

  # Show collection types
  echo "Available collection types:"
  grep "export const collections" "$CONFIG_FILE" | sed 's/.*{\s*//' | sed 's/\s*}.*//' | tr ',' '\n' | sed 's/^\s*/  - /'
  echo ""

  echo "You can now import types in your Astro components:"
  echo '  import type { CollectionEntry } from "astro:content";'
  echo '  type BlogPost = CollectionEntry<"blog">;'
else
  echo ""
  echo "Warning: Types file not found at $TYPES_FILE"
  echo "This may indicate an issue with Astro type generation."
fi

echo ""
echo "Type generation complete!"
echo ""
echo "Next steps:"
echo "1. Restart your IDE/editor to load new types"
echo "2. Import collection types in your .astro files"
echo "3. Use getCollection() with auto-completion"
