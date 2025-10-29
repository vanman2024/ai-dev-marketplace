#!/bin/bash
# Generate new route with layouts and best practices

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <route-path> [--layout <layout-name>]"
  echo "Example: $0 /blog/[slug] --layout blog"
  exit 1
fi

ROUTE_PATH="$1"
LAYOUT_NAME="Layout"
PROJECT_ROOT="."

# Parse arguments
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --layout)
      LAYOUT_NAME="$2"
      shift 2
      ;;
    --root)
      PROJECT_ROOT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Convert layout name to proper case
LAYOUT_NAME="$(echo "$LAYOUT_NAME" | sed 's/^./\U&/')Layout"

# Remove leading slash and .astro extension
ROUTE_PATH="${ROUTE_PATH#/}"
ROUTE_PATH="${ROUTE_PATH%.astro}"

# Create full path
FULL_PATH="$PROJECT_ROOT/src/pages/$ROUTE_PATH.astro"
DIR_PATH=$(dirname "$FULL_PATH")

# Create directory if needed
mkdir -p "$DIR_PATH"

# Check if file already exists
if [ -f "$FULL_PATH" ]; then
  echo "❌ Route already exists: $FULL_PATH"
  exit 1
fi

# Determine if this is a dynamic route
if [[ "$ROUTE_PATH" == *"["* ]]; then
  # Dynamic route - needs getStaticPaths
  PARAM_NAME=$(echo "$ROUTE_PATH" | grep -o '\[.*\]' | tr -d '[]')

  cat > "$FULL_PATH" <<EOF
---
import $LAYOUT_NAME from '@/layouts/$LAYOUT_NAME.astro';

export async function getStaticPaths() {
  // TODO: Fetch data for dynamic routes
  const items = [
    { $PARAM_NAME: 'example-1' },
    { $PARAM_NAME: 'example-2' },
  ];

  return items.map((item) => ({
    params: { $PARAM_NAME: item.$PARAM_NAME },
    props: { item },
  }));
}

const { item } = Astro.props;
const { $PARAM_NAME } = Astro.params;
---

<$LAYOUT_NAME title={\`Page \${$PARAM_NAME}\`}>
  <h1>Dynamic Route: {$PARAM_NAME}</h1>
  <!-- TODO: Add your content here -->
</$LAYOUT_NAME>
EOF

  echo "✅ Created dynamic route: $FULL_PATH"
  echo "📝 TODO: Update getStaticPaths with actual data"
else
  # Static route
  PAGE_TITLE=$(echo "$ROUTE_PATH" | sed 's/\//-/g' | sed 's/^./\U&/' | sed 's/-/ /g')

  cat > "$FULL_PATH" <<EOF
---
import $LAYOUT_NAME from '@/layouts/$LAYOUT_NAME.astro';
---

<$LAYOUT_NAME title="$PAGE_TITLE">
  <h1>$PAGE_TITLE</h1>
  <!-- TODO: Add your content here -->
</$LAYOUT_NAME>
EOF

  echo "✅ Created static route: $FULL_PATH"
fi

echo "🌐 Route will be available at: /$ROUTE_PATH"
