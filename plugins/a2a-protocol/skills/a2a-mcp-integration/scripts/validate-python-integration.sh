#!/bin/bash
# Validate Python A2A + MCP integration setup

set -e

echo "=== Validating Python A2A + MCP Integration ==="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Error: Virtual environment not found. Run install-python-integration.sh first"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

echo "Checking Python packages..."

# Check A2A SDK
if ! python3 -c "import a2a" 2>/dev/null; then
    echo "✗ A2A Protocol SDK not installed"
    exit 1
fi
echo "✓ A2A Protocol SDK installed"

# Check MCP SDK
if ! python3 -c "import mcp" 2>/dev/null; then
    echo "✗ MCP SDK not installed"
    exit 1
fi
echo "✓ MCP SDK installed"

# Check versions
A2A_VERSION=$(python3 -c "import a2a; print(a2a.__version__)" 2>/dev/null || echo "unknown")
MCP_VERSION=$(python3 -c "import mcp; print(mcp.__version__)" 2>/dev/null || echo "unknown")

echo "✓ A2A Protocol version: $A2A_VERSION"
echo "✓ MCP SDK version: $MCP_VERSION"

# Check environment variables
echo ""
echo "Checking environment configuration..."

if [ -z "$A2A_API_KEY" ]; then
    echo "⚠ Warning: A2A_API_KEY not set"
else
    echo "✓ A2A_API_KEY is set"
fi

if [ -z "$MCP_SERVER_URL" ]; then
    echo "⚠ Warning: MCP_SERVER_URL not set"
else
    echo "✓ MCP_SERVER_URL is set"
fi

# Test import
echo ""
echo "Testing integration imports..."
python3 << EOF
try:
    from a2a import Client as A2AClient
    from mcp import Client as MCPClient
    print("✓ Integration imports successful")
except Exception as e:
    print(f"✗ Import error: {e}")
    exit(1)
EOF

echo ""
echo "=== Validation Complete ==="
echo "Python A2A + MCP integration is properly configured"
echo ""
echo "Next steps:"
echo "  1. Review examples/ directory"
echo "  2. Run: python examples/python-hybrid-agent.py"
