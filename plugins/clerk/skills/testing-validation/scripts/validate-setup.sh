#!/usr/bin/env bash
# validate-setup.sh - Validate Clerk configuration and setup
# Usage: bash validate-setup.sh [--fix]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FIX_MODE=false
ERRORS=0
WARNINGS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --fix)
      FIX_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--fix]"
      exit 1
      ;;
  esac
done

echo "🔍 Clerk Setup Validation"
echo "=========================="
echo ""

# Function to print status messages
info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; ((WARNINGS++)); }
error() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)); }

# Check for .env file
echo "📄 Checking environment files..."
if [[ -f .env ]]; then
  info ".env file exists"
elif [[ -f .env.local ]]; then
  info ".env.local file exists"
else
  error ".env or .env.local file not found"
  if [[ "$FIX_MODE" == true ]]; then
    cat > .env.example << 'EOF'
# Clerk API Keys
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
CLERK_SECRET_KEY=sk_test_your_secret_key_here

# Clerk URLs (for Next.js)
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard

# Test credentials (for E2E testing)
TEST_USER_EMAIL=test_user@example.com
TEST_USER_PASSWORD=test_password_here
EOF
    info "Created .env.example template"
  fi
fi

# Check for required environment variables
echo ""
echo "🔑 Checking environment variables..."

ENV_FILE=""
if [[ -f .env ]]; then
  ENV_FILE=".env"
elif [[ -f .env.local ]]; then
  ENV_FILE=".env.local"
fi

if [[ -n "$ENV_FILE" ]]; then
  # Check publishable key
  if grep -q "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" "$ENV_FILE" || grep -q "VITE_CLERK_PUBLISHABLE_KEY" "$ENV_FILE"; then
    PUBKEY=$(grep -E "(NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY|VITE_CLERK_PUBLISHABLE_KEY)" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' "'"'"'')
    if [[ "$PUBKEY" =~ ^pk_(test|live)_ ]]; then
      info "Publishable key found with correct format"
    elif [[ "$PUBKEY" == *"your_publishable_key_here"* ]] || [[ -z "$PUBKEY" ]]; then
      warn "Publishable key is placeholder - needs real value"
    else
      error "Publishable key has incorrect format (should start with pk_test_ or pk_live_)"
    fi
  else
    error "Publishable key not found in $ENV_FILE"
  fi

  # Check secret key
  if grep -q "CLERK_SECRET_KEY" "$ENV_FILE"; then
    SECKEY=$(grep "CLERK_SECRET_KEY" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' "'"'"'')
    if [[ "$SECKEY" =~ ^sk_(test|live)_ ]]; then
      info "Secret key found with correct format"
    elif [[ "$SECKEY" == *"your_secret_key_here"* ]] || [[ -z "$SECKEY" ]]; then
      warn "Secret key is placeholder - needs real value"
    else
      error "Secret key has incorrect format (should start with sk_test_ or sk_live_)"
    fi
  else
    error "Secret key not found in $ENV_FILE"
  fi

  # Check for URL configuration
  if grep -q "NEXT_PUBLIC_CLERK_SIGN_IN_URL" "$ENV_FILE"; then
    info "Sign-in URL configured"
  else
    warn "Sign-in URL not configured (optional but recommended)"
  fi
fi

# Check for ClerkProvider in app structure
echo ""
echo "⚛️  Checking React/Next.js integration..."

if [[ -f "app/layout.tsx" ]] || [[ -f "app/layout.js" ]]; then
  if grep -q "ClerkProvider" "app/layout.tsx" 2>/dev/null || grep -q "ClerkProvider" "app/layout.js" 2>/dev/null; then
    info "ClerkProvider found in app layout"
  else
    error "ClerkProvider not found in app layout"
    if [[ "$FIX_MODE" == true ]]; then
      warn "Please add ClerkProvider manually to app/layout.tsx"
    fi
  fi
