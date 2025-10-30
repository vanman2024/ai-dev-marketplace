#!/usr/bin/env bash

# Validate ElevenLabs + Vercel AI SDK integration
# Checks installation, configuration, and API connectivity

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global counters
PASSED=0
FAILED=0
WARNINGS=0

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

check_node() {
    log_info "Checking Node.js installation..."

    if ! command -v node &> /dev/null; then
        log_error "Node.js not installed"
        return 1
    fi

    local version=$(node --version)
    local major_version=$(echo "$version" | cut -d'.' -f1 | sed 's/v//')

    if [ "$major_version" -lt 18 ]; then
        log_error "Node.js version $version is too old (minimum: v18)"
        return 1
    fi

    log_success "Node.js $version installed"
    return 0
}

check_package_json() {
    log_info "Checking package.json..."

    if [ ! -f "package.json" ]; then
        log_error "package.json not found"
        return 1
    fi

    log_success "package.json exists"
    return 0
}

check_dependencies() {
    log_info "Checking npm dependencies..."

    local missing=()

    if [ ! -d "node_modules/@ai-sdk/elevenlabs" ]; then
        missing+=("@ai-sdk/elevenlabs")
    fi

    if [ ! -d "node_modules/ai" ]; then
        missing+=("ai")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: npm install ${missing[*]}"
        return 1
    fi

    log_success "@ai-sdk/elevenlabs and ai packages installed"

    # Check versions
    local elevenlabs_version=$(node -pe "require('./node_modules/@ai-sdk/elevenlabs/package.json').version" 2>/dev/null || echo "unknown")
    local ai_version=$(node -pe "require('./node_modules/ai/package.json').version" 2>/dev/null || echo "unknown")

    log_info "  @ai-sdk/elevenlabs: $elevenlabs_version"
    log_info "  ai: $ai_version"

    return 0
}

check_api_key() {
    log_info "Checking API key configuration..."

    # Check environment variable
    if [ -n "${ELEVENLABS_API_KEY:-}" ]; then
        log_success "ELEVENLABS_API_KEY environment variable set"
        return 0
    fi

    # Check .env.local
    if [ -f ".env.local" ]; then
        if grep -q "ELEVENLABS_API_KEY=" .env.local; then
            log_success "ELEVENLABS_API_KEY found in .env.local"
            return 0
        fi
    fi

    # Check .env
    if [ -f ".env" ]; then
        if grep -q "ELEVENLABS_API_KEY=" .env; then
            log_success "ELEVENLABS_API_KEY found in .env"
            return 0
        fi
    fi

    log_error "ELEVENLABS_API_KEY not configured"
    log_info "Set it in .env.local or as environment variable"
    return 1
}

test_import() {
    log_info "Testing module imports..."

    local test_script=$(mktemp --suffix=.mjs)

    cat > "$test_script" << 'EOF'
try {
  const { experimental_transcribe } = await import('ai');
  const { elevenlabs } = await import('@ai-sdk/elevenlabs');

  if (!experimental_transcribe) {
    console.error('FAIL: experimental_transcribe not exported from ai');
    process.exit(1);
  }

  if (!elevenlabs) {
    console.error('FAIL: elevenlabs not exported from @ai-sdk/elevenlabs');
    process.exit(1);
  }

  console.log('PASS: Imports successful');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Import error:', error.message);
  process.exit(1);
}
EOF

    if node "$test_script" > /dev/null 2>&1; then
        log_success "Module imports work correctly"
        rm -f "$test_script"
        return 0
    else
        log_error "Module import failed"
        rm -f "$test_script"
        return 1
    fi
}

test_model_creation() {
    log_info "Testing model creation..."

    local test_script=$(mktemp --suffix=.mjs)

    cat > "$test_script" << 'EOF'
try {
  const { elevenlabs } = await import('@ai-sdk/elevenlabs');

  const model = elevenlabs.transcription('scribe_v1');

  if (!model) {
    console.error('FAIL: Model creation returned null/undefined');
    process.exit(1);
  }

  console.log('PASS: Model created successfully');
  process.exit(0);
} catch (error) {
  console.error('FAIL: Model creation error:', error.message);
  process.exit(1);
}
EOF

    if node "$test_script" > /dev/null 2>&1; then
        log_success "Model creation successful"
        rm -f "$test_script"
        return 0
    else
        log_error "Model creation failed"
        rm -f "$test_script"
        return 1
    fi
}

