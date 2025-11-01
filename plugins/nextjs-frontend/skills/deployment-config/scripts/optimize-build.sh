#!/bin/bash
# Analyze and optimize Next.js build performance for Vercel
# Usage: ./optimize-build.sh [project-directory]

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "⚡ Next.js Build Optimization Analysis"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if next is installed
if ! command -v npx &> /dev/null; then
    echo "Error: npx not found. Please install Node.js"
    exit 1
fi

# Run build with timing
echo -e "${BLUE}📦 Building project...${NC}"
BUILD_START=$(date +%s)

if npm run build 2>&1 | tee build.log; then
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    echo -e "${GREEN}✓ Build completed in ${BUILD_TIME}s${NC}"
else
    echo "Build failed. Check build.log for details."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 Build Analysis${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Parse build output for route information
if [ -f "build.log" ]; then
    echo ""
    echo "Route Analysis:"
    echo "---------------"

    # Count route types
    STATIC_COUNT=$(grep -c "○ Static" build.log || echo "0")
    SSG_COUNT=$(grep -c "● SSG" build.log || echo "0")
    SSR_COUNT=$(grep -c "λ Server" build.log || echo "0")
    EDGE_COUNT=$(grep -c "ƒ Edge" build.log || echo "0")

    echo "  Static Routes: $STATIC_COUNT"
    echo "  SSG Routes: $SSG_COUNT"
    echo "  SSR Routes: $SSR_COUNT"
    echo "  Edge Routes: $EDGE_COUNT"

    TOTAL_ROUTES=$((STATIC_COUNT + SSG_COUNT + SSR_COUNT + EDGE_COUNT))

    if [ $TOTAL_ROUTES -gt 0 ]; then
        STATIC_PCT=$((STATIC_COUNT * 100 / TOTAL_ROUTES))
        echo ""
        echo "  Static/SSG Routes: ${STATIC_PCT}%"

        if [ $STATIC_PCT -lt 50 ]; then
            echo -e "  ${YELLOW}⚠ Consider using more static generation for better performance${NC}"
        fi
    fi
fi

# Check bundle sizes
echo ""
echo "Bundle Size Analysis:"
echo "---------------------"

if [ -d ".next" ]; then
    # Get largest chunks
    echo "Largest JavaScript chunks:"
    find .next -name "*.js" -type f -exec du -h {} + | sort -rh | head -5 | while read size file; do
        echo "  $size - $(basename $file)"
    done

    # Check for common large dependencies
    echo ""
    echo "Checking for large dependencies..."

    LARGE_DEPS=()
    if grep -q "\"moment\"" package.json 2>/dev/null; then
        LARGE_DEPS+=("moment (consider date-fns or day.js)")
    fi
    if grep -q "\"lodash\"" package.json 2>/dev/null; then
        if ! grep -q "\"lodash-es\"" package.json; then
            LARGE_DEPS+=("lodash (use lodash-es for tree-shaking)")
        fi
    fi

    if [ ${#LARGE_DEPS[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}⚠ Large dependencies found:${NC}"
        for dep in "${LARGE_DEPS[@]}"; do
            echo "    - $dep"
        done
    else
        echo -e "  ${GREEN}✓ No obvious large dependencies${NC}"
    fi
fi

# Optimization recommendations
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}💡 Optimization Recommendations${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RECOMMENDATIONS=()

# Check for bundle analyzer
if ! grep -q "@next/bundle-analyzer" package.json 2>/dev/null; then
    RECOMMENDATIONS+=("Install @next/bundle-analyzer to visualize bundle sizes")
fi

# Check for image optimization
if ! grep -q "next/image" -r app/ pages/ 2>/dev/null; then
    if grep -rq "<img" app/ pages/ 2>/dev/null; then
        RECOMMENDATIONS+=("Use next/image instead of <img> for automatic optimization")
    fi
fi

# Check for dynamic imports
if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
    if ! grep -q "dynamic.*import" app/ pages/ -r 2>/dev/null; then
        RECOMMENDATIONS+=("Consider dynamic imports for large components")
    fi
fi

# Check for SWC
if grep -q "\"@swc" package.json 2>/dev/null; then
    echo -e "${GREEN}✓ Using SWC for faster builds${NC}"
else
    RECOMMENDATIONS+=("Ensure SWC is enabled (default in Next.js 12+)")
fi

# Check for incremental builds
if [ -d ".next/cache" ]; then
    echo -e "${GREEN}✓ Build cache exists${NC}"
else
    RECOMMENDATIONS+=("Ensure build cache directory exists")
fi

# Output recommendations
if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
    for rec in "${RECOMMENDATIONS[@]}"; do
        echo -e "${YELLOW}→${NC} $rec"
    done
else
    echo -e "${GREEN}✓ Build configuration looks optimized!${NC}"
fi

# Vercel-specific optimizations
echo ""
echo "Vercel-Specific Optimizations:"
echo "------------------------------"

if [ -f "vercel.json" ]; then
    # Check function configuration
    if jq -e '.functions' vercel.json >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Function configuration present${NC}"
    else
        echo -e "${YELLOW}⚠ Consider configuring function memory/duration${NC}"
    fi

    # Check image optimization
    if jq -e '.images' vercel.json >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Image optimization configured${NC}"
    else
        echo "  Add image optimization settings for better performance"
    fi
else
    echo -e "${YELLOW}⚠ No vercel.json - using defaults${NC}"
    echo "  Create vercel.json to optimize function settings"
fi

# Build time analysis
echo ""
echo "Build Performance:"
echo "------------------"
echo "  Total build time: ${BUILD_TIME}s"

if [ $BUILD_TIME -gt 300 ]; then
    echo -e "  ${YELLOW}⚠ Build time > 5 minutes${NC}"
    echo "  Recommendations:"
    echo "    - Use incremental static regeneration (ISR)"
    echo "    - Implement proper code splitting"
    echo "    - Check for large dependencies"
elif [ $BUILD_TIME -gt 120 ]; then
    echo -e "  ${YELLOW}⚠ Build time > 2 minutes${NC}"
    echo "  Consider optimizing for faster builds"
else
    echo -e "  ${GREEN}✓ Build time is reasonable${NC}"
fi

# Cleanup
rm -f build.log

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Analysis complete!"
echo ""
echo "Next steps:"
echo "  1. Review recommendations above"
echo "  2. Install @next/bundle-analyzer for detailed analysis"
echo "  3. Configure vercel.json for production optimization"
echo "  4. Test deployment with 'vercel' command"
