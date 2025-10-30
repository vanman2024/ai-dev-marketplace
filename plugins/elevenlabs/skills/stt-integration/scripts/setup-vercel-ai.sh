#!/usr/bin/env bash
set -euo pipefail

#############################################################
# Setup Vercel AI SDK with ElevenLabs Provider
#############################################################
# Usage: ./setup-vercel-ai.sh [--typescript|--python] [--dev]
#
# This script installs and configures the Vercel AI SDK
# with the ElevenLabs provider for speech-to-text transcription.
#
# Options:
#   --typescript   Install TypeScript/JavaScript packages (default)
#   --python       Install Python packages
#   --dev          Install as dev dependency
#   --global       Install globally (npm only)
#############################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
LANGUAGE="typescript"
DEV_FLAG=""
GLOBAL_FLAG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --typescript)
            LANGUAGE="typescript"
            shift
            ;;
        --python)
            LANGUAGE="python"
            shift
            ;;
        --dev)
            DEV_FLAG="--save-dev"
            shift
            ;;
        --global)
            GLOBAL_FLAG="-g"
            shift
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Vercel AI SDK + ElevenLabs Setup             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$LANGUAGE" == "typescript" ]]; then
    echo -e "${BLUE}Setting up TypeScript/JavaScript environment...${NC}"
    echo ""

    # Detect package manager
    if command -v pnpm &> /dev/null; then
        PKG_MANAGER="pnpm"
        ADD_CMD="add"
    elif command -v yarn &> /dev/null; then
        PKG_MANAGER="yarn"
        ADD_CMD="add"
    elif command -v npm &> /dev/null; then
        PKG_MANAGER="npm"
        ADD_CMD="install"
    else
        echo -e "${RED}Error: No package manager found (npm, yarn, or pnpm)${NC}"
        echo "Please install Node.js and npm first:"
        echo "  https://nodejs.org/"
        exit 1
    fi

    echo -e "${GREEN}✓ Detected package manager: $PKG_MANAGER${NC}"
    echo ""

    # Check for package.json
    if [[ ! -f "package.json" ]] && [[ -z "$GLOBAL_FLAG" ]]; then
        echo -e "${YELLOW}No package.json found. Initializing new project...${NC}"
        if [[ "$PKG_MANAGER" == "pnpm" ]]; then
            pnpm init
        elif [[ "$PKG_MANAGER" == "yarn" ]]; then
            yarn init -y
        else
            npm init -y
        fi
        echo -e "${GREEN}✓ Created package.json${NC}"
        echo ""
    fi

    # Install Vercel AI SDK core
    echo -e "${BLUE}Installing Vercel AI SDK core package...${NC}"
    if [[ -n "$GLOBAL_FLAG" ]]; then
        npm install $GLOBAL_FLAG ai
    elif [[ "$PKG_MANAGER" == "pnpm" ]]; then
        pnpm add ai $DEV_FLAG
    elif [[ "$PKG_MANAGER" == "yarn" ]]; then
        yarn add ai $DEV_FLAG
    else
        npm install ai $DEV_FLAG
    fi
    echo -e "${GREEN}✓ Installed ai package${NC}"
    echo ""

    # Install ElevenLabs provider
    echo -e "${BLUE}Installing ElevenLabs provider package...${NC}"
    if [[ -n "$GLOBAL_FLAG" ]]; then
        npm install $GLOBAL_FLAG @ai-sdk/elevenlabs
    elif [[ "$PKG_MANAGER" == "pnpm" ]]; then
        pnpm add @ai-sdk/elevenlabs $DEV_FLAG
    elif [[ "$PKG_MANAGER" == "yarn" ]]; then
        yarn add @ai-sdk/elevenlabs $DEV_FLAG
    else
        npm install @ai-sdk/elevenlabs $DEV_FLAG
    fi
    echo -e "${GREEN}✓ Installed @ai-sdk/elevenlabs package${NC}"
    echo ""

    # Verify installation
    echo -e "${BLUE}Verifying installation...${NC}"
    if [[ "$PKG_MANAGER" == "npm" ]]; then
        npm list ai @ai-sdk/elevenlabs 2>/dev/null || true
    elif [[ "$PKG_MANAGER" == "yarn" ]]; then
        yarn list --pattern "ai|@ai-sdk/elevenlabs" 2>/dev/null || true
    else
        pnpm list ai @ai-sdk/elevenlabs 2>/dev/null || true
    fi
    echo ""

    # Check for TypeScript
    if command -v tsc &> /dev/null || [[ -f "node_modules/.bin/tsc" ]]; then
        echo -e "${GREEN}✓ TypeScript detected${NC}"
    else
        echo -e "${YELLOW}TypeScript not found. Install with:${NC}"
        echo "  $PKG_MANAGER $ADD_CMD -D typescript @types/node"
    fi

    # Setup .env template if not exists
    if [[ ! -f ".env" ]] && [[ ! -f ".env.local" ]]; then
        echo -e "${BLUE}Creating .env.local template...${NC}"
        cat > .env.local << 'EOF'
# ElevenLabs API Configuration
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# Get your API key from: https://elevenlabs.io/app/settings/api-keys
EOF
        echo -e "${GREEN}✓ Created .env.local template${NC}"
        echo -e "${YELLOW}⚠ Remember to add your ELEVENLABS_API_KEY to .env.local${NC}"
    fi

    # Add .env to .gitignore if not present
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "^\.env" .gitignore; then
            echo -e "${BLUE}Adding .env* to .gitignore...${NC}"
            echo -e "\n# Environment variables\n.env\n.env.local\n.env*.local" >> .gitignore
            echo -e "${GREEN}✓ Updated .gitignore${NC}"
        fi
    else
        echo -e "${BLUE}Creating .gitignore...${NC}"
        cat > .gitignore << 'EOF'
