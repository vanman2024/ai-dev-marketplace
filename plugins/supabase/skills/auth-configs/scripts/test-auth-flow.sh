#!/bin/bash

# test-auth-flow.sh - Test Supabase authentication flows end-to-end
# Usage: ./test-auth-flow.sh [provider|--email|--all]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_dependencies() {
    local missing_deps=()

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Install with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
}

check_env_vars() {
    local missing_vars=()

    if [ -z "${SUPABASE_URL:-}" ]; then
        missing_vars+=("SUPABASE_URL")
    fi

    if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
        missing_vars+=("SUPABASE_ANON_KEY")
    fi

    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        echo ""
        echo "Set these variables in .env.local:"
        echo "  SUPABASE_URL=https://your-project.supabase.co"
        echo "  SUPABASE_ANON_KEY=your-anon-key"
        exit 1
    fi
}

test_supabase_connection() {
    print_info "Testing Supabase connection..."

    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/rest/v1/" \
        -H "apikey: ${SUPABASE_ANON_KEY}" 2>&1)

    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        print_success "Supabase connection successful"
        return 0
    else
        print_error "Failed to connect to Supabase (HTTP $http_code)"
        return 1
    fi
}

test_email_signup() {
    local test_email="${1:-test-$(date +%s)@example.com}"
    local test_password="TestPassword123!"

    print_info "Testing email signup with: $test_email"

    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/auth/v1/signup" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$test_email\",\"password\":\"$test_password\"}" 2>&1)

    local body=$(echo "$response" | head -n-1)
    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        print_success "Email signup successful"

        # Check if email confirmation is required
        local email_confirmed=$(echo "$body" | jq -r '.user.email_confirmed_at // empty')
        if [ -z "$email_confirmed" ]; then
            print_warning "Email confirmation required - check inbox for $test_email"
        else
            print_success "Email automatically confirmed"
        fi

        echo "$body" | jq -r '.access_token' > /tmp/test_access_token.txt
        return 0
    else
        print_error "Email signup failed (HTTP $http_code)"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    fi
}

test_email_login() {
    local test_email="${1:-test@example.com}"
    local test_password="TestPassword123!"

    print_info "Testing email login with: $test_email"

    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$test_email\",\"password\":\"$test_password\"}" 2>&1)

    local body=$(echo "$response" | head -n-1)
    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        print_success "Email login successful"
        echo "$body" | jq -r '.access_token' > /tmp/test_access_token.txt
        return 0
    else
        print_error "Email login failed (HTTP $http_code)"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    fi
}

test_magic_link() {
    local test_email="${1:-test-$(date +%s)@example.com}"

    print_info "Testing magic link for: $test_email"

    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/auth/v1/otp" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$test_email\",\"create_user\":true}" 2>&1)

    local body=$(echo "$response" | head -n-1)
    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        print_success "Magic link sent successfully"
        print_warning "Check inbox for $test_email to complete login"
        return 0
    else
        print_error "Magic link failed (HTTP $http_code)"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    fi
}

test_oauth_provider() {
    local provider=$1

    print_info "Testing OAuth provider: $provider"

    # OAuth requires browser interaction, so we just validate the auth URL
    local auth_url="${SUPABASE_URL}/auth/v1/authorize?provider=${provider}"

    print_info "OAuth authorization URL:"
    echo "  $auth_url"
    echo ""
    print_warning "OAuth requires browser interaction:"
    echo "  1. Open the URL above in a browser"
    echo "  2. Complete OAuth flow with $provider"
    echo "  3. Verify redirect to callback URL"
    echo ""

    # Test if provider is configured
    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/auth/v1/settings" \
        -H "apikey: ${SUPABASE_ANON_KEY}" 2>&1)

    local body=$(echo "$response" | head -n-1)
    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        local provider_enabled=$(echo "$body" | jq -r ".external.${provider} // false")
        if [ "$provider_enabled" = "true" ]; then
            print_success "$provider OAuth is configured"
        else
            print_warning "$provider OAuth may not be configured"
            echo "Configure in Supabase Dashboard: Authentication > Providers"
        fi
    fi
}

