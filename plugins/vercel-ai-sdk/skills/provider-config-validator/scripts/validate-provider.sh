#!/bin/bash
# Provider Configuration Validator
# Validates Vercel AI SDK provider setup including packages, API keys, and configuration

set -e

PROVIDER=${1:-"openai"}
PROJECT_ROOT=${2:-.}

echo "🔍 Validating $PROVIDER provider configuration..."
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation results
ERRORS=0
WARNINGS=0

# Helper functions
error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

# Detect project type
if [ -f "$PROJECT_ROOT/package.json" ]; then
    PROJECT_TYPE="node"
elif [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
    PROJECT_TYPE="python"
else
    error "Could not detect project type (no package.json or requirements.txt found)"
    exit 1
fi

echo "📦 Project type: $PROJECT_TYPE"
echo ""

# Provider-specific configuration
case "$PROVIDER" in
    openai)
        ENV_VAR="OPENAI_API_KEY"
        KEY_PREFIX="sk-"
        if [ "$PROJECT_TYPE" = "node" ]; then
            PACKAGE="@ai-sdk/openai"
            ALT_PACKAGE="openai"
        else
            PACKAGE="openai"
        fi
        VALID_MODELS=("gpt-4" "gpt-4-turbo" "gpt-3.5-turbo" "gpt-4o" "gpt-4o-mini")
        ;;
    anthropic)
        ENV_VAR="ANTHROPIC_API_KEY"
        KEY_PREFIX="sk-ant-"
        if [ "$PROJECT_TYPE" = "node" ]; then
            PACKAGE="@ai-sdk/anthropic"
            ALT_PACKAGE="@anthropic-ai/sdk"
        else
            PACKAGE="anthropic"
        fi
        VALID_MODELS=("claude-3-5-sonnet-20241022" "claude-3-opus-20240229" "claude-3-sonnet-20240229" "claude-3-haiku-20240307")
        ;;
    google)
        ENV_VAR="GOOGLE_GENERATIVE_AI_API_KEY"
        KEY_PREFIX=""
        PACKAGE="@ai-sdk/google"
        VALID_MODELS=("gemini-1.5-pro" "gemini-1.5-flash" "gemini-1.0-pro")
        ;;
    xai)
        ENV_VAR="XAI_API_KEY"
        KEY_PREFIX="xai-"
        PACKAGE="@ai-sdk/xai"
        VALID_MODELS=("grok-beta" "grok-vision-beta")
        ;;
    groq)
        ENV_VAR="GROQ_API_KEY"
        KEY_PREFIX="gsk_"
        PACKAGE="@ai-sdk/groq"
        VALID_MODELS=("llama-3.1-70b-versatile" "mixtral-8x7b-32768")
        ;;
    *)
        error "Unknown provider: $PROVIDER"
        echo "Supported providers: openai, anthropic, google, xai, groq"
        exit 1
        ;;
esac

echo "🔧 Checking provider: $PROVIDER"
echo "   Environment variable: $ENV_VAR"
echo "   Package: $PACKAGE"
echo ""

# Check 1: Package Installation
echo "📦 Checking package installation..."
if [ "$PROJECT_TYPE" = "node" ]; then
    if [ -d "$PROJECT_ROOT/node_modules/$PACKAGE" ]; then
        success "Package $PACKAGE is installed"
        # Check version
        VERSION=$(node -p "require('$PROJECT_ROOT/node_modules/$PACKAGE/package.json').version" 2>/dev/null || echo "unknown")
        echo "   Version: $VERSION"
    elif [ -n "$ALT_PACKAGE" ] && [ -d "$PROJECT_ROOT/node_modules/$ALT_PACKAGE" ]; then
        success "Alternative package $ALT_PACKAGE is installed"
        VERSION=$(node -p "require('$PROJECT_ROOT/node_modules/$ALT_PACKAGE/package.json').version" 2>/dev/null || echo "unknown")
        echo "   Version: $VERSION"
    else
        error "Package $PACKAGE not found in node_modules"
        echo "   Fix: npm install $PACKAGE"
    fi
