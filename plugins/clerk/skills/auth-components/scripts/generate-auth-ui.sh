#!/bin/bash
# Generate Clerk authentication UI pages
# Usage: ./generate-auth-ui.sh <output-dir> <component-type>

set -euo pipefail

OUTPUT_DIR="${1:-.}"
COMPONENT_TYPE="${2:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Validate output directory
if [[ ! -d "$OUTPUT_DIR" ]]; then
    log_error "Output directory does not exist: $OUTPUT_DIR"
    exit 1
fi

# Generate sign-in page
generate_signin() {
    local signin_dir="$OUTPUT_DIR/sign-in/[[...sign-in]]"
    mkdir -p "$signin_dir"

    if [[ -f "$TEMPLATES_DIR/sign-in-page.tsx" ]]; then
        cp "$TEMPLATES_DIR/sign-in-page.tsx" "$signin_dir/page.tsx"
        log_info "Created sign-in page: $signin_dir/page.tsx"
    else
        log_error "Sign-in template not found: $TEMPLATES_DIR/sign-in-page.tsx"
        return 1
    fi
}

# Generate sign-up page
generate_signup() {
    local signup_dir="$OUTPUT_DIR/sign-up/[[...sign-up]]"
    mkdir -p "$signup_dir"

    if [[ -f "$TEMPLATES_DIR/sign-up-page.tsx" ]]; then
        cp "$TEMPLATES_DIR/sign-up-page.tsx" "$signup_dir/page.tsx"
        log_info "Created sign-up page: $signup_dir/page.tsx"
    else
        log_error "Sign-up template not found: $TEMPLATES_DIR/sign-up-page.tsx"
        return 1
    fi
}

# Generate user profile page
generate_profile() {
    local profile_dir="$OUTPUT_DIR/profile/[[...profile]]"
    mkdir -p "$profile_dir"

    cat > "$profile_dir/page.tsx" <<'EOF'
import { UserProfile } from '@clerk/nextjs'

export default function ProfilePage() {
  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      <UserProfile
        appearance={{
          elements: {
            rootBox: "w-full max-w-4xl",
            card: "shadow-lg"
          }
        }}
      />
    </div>
  )
}
EOF
    log_info "Created profile page: $profile_dir/page.tsx"
}

# Generate protected route wrapper
generate_protected_wrapper() {
    local components_dir="$OUTPUT_DIR/../components/auth"
    mkdir -p "$components_dir"

    if [[ -f "$TEMPLATES_DIR/protected-wrapper.tsx" ]]; then
        cp "$TEMPLATES_DIR/protected-wrapper.tsx" "$components_dir/protected-wrapper.tsx"
        log_info "Created protected wrapper: $components_dir/protected-wrapper.tsx"
    else
        log_warn "Protected wrapper template not found, skipping"
    fi
}

# Main execution
echo "=== Clerk Auth UI Generator ==="
echo "Output directory: $OUTPUT_DIR"
echo "Component type: $COMPONENT_TYPE"
echo ""

case "$COMPONENT_TYPE" in
    signin)
        generate_signin
        ;;
    signup)
        generate_signup
        ;;
    both)
        generate_signin
        generate_signup
        ;;
    profile)
        generate_profile
        ;;
    all)
        generate_signin
        generate_signup
        generate_profile
        generate_protected_wrapper
        ;;
    *)
        log_error "Invalid component type: $COMPONENT_TYPE"
        echo "Valid types: signin, signup, both, profile, all"
        exit 1
        ;;
esac

echo ""
log_info "Auth UI generation complete!"
echo ""
echo "Next steps:"
echo "1. Add CLERK_PUBLISHABLE_KEY to .env.local"
echo "2. Add CLERK_SECRET_KEY to .env.local"
echo "3. Wrap app with <ClerkProvider> in layout.tsx"
echo "4. Configure afterSignInUrl and afterSignUpUrl"
