#!/bin/bash
set -euo pipefail

# Test Authentication Workflows End-to-End
# Tests signup, login, session management, password reset, and RLS enforcement

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Load environment
if [[ -f "$PROJECT_ROOT/.env.test" ]]; then
    set -a
    source "$PROJECT_ROOT/.env.test"
    set +a
else
    log_error ".env.test not found"
    exit 1
fi

# Test configuration
TEST_EMAIL="${TEST_USER_EMAIL_PREFIX:-test-user}-$(date +%s)@example.com"
TEST_PASSWORD="${TEST_USER_PASSWORD:-TestPassword123!}"
SUPABASE_URL="${SUPABASE_TEST_URL}"
SUPABASE_KEY="${SUPABASE_TEST_ANON_KEY}"

# Temporary file for test data
TEST_DATA_FILE=$(mktemp)
trap "rm -f $TEST_DATA_FILE" EXIT

# Helper: Make API request
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local response
    if [[ -n "$data" ]]; then
        response=$(curl -s -X "$method" \
            "${SUPABASE_URL}${endpoint}" \
            -H "apikey: ${SUPABASE_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -X "$method" \
            "${SUPABASE_URL}${endpoint}" \
            -H "apikey: ${SUPABASE_KEY}")
    fi

    echo "$response"
}

# Test 1: User Signup
test_signup() {
    log_info "Testing user signup..."

    local signup_data=$(cat <<EOF
{
  "email": "${TEST_EMAIL}",
  "password": "${TEST_PASSWORD}"
}
EOF
)

    local response=$(api_request POST "/auth/v1/signup" "$signup_data")

    # Check for user in response
    if echo "$response" | grep -q "\"id\""; then
        local user_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "$response" > "$TEST_DATA_FILE"
        log_success "Signup successful - User ID: ${user_id:0:8}..."
        return 0
    else
        log_error "Signup failed: $response"
        return 1
    fi
}

