#!/bin/bash
# Test and validate Edge Function configuration for Vercel
# Usage: ./test-edge-functions.sh [project-directory]

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "⚡ Edge Function Configuration Test"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Find edge runtime files
echo -e "${BLUE}🔍 Scanning for Edge Runtime usage...${NC}"
echo ""

EDGE_FILES=()

# Search for edge runtime exports
if [ -d "app" ] || [ -d "pages" ]; then
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            EDGE_FILES+=("$file")
        fi
    done < <(grep -rl "export const runtime.*=.*['\"]edge['\"]" \
        --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
        app/ pages/ 2>/dev/null || true)

    # Also check for edge in config
    while IFS= read -r file; do
        if [ -n "$file" ] && [[ ! " ${EDGE_FILES[@]} " =~ " ${file} " ]]; then
            EDGE_FILES+=("$file")
        fi
    done < <(grep -rl "runtime:.*['\"]edge['\"]" \
        --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
        app/ pages/ 2>/dev/null || true)
fi

if [ ${#EDGE_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} No Edge Runtime usage found"
    echo ""
    echo "To use Edge Functions, add to your route:"
    echo ""
    echo "  export const runtime = 'edge'"
    echo ""
    exit 0
fi

echo "Found ${#EDGE_FILES[@]} file(s) using Edge Runtime:"
for file in "${EDGE_FILES[@]}"; do
    echo "  - $file"
done
echo ""

# Check each edge file for compatibility issues
echo -e "${BLUE}🔬 Analyzing Edge Function compatibility...${NC}"
echo ""

for file in "${EDGE_FILES[@]}"; do
    echo "Checking: $file"

    # Check for Node.js-specific APIs
    NODE_APIS=(
        "fs\."
        "require\("
        "process\.cwd"
        "process\.env\.NODE_ENV"
        "__dirname"
        "__filename"
        "child_process"
        "crypto\.createHash"
    )

    for api in "${NODE_APIS[@]}"; do
        if grep -q "$api" "$file" 2>/dev/null; then
            echo -e "  ${RED}✗${NC} Uses Node.js API: $api (not available in Edge)"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Check for dynamic imports that might be incompatible
    if grep -q "import.*fs.*from.*['\"]fs['\"]" "$file" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} Imports 'fs' module (not available in Edge)"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "import.*path.*from.*['\"]path['\"]" "$file" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC} Imports 'path' module (limited in Edge)"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for large dependencies
    LARGE_DEPS=("moment" "lodash" "axios")
    for dep in "${LARGE_DEPS[@]}"; do
        if grep -q "from ['\"]$dep['\"]" "$file" 2>/dev/null; then
            echo -e "  ${YELLOW}⚠${NC} Uses $dep (may increase edge bundle size)"
            WARNINGS=$((WARNINGS + 1))
        fi
    done

    # Check for proper Web API usage
    if grep -q "Request\|Response\|Headers" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Uses Web APIs (good for Edge)"
    fi

    echo ""
done

# Check middleware
echo -e "${BLUE}🔍 Checking middleware configuration...${NC}"
echo ""

MIDDLEWARE_FILES=()
if [ -f "middleware.ts" ]; then
    MIDDLEWARE_FILES+=("middleware.ts")
elif [ -f "middleware.js" ]; then
    MIDDLEWARE_FILES+=("middleware.js")
fi

# Check for middleware in src/
if [ -f "src/middleware.ts" ]; then
    MIDDLEWARE_FILES+=("src/middleware.ts")
elif [ -f "src/middleware.js" ]; then
    MIDDLEWARE_FILES+=("src/middleware.js")
fi

if [ ${#MIDDLEWARE_FILES[@]} -gt 0 ]; then
    echo "Found middleware:"
    for mw in "${MIDDLEWARE_FILES[@]}"; do
        echo "  - $mw"

        # Check for matcher configuration
        if grep -q "export const config.*matcher" "$mw" 2>/dev/null; then
            echo -e "    ${GREEN}✓${NC} Has matcher configuration"
        else
            echo -e "    ${YELLOW}⚠${NC} No matcher (runs on all routes)"
            WARNINGS=$((WARNINGS + 1))
        fi

        # Check middleware size
        SIZE=$(wc -c < "$mw")
        if [ $SIZE -gt 10240 ]; then
            echo -e "    ${YELLOW}⚠${NC} Middleware is large (${SIZE} bytes)"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
else
    echo "No middleware found"
fi

echo ""

# Check vercel.json edge configuration
echo -e "${BLUE}📋 Checking vercel.json configuration...${NC}"
echo ""

if [ -f "vercel.json" ]; then
    # Check for edge function configuration
    if jq -e '.functions' vercel.json >/dev/null 2>&1; then
        echo "Function configuration found"

        # Check for memory limits (edge has different limits)
        if jq -e '.functions."**/*".memory' vercel.json >/dev/null 2>&1; then
            MEMORY=$(jq -r '.functions."**/*".memory' vercel.json)
            echo "  Memory: ${MEMORY}MB"
            if [ "$MEMORY" -gt 128 ]; then
                echo -e "  ${YELLOW}⚠${NC} Edge functions limited to 128MB"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi

        # Check for max duration (edge has 30s limit on Hobby/Pro)
        if jq -e '.functions."**/*".maxDuration' vercel.json >/dev/null 2>&1; then
            DURATION=$(jq -r '.functions."**/*".maxDuration' vercel.json)
            echo "  Max duration: ${DURATION}s"
            if [ "$DURATION" -gt 30 ]; then
                echo -e "  ${YELLOW}⚠${NC} Edge functions limited to 30s on most plans"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    fi
else
    echo "No vercel.json found (using defaults)"
fi

echo ""

# Size recommendations
echo -e "${BLUE}📦 Size Recommendations${NC}"
echo ""
echo "Edge Function Limits:"
echo "  - Uncompressed: 1MB per function"
echo "  - Compressed: 256KB (typical)"
echo "  - Cold start: < 100ms target"
echo ""

# Best practices
echo -e "${BLUE}✅ Edge Function Best Practices${NC}"
echo ""
echo "DO:"
echo "  ✓ Use Web APIs (Request, Response, Headers, fetch)"
echo "  ✓ Keep functions small and focused"
echo "  ✓ Use for geo-routing, A/B testing, auth"
echo "  ✓ Configure matcher in middleware"
echo "  ✓ Use streaming responses when possible"
echo ""
echo "DON'T:"
echo "  ✗ Use Node.js-specific APIs"
echo "  ✗ Import large dependencies"
echo "  ✗ Perform heavy computation"
echo "  ✗ Use file system operations"
echo "  ✗ Run long-running tasks"
echo ""

# Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Edge Function Check Complete${NC}"
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"

    if [ $WARNINGS -eq 0 ]; then
        echo ""
        echo "Edge functions look good!"
    else
        echo ""
        echo "Review warnings for optimization opportunities"
    fi

    exit 0
else
    echo -e "${RED}✗ Edge Function Issues Found${NC}"
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"
    echo ""
    echo "Fix errors before deploying edge functions"
    exit 1
fi
