#!/bin/bash
# Create new page with best practices template

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <page-path> [--layout <layout-name>] [--title <title>]"
  echo "Example: $0 /about --layout marketing --title 'About Us'"
  exit 1
fi

PAGE_PATH="$1"
LAYOUT_NAME="Layout"
PAGE_TITLE=""
PROJECT_ROOT="."

# Parse arguments
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --layout)
      LAYOUT_NAME="$2"
      shift 2
      ;;
    --title)
      PAGE_TITLE="$2"
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

# Remove leading slash
PAGE_PATH="${PAGE_PATH#/}"

# Generate title from path if not provided
if [ -z "$PAGE_TITLE" ]; then
  PAGE_TITLE=$(echo "$PAGE_PATH" | sed 's/\//-/g' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
fi

# Create full path
FULL_PATH="$PROJECT_ROOT/src/pages/$PAGE_PATH.astro"
DIR_PATH=$(dirname "$FULL_PATH")

# Create directory if needed
mkdir -p "$DIR_PATH"

# Check if file already exists
if [ -f "$FULL_PATH" ]; then
  echo "❌ Page already exists: $FULL_PATH"
  exit 1
fi

# Create page file
cat > "$FULL_PATH" <<EOF
---
import $LAYOUT_NAME from '@/layouts/$LAYOUT_NAME.astro';

const pageTitle = '$PAGE_TITLE';
const pageDescription = 'Description for $PAGE_TITLE page';
---

<$LAYOUT_NAME title={pageTitle} description={pageDescription}>
  <div class="page-container">
    <header class="page-header">
      <h1>{pageTitle}</h1>
      <p class="lead">{pageDescription}</p>
    </header>

    <section class="page-content">
      <!-- TODO: Add your page content here -->
      <p>This is the $PAGE_TITLE page.</p>
    </section>
  </div>
</$LAYOUT_NAME>

<style>
  .page-container {
    max-width: 1200px;
    margin: 0 auto;
  }

  .page-header {
    text-align: center;
    margin-bottom: 3rem;
  }

  .page-header h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
  }

  .lead {
    font-size: 1.25rem;
    color: #64748b;
  }

  .page-content {
    margin-top: 2rem;
  }
</style>
EOF

echo "✅ Created page: $FULL_PATH"
echo "🌐 Page will be available at: /$PAGE_PATH"
echo "📝 TODO: Update page content and description"
