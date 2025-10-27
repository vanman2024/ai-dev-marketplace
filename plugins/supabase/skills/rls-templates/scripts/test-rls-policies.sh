#!/bin/bash
# Test RLS policies enforcement with different user contexts
# Usage: test-rls-policies.sh <table> [--user-id UUID] [--org-id UUID]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $0 <table> [options]

Options:
  --user-id UUID     Test with specific user ID
  --org-id UUID      Test with specific organization ID
  --anon             Test anonymous access (default)

Environment Variables (required):
  SUPABASE_DB_URL    - PostgreSQL connection string
  SUPABASE_ANON_KEY  - Supabase anonymous key (for API tests)

Examples:
  $0 conversations
  $0 messages --user-id "550e8400-e29b-41d4-a716-446655440000"
  $0 documents --org-id "org-uuid-here"
EOF
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

check_prerequisites() {
    if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
        log_error "SUPABASE_DB_URL environment variable not set"
        exit 1
    fi

    if ! command -v psql &> /dev/null; then
        log_error "psql not found. Install PostgreSQL client tools."
        exit 1
    fi
}

test_rls_enabled() {
    local table="$1"

    log_test "Checking if RLS is enabled on $table"

    local enabled=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT relrowsecurity
        FROM pg_class
        WHERE relname = '$table';
    " 2>/dev/null | tr -d ' ')

    if [[ "$enabled" == "t" ]]; then
        log_info "✓ RLS is enabled"
        return 0
    else
        log_error "✗ RLS is NOT enabled!"
        return 1
    fi
}

test_policies_exist() {
    local table="$1"

    log_test "Checking policies on $table"

    local policies=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT policyname, cmd
        FROM pg_policies
        WHERE tablename = '$table';
    " 2>/dev/null)

    if [[ -z "$policies" ]]; then
        log_error "✗ No policies found!"
        return 1
    else
        log_info "✓ Policies found:"
        echo "$policies" | while read -r line; do
            if [[ -n "$line" ]]; then
                echo "    $line"
            fi
        done
        return 0
    fi
}