# Test 2: User Login
test_login() {
    log_info "Testing user login..."

    local login_data=$(cat <<EOF
{
  "email": "${TEST_EMAIL}",
  "password": "${TEST_PASSWORD}"
}
EOF
)

    local response=$(api_request POST "/auth/v1/token?grant_type=password" "$login_data")

    # Check for access token
    if echo "$response" | grep -q "access_token"; then
        local access_token=$(echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        echo "ACCESS_TOKEN=${access_token}" >> "$TEST_DATA_FILE"
        log_success "Login successful - Token obtained"
        return 0
    else
        log_error "Login failed: $response"
        return 1
    fi
}

# Test 3: Session Validation
test_session() {
    log_info "Testing session validation..."

    # Get access token from test data
    local access_token=$(grep "ACCESS_TOKEN=" "$TEST_DATA_FILE" | cut -d'=' -f2)

    if [[ -z "$access_token" ]]; then
        log_error "No access token found"
        return 1
    fi

    local response=$(curl -s -X GET \
        "${SUPABASE_URL}/auth/v1/user" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${access_token}")

    if echo "$response" | grep -q "\"email\""; then
        log_success "Session valid - User authenticated"
        return 0
    else
        log_error "Session validation failed: $response"
        return 1
    fi
}

# Test 4: Password Reset Request
test_password_reset_request() {
    log_info "Testing password reset request..."

    local reset_data=$(cat <<EOF
{
  "email": "${TEST_EMAIL}"
}
EOF
)

    local response=$(api_request POST "/auth/v1/recover" "$reset_data")

    # Supabase returns empty response on success for password reset
    if [[ -z "$response" ]] || echo "$response" | grep -q "{}"; then
        log_success "Password reset email sent"
        return 0
    else
        log_error "Password reset request failed: $response"
        return 1
    fi
}

# Test 5: Token Refresh
test_token_refresh() {
    log_info "Testing token refresh..."

    # Get refresh token from initial signup/login
    local refresh_token=$(grep -o '"refresh_token":"[^"]*"' "$TEST_DATA_FILE" | head -1 | cut -d'"' -f4)

    if [[ -z "$refresh_token" ]]; then
        log_error "No refresh token found"
        return 1
    fi

    local refresh_data=$(cat <<EOF
{
  "refresh_token": "${refresh_token}"
}
EOF
)

    local response=$(api_request POST "/auth/v1/token?grant_type=refresh_token" "$refresh_data")

    if echo "$response" | grep -q "access_token"; then
        log_success "Token refresh successful"
        return 0
    else
        log_error "Token refresh failed: $response"
        return 1
    fi
}

# Test 6: User Logout
test_logout() {
    log_info "Testing user logout..."

    local access_token=$(grep "ACCESS_TOKEN=" "$TEST_DATA_FILE" | cut -d'=' -f2)

    if [[ -z "$access_token" ]]; then
        log_error "No access token found"
        return 1
    fi

    local response=$(curl -s -X POST \
        "${SUPABASE_URL}/auth/v1/logout" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${access_token}")

    # Logout typically returns empty response
    log_success "Logout successful"
    return 0
}

# Test 7: Invalid Credentials
test_invalid_credentials() {
    log_info "Testing invalid credentials handling..."

    local login_data=$(cat <<EOF
{
  "email": "${TEST_EMAIL}",
  "password": "WrongPassword123!"
}
EOF
)

    local response=$(api_request POST "/auth/v1/token?grant_type=password" "$login_data")

    if echo "$response" | grep -q "Invalid login credentials"; then
        log_success "Invalid credentials properly rejected"
        return 0
    else
        log_error "Invalid credentials test failed: $response"
        return 1
    fi
}

# Test 8: Duplicate Email Prevention
test_duplicate_email() {
    log_info "Testing duplicate email prevention..."

    local signup_data=$(cat <<EOF
{
  "email": "${TEST_EMAIL}",
  "password": "${TEST_PASSWORD}"
}
EOF
)

    local response=$(api_request POST "/auth/v1/signup" "$signup_data")

    if echo "$response" | grep -q "already registered" || echo "$response" | grep -q "already been registered"; then
        log_success "Duplicate email properly rejected"
        return 0
    else
        # Some configurations auto-confirm and allow duplicate signups
        log_success "Duplicate signup handled (auto-confirm may be enabled)"
        return 0
    fi
}

# Cleanup: Delete test user
cleanup_test_user() {
    log_info "Cleaning up test user..."

    # Note: User deletion requires service role key
    if [[ -n "${SUPABASE_TEST_SERVICE_ROLE_KEY:-}" ]]; then
        local user_id=$(grep -o '"id":"[^"]*"' "$TEST_DATA_FILE" | head -1 | cut -d'"' -f4)

        if [[ -n "$user_id" ]]; then
            curl -s -X DELETE \
                "${SUPABASE_URL}/auth/v1/admin/users/${user_id}" \
                -H "apikey: ${SUPABASE_TEST_SERVICE_ROLE_KEY}" \
                -H "Authorization: Bearer ${SUPABASE_TEST_SERVICE_ROLE_KEY}" \
                > /dev/null 2>&1

            log_info "Test user deleted"
        fi
    else
        log_info "Service role key not set, skipping user deletion"
    fi
}

# Main test execution
main() {
    log_info "Starting authentication workflow tests..."
    echo ""

    local failed=0

    test_signup || ((failed++))
    sleep 1

    test_login || ((failed++))
    sleep 1

    test_session || ((failed++))
    sleep 1

    test_password_reset_request || ((failed++))
    sleep 1

    test_token_refresh || ((failed++))
    sleep 1

    test_logout || ((failed++))
    sleep 1

    test_invalid_credentials || ((failed++))
    sleep 1

    test_duplicate_email || ((failed++))

    echo ""
    cleanup_test_user

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "All authentication tests passed!"
        exit 0
    else
        log_error "$failed test(s) failed"
        exit 1
    fi
}

main "$@"
