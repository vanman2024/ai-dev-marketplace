#!/bin/bash
# check-compatibility.sh
# Checks framework version compatibility with OpenRouter

set -e

echo "🔍 Checking framework version compatibility..."

# Check Node.js version if package.json exists
if [ -f "package.json" ]; then
    echo ""
    echo "📦 Node.js Project Detected"
    echo "---"

    # Check Node.js version
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        echo "Node.js: $NODE_VERSION"

        # Check if Node.js >= 18
        MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$MAJOR_VERSION" -ge 18 ]; then
            echo "✅ Node.js version compatible (>= 18.x required)"
        else
            echo "⚠️  Warning: Node.js 18.x or higher recommended"
        fi
    else
        echo "❌ Node.js not found"
    fi

    # Check package versions
    echo ""
    echo "📚 Installed Packages:"

    # Check Vercel AI SDK
    if grep -q '"ai"' package.json; then
        AI_VERSION=$(grep '"ai"' package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo "  - ai: $AI_VERSION"
        if [ -n "$AI_VERSION" ]; then
            MAJOR=$(echo "$AI_VERSION" | cut -d'.' -f1)
            if [ "$MAJOR" -ge 3 ]; then
                echo "    ✅ Compatible (>= 3.x required for OpenRouter)"
            else
                echo "    ⚠️  Warning: Version 3.x or higher recommended"
            fi
        fi
    fi

    # Check OpenAI SDK adapter
    if grep -q '"@ai-sdk/openai"' package.json; then
        OPENAI_SDK_VERSION=$(grep '"@ai-sdk/openai"' package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo "  - @ai-sdk/openai: $OPENAI_SDK_VERSION"
        echo "    ✅ Compatible with OpenRouter"
    fi

    # Check LangChain
    if grep -q '"langchain"' package.json; then
        LC_VERSION=$(grep '"langchain"' package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo "  - langchain: $LC_VERSION"
        if [ -n "$LC_VERSION" ]; then
            MINOR=$(echo "$LC_VERSION" | cut -d'.' -f2)
            if [ "$MINOR" -ge 3 ]; then
                echo "    ✅ Compatible (>= 0.3.x recommended)"
            else
                echo "    ⚠️  Warning: Version 0.3.x or higher recommended"
            fi
        fi
    fi

    # Check OpenAI SDK
    if grep -q '"openai"' package.json; then
        OPENAI_VERSION=$(grep '"openai"' package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo "  - openai: $OPENAI_VERSION"
        if [ -n "$OPENAI_VERSION" ]; then
            MAJOR=$(echo "$OPENAI_VERSION" | cut -d'.' -f1)
            if [ "$MAJOR" -ge 4 ]; then
                echo "    ✅ Compatible (>= 4.x required)"
            else
                echo "    ⚠️  Warning: Version 4.x or higher required"
            fi
        fi
    fi
fi

# Check Python version if Python files exist
if [ -f "requirements.txt" ] || [ -d "venv" ] || [ -d ".venv" ]; then
    echo ""
    echo "🐍 Python Project Detected"
    echo "---"

    # Check Python version
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        echo "Python: $PYTHON_VERSION"

        # Check if Python >= 3.8
        MAJOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f1)
        MINOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f2)
        if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 8 ]; then
            echo "✅ Python version compatible (>= 3.8 required)"
        else
            echo "⚠️  Warning: Python 3.8 or higher required"
        fi
    else
        echo "❌ Python not found"
    fi

    # Check installed packages
    echo ""
    echo "📚 Installed Python Packages:"

    # Activate venv if exists
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi

    # Check LangChain
    if python3 -c "import langchain" 2>/dev/null; then
        LC_VERSION=$(python3 -c "import langchain; print(langchain.__version__)" 2>/dev/null || echo "unknown")
        echo "  - langchain: $LC_VERSION"
        if [ "$LC_VERSION" != "unknown" ]; then
            MINOR=$(echo "$LC_VERSION" | cut -d'.' -f2)
            if [ "$MINOR" -ge 3 ]; then
                echo "    ✅ Compatible (>= 0.3.x recommended)"
            else
                echo "    ⚠️  Warning: Version 0.3.x or higher recommended"
            fi
        fi
    fi

    # Check OpenAI SDK
    if python3 -c "import openai" 2>/dev/null; then
        OPENAI_VERSION=$(python3 -c "import openai; print(openai.__version__)" 2>/dev/null || echo "unknown")
        echo "  - openai: $OPENAI_VERSION"
        if [ "$OPENAI_VERSION" != "unknown" ]; then
            MAJOR=$(echo "$OPENAI_VERSION" | cut -d'.' -f1)
            if [ "$MAJOR" -ge 1 ]; then
                echo "    ✅ Compatible (>= 1.x required)"
            else
                echo "    ⚠️  Warning: Version 1.x or higher required"
            fi
        fi
    fi
fi

# Check for .env file
echo ""
echo "⚙️  Environment Configuration"
echo "---"

if [ -f ".env" ]; then
    echo "✅ .env file found"

    # Check for required variables
    if grep -q "OPENROUTER_API_KEY" .env; then
        if grep -q "OPENROUTER_API_KEY=sk-or-v1-your-key-here" .env; then
            echo "⚠️  Warning: OPENROUTER_API_KEY needs to be updated"
        else
            echo "✅ OPENROUTER_API_KEY configured"
        fi
    else
        echo "❌ OPENROUTER_API_KEY not found in .env"
    fi

    if grep -q "OPENROUTER_MODEL" .env; then
        MODEL=$(grep "OPENROUTER_MODEL" .env | cut -d'=' -f2)
        echo "✅ OPENROUTER_MODEL configured: $MODEL"
    else
        echo "ℹ️  OPENROUTER_MODEL not set (optional)"
    fi
else
    echo "❌ .env file not found"
fi

# Summary
echo ""
echo "📋 Compatibility Summary"
echo "---"
echo "✅ = Compatible"
echo "⚠️  = Warning (may work but upgrade recommended)"
echo "❌ = Not compatible (action required)"
echo ""
echo "For detailed OpenRouter documentation, visit:"
echo "https://openrouter.ai/docs"