test_session_refresh() {
    print_info "Testing session refresh..."

    if [ ! -f /tmp/test_access_token.txt ]; then
        print_warning "No active session to refresh"
        print_info "Run email login test first"
        return 1
    fi

    local access_token=$(cat /tmp/test_access_token.txt)

    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/auth/v1/user" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer $access_token" 2>&1)

    local body=$(echo "$response" | head -n-1)
    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        print_success "Session is valid"
        local user_email=$(echo "$body" | jq -r '.email')
        print_info "Authenticated as: $user_email"
        return 0
    else
        print_error "Session validation failed (HTTP $http_code)"
        return 1
    fi
}

test_protected_request() {
    print_info "Testing authenticated request to protected route..."

    if [ ! -f /tmp/test_access_token.txt ]; then
        print_warning "No active session"
        print_info "Run email login test first"
        return 1
    fi

    local access_token=$(cat /tmp/test_access_token.txt)

    # Test authenticated request to a protected table
    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/rest/v1/rpc/auth.uid" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer $access_token" 2>&1)

    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
        print_success "Authenticated request successful"
        return 0
    else
        print_error "Authenticated request failed (HTTP $http_code)"
        return 1
    fi
}

test_logout() {
    print_info "Testing logout..."

    if [ ! -f /tmp/test_access_token.txt ]; then
        print_warning "No active session to logout"
        return 0
    fi

    local access_token=$(cat /tmp/test_access_token.txt)

    local response=$(curl -s -w "\n%{http_code}" \
        "${SUPABASE_URL}/auth/v1/logout" \
        -X POST \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer $access_token" 2>&1)

    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "204" ] || [ "$http_code" = "200" ]; then
        print_success "Logout successful"
        rm -f /tmp/test_access_token.txt
        return 0
    else
        print_error "Logout failed (HTTP $http_code)"
        return 1
    fi
}

run_comprehensive_tests() {
    echo ""
    print_info "Running comprehensive authentication tests..."
    echo ""

    local passed=0
    local failed=0

    # Test 1: Connection
    echo "Test 1: Supabase Connection"
    if test_supabase_connection; then
        ((passed++))
    else
        ((failed++))
    fi
    echo ""

    # Test 2: Email Signup
    echo "Test 2: Email Signup"
    local test_email="test-$(date +%s)@example.com"
    if test_email_signup "$test_email"; then
        ((passed++))
    else
        ((failed++))
    fi
    echo ""

    # Test 3: Session Validation
    echo "Test 3: Session Validation"
    if test_session_refresh; then
        ((passed++))
    else
        ((failed++))
    fi
    echo ""

    # Test 4: Protected Request
    echo "Test 4: Authenticated Request"
    if test_protected_request; then
        ((passed++))
    else
        ((failed++))
    fi
    echo ""

    # Test 5: Logout
    echo "Test 5: Logout"
    if test_logout; then
        ((passed++))
    else
        ((failed++))
    fi
    echo ""

    # Test 6: Magic Link
    echo "Test 6: Magic Link"
    if test_magic_link "magic-$(date +%s)@example.com"; then
        ((passed++))
    else
        ((failed++))
    fi
    echo ""

    # Summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_info "Test Summary:"
    echo "  Passed: $passed"
    if [ $failed -gt 0 ]; then
        echo -e "  ${RED}Failed: $failed${NC}"
    else
        echo "  Failed: $failed"
    fi
    echo ""

    if [ $failed -eq 0 ]; then
        print_success "All tests passed!"
        return 0
    else
        print_error "Some tests failed"
        return 1
    fi
}

show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [PROVIDER]

Test Supabase authentication flows end-to-end.

Options:
  --email          Test email authentication only
  --magic-link     Test magic link authentication
  --all            Run all authentication tests
  --help           Show this help message

Provider:
  google, github, discord, etc. - Test specific OAuth provider

Examples:
  $0 --email                    # Test email auth
  $0 google                     # Test Google OAuth
  $0 --all                      # Run comprehensive tests

Environment Variables Required:
  SUPABASE_URL                  # Your Supabase project URL
  SUPABASE_ANON_KEY             # Public anonymous key

EOF
}

main() {
    # Check dependencies
    check_dependencies

    # Check environment variables
    check_env_vars

    # Parse arguments
    if [ $# -eq 0 ]; then
        run_comprehensive_tests
        exit $?
    fi

    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --email)
            test_email_signup
            test_session_refresh
            test_logout
            ;;
        --magic-link)
            test_magic_link
            ;;
        --all)
            run_comprehensive_tests
            ;;
        *)
            # Assume it's an OAuth provider
            test_oauth_provider "$1"
            ;;
    esac
}

main "$@"
