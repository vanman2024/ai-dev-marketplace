#!/usr/bin/env bash
# check-prerequisites.sh - Verify system prerequisites for Astro
# Usage: bash check-prerequisites.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking Astro Prerequisites..."
echo ""

# Check Node.js
echo "[1/3] Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//')
    REQUIRED_VERSION="18.14.1"

    # Compare versions
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        echo -e "${GREEN}✅ Node.js $NODE_VERSION (>= $REQUIRED_VERSION required)${NC}"
    else
        echo -e "${RED}❌ Node.js $NODE_VERSION is too old${NC}"
        echo -e "${YELLOW}   Astro requires Node.js $REQUIRED_VERSION or higher${NC}"
        echo -e "${YELLOW}   Install from: https://nodejs.org/${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo -e "${YELLOW}   Install from: https://nodejs.org/${NC}"
    exit 1
fi
echo ""

# Check package manager
echo "[2/3] Checking package manager..."
PM_FOUND=false

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ npm $NPM_VERSION${NC}"
    PM_FOUND=true
fi

if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm --version)
    echo -e "${GREEN}✅ pnpm $PNPM_VERSION${NC}"
    PM_FOUND=true
fi

if command -v yarn &> /dev/null; then
    YARN_VERSION=$(yarn --version)
    echo -e "${GREEN}✅ yarn $YARN_VERSION${NC}"
    PM_FOUND=true
fi

if command -v bun &> /dev/null; then
    BUN_VERSION=$(bun --version)
    echo -e "${GREEN}✅ bun $BUN_VERSION${NC}"
    PM_FOUND=true
fi

if [ "$PM_FOUND" = false ]; then
    echo -e "${RED}❌ No package manager found${NC}"
    echo -e "${YELLOW}   npm comes with Node.js by default${NC}"
    exit 1
fi
echo ""

# Check Git
echo "[3/3] Checking Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo -e "${GREEN}✅ Git $GIT_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  Git not installed (optional but recommended)${NC}"
fi
echo ""

echo "========================================="
echo -e "${GREEN}✅ All prerequisites met!${NC}"
echo "========================================="
echo ""
echo "Ready to create Astro project with:"
echo "  npm create astro@latest"
echo ""

exit 0
