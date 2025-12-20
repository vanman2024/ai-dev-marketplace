#!/bin/bash
# Install Python SDKs for A2A and MCP integration

set -e

echo "=== Installing Python A2A + MCP Integration SDKs ==="

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
REQUIRED_VERSION="3.8"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Error: Python 3.8+ required, found $PYTHON_VERSION"
    exit 1
fi

echo "✓ Python version: $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

echo "Installing A2A Protocol SDK..."
pip install --upgrade pip
pip install a2a-protocol

echo "Installing MCP SDK..."
pip install mcp-sdk

echo "Installing integration dependencies..."
pip install aiohttp asyncio python-dotenv

echo ""
echo "=== Installation Complete ==="
echo "Installed packages:"
pip list | grep -E "a2a-protocol|mcp-sdk|aiohttp"

echo ""
echo "To activate the environment:"
echo "  source venv/bin/activate"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env"
echo "  2. Configure A2A_API_KEY and MCP_SERVER_URL"
echo "  3. Run: ./scripts/validate-python-integration.sh"
