#!/bin/bash
# setup-vercel-integration.sh
# Sets up Vercel AI SDK with OpenRouter integration

set -e

echo "🚀 Setting up Vercel AI SDK with OpenRouter..."

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this in a Node.js project root."
    exit 1
fi

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
    PKG_MGR="pnpm"
elif [ -f "yarn.lock" ]; then
    PKG_MGR="yarn"
elif [ -f "bun.lockb" ]; then
    PKG_MGR="bun"
else
    PKG_MGR="npm"
fi

echo "📦 Detected package manager: $PKG_MGR"

# Install Vercel AI SDK
echo "📥 Installing Vercel AI SDK..."
case $PKG_MGR in
    pnpm)
        pnpm add ai @ai-sdk/openai zod
        pnpm add -D @types/node
        ;;
    yarn)
        yarn add ai @ai-sdk/openai zod
        yarn add -D @types/node
        ;;
    bun)
        bun add ai @ai-sdk/openai zod
        bun add -D @types/node
        ;;
    *)
        npm install ai @ai-sdk/openai zod
        npm install -D @types/node
        ;;
esac

echo "✅ Vercel AI SDK installed successfully!"

# Check for .env file
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cat > .env << 'EOF'
# OpenRouter API Configuration
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet

# Optional: For OpenRouter rankings
OPENROUTER_SITE_URL=https://yourapp.com
OPENROUTER_SITE_NAME=YourApp
EOF
    echo "✅ Created .env file. Please update OPENROUTER_API_KEY with your actual key."
else
    echo "ℹ️  .env file already exists. Please ensure it contains OPENROUTER_API_KEY."
fi

# Add .env to .gitignore if not already there
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo ".env" >> .gitignore
        echo "✅ Added .env to .gitignore"
    fi
else
    echo ".env" > .gitignore
    echo "✅ Created .gitignore with .env"
fi

# Create lib directory if it doesn't exist
mkdir -p src/lib

echo ""
echo "✅ Vercel AI SDK setup complete!"
echo ""
echo "Next steps:"
echo "1. Update OPENROUTER_API_KEY in .env file"
echo "2. Copy template: cp skills/provider-integration-templates/templates/vercel-ai-sdk-config.ts src/lib/ai.ts"
echo "3. Review examples: Read skills/provider-integration-templates/examples/vercel-streaming-example.md"
echo "4. Validate setup: bash scripts/validate-integration.sh --framework vercel"
echo ""
