#!/bin/bash
# optimize-components.sh - Apply performance optimizations

set -e

echo "⚡ Applying component performance optimizations..."
echo ""

# Check if we're in an Astro project
if [ ! -f "astro.config.mjs" ] && [ ! -f "astro.config.ts" ]; then
  echo "❌ Error: Not in an Astro project directory"
  exit 1
fi

CONFIG_FILE="astro.config.mjs"
if [ -f "astro.config.ts" ]; then
  CONFIG_FILE="astro.config.ts"
fi

echo "📊 Analyzing component usage patterns..."

# Find all React components
REACT_COMPONENTS=$(find src/components -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l)
echo "   Found $REACT_COMPONENTS React components"

# Find all Astro files that use React components
ASTRO_FILES_WITH_REACT=$(grep -r "client:" src --include="*.astro" 2>/dev/null | wc -l)
echo "   Found $ASTRO_FILES_WITH_REACT Astro files with hydrated components"

echo ""
echo "🔍 Checking for optimization opportunities..."
echo ""

# Check for client:load usage (least optimal)
CLIENT_LOAD_COUNT=$(grep -r "client:load" src --include="*.astro" 2>/dev/null | wc -l)
if [ $CLIENT_LOAD_COUNT -gt 0 ]; then
  echo "⚠️  Found $CLIENT_LOAD_COUNT instances of client:load"
  echo "   Consider using client:visible or client:idle for better performance"
  echo ""
  echo "   Files using client:load:"
  grep -r "client:load" src --include="*.astro" 2>/dev/null | cut -d: -f1 | sort -u | sed 's/^/   - /'
  echo ""
fi

# Check for client:visible and client:idle usage (optimal)
CLIENT_VISIBLE_COUNT=$(grep -r "client:visible" src --include="*.astro" 2>/dev/null | wc -l)
CLIENT_IDLE_COUNT=$(grep -r "client:idle" src --include="*.astro" 2>/dev/null | wc -l)

echo "✅ Optimized hydration patterns:"
echo "   - client:visible: $CLIENT_VISIBLE_COUNT instances"
echo "   - client:idle: $CLIENT_IDLE_COUNT instances"

echo ""
echo "🎯 Performance recommendations:"
echo ""

# Recommendation 1: Use appropriate client directives
echo "1. Client Directive Strategy:"
echo "   ✓ Use client:load only for above-the-fold critical interactive elements"
echo "   ✓ Use client:visible for below-the-fold components (lazy load)"
echo "   ✓ Use client:idle for non-critical interactive components"
echo "   ✓ Use client:media for responsive components"
echo ""

# Recommendation 2: Code splitting
echo "2. Code Splitting:"
if grep -q "import.*from.*react" src/components/*.tsx 2>/dev/null; then
  echo "   ✓ Use dynamic imports for heavy components:"
  echo "     const HeavyComponent = lazy(() => import('./HeavyComponent'));"
  echo ""
fi

# Recommendation 3: Bundle analysis
echo "3. Bundle Analysis:"
echo "   Run: npm run build && npx astro build --analyze"
echo "   This will show you bundle sizes and opportunities for optimization"
echo ""

# Recommendation 4: Image optimization
echo "4. Image Optimization:"
if [ -d "src/assets" ] || [ -d "public/images" ]; then
  echo "   ✓ Use Astro Image component for automatic optimization:"
  echo "     import { Image } from 'astro:assets';"
  echo "     <Image src={myImage} alt=\"...\" />"
  echo ""
fi

# Recommendation 5: CSS optimization
echo "5. CSS Optimization:"
if [ -f "tailwind.config.mjs" ] || [ -f "tailwind.config.ts" ]; then
  TAILWIND_CONFIG="tailwind.config.mjs"
  if [ -f "tailwind.config.ts" ]; then
    TAILWIND_CONFIG="tailwind.config.ts"
  fi

  if grep -q "purge" "$TAILWIND_CONFIG" || grep -q "content" "$TAILWIND_CONFIG"; then
    echo "   ✅ Tailwind purge/content configuration found"
  else
    echo "   ⚠️  Ensure Tailwind content paths are properly configured"
    echo "      content: ['./src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx,vue}']"
  fi
  echo ""
fi

# Check for performance-critical patterns
echo "6. React Performance Patterns:"
echo "   ✓ Use React.memo() for expensive components"
echo "   ✓ Use useMemo() and useCallback() to prevent unnecessary re-renders"
echo "   ✓ Avoid inline function definitions in JSX"
echo "   ✓ Split large components into smaller, focused components"
echo ""

# Create optimization report
REPORT_FILE=".astro/optimization-report.txt"
mkdir -p .astro

cat > "$REPORT_FILE" << EOF
Component Integration Optimization Report
Generated: $(date)
==========================================

Component Statistics:
- Total React Components: $REACT_COMPONENTS
- Astro Files with Hydration: $ASTRO_FILES_WITH_REACT
- client:load usage: $CLIENT_LOAD_COUNT
- client:visible usage: $CLIENT_VISIBLE_COUNT
- client:idle usage: $CLIENT_IDLE_COUNT

Optimization Score: $(( (CLIENT_VISIBLE_COUNT + CLIENT_IDLE_COUNT) * 100 / (ASTRO_FILES_WITH_REACT + 1) ))%

Recommendations:
1. Review client:load usage and consider alternatives
2. Implement code splitting for heavy components
3. Run bundle analysis: npm run build && npx astro build --analyze
4. Optimize images using Astro Image component
5. Ensure Tailwind CSS purge is configured correctly
6. Apply React performance patterns (memo, useMemo, useCallback)

Files to Review:
$(grep -r "client:load" src --include="*.astro" 2>/dev/null | cut -d: -f1 | sort -u || echo "None")

Next Steps:
- Review components with client:load
- Consider lazy loading non-critical components
- Measure performance with Lighthouse
- Monitor bundle sizes in production builds
EOF

echo "📄 Optimization report saved to: $REPORT_FILE"
echo ""

echo "✅ Optimization analysis complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Review the recommendations above"
echo "   2. Update client directives where appropriate"
echo "   3. Run 'npm run build' to measure bundle size"
echo "   4. Test with Lighthouse for performance metrics"
echo ""
echo "💡 Pro tip: Use 'npm run preview' to test the optimized build locally"
