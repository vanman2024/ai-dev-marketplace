#!/usr/bin/env bash
# install-sdk.sh - Install ElevenLabs SDK for TypeScript or Python
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get language argument
LANGUAGE="${1:-}"

show_usage() {
    echo "Usage: bash scripts/install-sdk.sh [typescript|python]"
    echo ""
    echo "Options:"
    echo "  typescript    Install @elevenlabs/elevenlabs-js and dotenv"
    echo "  python        Install elevenlabs and python-dotenv"
    echo ""
    echo "Example:"
    echo "  bash scripts/install-sdk.sh typescript"
    exit 1
}

# Validate language argument
if [[ -z "$LANGUAGE" ]]; then
    show_usage
fi

case "$LANGUAGE" in
    typescript|ts|node|nodejs|javascript|js)
        LANGUAGE="typescript"
        ;;
    python|py)
        LANGUAGE="python"
        ;;
    *)
        echo -e "${RED}Error: Invalid language '$LANGUAGE'${NC}"
        echo ""
        show_usage
        ;;
esac

echo "ElevenLabs SDK Installation"
echo "==========================="
echo ""

# Install TypeScript/JavaScript SDK
if [[ "$LANGUAGE" == "typescript" ]]; then
    echo -e "${BLUE}Installing TypeScript/JavaScript SDK...${NC}"
    echo ""

    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}Error: npm not found${NC}"
        echo "Please install Node.js and npm first:"
        echo "  https://nodejs.org/"
        exit 1
    fi

    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$NODE_VERSION" -lt 18 ]]; then
        echo -e "${YELLOW}Warning: Node.js version $NODE_VERSION detected${NC}"
        echo "ElevenLabs SDK recommends Node.js 18 or higher"
        echo ""
    fi

    # Detect package manager
    if [[ -f "pnpm-lock.yaml" ]]; then
        PKG_MANAGER="pnpm"
    elif [[ -f "yarn.lock" ]]; then
        PKG_MANAGER="yarn"
    elif [[ -f "bun.lockb" ]]; then
        PKG_MANAGER="bun"
    else
        PKG_MANAGER="npm"
    fi

    echo "Using package manager: $PKG_MANAGER"
    echo ""

    # Install packages
    echo "Installing @elevenlabs/elevenlabs-js..."
    case "$PKG_MANAGER" in
        pnpm)
            pnpm add elevenlabs
            ;;
        yarn)
            yarn add elevenlabs
            ;;
        bun)
            bun add elevenlabs
            ;;
        *)
            npm install elevenlabs
            ;;
    esac

    echo ""
    echo "Installing dotenv..."
    case "$PKG_MANAGER" in
        pnpm)
            pnpm add dotenv
            ;;
        yarn)
            yarn add dotenv
            ;;
        bun)
            bun add dotenv
            ;;
        *)
            npm install dotenv
            ;;
    esac

    echo ""
    echo -e "${GREEN}✓ TypeScript SDK installed successfully${NC}"
    echo ""
    echo "Installed packages:"
    echo "  - elevenlabs (ElevenLabs API client)"
    echo "  - dotenv (Environment variable loader)"
    echo ""
    echo "Next steps:"
    echo "1. Configure API key: bash scripts/setup-auth.sh"
    echo "2. Generate client: bash scripts/generate-client.sh typescript src/lib/elevenlabs.ts"
    echo "3. See example: cat examples/nextjs-auth/README.md"

# Install Python SDK
elif [[ "$LANGUAGE" == "python" ]]; then
    echo -e "${BLUE}Installing Python SDK...${NC}"
    echo ""

    # Check if pip is available
    if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
        echo -e "${RED}Error: pip not found${NC}"
        echo "Please install Python and pip first:"
        echo "  https://www.python.org/downloads/"
        exit 1
    fi

    # Use pip3 if pip is not available
    PIP_CMD="pip"
    if ! command -v pip &> /dev/null; then
        PIP_CMD="pip3"
    fi

    # Check Python version
    PYTHON_VERSION=$($PIP_CMD --version | grep -oP 'python \K[0-9]+\.[0-9]+' || echo "unknown")
    echo "Using Python $PYTHON_VERSION"
    echo ""

    # Check if virtual environment is active
    if [[ -z "${VIRTUAL_ENV:-}" ]]; then
        echo -e "${YELLOW}Warning: No virtual environment detected${NC}"
        echo "It's recommended to use a virtual environment:"
        echo "  python -m venv venv"
        echo "  source venv/bin/activate"
        echo ""
        echo "Continue with global installation? (y/n)"
        read -r continue
        if [[ ! "$continue" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi

    # Install packages
    echo "Installing elevenlabs..."
    $PIP_CMD install elevenlabs

    echo ""
    echo "Installing python-dotenv..."
    $PIP_CMD install python-dotenv

    echo ""
    echo -e "${GREEN}✓ Python SDK installed successfully${NC}"
    echo ""
    echo "Installed packages:"
    echo "  - elevenlabs (ElevenLabs API client)"
    echo "  - python-dotenv (Environment variable loader)"
    echo ""
    echo "Next steps:"
    echo "1. Configure API key: bash scripts/setup-auth.sh"
    echo "2. Generate client: bash scripts/generate-client.sh python src/elevenlabs_client.py"
    echo "3. See example: cat examples/python-auth/README.md"
fi

echo ""
echo "Installation complete!"
