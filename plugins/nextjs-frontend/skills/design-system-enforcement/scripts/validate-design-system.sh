#!/bin/bash

# Design System Validation Script
# Validates code against design system guidelines

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

echo "🔍 Design System Validation"
echo "============================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VIOLATIONS=0
WARNINGS=0

# Check if design system exists
if [ ! -f ".design-system.md" ]; then
    echo -e "${RED}❌ No .design-system.md found${NC}"
    echo "Run ./scripts/setup-design-system.sh first"
    exit 1
fi

echo "✓ Found .design-system.md"
echo ""

# Find all TSX/JSX files
if [ -f "$TARGET" ]; then
    FILES="$TARGET"
else
    FILES=$(find "$TARGET" -type f \( -name "*.tsx" -o -name "*.jsx" \) 2>/dev/null || echo "")
fi

if [ -z "$FILES" ]; then
    echo "No TypeScript/JavaScript files found"
    exit 0
fi

echo "📁 Scanning files..."
echo ""

# 1. Check Typography - Font Sizes
echo "1️⃣  Typography: Font Sizes"
echo "   Expected: 4 sizes only"

FONT_SIZES=$(echo "$FILES" | xargs grep -oh "text-\(xs\|sm\|base\|lg\|xl\|2xl\|3xl\|4xl\|5xl\|6xl\|7xl\|8xl\|9xl\)" 2>/dev/null | sort -u || echo "")
SIZE_COUNT=$(echo "$FONT_SIZES" | grep -c "text-" || echo "0")

if [ "$SIZE_COUNT" -le 4 ]; then
    echo -e "   ${GREEN}✅ Pass${NC} - Found $SIZE_COUNT font sizes"
else
    echo -e "   ${RED}❌ Fail${NC} - Found $SIZE_COUNT font sizes (max: 4)"
    echo "   Found: $FONT_SIZES"
    VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# 2. Check Typography - Font Weights
echo "2️⃣  Typography: Font Weights"
echo "   Expected: font-semibold and font-normal only"

FONT_WEIGHTS=$(echo "$FILES" | xargs grep -oh "font-\(thin\|extralight\|light\|normal\|medium\|semibold\|bold\|extrabold\|black\)" 2>/dev/null | sort -u || echo "")

if echo "$FONT_WEIGHTS" | grep -qE "font-(thin|extralight|light|medium|bold|extrabold|black)"; then
    echo -e "   ${RED}❌ Fail${NC} - Found invalid font weights"
    echo "   Found: $FONT_WEIGHTS"
    echo "   Allowed: font-semibold, font-normal"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "   ${GREEN}✅ Pass${NC} - Using allowed font weights"
fi
echo ""

# 3. Check Spacing - 8pt Grid
echo "3️⃣  Spacing: 8pt Grid System"
echo "   All spacing must be divisible by 8 or 4"

INVALID_SPACING=$(echo "$FILES" | xargs grep -nE "\[(padding|margin|gap):[^]]*\]" 2>/dev/null || echo "")

if [ -n "$INVALID_SPACING" ]; then
    echo -e "   ${RED}❌ Fail${NC} - Found custom spacing (use Tailwind utilities)"
    echo "$INVALID_SPACING" | head -5
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "   ${GREEN}✅ Pass${NC} - Using Tailwind spacing utilities"
fi
echo ""

# 4. Check Colors - 60/30/10 Rule
echo "4️⃣  Colors: 60/30/10 Distribution"
echo "   60% neutral, 30% complementary, 10% accent"

BG_BACKGROUND=$(echo "$FILES" | xargs grep -o "bg-background" 2>/dev/null | wc -l || echo "0")
TEXT_FOREGROUND=$(echo "$FILES" | xargs grep -o "text-foreground" 2>/dev/null | wc -l || echo "0")
BG_PRIMARY=$(echo "$FILES" | xargs grep -o "bg-primary" 2>/dev/null | wc -l || echo "0")

TOTAL=$((BG_BACKGROUND + TEXT_FOREGROUND + BG_PRIMARY))

if [ "$TOTAL" -gt 0 ]; then
    PRIMARY_PERCENT=$((BG_PRIMARY * 100 / TOTAL))
    
    if [ "$PRIMARY_PERCENT" -le 10 ]; then
        echo -e "   ${GREEN}✅ Pass${NC} - Accent color at ${PRIMARY_PERCENT}%"
    else
        echo -e "   ${YELLOW}⚠️  Warning${NC} - Accent color at ${PRIMARY_PERCENT}% (should be ≤10%)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "   ${YELLOW}⚠️  Skipped${NC} - No color classes found"
fi
echo ""

# 5. Check shadcn/ui Components
echo "5️⃣  Components: shadcn/ui Usage"

CUSTOM_COMPONENTS=$(echo "$FILES" | xargs grep -E "className=\"[^\"]*button[^\"]*\"" 2>/dev/null | grep -v "@/components/ui" || echo "")

if [ -n "$CUSTOM_COMPONENTS" ]; then
    echo -e "   ${YELLOW}⚠️  Warning${NC} - Found potential custom components"
    echo "   Prefer shadcn/ui components from @/components/ui/"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "   ${GREEN}✅ Pass${NC} - Using shadcn/ui components"
fi
echo ""

# 6. Check Accessibility
echo "6️⃣  Accessibility"

BUTTONS_WITHOUT_ARIA=$(echo "$FILES" | xargs grep -n "<button" 2>/dev/null | grep -v "aria-label" | grep -v "aria-labelledby" || echo "")

if [ -n "$BUTTONS_WITHOUT_ARIA" ]; then
    echo -e "   ${YELLOW}⚠️  Warning${NC} - Some buttons missing ARIA labels"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "   ${GREEN}✅ Pass${NC} - Accessibility checks passed"
fi
echo ""

# Summary
echo "=========================="
echo "📊 Validation Summary"
echo "=========================="
echo ""

if [ "$VIOLATIONS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Design system compliance: 100%"
    exit 0
elif [ "$VIOLATIONS" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s)${NC}"
    echo ""
    echo "No critical violations, but consider addressing warnings"
    exit 0
else
    echo -e "${RED}❌ $VIOLATIONS violation(s)${NC}"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS warning(s)${NC}"
    fi
    echo ""
    echo "Please fix violations before proceeding"
    exit 1
fi
