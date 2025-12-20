#!/bin/bash
# Install TypeScript/Node.js SDKs for A2A and MCP integration

set -e

echo "=== Installing TypeScript A2A + MCP Integration SDKs ==="

# Check Node version
if ! command -v node &> /dev/null; then
    echo "Error: Node.js not found. Please install Node.js 18+"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "Error: Node.js 18+ required, found version $NODE_VERSION"
    exit 1
fi

echo "✓ Node.js version: $(node --version)"

# Initialize package.json if it doesn't exist
if [ ! -f "package.json" ]; then
    echo "Initializing package.json..."
    npm init -y
fi

# Install A2A SDK
echo "Installing A2A Protocol SDK..."
npm install @a2a/protocol

# Install MCP SDK
echo "Installing MCP SDK..."
npm install @modelcontextprotocol/sdk

# Install TypeScript and development dependencies
echo "Installing TypeScript and dependencies..."
npm install --save-dev typescript @types/node ts-node

# Install runtime dependencies
echo "Installing integration dependencies..."
npm install axios dotenv

# Create tsconfig.json if it doesn't exist
if [ ! -f "tsconfig.json" ]; then
    echo "Creating tsconfig.json..."
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node"
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
EOF
fi

echo ""
echo "=== Installation Complete ==="
echo "Installed packages:"
npm list --depth=0 | grep -E "@a2a/protocol|@modelcontextprotocol/sdk"

echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env"
echo "  2. Configure A2A_API_KEY and MCP_SERVER_URL"
echo "  3. Run: ./scripts/validate-typescript-integration.sh"
