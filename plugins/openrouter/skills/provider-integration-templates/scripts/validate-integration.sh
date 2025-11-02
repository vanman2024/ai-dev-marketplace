#!/bin/bash
# validate-integration.sh
# Validates OpenRouter integration is working correctly

set -e

FRAMEWORK=""
MODEL="anthropic/claude-4.5-sonnet"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --framework)
            FRAMEWORK="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --framework <vercel|langchain|openai> [--model <model-id>]"
            exit 1
            ;;
    esac
done

if [ -z "$FRAMEWORK" ]; then
    echo "❌ Error: --framework required (vercel|langchain|openai)"
    exit 1
fi

echo "🔍 Validating OpenRouter $FRAMEWORK integration..."

# Check for .env file
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check for API key
if [ -z "$OPENROUTER_API_KEY" ] || [ "$OPENROUTER_API_KEY" = "sk-or-v1-your-key-here" ]; then
    echo "❌ Error: OPENROUTER_API_KEY not set in .env file"
    exit 1
fi

echo "✅ Found API key in .env"

# Validate based on framework
case $FRAMEWORK in
    vercel)
        echo "🔍 Checking Vercel AI SDK installation..."

        if [ ! -f "package.json" ]; then
            echo "❌ Error: package.json not found"
            exit 1
        fi

        # Check if ai package is installed
        if ! grep -q '"ai"' package.json; then
            echo "❌ Error: 'ai' package not found in package.json"
            echo "Run: npm install ai @ai-sdk/openai"
            exit 1
        fi

        echo "✅ Vercel AI SDK packages found"

        # Check for lib/ai.ts or similar
        if [ -f "src/lib/ai.ts" ] || [ -f "lib/ai.ts" ]; then
            echo "✅ AI configuration file found"
        else
            echo "⚠️  Warning: AI configuration file not found at src/lib/ai.ts"
        fi
        ;;

    langchain)
        echo "🔍 Checking LangChain installation..."

        # Check Python or TypeScript
        if [ -f "requirements.txt" ] || [ -d "venv" ]; then
            # Python
            if command -v python3 &> /dev/null; then
                if python3 -c "import langchain" 2>/dev/null; then
                    echo "✅ LangChain (Python) installed"
                else
                    echo "❌ Error: LangChain not installed in Python"
                    echo "Run: pip install langchain langchain-openai"
                    exit 1
                fi
            fi
        elif [ -f "package.json" ]; then
            # TypeScript
            if ! grep -q '"langchain"' package.json; then
                echo "❌ Error: 'langchain' package not found in package.json"
                echo "Run: npm install langchain @langchain/openai"
                exit 1
            fi
            echo "✅ LangChain (TypeScript) packages found"
        else
            echo "❌ Error: Could not detect project type"
            exit 1
        fi
        ;;

    openai)
        echo "🔍 Checking OpenAI SDK installation..."

        # Check Python or TypeScript
        if [ -f "requirements.txt" ] || [ -d "venv" ]; then
            # Python
            if command -v python3 &> /dev/null; then
                if python3 -c "import openai" 2>/dev/null; then
                    echo "✅ OpenAI SDK (Python) installed"
                else
                    echo "❌ Error: OpenAI SDK not installed in Python"
                    echo "Run: pip install openai"
                    exit 1
                fi
            fi
        elif [ -f "package.json" ]; then
            # TypeScript
            if ! grep -q '"openai"' package.json; then
                echo "❌ Error: 'openai' package not found in package.json"
                echo "Run: npm install openai"
                exit 1
            fi
            echo "✅ OpenAI SDK (TypeScript) packages found"
        fi
        ;;

    *)
        echo "❌ Error: Unknown framework '$FRAMEWORK'"
        exit 1
        ;;
esac

# Test API connection
echo ""
echo "🌐 Testing OpenRouter API connection..."
echo "Model: $MODEL"

RESPONSE=$(curl -s -w "\n%{http_code}" https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "HTTP-Referer: http://localhost:3000" \
    -H "X-Title: Validation Test" \
    -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{\"role\": \"user\", \"content\": \"Say 'API test successful' and nothing else.\"}],
        \"max_tokens\": 20
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ API connection successful!"
    echo "Response: $(echo "$BODY" | grep -o '"content":"[^"]*"' | head -1)"
else
    echo "❌ API connection failed (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    exit 1
fi

echo ""
echo "✅ All validation checks passed!"
echo ""
echo "Your OpenRouter $FRAMEWORK integration is ready to use."