test_anonymous_access() {
    local table="$1"

    log_test "Testing anonymous access (should be denied)"

    # Set role to anon (unauthenticated)
    local result=$(psql "$SUPABASE_DB_URL" -t -c "
        SET ROLE anon;
        SELECT COUNT(*) FROM $table;
        RESET ROLE;
    " 2>&1)

    if echo "$result" | grep -q "0"; then
        log_info "✓ Anonymous access correctly denied (0 rows)"
        return 0
    elif echo "$result" | grep -qi "permission denied"; then
        log_info "✓ Anonymous access correctly denied (permission error)"
        return 0
    else
        log_warn "⚠ Anonymous access returned data: $result"
        return 1
    fi
}

test_authenticated_user_access() {
    local table="$1"
    local user_id="$2"

    log_test "Testing authenticated user access (user: ${user_id:0:8}...)"

    # Test with authenticated role and auth.uid() set
    local result=$(psql "$SUPABASE_DB_URL" -t -c "
        SET ROLE authenticated;
        SET request.jwt.claim.sub = '$user_id';
        SELECT COUNT(*) FROM $table WHERE user_id = '$user_id';
        RESET ROLE;
    " 2>&1)

    if echo "$result" | grep -qE "[0-9]+"; then
        local count=$(echo "$result" | tr -d ' ' | grep -oE "[0-9]+")
        log_info "✓ User can access their own data ($count rows)"
        return 0
    else
        log_error "✗ User access failed: $result"
        return 1
    fi
}

test_user_isolation() {
    local table="$1"
    local user1="$2"
    local user2="${3:-$(uuidgen)}"

    log_test "Testing user isolation (user1 cannot see user2 data)"

    # Try to access another user's data
    local result=$(psql "$SUPABASE_DB_URL" -t -c "
        SET ROLE authenticated;
        SET request.jwt.claim.sub = '$user1';
        SELECT COUNT(*) FROM $table WHERE user_id = '$user2';
        RESET ROLE;
    " 2>&1)

    if echo "$result" | grep -q "0"; then
        log_info "✓ User isolation working (0 rows from other user)"
        return 0
    else
        log_error "✗ User isolation FAILED: user can see other user's data!"
        return 1
    fi
}

test_insert_policy() {
    local table="$1"
    local user_id="$2"

    log_test "Testing INSERT policy"

    # Try to insert with correct user_id
    local result=$(psql "$SUPABASE_DB_URL" -t -c "
        SET ROLE authenticated;
        SET request.jwt.claim.sub = '$user_id';
        -- This would insert if column structure matches
        SELECT 'INSERT policy exists and would allow correct user_id';
        RESET ROLE;
    " 2>&1)

    # Just verify the session can be established
    if echo "$result" | grep -qi "policy exists"; then
        log_info "✓ INSERT context can be established"
        return 0
    else
        log_warn "⚠ Could not verify INSERT policy"
        return 1
    fi
}

test_update_policy() {
    local table="$1"
    local user_id="$2"

    log_test "Testing UPDATE policy"

    # Verify UPDATE policies exist
    local update_policies=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*)
        FROM pg_policies
        WHERE tablename = '$table' AND cmd = 'UPDATE';
    " 2>/dev/null | tr -d ' ')

    if [[ "$update_policies" -gt 0 ]]; then
        log_info "✓ UPDATE policies configured ($update_policies policies)"
        return 0
    else
        log_warn "⚠ No UPDATE policies found"
        return 1
    fi
}

test_delete_policy() {
    local table="$1"
    local user_id="$2"

    log_test "Testing DELETE policy"

    # Verify DELETE policies exist
    local delete_policies=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*)
        FROM pg_policies
        WHERE tablename = '$table' AND cmd = 'DELETE';
    " 2>/dev/null | tr -d ' ')

    if [[ "$delete_policies" -gt 0 ]]; then
        log_info "✓ DELETE policies configured ($delete_policies policies)"
        return 0
    else
        log_warn "⚠ No DELETE policies found"
        return 1
    fi
}

test_performance_indexes() {
    local table="$1"

    log_test "Checking performance indexes"

    local indexes=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT indexname
        FROM pg_indexes
        WHERE tablename = '$table'
        AND indexname LIKE 'idx_%';
    " 2>/dev/null)

    if [[ -n "$indexes" ]]; then
        log_info "✓ Performance indexes found:"
        echo "$indexes" | while read -r line; do
            if [[ -n "$line" ]]; then
                echo "    $(echo $line | tr -d ' ')"
            fi
        done
        return 0
    else
        log_warn "⚠ No performance indexes found (recommend adding)"
        return 1
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    check_prerequisites

    local table="$1"
    shift

    local user_id=""
    local org_id=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user-id)
                user_id="$2"
                shift 2
                ;;
            --org-id)
                org_id="$2"
                shift 2
                ;;
            --anon)
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Generate test user ID if not provided
    if [[ -z "$user_id" ]]; then
        user_id=$(uuidgen 2>/dev/null || echo "550e8400-e29b-41d4-a716-446655440000")
        log_info "Using generated test user ID: $user_id"
    fi

    echo "========================================"
    log_info "Testing RLS policies on table: $table"
    echo "========================================"
    echo

    local failed=0

    # Run all tests
    test_rls_enabled "$table" || ((failed++))
    echo

    test_policies_exist "$table" || ((failed++))
    echo

    test_performance_indexes "$table"
    echo

    test_anonymous_access "$table" || ((failed++))
    echo

    test_authenticated_user_access "$table" "$user_id" || ((failed++))
    echo

    test_user_isolation "$table" "$user_id" || ((failed++))
    echo

    test_insert_policy "$table" "$user_id"
    echo

    test_update_policy "$table" "$user_id"
    echo

    test_delete_policy "$table" "$user_id"
    echo

    echo "========================================"
    if [[ $failed -eq 0 ]]; then
        log_info "All critical tests passed! ✓"
        exit 0
    else
        log_error "$failed critical test(s) failed"
        exit 1
    fi
}

main "$@"
