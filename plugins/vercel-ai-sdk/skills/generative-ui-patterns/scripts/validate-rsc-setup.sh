#!/bin/bash

#
# Validate Next.js RSC Setup for Generative UI
#
# Checks:
# - Next.js version (13.4+)
# - React version (18+)
# - App Router directory
# - TypeScript configuration
# - AI SDK installation
#

set -e

echo "==================================="
echo "Validating Next.js RSC Setup"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found. Are you in a Next.js project?${NC}"
    exit 1
fi

echo "Checking dependencies..."
echo ""

# Check Next.js version
if ! grep -q '"next"' package.json; then
    echo -e "${RED}❌ Next.js not found in package.json${NC}"
    exit 1
fi

NEXT_VERSION=$(node -p "require('./package.json').dependencies.next || require('./package.json').devDependencies.next" 2>/dev/null || echo "not found")
echo -e "Next.js version: ${YELLOW}${NEXT_VERSION}${NC}"

# Extract version number
NEXT_MAJOR=$(echo "$NEXT_VERSION" | sed 's/[^0-9]*\([0-9]*\)\..*/\1/')
NEXT_MINOR=$(echo "$NEXT_VERSION" | sed 's/[^0-9]*[0-9]*\.\([0-9]*\).*/\1/')

if [ "$NEXT_MAJOR" -lt 13 ] || ([ "$NEXT_MAJOR" -eq 13 ] && [ "$NEXT_MINOR" -lt 4 ]); then
    echo -e "${RED}❌ Next.js 13.4+ required for App Router and RSC${NC}"
    echo -e "${YELLOW}   Current: ${NEXT_VERSION}${NC}"
    echo -e "${YELLOW}   Run: npm install next@latest${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Next.js version OK (13.4+)${NC}"
fi

# Check React version
if ! grep -q '"react"' package.json; then
    echo -e "${RED}❌ React not found in package.json${NC}"
    exit 1
fi

REACT_VERSION=$(node -p "require('./package.json').dependencies.react || require('./package.json').devDependencies.react" 2>/dev/null || echo "not found")
echo -e "React version: ${YELLOW}${REACT_VERSION}${NC}"

REACT_MAJOR=$(echo "$REACT_VERSION" | sed 's/[^0-9]*\([0-9]*\)\..*/\1/')

if [ "$REACT_MAJOR" -lt 18 ]; then
    echo -e "${RED}❌ React 18+ required for Server Components${NC}"
    echo -e "${YELLOW}   Current: ${REACT_VERSION}${NC}"
    echo -e "${YELLOW}   Run: npm install react@latest react-dom@latest${NC}"
    exit 1
else
    echo -e "${GREEN}✓ React version OK (18+)${NC}"
fi

# Check AI SDK installation
if ! grep -q '"ai"' package.json; then
    echo -e "${YELLOW}⚠ AI SDK not found${NC}"
    echo -e "${YELLOW}   Run: npm install ai${NC}"
else
    AI_VERSION=$(node -p "require('./package.json').dependencies.ai || require('./package.json').devDependencies.ai" 2>/dev/null || echo "not found")
    echo -e "${GREEN}✓ AI SDK installed: ${AI_VERSION}${NC}"
fi

echo ""
echo "Checking project structure..."
echo ""

# Check for App Router
if [ -d "app" ]; then
    echo -e "${GREEN}✓ App Router directory found${NC}"
else
    echo -e "${RED}❌ App Router directory (app/) not found${NC}"
    echo -e "${YELLOW}   Create app/ directory for RSC support${NC}"
    exit 1
fi

# Check for TypeScript
if [ -f "tsconfig.json" ]; then
    echo -e "${GREEN}✓ TypeScript configuration found${NC}"

    # Check for proper TypeScript settings
    if grep -q '"jsx": "preserve"' tsconfig.json; then
        echo -e "${GREEN}✓ TypeScript JSX setting correct${NC}"
    else
        echo -e "${YELLOW}⚠ TypeScript JSX should be 'preserve' for Next.js${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No tsconfig.json found (JavaScript project)${NC}"
fi

# Check for next.config.js
if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
    echo -e "${GREEN}✓ Next.js config found${NC}"
else
    echo -e "${YELLOW}⚠ No next.config.js found${NC}"
fi

echo ""
echo "Checking for AI SDK providers..."
echo ""

# Check for AI SDK providers
PROVIDERS=("@ai-sdk/openai" "@ai-sdk/anthropic" "@ai-sdk/google" "@ai-sdk/xai")
FOUND_PROVIDER=0

for provider in "${PROVIDERS[@]}"; do
    if grep -q "\"$provider\"" package.json; then
        echo -e "${GREEN}✓ Found provider: $provider${NC}"
        FOUND_PROVIDER=1
    fi
done

if [ $FOUND_PROVIDER -eq 0 ]; then
    echo -e "${YELLOW}⚠ No AI SDK provider found${NC}"
    echo -e "${YELLOW}   Install at least one: npm install @ai-sdk/openai${NC}"
fi

echo ""
echo "==================================="
echo "Summary"
echo "==================================="
echo ""
echo -e "${GREEN}✓ Next.js RSC setup is valid${NC}"
echo -e "${GREEN}✓ Ready for Generative UI implementation${NC}"
echo ""
echo "Next steps:"
echo "1. Use templates/server-action-pattern.tsx for server actions"
echo "2. Use templates/client-wrapper.tsx for client components"
echo "3. Run scripts/generate-ui-component.sh to scaffold components"
echo ""
