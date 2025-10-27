#!/bin/bash
set -euo pipefail

# Test and validate pgvector setup
# Usage: ./test-vector-search.sh <table_name> [db_url]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Validate arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <table_name> [db_url]"
    echo ""
    echo "Example:"
    echo "  $0 documents"
    exit 1
fi

TABLE_NAME="$1"
DB_URL="${2:-${SUPABASE_DB_URL:-}}"

if [ -z "$DB_URL" ]; then
    log_fail "Database URL required"
    echo "Provide as 2nd argument or set SUPABASE_DB_URL environment variable"
    exit 1
fi

PASSED=0
FAILED=0

# Test 1: Check pgvector extension
log_test "Checking pgvector extension..."
EXTENSION_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_extension WHERE extname = 'vector';")
if [ "$EXTENSION_EXISTS" -eq 1 ]; then
    VERSION=$(psql "$DB_URL" -t -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';")
    log_pass "pgvector extension enabled (version: $VERSION)"
    ((PASSED++))
else
    log_fail "pgvector extension not found"
    ((FAILED++))
fi

# Test 2: Check table exists
log_test "Checking table '$TABLE_NAME' exists..."
TABLE_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '$TABLE_NAME';")
if [ "$TABLE_EXISTS" -eq 1 ]; then
    log_pass "Table '$TABLE_NAME' exists"
    ((PASSED++))
else
    log_fail "Table '$TABLE_NAME' not found"
    ((FAILED++))
    log_info "Stopping tests - table does not exist"
    echo ""
    echo "Summary: $PASSED passed, $FAILED failed"
    exit 1
fi

# Test 3: Check embedding column
log_test "Checking embedding column..."
EMBEDDING_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = '$TABLE_NAME' AND column_name = 'embedding';")
if [ "$EMBEDDING_EXISTS" -eq 1 ]; then
    # Get vector dimension
    DIMENSION=$(psql "$DB_URL" -t -c "SELECT atttypmod FROM pg_attribute WHERE attrelid = '$TABLE_NAME'::regclass AND attname = 'embedding';")
    log_pass "Embedding column exists (dimension: $DIMENSION)"
    ((PASSED++))
else
    log_fail "Embedding column not found"
    ((FAILED++))
fi

# Test 4: Check vector index
log_test "Checking vector index..."
INDEX_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_indexes WHERE tablename = '$TABLE_NAME' AND indexname LIKE '%embedding%';")
if [ "$INDEX_EXISTS" -ge 1 ]; then
    INDEX_TYPE=$(psql "$DB_URL" -t -c "SELECT indexdef FROM pg_indexes WHERE tablename = '$TABLE_NAME' AND indexname LIKE '%embedding%' LIMIT 1;" | grep -o 'USING [a-z]*' | awk '{print $2}')
    INDEX_SIZE=$(psql "$DB_URL" -t -c "SELECT pg_size_pretty(pg_relation_size(indexname::regclass)) FROM pg_indexes WHERE tablename = '$TABLE_NAME' AND indexname LIKE '%embedding%' LIMIT 1;")
    log_pass "Vector index exists (type: $INDEX_TYPE, size: $INDEX_SIZE)"
    ((PASSED++))
else
    log_warn "No vector index found - queries will be slow"
    log_info "Run scripts/create-indexes.sh to create an index"
fi

# Test 5: Check row count
log_test "Checking table data..."
ROW_COUNT=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM $TABLE_NAME;")
if [ "$ROW_COUNT" -gt 0 ]; then
    log_pass "Table has $ROW_COUNT rows"
    ((PASSED++))
else
    log_warn "Table is empty - cannot test queries"
fi

# Test 6: Test vector similarity query (if data exists)
if [ "$ROW_COUNT" -gt 0 ]; then
    log_test "Testing vector similarity query..."

    # Get a random embedding from the table
    TEST_QUERY=$(psql "$DB_URL" -t -c "
        SELECT embedding FROM $TABLE_NAME LIMIT 1;
    ")

    # Test cosine distance query with EXPLAIN ANALYZE
    QUERY_PLAN=$(psql "$DB_URL" -c "
        EXPLAIN ANALYZE
        SELECT id FROM $TABLE_NAME
        ORDER BY embedding <=> (SELECT embedding FROM $TABLE_NAME LIMIT 1)
        LIMIT 5;
    " 2>&1)

    # Check if index is being used
    if echo "$QUERY_PLAN" | grep -q "Index Scan"; then
        EXEC_TIME=$(echo "$QUERY_PLAN" | grep "Execution Time" | awk '{print $3}')
        log_pass "Vector query uses index (execution time: ${EXEC_TIME}ms)"
        ((PASSED++))
    else
        log_warn "Vector query not using index (sequential scan)"
        log_info "This is normal for small tables or if index wasn't created"
    fi

    # Test query performance
    if [ -n "$EXEC_TIME" ]; then
        if (( $(echo "$EXEC_TIME < 100" | bc -l) )); then
            log_pass "Query performance: EXCELLENT (< 100ms)"
        elif (( $(echo "$EXEC_TIME < 500" | bc -l) )); then
            log_pass "Query performance: GOOD (< 500ms)"
        else
            log_warn "Query performance: SLOW (> 500ms) - consider tuning index parameters"
        fi
    fi
fi

# Test 7: Check full-text search setup (for hybrid search)
log_test "Checking full-text search configuration..."
FTS_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = '$TABLE_NAME' AND column_name = 'fts';")
if [ "$FTS_EXISTS" -eq 1 ]; then
    GIN_INDEX_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_indexes WHERE tablename = '$TABLE_NAME' AND indexdef LIKE '%gin%';")
    if [ "$GIN_INDEX_EXISTS" -ge 1 ]; then
        log_pass "Full-text search configured (hybrid search ready)"
        ((PASSED++))
    else
        log_warn "FTS column exists but no GIN index found"
    fi
else
    log_info "Full-text search not configured (semantic search only)"
fi

# Test 8: Check for hybrid search function
log_test "Checking hybrid search function..."
HYBRID_FUNC=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname LIKE '%${TABLE_NAME}%hybrid%';")
if [ "$HYBRID_FUNC" -ge 1 ]; then
    log_pass "Hybrid search function exists"
    ((PASSED++))
else
    log_info "Hybrid search function not found (optional)"
fi

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    log_pass "All tests passed! Vector search is configured correctly."
    exit 0
else
    log_fail "Some tests failed. Review errors above."
    exit 1
fi
