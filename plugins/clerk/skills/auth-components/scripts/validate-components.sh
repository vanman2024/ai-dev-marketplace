#!/bin/bash
# Validate Clerk component implementation
# Usage: ./validate-components.sh <project-dir>

set -euo pipefail

PROJECT_DIR="${1:-.}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "=== Clerk Component Validation ==="
echo "Project: $PROJECT_DIR"
echo ""

PASSED=0
FAILED=0
WARNINGS=0

# Check for Clerk dependencies
echo "Checking dependencies..."
if [[ -f "$PROJECT_DIR/package.json" ]]; then
    if grep -q "@clerk/nextjs" "$PROJECT_DIR/package.json"; then
        log_info "@clerk/nextjs installed"
        ((PASSED++))
    else
        log_error "@clerk/nextjs not found in package.json"
        ((FAILED++))
    fi
else
    log_error "package.json not found"
    ((FAILED++))
fi

# Check for environment variables
echo ""
echo "Checking environment configuration..."
if [[ -f "$PROJECT_DIR/.env.local" ]]; then
    if grep -q "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" "$PROJECT_DIR/.env.local"; then
        log_info "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY configured"
        ((PASSED++))
    else
        log_error "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY not found"
        ((FAILED++))
    fi

    if grep -q "CLERK_SECRET_KEY" "$PROJECT_DIR/.env.local"; then
        log_info "CLERK_SECRET_KEY configured"
        ((PASSED++))
    else
        log_error "CLERK_SECRET_KEY not found"
        ((FAILED++))
    fi
else
    log_warn ".env.local not found"
    ((WARNINGS++))
fi

# Check for ClerkProvider in layout
echo ""
echo "Checking ClerkProvider setup..."
LAYOUT_FILES=(
    "$PROJECT_DIR/app/layout.tsx"
    "$PROJECT_DIR/src/app/layout.tsx"
)

CLERK_PROVIDER_FOUND=false
for layout in "${LAYOUT_FILES[@]}"; do
    if [[ -f "$layout" ]]; then
        if grep -q "ClerkProvider" "$layout"; then
            log_info "ClerkProvider found in $(basename $(dirname $layout))/$(basename $layout)"
            CLERK_PROVIDER_FOUND=true
            ((PASSED++))
            break
        fi
    fi
done

if [[ "$CLERK_PROVIDER_FOUND" == false ]]; then
    log_error "ClerkProvider not found in layout.tsx"
    ((FAILED++))
fi

# Check for auth pages
echo ""
echo "Checking authentication pages..."
AUTH_PAGES=(
    "app/sign-in"
    "app/sign-up"
    "src/app/sign-in"
    "src/app/sign-up"
)

SIGNIN_FOUND=false
SIGNUP_FOUND=false

for page_dir in "${AUTH_PAGES[@]}"; do
    if [[ -d "$PROJECT_DIR/$page_dir" ]]; then
        if [[ "$page_dir" =~ "sign-in" ]]; then
            log_info "Sign-in page found: $page_dir"
            SIGNIN_FOUND=true
            ((PASSED++))
        fi
        if [[ "$page_dir" =~ "sign-up" ]]; then
            log_info "Sign-up page found: $page_dir"
            SIGNUP_FOUND=true
            ((PASSED++))
        fi
    fi
done

if [[ "$SIGNIN_FOUND" == false ]]; then
    log_warn "Sign-in page not found"
    ((WARNINGS++))
fi

if [[ "$SIGNUP_FOUND" == false ]]; then
    log_warn "Sign-up page not found"
    ((WARNINGS++))
fi

# Check for middleware
echo ""
echo "Checking Clerk middleware..."
MIDDLEWARE_FILES=(
    "$PROJECT_DIR/middleware.ts"
    "$PROJECT_DIR/src/middleware.ts"
)

MIDDLEWARE_FOUND=false
for middleware in "${MIDDLEWARE_FILES[@]}"; do
    if [[ -f "$middleware" ]]; then
        if grep -q "clerkMiddleware\|authMiddleware" "$middleware"; then
            log_info "Clerk middleware configured"
            MIDDLEWARE_FOUND=true
            ((PASSED++))
            break
        fi
    fi
done

if [[ "$MIDDLEWARE_FOUND" == false ]]; then
    log_warn "Clerk middleware not found (optional but recommended)"
    ((WARNINGS++))
fi

# Check for hardcoded secrets
echo ""
echo "Checking for hardcoded secrets..."
SECRET_FOUND=false

# Search for patterns like sk_test_ or pk_test_ in TypeScript/JavaScript files
while IFS= read -r file; do
    if grep -q "sk_test_\|pk_test_\|sk_live_\|pk_live_" "$file" 2>/dev/null; then
        log_error "Potential hardcoded secret in: $file"
        SECRET_FOUND=true
        ((FAILED++))
    fi
done < <(find "$PROJECT_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -not -path "*/node_modules/*" 2>/dev/null)

if [[ "$SECRET_FOUND" == false ]]; then
    log_info "No hardcoded secrets detected"
    ((PASSED++))
fi

# Summary
echo ""
echo "==================================="
echo "Validation Summary:"
echo "  ✓ Passed:   $PASSED"
echo "  ✗ Failed:   $FAILED"
echo "  ⚠ Warnings: $WARNINGS"
echo "==================================="

if [[ $FAILED -eq 0 ]]; then
    echo ""
    log_info "Clerk component validation passed!"
    exit 0
else
    echo ""
    log_error "Clerk component validation failed"
    echo ""
    echo "Next steps:"
    echo "1. Install @clerk/nextjs: npm install @clerk/nextjs"
    echo "2. Add environment variables to .env.local"
    echo "3. Wrap app with <ClerkProvider> in layout.tsx"
    echo "4. Create sign-in and sign-up pages"
    exit 1
fi
