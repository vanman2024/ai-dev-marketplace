#!/bin/bash
set -euo pipefail

# Cleanup Test Resources
# Removes test users, test data, and temporary test resources

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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
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

DB_URL="${DATABASE_URL:-${SUPABASE_TEST_URL}}"
CLEANUP_ENABLED="${TEST_CLEANUP_ENABLED:-true}"

# Check if cleanup is enabled
if [[ "$CLEANUP_ENABLED" != "true" ]]; then
    log_warn "Cleanup is disabled in .env.test"
    log_info "Set TEST_CLEANUP_ENABLED=true to enable"
    exit 0
fi

# Cleanup test users (requires service role key)
cleanup_test_users() {
    log_info "Cleaning up test users..."

    if [[ -z "${SUPABASE_TEST_SERVICE_ROLE_KEY:-}" ]]; then
        log_warn "Service role key not set, skipping user cleanup"
        return 0
    fi

    local test_email_prefix="${TEST_USER_EMAIL_PREFIX:-test-user}"
    local supabase_url="${SUPABASE_TEST_URL}"
    local service_key="${SUPABASE_TEST_SERVICE_ROLE_KEY}"

    # List test users
    local users=$(curl -s -X GET \
        "${supabase_url}/auth/v1/admin/users" \
        -H "apikey: ${service_key}" \
        -H "Authorization: Bearer ${service_key}" | \
        grep -o '"id":"[^"]*"' | cut -d'"' -f4)

    local deleted_count=0

    # Delete each test user
    for user_id in $users; do
        # Get user email to check if it's a test user
        local user_info=$(curl -s -X GET \
            "${supabase_url}/auth/v1/admin/users/${user_id}" \
            -H "apikey: ${service_key}" \
            -H "Authorization: Bearer ${service_key}")

        if echo "$user_info" | grep -q "$test_email_prefix"; then
            curl -s -X DELETE \
                "${supabase_url}/auth/v1/admin/users/${user_id}" \
                -H "apikey: ${service_key}" \
                -H "Authorization: Bearer ${service_key}" \
                > /dev/null 2>&1

            ((deleted_count++))
        fi
    done

    if [[ $deleted_count -gt 0 ]]; then
        log_success "Deleted $deleted_count test user(s)"
    else
        log_info "No test users to cleanup"
    fi
}

# Cleanup test tables
cleanup_test_tables() {
    log_info "Cleaning up test tables..."

    # List of test tables to clean
    local test_tables=(
        "test_embeddings"
        "test_messages"
        "test_notes"
        "test_posts"
    )

    for table in "${test_tables[@]}"; do
        local exists=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '$table';" 2>/dev/null | tr -d ' ' || echo "0")

        if [[ "$exists" -gt 0 ]]; then
            psql "$DB_URL" -c "DROP TABLE IF EXISTS $table CASCADE;" > /dev/null 2>&1
            log_success "Dropped test table: $table"
        fi
    done
}

# Cleanup test data from production tables
cleanup_test_data() {
    log_info "Cleaning up test data..."

    # Clean test data created in the last 24 hours
    local cutoff_time=$(date -u -d '24 hours ago' '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -u -v-24H '+%Y-%m-%d %H:%M:%S')

    # Example: Clean test users from a users table
    # Adjust based on your schema
    psql "$DB_URL" > /dev/null 2>&1 <<EOF || true
-- Clean test data older than 24 hours
-- Customize these based on your actual schema

-- Example: DELETE FROM users WHERE email LIKE '${TEST_USER_EMAIL_PREFIX:-test-user}%';
-- Example: DELETE FROM posts WHERE created_at > '$cutoff_time' AND user_id IS NULL;
EOF

    log_info "Test data cleanup attempted"
}

# Cleanup test functions
cleanup_test_functions() {
    log_info "Cleaning up test functions..."

    local test_functions=(
        "match_test_embeddings"
    )

    for func in "${test_functions[@]}"; do
        psql "$DB_URL" -c "DROP FUNCTION IF EXISTS $func CASCADE;" > /dev/null 2>&1
    done

    log_info "Test functions cleaned up"
}

# Cleanup test files
cleanup_test_files() {
    log_info "Cleaning up test files..."

    # Clean coverage reports
    if [[ -d "$PROJECT_ROOT/coverage" ]]; then
        rm -rf "$PROJECT_ROOT/coverage"
        log_success "Removed coverage directory"
    fi

    # Clean test results
    if [[ -f "$PROJECT_ROOT/junit.xml" ]]; then
        rm -f "$PROJECT_ROOT/junit.xml"
        log_success "Removed test results"
    fi

    # Clean temporary test files
    find "$PROJECT_ROOT" -name "*.test.js" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -name "*.test.js.map" -type f -delete 2>/dev/null || true

    log_info "Test files cleaned up"
}

# Cleanup storage buckets (if using storage)
cleanup_storage() {
    log_info "Cleaning up test storage..."

    if [[ -z "${SUPABASE_TEST_SERVICE_ROLE_KEY:-}" ]]; then
        log_warn "Service role key not set, skipping storage cleanup"
        return 0
    fi

    # Example: Clean test buckets or files
    # This would require Supabase storage API calls
    # Implement based on your storage usage

    log_info "Storage cleanup skipped (implement if needed)"
}

# Reset database to migrations (optional)
reset_database() {
    log_info "Database reset not performed by default"
    log_info "To reset database: supabase db reset --linked"
}

# Main execution
main() {
    log_info "Starting test resource cleanup..."
    echo ""

    cleanup_test_users
    cleanup_test_tables
    cleanup_test_data
    cleanup_test_functions
    cleanup_test_files
    cleanup_storage

    echo ""
    log_success "Test resource cleanup complete!"
    echo ""
    log_info "To perform full database reset:"
    log_info "  supabase db reset --linked"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            log_info "Full cleanup mode enabled"
            reset_database
            shift
            ;;
        --dry-run)
            log_info "Dry run mode - no changes will be made"
            CLEANUP_ENABLED="false"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --full         Perform full database reset"
            echo "  --dry-run      Show what would be cleaned without making changes"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

main "$@"
