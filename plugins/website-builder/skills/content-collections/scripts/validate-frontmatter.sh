#!/bin/bash
# validate-frontmatter.sh
# Validate content frontmatter against collection schema

set -e

COLLECTION_NAME="$1"
CONTENT_PATH="$2"

if [ -z "$COLLECTION_NAME" ] || [ -z "$CONTENT_PATH" ]; then
  echo "Usage: $0 <collection-name> <content-path>"
  echo "Example: $0 blog src/content/blog/my-post.md"
  exit 1
fi

PROJECT_ROOT="$(dirname "$CONTENT_PATH" | sed 's|/src/content.*||')"
CONFIG_FILE="$PROJECT_ROOT/src/content/config.ts"

echo "Validating frontmatter for: $CONTENT_PATH"
echo "Collection: $COLLECTION_NAME"
echo ""

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Content config not found at $CONFIG_FILE"
  echo "Run setup-content-collections.sh first"
  exit 1
fi

# Check if content file exists
if [ ! -f "$CONTENT_PATH" ]; then
  echo "Error: Content file not found: $CONTENT_PATH"
  exit 1
fi

# Extract frontmatter (between --- delimiters)
FRONTMATTER=$(awk '/^---$/{flag=!flag;next}flag' "$CONTENT_PATH")

if [ -z "$FRONTMATTER" ]; then
  echo "Error: No frontmatter found in $CONTENT_PATH"
  exit 1
fi

echo "Frontmatter extracted:"
echo "---"
echo "$FRONTMATTER"
echo "---"
echo ""

# Create temporary validation script
TEMP_VALIDATOR=$(mktemp --suffix=.mjs)

cat > "$TEMP_VALIDATOR" << 'EOF'
import { z } from 'zod';
import fs from 'fs';
import yaml from 'yaml';

const args = process.argv.slice(2);
const collectionName = args[0];
const configPath = args[1];
const frontmatter = args[2];

// Parse frontmatter YAML
let parsedFrontmatter;
try {
  parsedFrontmatter = yaml.parse(frontmatter);
} catch (error) {
  console.error('Error parsing frontmatter YAML:', error.message);
  process.exit(1);
}

// Import collection schema
let collections;
try {
  const configModule = await import(configPath);
  collections = configModule.collections;
} catch (error) {
  console.error('Error loading config:', error.message);
  process.exit(1);
}

const collection = collections[collectionName];
if (!collection) {
  console.error(`Error: Collection "${collectionName}" not found in config`);
  console.error(`Available collections: ${Object.keys(collections).join(', ')}`);
  process.exit(1);
}

// Validate frontmatter against schema
const result = collection.schema.safeParse(parsedFrontmatter);

if (result.success) {
  console.log('✓ Validation passed!');
  console.log('');
  console.log('Validated fields:');
  Object.entries(result.data).forEach(([key, value]) => {
    console.log(`  ${key}: ${JSON.stringify(value)}`);
  });
  process.exit(0);
} else {
  console.error('✗ Validation failed!');
  console.error('');
  console.error('Errors:');
  result.error.errors.forEach(err => {
    console.error(`  - ${err.path.join('.')}: ${err.message}`);
  });
  process.exit(1);
}
EOF

# Check if node is available
if ! command -v node &> /dev/null; then
  echo "Error: Node.js not found. Please install Node.js to run validation."
  rm "$TEMP_VALIDATOR"
  exit 1
fi

# Check if required packages are installed
if [ ! -d "$PROJECT_ROOT/node_modules/zod" ]; then
  echo "Error: zod not installed. Run: npm install zod"
  rm "$TEMP_VALIDATOR"
  exit 1
fi

# Run validation
echo "Running validation..."
cd "$PROJECT_ROOT"
node "$TEMP_VALIDATOR" "$COLLECTION_NAME" "$CONFIG_FILE" "$FRONTMATTER"
RESULT=$?

# Cleanup
rm "$TEMP_VALIDATOR"

if [ $RESULT -eq 0 ]; then
  echo ""
  echo "Validation successful!"
else
  echo ""
  echo "Validation failed. Please fix the errors above."
fi

exit $RESULT