check_nextjs() {
    log_info "Checking Next.js setup..."

    if [ ! -f "package.json" ]; then
        log_warning "Cannot verify Next.js (no package.json)"
        return 1
    fi

    if ! grep -q '"next"' package.json; then
        log_warning "Next.js not detected in dependencies"
        return 1
    fi

    local version=$(node -pe "require('./package.json').dependencies.next || require('./package.json').devDependencies.next" 2>/dev/null || echo "unknown")

    log_success "Next.js detected (version: $version)"

    # Check for API routes
    if [ -d "app/api" ] || [ -d "pages/api" ]; then
        log_info "  API routes directory exists"
    else
        log_warning "  No API routes directory found"
    fi

    return 0
}

check_api_route() {
    log_info "Checking for transcription API route..."

    local found=false

    if [ -d "app/api" ]; then
        if find app/api -name "route.ts" -o -name "route.js" | grep -q "transcribe\|elevenlabs"; then
            log_success "App Router API route found"
            found=true
        fi
    fi

    if [ -d "pages/api" ]; then
        if find pages/api -name "*.ts" -o -name "*.js" | grep -q "transcribe\|elevenlabs"; then
            log_success "Pages Router API route found"
            found=true
        fi
    fi

    if [ "$found" = false ]; then
        log_warning "No transcription API route found"
        log_info "Create one with: bash scripts/create-api-route.sh"
    fi

    return 0
}

check_typescript() {
    log_info "Checking TypeScript configuration..."

    if [ -f "tsconfig.json" ]; then
        log_success "tsconfig.json exists"

        # Check for strict mode
        if grep -q '"strict": true' tsconfig.json; then
            log_info "  Strict mode enabled"
        else
            log_warning "  Strict mode not enabled"
        fi

        return 0
    else
        log_warning "TypeScript not configured (no tsconfig.json)"
        return 1
    fi
}

check_gitignore() {
    log_info "Checking .gitignore..."

    if [ ! -f ".gitignore" ]; then
        log_warning ".gitignore not found"
        return 1
    fi

    local issues=()

    if ! grep -q ".env.local" .gitignore; then
        issues+=(".env.local")
    fi

    if ! grep -q "node_modules" .gitignore; then
        issues+=("node_modules")
    fi

    if [ ${#issues[@]} -gt 0 ]; then
        log_warning "Missing in .gitignore: ${issues[*]}"
        return 1
    fi

    log_success ".gitignore properly configured"
    return 0
}

print_summary() {
    echo
    echo "======================================"
    echo "      VALIDATION SUMMARY"
    echo "======================================"
    echo
    echo -e "Passed:   ${GREEN}${PASSED}${NC}"
    echo -e "Failed:   ${RED}${FAILED}${NC}"
    echo -e "Warnings: ${YELLOW}${WARNINGS}${NC}"
    echo
    echo "======================================"
    echo

    if [ $FAILED -eq 0 ]; then
        log_success "All critical checks passed!"
        if [ $WARNINGS -gt 0 ]; then
            log_info "Review warnings above for improvements"
        fi
        return 0
    else
        log_error "Some critical checks failed"
        log_info "Fix the issues above and run validation again"
        return 1
    fi
}

main() {
    echo "======================================"
    echo "  ElevenLabs + Vercel AI SDK"
    echo "       Integration Validator"
    echo "======================================"
    echo

    # Run all checks
    check_node || true
    check_package_json || true
    check_dependencies || true
    check_api_key || true
    test_import || true
    test_model_creation || true
    check_nextjs || true
    check_api_route || true
    check_typescript || true
    check_gitignore || true

    # Print summary
    print_summary
}

# Run main function
main "$@"
