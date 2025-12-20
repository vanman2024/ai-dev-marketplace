#!/bin/bash
# Validate A2A and MCP protocol version compatibility

set -e

echo "=== Validating A2A + MCP Protocol Compatibility ==="

# Function to compare versions
version_compare() {
    if [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Minimum supported versions
MIN_A2A_VERSION="1.0.0"
MIN_MCP_VERSION="1.0.0"

echo "Minimum required versions:"
echo "  A2A Protocol: $MIN_A2A_VERSION+"
echo "  MCP: $MIN_MCP_VERSION+"
echo ""

# Check Python environment
if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
    echo "Checking Python environment..."
    source venv/bin/activate

    if python3 -c "import a2a" 2>/dev/null; then
        A2A_PY_VERSION=$(python3 -c "import a2a; print(a2a.__version__)" 2>/dev/null || echo "unknown")
        echo "  Python A2A SDK: $A2A_PY_VERSION"

        if [ "$A2A_PY_VERSION" != "unknown" ]; then
            if version_compare "$MIN_A2A_VERSION" "$A2A_PY_VERSION"; then
                echo "  ✓ Compatible"
            else
                echo "  ✗ Incompatible: requires $MIN_A2A_VERSION+"
            fi
        fi
    fi

    if python3 -c "import mcp" 2>/dev/null; then
        MCP_PY_VERSION=$(python3 -c "import mcp; print(mcp.__version__)" 2>/dev/null || echo "unknown")
        echo "  Python MCP SDK: $MCP_PY_VERSION"

        if [ "$MCP_PY_VERSION" != "unknown" ]; then
            if version_compare "$MIN_MCP_VERSION" "$MCP_PY_VERSION"; then
                echo "  ✓ Compatible"
            else
                echo "  ✗ Incompatible: requires $MIN_MCP_VERSION+"
            fi
        fi
    fi
fi

# Check Node.js environment
if [ -f "package.json" ] && [ -d "node_modules" ]; then
    echo ""
    echo "Checking Node.js environment..."

    if [ -d "node_modules/@a2a/protocol" ]; then
        A2A_JS_VERSION=$(node -p "require('./node_modules/@a2a/protocol/package.json').version" 2>/dev/null || echo "unknown")
        echo "  Node.js A2A SDK: $A2A_JS_VERSION"

        if [ "$A2A_JS_VERSION" != "unknown" ]; then
            if version_compare "$MIN_A2A_VERSION" "$A2A_JS_VERSION"; then
                echo "  ✓ Compatible"
            else
                echo "  ✗ Incompatible: requires $MIN_A2A_VERSION+"
            fi
        fi
    fi

    if [ -d "node_modules/@modelcontextprotocol/sdk" ]; then
        MCP_JS_VERSION=$(node -p "require('./node_modules/@modelcontextprotocol/sdk/package.json').version" 2>/dev/null || echo "unknown")
        echo "  Node.js MCP SDK: $MCP_JS_VERSION"

        if [ "$MCP_JS_VERSION" != "unknown" ]; then
            if version_compare "$MIN_MCP_VERSION" "$MCP_JS_VERSION"; then
                echo "  ✓ Compatible"
            else
                echo "  ✗ Incompatible: requires $MIN_MCP_VERSION+"
            fi
        fi
    fi
fi

echo ""
echo "=== Compatibility Check Complete ==="
echo ""
echo "Note: Both protocols are designed to be complementary:"
echo "  - A2A handles agent-to-agent communication"
echo "  - MCP handles agent-to-tool communication"
echo "  - They work together in hybrid systems"
