#!/bin/bash
# Install A2A Protocol TypeScript SDK

set -e

echo "Installing A2A Protocol TypeScript SDK..."

# Check Node.js version
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
REQUIRED_VERSION=18

if [ "$NODE_VERSION" -lt "$REQUIRED_VERSION" ]; then
    echo "Error: Node.js $REQUIRED_VERSION or higher is required (found v$NODE_VERSION)"
    exit 1
fi

# Detect package manager
if [ -f "package-lock.json" ]; then
    PKG_MANAGER="npm"
elif [ -f "yarn.lock" ]; then
    PKG_MANAGER="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    PKG_MANAGER="pnpm"
else
    PKG_MANAGER="npm"
fi

echo "Using package manager: $PKG_MANAGER"

# Install SDK
echo "Installing @a2a/protocol package..."
case $PKG_MANAGER in
    npm)
        npm install @a2a/protocol
        ;;
    yarn)
        yarn add @a2a/protocol
        ;;
    pnpm)
        pnpm add @a2a/protocol
        ;;
esac

echo "✓ A2A Protocol TypeScript SDK installed successfully"
echo ""
echo "Next steps:"
echo "1. Set up environment variables (see templates/env-template.txt)"
echo "2. Configure authentication (see templates/typescript-config.ts)"
echo "3. Run validation: ./scripts/validate-typescript.sh"
