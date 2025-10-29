#!/bin/bash
# Analyze build and runtime performance of Astro project

set -e

PROJECT_ROOT="${1:-.}"

echo "Analyzing Astro project performance..."
echo ""

# Check if project is built
if [ ! -d "$PROJECT_ROOT/dist" ]; then
  echo "⚠️  No dist/ directory found. Run 'npm run build' first."
  echo ""
  read -p "Run build now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_ROOT"
    npm run build
  else
    exit 1
  fi
fi

echo "================================"
echo "Build Output Analysis"
echo "================================"
echo ""

# Analyze dist directory size
if command -v du &> /dev/null; then
  TOTAL_SIZE=$(du -sh "$PROJECT_ROOT/dist" | cut -f1)
  echo "📦 Total build size: $TOTAL_SIZE"
  echo ""

  # Break down by file type
  echo "File type breakdown:"
  echo "-------------------"

  if [ -d "$PROJECT_ROOT/dist/_astro" ]; then
    JS_SIZE=$(du -sh "$PROJECT_ROOT/dist/_astro"/*.js 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
    CSS_SIZE=$(du -sh "$PROJECT_ROOT/dist/_astro"/*.css 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
    echo "JavaScript: ${JS_SIZE}KB"
    echo "CSS: ${CSS_SIZE}KB"
  fi

  echo ""
fi

# Count HTML pages
HTML_COUNT=$(find "$PROJECT_ROOT/dist" -name "*.html" | wc -l)
echo "📄 Total HTML pages: $HTML_COUNT"
echo ""

# Analyze JavaScript bundles
echo "================================"
echo "JavaScript Bundle Analysis"
echo "================================"
echo ""

if [ -d "$PROJECT_ROOT/dist/_astro" ]; then
  echo "JavaScript bundles:"
  echo "-------------------"
  find "$PROJECT_ROOT/dist/_astro" -name "*.js" -type f -exec du -h {} + | sort -rh | head -10
  echo ""
else
  echo "No JavaScript bundles found in dist/_astro/"
  echo ""
fi

# Check for large files
echo "================================"
echo "Large Files (>100KB)"
echo "================================"
echo ""

find "$PROJECT_ROOT/dist" -type f -size +100k -exec du -h {} + | sort -rh

echo ""
echo "================================"
echo "Performance Recommendations"
echo "================================"
echo ""

# Check for unoptimized images
LARGE_IMAGES=$(find "$PROJECT_ROOT/dist" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -size +200k | wc -l)
if [ "$LARGE_IMAGES" -gt 0 ]; then
  echo "⚠️  Found $LARGE_IMAGES images larger than 200KB"
  echo "   Consider using Astro's Image component for optimization"
  echo ""
fi

# Check for source maps in production
if find "$PROJECT_ROOT/dist" -name "*.map" | grep -q .; then
  echo "⚠️  Source maps found in production build"
  echo "   Consider disabling source maps for production"
  echo ""
fi

# Check for multiple CSS files
CSS_COUNT=$(find "$PROJECT_ROOT/dist" -name "*.css" | wc -l)
if [ "$CSS_COUNT" -gt 3 ]; then
  echo "⚠️  Found $CSS_COUNT CSS files"
  echo "   Consider consolidating CSS to reduce HTTP requests"
  echo ""
fi

# Recommendations
echo "💡 Performance Tips:"
echo "   1. Use <Image> component from 'astro:assets' for images"
echo "   2. Enable inlineStylesheets: 'auto' in astro.config"
echo "   3. Use client:visible or client:idle for interactive components"
echo "   4. Split large vendor bundles in vite config"
echo "   5. Enable compression in hosting platform"
echo ""

# Check if lighthouse is available
if command -v lighthouse &> /dev/null; then
  echo "💡 Run Lighthouse for detailed performance metrics:"
  echo "   lighthouse http://localhost:4321 --view"
else
  echo "💡 Install Lighthouse for detailed performance metrics:"
  echo "   npm install -g lighthouse"
fi

echo ""
echo "Performance analysis complete!"
