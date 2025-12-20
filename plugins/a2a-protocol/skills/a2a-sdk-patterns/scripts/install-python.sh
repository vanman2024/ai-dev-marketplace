#!/bin/bash
# Install A2A Protocol Python SDK

set -e

echo "Installing A2A Protocol Python SDK..."

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
REQUIRED_VERSION="3.8"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Error: Python $REQUIRED_VERSION or higher is required (found $PYTHON_VERSION)"
    exit 1
fi

# Install SDK
echo "Installing a2a-protocol package..."
pip install a2a-protocol

echo "✓ A2A Protocol Python SDK installed successfully"
echo ""
echo "Next steps:"
echo "1. Set up environment variables (see templates/env-template.txt)"
echo "2. Configure authentication (see templates/python-config.py)"
echo "3. Run validation: ./scripts/validate-python.sh"