# Dependencies
node_modules/

# Environment variables
.env
.env.local
.env*.local

# Build output
dist/
build/
.next/

# IDE
.vscode/
.idea/

# OS
.DS_Store
EOF
        echo -e "${GREEN}✓ Created .gitignore${NC}"
    fi

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Installation Complete                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Set your API key in .env.local:"
    echo "     ELEVENLABS_API_KEY='your_api_key_here'"
    echo ""
    echo "  2. Import and use in your code:"
    echo "     import { elevenlabs } from '@ai-sdk/elevenlabs';"
    echo "     import { experimental_transcribe as transcribe } from 'ai';"
    echo ""
    echo "  3. See examples in:"
    echo "     plugins/elevenlabs/skills/stt-integration/examples/vercel-ai-stt/"
    echo ""

elif [[ "$LANGUAGE" == "python" ]]; then
    echo -e "${BLUE}Setting up Python environment...${NC}"
    echo ""

    # Check for Python
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        echo -e "${RED}Error: Python not found${NC}"
        echo "Please install Python 3.8 or higher:"
        echo "  https://www.python.org/downloads/"
        exit 1
    fi

    PYTHON_CMD="python3"
    if ! command -v python3 &> /dev/null; then
        PYTHON_CMD="python"
    fi

    echo -e "${GREEN}✓ Detected Python: $($PYTHON_CMD --version)${NC}"
    echo ""

    # Check for venv
    if [[ ! -d "venv" ]] && [[ ! -d ".venv" ]]; then
        echo -e "${YELLOW}No virtual environment found. Creating one...${NC}"
        $PYTHON_CMD -m venv venv
        echo -e "${GREEN}✓ Created virtual environment${NC}"
        echo ""
        echo -e "${YELLOW}Activate it with:${NC}"
        echo "  source venv/bin/activate  # Linux/macOS"
        echo "  venv\\Scripts\\activate     # Windows"
        echo ""
    fi

    # Detect if venv is active
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        echo -e "${GREEN}✓ Virtual environment active: $VIRTUAL_ENV${NC}"
    else
        echo -e "${YELLOW}⚠ Virtual environment not active${NC}"
        echo "Continuing with system Python..."
    fi
    echo ""

    # Install packages
    echo -e "${BLUE}Installing Python packages...${NC}"

    # Create requirements.txt if it doesn't exist
    if [[ ! -f "requirements.txt" ]]; then
        echo -e "${BLUE}Creating requirements.txt...${NC}"
        cat > requirements.txt << 'EOF'
# Vercel AI SDK for Python
ai-sdk>=0.1.0

# ElevenLabs SDK
elevenlabs>=1.0.0

# Async support
httpx>=0.25.0
aiofiles>=23.0.0

# Type hints
typing-extensions>=4.8.0
EOF
        echo -e "${GREEN}✓ Created requirements.txt${NC}"
    fi

    $PYTHON_CMD -m pip install --upgrade pip
    $PYTHON_CMD -m pip install -r requirements.txt

    echo -e "${GREEN}✓ Installed Python packages${NC}"
    echo ""

    # Setup .env if not exists
    if [[ ! -f ".env" ]]; then
        echo -e "${BLUE}Creating .env template...${NC}"
        cat > .env << 'EOF'
# ElevenLabs API Configuration
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# Get your API key from: https://elevenlabs.io/app/settings/api-keys
EOF
        echo -e "${GREEN}✓ Created .env template${NC}"
        echo -e "${YELLOW}⚠ Remember to add your ELEVENLABS_API_KEY to .env${NC}"
    fi

    # Add .env to .gitignore if not present
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "^\.env" .gitignore; then
            echo -e "${BLUE}Adding .env to .gitignore...${NC}"
            echo -e "\n# Environment variables\n.env\n.env.local" >> .gitignore
            echo -e "${GREEN}✓ Updated .gitignore${NC}"
        fi
    else
        echo -e "${BLUE}Creating .gitignore...${NC}"
        cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
venv/
.venv/
*.egg-info/

# Environment variables
.env
.env.local

# IDE
.vscode/
.idea/

# OS
.DS_Store
EOF
        echo -e "${GREEN}✓ Created .gitignore${NC}"
    fi

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Installation Complete                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Activate virtual environment (if not already active):"
    echo "     source venv/bin/activate"
    echo ""
    echo "  2. Set your API key in .env:"
    echo "     ELEVENLABS_API_KEY='your_api_key_here'"
    echo ""
    echo "  3. Import and use in your code:"
    echo "     from elevenlabs import ElevenLabs"
    echo "     client = ElevenLabs(api_key='your_key')"
    echo ""
    echo "  4. See examples in:"
    echo "     plugins/elevenlabs/skills/stt-integration/examples/"
    echo ""
fi

echo -e "${BLUE}📚 Documentation:${NC}"
echo "  - ElevenLabs STT: https://elevenlabs.io/docs/capabilities/speech-to-text"
echo "  - Vercel AI SDK: https://ai-sdk.dev/providers/ai-sdk-providers/elevenlabs"
echo "  - Skill templates: plugins/elevenlabs/skills/stt-integration/templates/"
echo ""
