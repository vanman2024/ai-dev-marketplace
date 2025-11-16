#!/bin/bash
# Validate Clerk middleware configuration and best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation results
ERRORS=0
WARNINGS=0
PASSED=0

# Check file existence
check_file() {
    local file="$1"
    local description="$2"

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Check file content
check_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    local severity="${4:-error}" # error or warning

    if [ ! -f "$file" ]; then
        return 1
    fi

    if grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED=$((PASSED + 1))
        return 0
    else
        if [ "$severity" = "error" ]; then
            echo -e "${RED}✗${NC} $description"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${YELLOW}⚠${NC} $description"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

# Check for security issues
check_security() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 0
    fi

    # Check for hardcoded keys (basic patterns)
    if grep -qE "(sk-|pk_)(test|live)_[a-zA-Z0-9]{20,}" "$file"; then
        echo -e "${RED}✗ SECURITY${NC}: Hardcoded API key detected in $file"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # Check for hardcoded secrets
    if grep -qE "clerk.*key.*=.*['\"][a-zA-Z0-9_-]{20,}['\"]" "$file"; then
        echo -e "${YELLOW}⚠ SECURITY${NC}: Possible hardcoded secret in $file"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi

    return 0
}

echo -e "${BLUE}=== Clerk Middleware Validation ===${NC}"
echo ""

# 1. Check middleware file exists
echo -e "${BLUE}File Structure:${NC}"
check_file "middleware.ts" "middleware.ts exists"
echo ""

# 2. Validate middleware content
if [ -f "middleware.ts" ]; then
    echo -e "${BLUE}Middleware Configuration:${NC}"

    check_content "middleware.ts" "@clerk/nextjs" \
        "Clerk SDK imported"

    check_content "middleware.ts" "clerkMiddleware" \
        "clerkMiddleware function used"

    check_content "middleware.ts" "createRouteMatcher" \
        "Route matcher helper imported" "warning"

    check_content "middleware.ts" "matcher" \
        "Route matcher configuration present"

    check_content "middleware.ts" "NextResponse" \
        "NextResponse imported" "warning"

    echo ""
fi

# 3. Check environment configuration
echo -e "${BLUE}Environment Configuration:${NC}"

if [ -f ".env.local" ]; then
    check_content ".env.local" "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" \
        "Publishable key configured"

    check_content ".env.local" "CLERK_SECRET_KEY" \
        "Secret key configured"

    # Check for placeholder values
    if grep -q "your_clerk.*_key_here" .env.local; then
        echo -e "${YELLOW}⚠${NC} Placeholder values found - update with real keys"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Security check
    check_security ".env.local"
else
    echo -e "${YELLOW}⚠${NC} .env.local not found (environment variables may be set elsewhere)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check .env.example
if [ -f ".env.example" ]; then
    check_file ".env.example" ".env.example exists (good practice)"

    # Should NOT have real keys
    if grep -qE "(sk-|pk_)(test|live)_[a-zA-Z0-9]{20,}" .env.example 2>/dev/null; then
        echo -e "${RED}✗ SECURITY${NC}: Real API keys in .env.example"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} .env.example not found (recommended for documentation)"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""

# 4. Check gitignore
echo -e "${BLUE}Version Control:${NC}"

if [ -f ".gitignore" ]; then
    check_content ".gitignore" "\.env\.local" \
        ".env.local in .gitignore"

    check_content ".gitignore" "\.env" \
        ".env files in .gitignore" "warning"
else
    echo -e "${RED}✗${NC} .gitignore not found"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# 5. Check Next.js configuration
echo -e "${BLUE}Next.js Configuration:${NC}"

if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
    echo -e "${GREEN}✓${NC} Next.js config found"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}⚠${NC} Next.js config not found"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for App Router or Pages Router
if [ -d "app" ]; then
    echo -e "${GREEN}✓${NC} Next.js App Router detected"
    PASSED=$((PASSED + 1))
elif [ -d "pages" ]; then
    echo -e "${GREEN}✓${NC} Next.js Pages Router detected"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗${NC} Could not detect Next.js router type"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# 6. Check authentication pages
echo -e "${BLUE}Authentication Pages:${NC}"

# App Router paths
if [ -d "app" ]; then
    if [ -d "app/sign-in" ] || [ -f "app/sign-in/page.tsx" ] || [ -f "app/sign-in/page.ts" ]; then
        echo -e "${GREEN}✓${NC} Sign-in page exists"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} Sign-in page not found"
        WARNINGS=$((WARNINGS + 1))
    fi

    if [ -d "app/sign-up" ] || [ -f "app/sign-up/page.tsx" ] || [ -f "app/sign-up/page.ts" ]; then
        echo -e "${GREEN}✓${NC} Sign-up page exists"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} Sign-up page not found"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Pages Router paths
if [ -d "pages" ]; then
    if [ -f "pages/sign-in.tsx" ] || [ -f "pages/sign-in.ts" ] || [ -d "pages/sign-in" ]; then
        echo -e "${GREEN}✓${NC} Sign-in page exists"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} Sign-in page not found"
        WARNINGS=$((WARNINGS + 1))
    fi

    if [ -f "pages/sign-up.tsx" ] || [ -f "pages/sign-up.ts" ] || [ -d "pages/sign-up" ]; then
        echo -e "${GREEN}✓${NC} Sign-up page exists"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} Sign-up page not found"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""

# 7. Middleware best practices
if [ -f "middleware.ts" ]; then
    echo -e "${BLUE}Best Practices:${NC}"

    # Check for proper matcher (excludes static files)
    if grep -q "_next" middleware.ts && grep -q "static" middleware.ts; then
        echo -e "${GREEN}✓${NC} Matcher excludes Next.js internals and static files"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} Matcher may not properly exclude static files"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for API route protection
    if grep -q "api" middleware.ts; then
        echo -e "${GREEN}✓${NC} API routes included in matcher"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} API routes may not be protected"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check for proper redirect handling
    if grep -q "redirect" middleware.ts || grep -q "NextResponse.redirect" middleware.ts; then
        echo -e "${GREEN}✓${NC} Redirect logic implemented"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}⚠${NC} No redirect logic found"
        WARNINGS=$((WARNINGS + 1))
    fi

    echo ""
fi

# 8. Security checks
echo -e "${BLUE}Security Validation:${NC}"

# Check all TypeScript/JavaScript files for hardcoded keys
SECURITY_ISSUES=0
while IFS= read -r file; do
    if check_security "$file"; then
        continue
    else
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi
done < <(find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" 2>/dev/null | grep -v node_modules | head -20)

if [ $SECURITY_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No obvious security issues found in code files"
    PASSED=$((PASSED + 1))
fi

echo ""

# Summary
echo -e "${BLUE}=== Validation Summary ===${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
else
    echo "Warnings: 0"
fi
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Errors: $ERRORS${NC}"
else
    echo "Errors: 0"
fi
echo ""

# Recommendations
if [ $ERRORS -gt 0 ] || [ $WARNINGS -gt 0 ]; then
    echo -e "${BLUE}Recommendations:${NC}"

    if [ $ERRORS -gt 0 ]; then
        echo -e "${RED}Critical Issues:${NC}"
        echo "  - Fix all errors before deploying to production"
        echo "  - Ensure middleware.ts is properly configured"
        echo "  - Verify environment variables are set"
        echo ""
    fi

    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Improvements:${NC}"
        echo "  - Create .env.example for documentation"
        echo "  - Add sign-in and sign-up pages"
        echo "  - Review matcher configuration for completeness"
        echo ""
    fi
fi

# Exit code
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}✗ Validation failed${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Validation passed${NC}"
    exit 0
fi
