#!/bin/bash
# Validate Vercel deployment configuration for Next.js projects
# Usage: ./validate-deployment.sh [project-directory]

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "🔍 Validating Vercel Deployment Configuration..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}✗${NC} package.json not found"
    exit 1
fi

echo -e "${GREEN}✓${NC} package.json found"

# Check for Next.js dependency
if ! grep -q "\"next\"" package.json; then
    echo -e "${RED}✗${NC} Next.js not found in dependencies"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC} Next.js dependency detected"
fi

# Validate vercel.json if it exists
if [ -f "vercel.json" ]; then
    echo ""
    echo "📄 Validating vercel.json..."

    # Check JSON syntax
    if ! jq empty vercel.json 2>/dev/null; then
        echo -e "${RED}✗${NC} vercel.json has invalid JSON syntax"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓${NC} vercel.json syntax valid"

        # Check for schema reference
        if jq -e '."$schema"' vercel.json >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Schema reference included"
        else
            echo -e "${YELLOW}⚠${NC} Schema reference missing (recommended)"
            WARNINGS=$((WARNINGS + 1))
        fi

        # Validate build command
        if jq -e '.buildCommand' vercel.json >/dev/null 2>&1; then
            BUILD_CMD=$(jq -r '.buildCommand' vercel.json)
            echo -e "${GREEN}✓${NC} Custom build command: $BUILD_CMD"
        fi

        # Check for dangerous configurations
        if jq -e '.functions."**/*".maxDuration' vercel.json >/dev/null 2>&1; then
            DURATION=$(jq -r '.functions."**/*".maxDuration' vercel.json)
            if [ "$DURATION" -gt 60 ]; then
                echo -e "${YELLOW}⚠${NC} Function duration ${DURATION}s requires Pro plan or higher"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} vercel.json not found (using defaults)"
fi

# Check environment variable documentation
echo ""
echo "🔐 Checking Environment Variables..."

if [ -f ".env.example" ]; then
    echo -e "${GREEN}✓${NC} .env.example found"

    # Count documented variables
    ENV_COUNT=$(grep -c "^[A-Z_]*=" .env.example || true)
    echo "   Found $ENV_COUNT documented variables"
else
    echo -e "${YELLOW}⚠${NC} .env.example not found (recommended for documentation)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for committed secrets
if [ -f ".env" ] || [ -f ".env.local" ] || [ -f ".env.production" ]; then
    if git ls-files --error-unmatch .env .env.local .env.production 2>/dev/null; then
        echo -e "${RED}✗${NC} Environment files tracked in Git (security risk!)"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check .gitignore
if [ -f ".gitignore" ]; then
    if grep -q "^\.env\.local$" .gitignore && grep -q "^\.env\*.local$" .gitignore; then
        echo -e "${GREEN}✓${NC} .gitignore properly excludes environment files"
    else
        echo -e "${YELLOW}⚠${NC} .gitignore missing environment file exclusions"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Verify build output directory
echo ""
echo "📦 Checking Build Configuration..."

if [ -d ".next" ]; then
    echo -e "${GREEN}✓${NC} .next build directory exists"

    # Check if .next is gitignored
    if grep -q "^\.next$" .gitignore 2>/dev/null; then
        echo -e "${GREEN}✓${NC} .next properly excluded from Git"
    else
        echo -e "${RED}✗${NC} .next should be in .gitignore"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check for Next.js configuration
if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
    echo -e "${GREEN}✓${NC} Next.js configuration found"

    # Check for edge runtime usage
    CONFIG_FILE=$(ls next.config.{js,mjs,ts} 2>/dev/null | head -1)
    if grep -q "runtime.*edge" "$CONFIG_FILE" 2>/dev/null; then
        echo "   Edge runtime detected"
    fi
else
    echo -e "${YELLOW}⚠${NC} No next.config file (using defaults)"
fi

# Check package manager lock files
echo ""
echo "📋 Checking Package Manager..."

if [ -f "package-lock.json" ]; then
    echo -e "${GREEN}✓${NC} Using npm (package-lock.json)"
elif [ -f "yarn.lock" ]; then
    echo -e "${GREEN}✓${NC} Using yarn (yarn.lock)"
elif [ -f "pnpm-lock.yaml" ]; then
    echo -e "${GREEN}✓${NC} Using pnpm (pnpm-lock.yaml)"
else
    echo -e "${RED}✗${NC} No lock file found (npm/yarn/pnpm)"
    ERRORS=$((ERRORS + 1))
fi

# Check for common performance issues
echo ""
echo "⚡ Performance Checks..."

# Check for unoptimized images
if grep -rq "img src=" --include="*.tsx" --include="*.jsx" --include="*.js" app/ pages/ 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Found <img> tags - consider using next/image"
    WARNINGS=$((WARNINGS + 1))
fi

# Check bundle size configuration
if [ -f "package.json" ]; then
    if ! grep -q "@next/bundle-analyzer" package.json; then
        echo -e "${YELLOW}⚠${NC} Consider adding @next/bundle-analyzer for bundle optimization"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Validation Complete${NC}"
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"

    if [ $WARNINGS -gt 0 ]; then
        echo ""
        echo "Deployment should succeed, but address warnings for best practices."
    else
        echo ""
        echo "Configuration looks good! Ready to deploy."
    fi

    exit 0
else
    echo -e "${RED}✗ Validation Failed${NC}"
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"
    echo ""
    echo "Fix errors before deploying to Vercel."
    exit 1
fi