elif [[ -f "src/app/layout.tsx" ]] || [[ -f "src/app/layout.js" ]]; then
  if grep -q "ClerkProvider" "src/app/layout.tsx" 2>/dev/null || grep -q "ClerkProvider" "src/app/layout.js" 2>/dev/null; then
    info "ClerkProvider found in src/app layout"
  else
    error "ClerkProvider not found in src/app layout"
  fi
elif [[ -f "pages/_app.tsx" ]] || [[ -f "pages/_app.js" ]]; then
  if grep -q "ClerkProvider" "pages/_app.tsx" 2>/dev/null || grep -q "ClerkProvider" "pages/_app.js" 2>/dev/null; then
    info "ClerkProvider found in pages/_app"
  else
    error "ClerkProvider not found in pages/_app"
  fi
elif [[ -f "src/main.tsx" ]] || [[ -f "src/main.jsx" ]]; then
  if grep -q "ClerkProvider" "src/main.tsx" 2>/dev/null || grep -q "ClerkProvider" "src/main.jsx" 2>/dev/null; then
    info "ClerkProvider found in React app entry point"
  else
    error "ClerkProvider not found in React app entry point"
  fi
else
  warn "Could not locate app entry point (layout.tsx, _app.tsx, or main.tsx)"
fi

# Check for middleware configuration (Next.js)
echo ""
echo "🛡️  Checking middleware configuration..."

if [[ -f "middleware.ts" ]] || [[ -f "middleware.js" ]]; then
  if grep -q "authMiddleware\|clerkMiddleware" "middleware.ts" 2>/dev/null || grep -q "authMiddleware\|clerkMiddleware" "middleware.js" 2>/dev/null; then
    info "Clerk middleware configured"
  else
    error "middleware.ts exists but Clerk middleware not configured"
  fi
else
  warn "middleware.ts not found (optional but recommended for route protection)"
fi

# Check package.json for Clerk dependencies
echo ""
echo "📦 Checking dependencies..."

if [[ -f "package.json" ]]; then
  if grep -q "@clerk/nextjs\|@clerk/clerk-react\|@clerk/clerk-js" "package.json"; then
    info "Clerk SDK installed"

    # Check for version
    CLERK_VERSION=$(grep -o "@clerk/[^\"]*" "package.json" | head -1)
    if [[ -n "$CLERK_VERSION" ]]; then
      info "Using $CLERK_VERSION"
    fi
  else
    error "Clerk SDK not installed"
    if [[ "$FIX_MODE" == true ]]; then
      warn "Install with: npm install @clerk/nextjs (or appropriate package)"
    fi
  fi
else
  error "package.json not found"
fi

# Security checks
echo ""
echo "🔒 Security checks..."

# Check for exposed secret keys in client code
if grep -r "sk_test_\|sk_live_" --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" app/ src/ pages/ 2>/dev/null | grep -v "node_modules" | grep -v ".env"; then
  error "SECRET KEY exposed in client code! Check the files above."
else
  info "No secret keys found in client code"
fi

# Check for .env in .gitignore
if [[ -f ".gitignore" ]]; then
  if grep -q "^\.env$\|^\.env\.local$" ".gitignore"; then
    info ".env files excluded from git"
  else
    error ".env not in .gitignore - API keys could be committed!"
    if [[ "$FIX_MODE" == true ]]; then
      echo ".env" >> .gitignore
      echo ".env.local" >> .gitignore
      info "Added .env to .gitignore"
    fi
  fi
else
  warn ".gitignore not found"
fi

# Summary
echo ""
echo "=========================="
echo "📊 Validation Summary"
echo "=========================="
if [[ $ERRORS -eq 0 ]]; then
  info "All checks passed! ✓"
  if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
  fi
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s) found${NC}"
  if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
  fi
  if [[ "$FIX_MODE" == false ]]; then
    echo ""
    echo "Run with --fix to attempt automatic fixes"
  fi
  exit 1
fi
