#!/bin/bash
# Validate A2A Protocol TypeScript SDK installation

set -e

echo "Validating A2A Protocol TypeScript SDK installation..."

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "✗ No package.json found in current directory"
    exit 1
fi

# Check if package is installed
if ! grep -q "@a2a/protocol" package.json; then
    echo "✗ A2A Protocol TypeScript SDK is not installed"
    echo "Run: ./scripts/install-typescript.sh"
    exit 1
fi

# Get version
VERSION=$(node -e "console.log(require('@a2a/protocol/package.json').version)" 2>/dev/null || echo "unknown")
echo "✓ A2A Protocol TypeScript SDK installed (version: $VERSION)"

# Check environment variables
if [ -z "$A2A_API_KEY" ]; then
    echo "⚠ Warning: A2A_API_KEY environment variable not set"
    echo "Set it in .env file or export it: export A2A_API_KEY=your_api_key_here"
else
    echo "✓ A2A_API_KEY is set"
fi

if [ -z "$A2A_BASE_URL" ]; then
    echo "⚠ Warning: A2A_BASE_URL environment variable not set"
    echo "Set it in .env file or export it: export A2A_BASE_URL=https://api.a2a.example.com"
else
    echo "✓ A2A_BASE_URL is set"
fi

echo ""
echo "Validation complete!"
