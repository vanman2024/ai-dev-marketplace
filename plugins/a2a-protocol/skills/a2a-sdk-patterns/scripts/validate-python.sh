#!/bin/bash
# Validate A2A Protocol Python SDK installation

set -e

echo "Validating A2A Protocol Python SDK installation..."

# Check if package is installed
if ! python3 -c "import a2a_protocol" 2>/dev/null; then
    echo "✗ A2A Protocol Python SDK is not installed"
    echo "Run: ./scripts/install-python.sh"
    exit 1
fi

# Check version
VERSION=$(python3 -c "import a2a_protocol; print(a2a_protocol.__version__)" 2>/dev/null || echo "unknown")
echo "✓ A2A Protocol Python SDK installed (version: $VERSION)"

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
