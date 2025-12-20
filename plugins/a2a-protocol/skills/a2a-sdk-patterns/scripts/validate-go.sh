#!/bin/bash
# Validate A2A Protocol Go SDK installation

set -e

echo "Validating A2A Protocol Go SDK installation..."

# Check if go.mod exists
if [ ! -f "go.mod" ]; then
    echo "✗ No go.mod file found"
    echo "Run: ./scripts/install-go.sh"
    exit 1
fi

# Check if package is installed
if ! grep -q "github.com/a2a/protocol-go" go.mod; then
    echo "✗ A2A Protocol Go SDK is not installed"
    echo "Run: ./scripts/install-go.sh"
    exit 1
fi

# Get version
VERSION=$(grep "github.com/a2a/protocol-go" go.mod | awk '{print $2}')
echo "✓ A2A Protocol Go SDK installed (version: $VERSION)"

# Try to build to verify
if go build > /dev/null 2>&1; then
    echo "✓ Project builds successfully"
else
    echo "⚠ Warning: Project build failed (might be normal if no main package)"
fi

# Check environment variables
if [ -z "$A2A_API_KEY" ]; then
    echo "⚠ Warning: A2A_API_KEY environment variable not set"
else
    echo "✓ A2A_API_KEY is set"
fi

if [ -z "$A2A_BASE_URL" ]; then
    echo "⚠ Warning: A2A_BASE_URL environment variable not set"
else
    echo "✓ A2A_BASE_URL is set"
fi

echo ""
echo "Validation complete!"
