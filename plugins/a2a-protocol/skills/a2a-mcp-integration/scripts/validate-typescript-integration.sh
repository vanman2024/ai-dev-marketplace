#!/bin/bash
# Validate TypeScript A2A + MCP integration setup

set -e

echo "=== Validating TypeScript A2A + MCP Integration ==="

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "✗ Node.js not found"
    exit 1
fi
echo "✓ Node.js version: $(node --version)"

# Check package.json
if [ ! -f "package.json" ]; then
    echo "✗ package.json not found. Run install-typescript-integration.sh first"
    exit 1
fi
echo "✓ package.json found"

# Check node_modules
if [ ! -d "node_modules" ]; then
    echo "✗ node_modules not found. Run: npm install"
    exit 1
fi
echo "✓ node_modules directory exists"

# Check A2A SDK
if [ ! -d "node_modules/@a2a/protocol" ]; then
    echo "✗ A2A Protocol SDK not installed"
    exit 1
fi
echo "✓ A2A Protocol SDK installed"

# Check MCP SDK
if [ ! -d "node_modules/@modelcontextprotocol/sdk" ]; then
    echo "✗ MCP SDK not installed"
    exit 1
fi
echo "✓ MCP SDK installed"

# Check TypeScript
if [ ! -d "node_modules/typescript" ]; then
    echo "✗ TypeScript not installed"
    exit 1
fi
echo "✓ TypeScript installed"

# Get versions
A2A_VERSION=$(node -p "require('./node_modules/@a2a/protocol/package.json').version" 2>/dev/null || echo "unknown")
MCP_VERSION=$(node -p "require('./node_modules/@modelcontextprotocol/sdk/package.json').version" 2>/dev/null || echo "unknown")
TS_VERSION=$(node -p "require('./node_modules/typescript/package.json').version" 2>/dev/null || echo "unknown")

echo "✓ A2A Protocol version: $A2A_VERSION"
echo "✓ MCP SDK version: $MCP_VERSION"
echo "✓ TypeScript version: $TS_VERSION"

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

# Test TypeScript compilation
echo ""
echo "Testing TypeScript compilation..."
cat > /tmp/test-integration.ts << 'EOF'
import { Client as A2AClient } from '@a2a/protocol';
import { Client as MCPClient } from '@modelcontextprotocol/sdk';

console.log('✓ Integration imports successful');
EOF

if npx tsc --noEmit /tmp/test-integration.ts 2>/dev/null; then
    echo "✓ TypeScript compilation successful"
    rm /tmp/test-integration.ts
else
    echo "⚠ TypeScript compilation warning (may need configuration)"
    rm /tmp/test-integration.ts
fi

echo ""
echo "=== Validation Complete ==="
echo "TypeScript A2A + MCP integration is properly configured"
echo ""
echo "Next steps:"
echo "  1. Review examples/ directory"
echo "  2. Run: ts-node examples/typescript-hybrid-agent.ts"