else
    # Python project
    if python3 -c "import $PACKAGE" 2>/dev/null; then
        success "Package $PACKAGE is installed"
        VERSION=$(python3 -c "import $PACKAGE; print($PACKAGE.__version__)" 2>/dev/null || echo "unknown")
        echo "   Version: $VERSION"
    else
        error "Package $PACKAGE not installed"
        echo "   Fix: pip install $PACKAGE"
    fi
fi
echo ""

# Check 2: .env file exists
echo "📄 Checking environment file..."
if [ -f "$PROJECT_ROOT/.env" ]; then
    success ".env file exists"
else
    warning ".env file not found"
    echo "   Fix: Create .env file with $ENV_VAR"
fi
echo ""

# Check 3: API Key environment variable
echo "🔑 Checking API key..."
if [ -f "$PROJECT_ROOT/.env" ]; then
    # Load .env file
    export $(cat "$PROJECT_ROOT/.env" | grep -v '^#' | xargs)
fi

if [ -z "${!ENV_VAR}" ]; then
    error "$ENV_VAR not set in environment"
    echo "   Fix: Add $ENV_VAR=your-api-key to .env file"
elif [ "${!ENV_VAR}" = "your-api-key-here" ] || [ "${!ENV_VAR}" = "sk-..." ]; then
    warning "$ENV_VAR is set to placeholder value"
    echo "   Fix: Replace with actual API key"
else
    # Check key format if prefix is defined
    if [ -n "$KEY_PREFIX" ]; then
        if [[ "${!ENV_VAR}" == $KEY_PREFIX* ]]; then
            success "$ENV_VAR is set with correct prefix"
        else
            error "$ENV_VAR has incorrect format (should start with $KEY_PREFIX)"
        fi
    else
        success "$ENV_VAR is set"
    fi
    # Don't print the actual key for security
    echo "   Key length: ${#!ENV_VAR} characters"
fi
echo ""

# Check 4: .gitignore includes .env
echo "🔒 Checking .gitignore..."
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    if grep -q "^\.env$" "$PROJECT_ROOT/.gitignore" || grep -q "^\.env" "$PROJECT_ROOT/.gitignore"; then
        success ".env is in .gitignore"
    else
        warning ".env not found in .gitignore"
        echo "   Fix: Add .env to .gitignore to prevent committing secrets"
    fi
else
    warning ".gitignore file not found"
    echo "   Fix: Create .gitignore and add .env"
fi
echo ""

# Check 5: Core SDK package
echo "📦 Checking Vercel AI SDK core..."
if [ "$PROJECT_TYPE" = "node" ]; then
    if [ -d "$PROJECT_ROOT/node_modules/ai" ]; then
        success "Vercel AI SDK (ai) is installed"
        VERSION=$(node -p "require('$PROJECT_ROOT/node_modules/ai/package.json').version" 2>/dev/null || echo "unknown")
        echo "   Version: $VERSION"
    else
        error "Vercel AI SDK (ai) not found"
        echo "   Fix: npm install ai"
    fi
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ All checks passed! Configuration is valid.${NC}"
    else
        echo -e "${YELLOW}⚠️  Configuration valid with $WARNINGS warning(s)${NC}"
    fi
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Ensure $ENV_VAR has your actual API key"
    echo "   2. Test connection with: npm run dev (or python main.py)"
    echo ""
    echo "📚 Documentation:"
    case "$PROVIDER" in
        openai)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/openai"
            ;;
        anthropic)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/anthropic"
            ;;
        google)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/google-generative-ai"
            ;;
        xai)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/xai"
            ;;
        groq)
            echo "   https://ai-sdk.dev/providers/ai-sdk-providers/groq"
            ;;
    esac
    exit 0
else
    echo -e "${RED}❌ Configuration has $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "🔧 Fix the errors above and run validation again"
    exit 1
fi
