#!/bin/bash
# SEO Audit Script for Next.js Applications
# Checks for 2025 SEO best practices

echo "🔍 Running SEO Audit..."
echo "========================"

ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}!${NC} $1"; ((WARNINGS++)); }

echo ""
echo "📄 Metadata Configuration"
echo "-------------------------"

# Check for metadata in layout
if grep -q "Metadata" app/layout.tsx 2>/dev/null; then
    pass "Metadata API used in app/layout.tsx"
else
    fail "Metadata API not found in app/layout.tsx"
fi

# Check for metadataBase
if grep -q "metadataBase" app/layout.tsx 2>/dev/null; then
    pass "metadataBase configured"
else
    warn "metadataBase not set (needed for relative URLs)"
fi

# Check for Open Graph
if grep -rq "openGraph" app/ 2>/dev/null; then
    pass "Open Graph tags configured"
else
    fail "Open Graph tags not found"
fi

# Check for Twitter cards
if grep -rq "twitter:" app/ 2>/dev/null || grep -rq "\"twitter\"" app/ 2>/dev/null; then
    pass "Twitter card configuration found"
else
    warn "Twitter card configuration not found"
fi

echo ""
echo "🗺️  Sitemap & Robots"
echo "--------------------"

# Check for sitemap
if [ -f "app/sitemap.ts" ] || [ -f "app/sitemap.tsx" ]; then
    pass "Dynamic sitemap found (app/sitemap.ts)"
elif [ -f "public/sitemap.xml" ]; then
    warn "Static sitemap found (prefer dynamic app/sitemap.ts)"
else
    fail "No sitemap found"
fi

# Check for robots
if [ -f "app/robots.ts" ] || [ -f "app/robots.tsx" ]; then
    pass "Dynamic robots.txt found (app/robots.ts)"
elif [ -f "public/robots.txt" ]; then
    warn "Static robots.txt found (prefer dynamic app/robots.ts)"
else
    fail "No robots.txt found"
fi

echo ""
echo "📊 Schema Markup"
echo "----------------"

# Check for JSON-LD
if grep -rq "application/ld+json" app/ components/ 2>/dev/null; then
    pass "JSON-LD structured data found"
else
    warn "No JSON-LD structured data found"
fi

# Check for Organization schema
if grep -rq '"@type": "Organization"' app/ components/ 2>/dev/null || \
   grep -rq "'@type': 'Organization'" app/ components/ 2>/dev/null; then
    pass "Organization schema found"
else
    warn "Organization schema not implemented"
fi

echo ""
echo "🖼️  Image Optimization"
echo "----------------------"

# Check for next/image usage
IMG_COUNT=$(grep -r "next/image" app/ components/ --include="*.tsx" 2>/dev/null | wc -l)
if [ "$IMG_COUNT" -gt 0 ]; then
    pass "next/image used ($IMG_COUNT imports found)"
else
    warn "next/image not used - consider for LCP optimization"
fi

# Check for priority images
if grep -rq "priority" app/ components/ --include="*.tsx" 2>/dev/null; then
    pass "Priority images found (good for LCP)"
else
    warn "No priority images found - add priority to above-fold images"
fi

echo ""
echo "🔤 Font Optimization"
echo "--------------------"

# Check for next/font
if grep -rq "next/font" app/ 2>/dev/null; then
    pass "next/font used for font optimization"
else
    warn "next/font not used - consider for CLS prevention"
fi

# Check for font-display: swap
if grep -rq "display: 'swap'" app/ 2>/dev/null || \
   grep -rq 'display: "swap"' app/ 2>/dev/null; then
    pass "font-display: swap configured"
else
    warn "font-display: swap not found"
fi

echo ""
echo "📝 Content Structure"
echo "--------------------"

# Check for semantic headings
H1_COUNT=$(grep -r "<h1" app/ --include="*.tsx" 2>/dev/null | wc -l)
if [ "$H1_COUNT" -gt 0 ]; then
    pass "H1 headings found ($H1_COUNT occurrences)"
else
    warn "No H1 headings found"
fi

# Check for alt text on images
if grep -rq 'alt=' app/ components/ --include="*.tsx" 2>/dev/null; then
    pass "Alt text attributes found on images"
else
    fail "No alt text found - add alt text to all images"
fi

echo ""
echo "📊 Summary"
echo "=========="
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}SEO audit passed!${NC}"
    exit 0
else
    echo -e "${RED}SEO audit found issues that need attention.${NC}"
    exit 1
fi
