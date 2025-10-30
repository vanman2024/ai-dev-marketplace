#!/usr/bin/env bash

# Setup script for @ai-sdk/elevenlabs integration
# Installs required dependencies and configures environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        return 1
    fi
    return 0
}

detect_package_manager() {
    if [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    elif [ -f "package-lock.json" ]; then
        echo "npm"
    elif [ -f "bun.lockb" ]; then
        echo "bun"
    else
        # Default to npm
        echo "npm"
    fi
}

install_dependencies() {
    local pm="$1"
    local deps=("$@")
    unset 'deps[0]' # Remove first element (package manager)

    log_info "Installing dependencies with $pm..."

    case "$pm" in
        pnpm)
            pnpm add "${deps[@]}"
            ;;
        yarn)
            yarn add "${deps[@]}"
            ;;
        npm)
            npm install "${deps[@]}"
            ;;
        bun)
            bun add "${deps[@]}"
            ;;
        *)
            log_error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

verify_installation() {
    local package="$1"

    if [ -d "node_modules/$package" ]; then
        log_success "$package installed successfully"
        return 0
    else
        log_error "$package installation failed"
        return 1
    fi
}

create_env_template() {
    local env_file=".env.local.example"

    if [ -f "$env_file" ]; then
        log_warning "$env_file already exists, skipping creation"
        return 0
    fi

    log_info "Creating $env_file template..."

    cat > "$env_file" << 'EOF'
# ElevenLabs API Key
# Get your API key from: https://elevenlabs.io/app/settings/api-keys
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# Optional: OpenAI API Key (for LLM responses in multi-modal chat)
# OPENAI_API_KEY=your_openai_api_key_here

# Optional: Anthropic API Key (alternative LLM provider)
# ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Optional: Configuration
# NEXT_PUBLIC_MAX_FILE_SIZE=10485760  # 10MB
# TRANSCRIPTION_TIMEOUT=60000          # 60 seconds
EOF

    log_success "Created $env_file template"
    log_info "Copy to .env.local and add your API keys:"
    echo -e "  ${BLUE}cp $env_file .env.local${NC}"
}

check_nextjs() {
    if [ -f "package.json" ]; then
        if grep -q '"next"' package.json; then
            local version=$(node -pe "require('./package.json').dependencies.next || require('./package.json').devDependencies.next" 2>/dev/null || echo "unknown")
            log_success "Next.js detected (version: $version)"
            return 0
        fi
    fi

    log_warning "Next.js not detected. This skill is optimized for Next.js projects."
    log_info "You can still use @ai-sdk/elevenlabs in other frameworks."
    return 1
}

main() {
    log_info "Starting @ai-sdk/elevenlabs setup..."
    echo

    # Check for Node.js
    if ! check_command node; then
        exit 1
    fi

    local node_version=$(node --version)
    log_info "Node.js version: $node_version"

    # Detect package manager
    local pm=$(detect_package_manager)
    log_info "Detected package manager: $pm"

    # Check if package manager is available
    if ! check_command "$pm"; then
        log_error "$pm is not installed but lock file exists"
        exit 1
    fi

    echo

    # Check for package.json
    if [ ! -f "package.json" ]; then
        log_error "package.json not found. Please run this from a Node.js project root."
        exit 1
    fi

    # Check for Next.js (optional)
    check_nextjs || true

    echo

    # Install dependencies
    log_info "Installing @ai-sdk/elevenlabs and dependencies..."

    local dependencies=(
        "@ai-sdk/elevenlabs"
        "ai"
    )

    if ! install_dependencies "$pm" "${dependencies[@]}"; then
        log_error "Failed to install dependencies"
        exit 1
    fi

    echo

    # Verify installations
    log_info "Verifying installations..."

    local all_verified=true
    for dep in "${dependencies[@]}"; do
        if ! verify_installation "$dep"; then
            all_verified=false
        fi
    done

    if [ "$all_verified" = false ]; then
        log_error "Some packages failed to install"
        exit 1
    fi

    echo

    # Create environment template
    create_env_template

    echo

    # Success message
    log_success "Setup complete!"
    echo
    log_info "Next steps:"
    echo "  1. Copy .env.local.example to .env.local"
    echo "  2. Add your ELEVENLABS_API_KEY to .env.local"
    echo "  3. Test transcription with: bash scripts/test-transcription.sh /path/to/audio.mp3"
    echo
    log_info "Example usage:"
    echo -e "${BLUE}import { experimental_transcribe as transcribe } from 'ai';${NC}"
    echo -e "${BLUE}import { elevenlabs } from '@ai-sdk/elevenlabs';${NC}"
    echo
    echo -e "${BLUE}const { text } = await transcribe({${NC}"
    echo -e "${BLUE}  model: elevenlabs.transcription('scribe_v1'),${NC}"
    echo -e "${BLUE}  audio: audioBuffer,${NC}"
    echo -e "${BLUE}});${NC}"
    echo
}

# Run main function
main "$@"
