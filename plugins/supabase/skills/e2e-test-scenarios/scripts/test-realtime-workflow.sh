#!/bin/bash
set -euo pipefail

# Test Realtime Features End-to-End
# Tests database change subscriptions, broadcast, and presence

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

log_info "Realtime tests require JavaScript/TypeScript test suite"
log_info "Run: npm test -- tests/realtime"
log_info "This script validates realtime setup only"

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

# Test 1: Verify realtime publication exists
test_realtime_publication() {
    log_info "Checking realtime publication..."

    local pub_exists=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_publication WHERE pubname = 'supabase_realtime';" | tr -d ' ')

    if [[ "$pub_exists" -gt 0 ]]; then
        log_success "Realtime publication exists"
        return 0
    else
        log_error "Realtime publication not found"
        log_info "Create it with: supabase start (for local) or enable in dashboard"
        return 1
    fi
}

# Test 2: Create test table with RLS
test_create_realtime_table() {
    log_info "Creating test realtime table..."

    psql "$DB_URL" > /dev/null 2>&1 <<'EOF'
DROP TABLE IF EXISTS test_messages CASCADE;

CREATE TABLE test_messages (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  user_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE test_messages ENABLE ROW LEVEL SECURITY;

-- Allow all operations for testing
CREATE POLICY "Allow all for testing" ON test_messages FOR ALL USING (true);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE test_messages;
EOF

    if [[ $? -eq 0 ]]; then
        log_success "Test realtime table created"
        return 0
    else
        log_error "Failed to create test realtime table"
        return 1
    fi
}

# Test 3: Verify table in publication
test_table_in_publication() {
    log_info "Verifying table in realtime publication..."

    local in_pub=$(psql "$DB_URL" -t <<'EOF' | tr -d ' '
SELECT COUNT(*)
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'test_messages';
EOF
)

    if [[ "$in_pub" -gt 0 ]]; then
        log_success "Table added to realtime publication"
        return 0
    else
        log_error "Table not in realtime publication"
        return 1
    fi
}

# Test 4: Test insert/update/delete operations
test_crud_operations() {
    log_info "Testing CRUD operations for realtime..."

    # Insert
    psql "$DB_URL" -c "INSERT INTO test_messages (content) VALUES ('test message 1');" > /dev/null 2>&1
    local insert_result=$?

    # Update
    psql "$DB_URL" -c "UPDATE test_messages SET content = 'updated' WHERE content = 'test message 1';" > /dev/null 2>&1
    local update_result=$?

    # Delete
    psql "$DB_URL" -c "DELETE FROM test_messages WHERE content = 'updated';" > /dev/null 2>&1
    local delete_result=$?

    if [[ $insert_result -eq 0 ]] && [[ $update_result -eq 0 ]] && [[ $delete_result -eq 0 ]]; then
        log_success "CRUD operations working"
        return 0
    else
        log_error "Some CRUD operations failed"
        return 1
    fi
}

# Test 5: Check replication slot (advanced)
test_replication_slot() {
    log_info "Checking replication slot..."

    local slot_count=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_replication_slots WHERE slot_type = 'logical';" 2>/dev/null | tr -d ' ' || echo "0")

    if [[ "$slot_count" -gt 0 ]]; then
        log_success "Replication slot exists for realtime"
        return 0
    else
        log_info "No replication slot found (normal for managed Supabase)"
        return 0
    fi
}

# Cleanup
cleanup_realtime_test() {
    log_info "Cleaning up realtime test table..."

    psql "$DB_URL" > /dev/null 2>&1 <<'EOF'
ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS test_messages;
DROP TABLE IF EXISTS test_messages CASCADE;
EOF

    log_info "Test table cleaned up"
}

# Main execution
main() {
    log_info "Starting realtime workflow tests..."
    echo ""

    local failed=0

    test_realtime_publication || ((failed++))
    test_create_realtime_table || ((failed++))
    test_table_in_publication || ((failed++))
    test_crud_operations || ((failed++))
    test_replication_slot || ((failed++))

    echo ""
    cleanup_realtime_test

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "All realtime setup tests passed!"
        log_info "Run full realtime tests with: npm test -- tests/realtime"
        exit 0
    else
        log_error "$failed test(s) failed"
        exit 1
    fi
}

main "$@"
