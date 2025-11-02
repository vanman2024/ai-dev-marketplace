#!/bin/bash
# setup-langchain-integration.sh
# Sets up LangChain with OpenRouter integration

set -e

# Parse arguments
LANGUAGE="python"
while [[ $# -gt 0 ]]; do
    case $1 in
        --python)
            LANGUAGE="python"
            shift
            ;;
        --typescript)
            LANGUAGE="typescript"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--python|--typescript]"
            exit 1
            ;;
    esac
done

echo "🚀 Setting up LangChain ($LANGUAGE) with OpenRouter..."

if [ "$LANGUAGE" = "python" ]; then
    # Python setup
    echo "🐍 Setting up Python environment..."

    # Check for Python
    if ! command -v python3 &> /dev/null; then
        echo "❌ Error: python3 not found. Please install Python 3.8+."
        exit 1
    fi

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ] && [ ! -d ".venv" ]; then
        echo "📦 Creating virtual environment..."
        python3 -m venv venv
        echo "✅ Virtual environment created at ./venv"
    fi

    # Activate virtual environment
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi

    # Install LangChain
    echo "📥 Installing LangChain packages..."
    pip install --upgrade pip
    pip install langchain langchain-openai python-dotenv

    echo "✅ LangChain packages installed!"

    # Create .env file
    if [ ! -f ".env" ]; then
        echo "📝 Creating .env file..."
        cat > .env << 'EOF'
# OpenRouter API Configuration
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1

# Optional: For OpenRouter rankings
OPENROUTER_SITE_URL=https://yourapp.com
OPENROUTER_SITE_NAME=YourApp
EOF
        echo "✅ Created .env file. Please update OPENROUTER_API_KEY."
    fi

    # Create directory structure
    mkdir -p src/config src/chains src/agents

    echo ""
    echo "✅ LangChain (Python) setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Activate venv: source venv/bin/activate"
    echo "2. Update OPENROUTER_API_KEY in .env"
    echo "3. Copy template: cp skills/provider-integration-templates/templates/langchain-config.py src/config/"
    echo "4. Review examples: Read skills/provider-integration-templates/examples/langchain-chain-example.md"

elif [ "$LANGUAGE" = "typescript" ]; then
    # TypeScript setup
    echo "📦 Setting up TypeScript environment..."

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

    # Install LangChain
    echo "📥 Installing LangChain packages..."
    case $PKG_MGR in
        pnpm)
            pnpm add langchain @langchain/openai dotenv
            pnpm add -D @types/node
            ;;
        yarn)
            yarn add langchain @langchain/openai dotenv
            yarn add -D @types/node
            ;;
        bun)
            bun add langchain @langchain/openai dotenv
            bun add -D @types/node
            ;;
        *)
            npm install langchain @langchain/openai dotenv
            npm install -D @types/node
            ;;
    esac

    echo "✅ LangChain packages installed!"

    # Create .env file
    if [ ! -f ".env" ]; then
        echo "📝 Creating .env file..."
        cat > .env << 'EOF'
# OpenRouter API Configuration
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1

# Optional: For OpenRouter rankings
OPENROUTER_SITE_URL=https://yourapp.com
OPENROUTER_SITE_NAME=YourApp
EOF
        echo "✅ Created .env file. Please update OPENROUTER_API_KEY."
    fi

    # Create directory structure
    mkdir -p src/config src/chains src/agents

    echo ""
    echo "✅ LangChain (TypeScript) setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Update OPENROUTER_API_KEY in .env"
    echo "2. Copy template: cp skills/provider-integration-templates/templates/langchain-config.ts src/config/"
    echo "3. Review examples: Read skills/provider-integration-templates/examples/langchain-chain-example.md"
fi

# Add .env to .gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo ".env" >> .gitignore
        echo "✅ Added .env to .gitignore"
    fi
else
    echo ".env" > .gitignore
    echo "✅ Created .gitignore with .env"
fi

echo ""
