#!/bin/bash
set -euo pipefail

# Test AI Features (pgvector) End-to-End
# Tests pgvector extension, embedding operations, vector search, and indexes

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

DB_URL="${DATABASE_URL:-${SUPABASE_TEST_URL}}"

# Test 1: Verify pgvector extension
test_pgvector_extension() {
    log_info "Testing pgvector extension..."

    local result=$(psql "$DB_URL" -t -c "SELECT extname FROM pg_extension WHERE extname = 'vector';" 2>/dev/null || echo "")

    if echo "$result" | grep -q "vector"; then
        log_success "pgvector extension is enabled"
        return 0
    else
        log_error "pgvector extension not found - run: CREATE EXTENSION vector;"
        return 1
    fi
}

# Test 2: Create test table with vector column
test_create_vector_table() {
    log_info "Creating test vector table..."

    psql "$DB_URL" > /dev/null 2>&1 <<'EOF'
DROP TABLE IF EXISTS test_embeddings;

CREATE TABLE test_embeddings (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  embedding vector(1536),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX ON test_embeddings USING hnsw (embedding vector_cosine_ops);
EOF

    if [[ $? -eq 0 ]]; then
        log_success "Test vector table created with HNSW index"
        return 0
    else
        log_error "Failed to create test vector table"
        return 1
    fi
}

# Test 3: Insert embeddings
test_insert_embeddings() {
    log_info "Inserting test embeddings..."

    # Generate random vectors for testing
    psql "$DB_URL" > /dev/null 2>&1 <<'EOF'
INSERT INTO test_embeddings (content, embedding)
VALUES
  ('machine learning tutorial', array_fill(random(), ARRAY[1536])::vector),
  ('deep learning basics', array_fill(random(), ARRAY[1536])::vector),
  ('neural networks guide', array_fill(random(), ARRAY[1536])::vector),
  ('python programming', array_fill(random(), ARRAY[1536])::vector),
  ('data science fundamentals', array_fill(random(), ARRAY[1536])::vector);
EOF

    if [[ $? -eq 0 ]]; then
        local count=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM test_embeddings;" | tr -d ' ')
        log_success "Inserted 5 test embeddings (total: $count)"
        return 0
    else
        log_error "Failed to insert test embeddings"
        return 1
    fi
}

# Test 4: Vector similarity search
test_vector_search() {
    log_info "Testing vector similarity search..."

    # Query using cosine distance
    local result=$(psql "$DB_URL" -t <<'EOF'
SELECT content, embedding <=> (SELECT embedding FROM test_embeddings LIMIT 1) AS distance
FROM test_embeddings
ORDER BY distance
LIMIT 3;
EOF
)

    if [[ -n "$result" ]]; then
        log_success "Vector similarity search working"
        return 0
    else
        log_error "Vector similarity search failed"
        return 1
    fi
}

# Test 5: Test match function (if exists)
test_match_function() {
    log_info "Testing match function..."

    # Create a basic match function
    psql "$DB_URL" > /dev/null 2>&1 <<'EOF'
CREATE OR REPLACE FUNCTION match_test_embeddings(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.7,
  match_count int DEFAULT 5
)
RETURNS TABLE (
  id bigint,
  content text,
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    id,
    content,
    1 - (embedding <=> query_embedding) AS similarity
  FROM test_embeddings
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;
EOF

    if [[ $? -eq 0 ]]; then
        log_success "Match function created"

        # Test the function
        local result=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM match_test_embeddings((SELECT embedding FROM test_embeddings LIMIT 1), 0.5, 10);" | tr -d ' ')

        if [[ "$result" -gt 0 ]]; then
            log_success "Match function returns $result results"
            return 0
        else
            log_error "Match function returned no results"
            return 1
        fi
    else
        log_error "Failed to create match function"
        return 1
    fi
}

# Test 6: Verify index usage
test_index_usage() {
    log_info "Verifying index usage..."

    local explain_output=$(psql "$DB_URL" -c "EXPLAIN SELECT * FROM test_embeddings ORDER BY embedding <=> (SELECT embedding FROM test_embeddings LIMIT 1) LIMIT 5;" 2>&1)

    if echo "$explain_output" | grep -qi "index"; then
        log_success "HNSW index is being used"
        return 0
    else
        log_error "Index may not be used - check EXPLAIN output"
        return 1
    fi
}

# Test 7: Test different distance operators
test_distance_operators() {
    log_info "Testing distance operators..."

    # Test cosine distance (<=>)
    psql "$DB_URL" -t -c "SELECT content, embedding <=> (SELECT embedding FROM test_embeddings LIMIT 1) FROM test_embeddings LIMIT 1;" > /dev/null 2>&1
    local cosine_result=$?

    # Test L2 distance (<->)
    psql "$DB_URL" -t -c "SELECT content, embedding <-> (SELECT embedding FROM test_embeddings LIMIT 1) FROM test_embeddings LIMIT 1;" > /dev/null 2>&1
    local l2_result=$?

    # Test inner product (<#>)
    psql "$DB_URL" -t -c "SELECT content, embedding <#> (SELECT embedding FROM test_embeddings LIMIT 1) FROM test_embeddings LIMIT 1;" > /dev/null 2>&1
    local inner_result=$?

    if [[ $cosine_result -eq 0 ]] && [[ $l2_result -eq 0 ]] && [[ $inner_result -eq 0 ]]; then
        log_success "All distance operators working (<=>, <->, <#>)"
        return 0
    else
        log_error "Some distance operators failed"
        return 1
    fi
}

# Test 8: Benchmark query performance
test_query_performance() {
    log_info "Benchmarking query performance..."

    local start_time=$(date +%s%N)

    psql "$DB_URL" -t <<'EOF' > /dev/null 2>&1
SELECT content
FROM test_embeddings
ORDER BY embedding <=> (SELECT embedding FROM test_embeddings LIMIT 1)
LIMIT 10;
EOF

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    if [[ $duration_ms -lt 1000 ]]; then
        log_success "Query completed in ${duration_ms}ms (target: <1000ms)"
        return 0
    else
        log_error "Query took ${duration_ms}ms (slower than expected)"
        return 1
    fi
}

# Test 9: Test vector dimension validation
test_dimension_validation() {
    log_info "Testing vector dimension validation..."

    # Try to insert wrong dimension (should fail)
    psql "$DB_URL" > /dev/null 2>&1 <<'EOF'
INSERT INTO test_embeddings (content, embedding)
VALUES ('wrong dimension', array_fill(random(), ARRAY[512])::vector);
EOF

    if [[ $? -ne 0 ]]; then
        log_success "Dimension validation working (rejected 512-dim vector)"
        return 0
    else
        log_error "Dimension validation failed (accepted wrong dimension)"
        return 1
    fi
}

# Cleanup: Drop test table
cleanup_test_table() {
    log_info "Cleaning up test table..."

    psql "$DB_URL" -c "DROP TABLE IF EXISTS test_embeddings;" > /dev/null 2>&1
    psql "$DB_URL" -c "DROP FUNCTION IF EXISTS match_test_embeddings;" > /dev/null 2>&1

    log_info "Test table and function dropped"
}

# Main test execution
main() {
    log_info "Starting AI features (pgvector) tests..."
    echo ""

    local failed=0

    test_pgvector_extension || ((failed++))
    test_create_vector_table || ((failed++))
    test_insert_embeddings || ((failed++))
    test_vector_search || ((failed++))
    test_match_function || ((failed++))
    test_index_usage || ((failed++))
    test_distance_operators || ((failed++))
    test_query_performance || ((failed++))
    test_dimension_validation || ((failed++))

    echo ""
    cleanup_test_table

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "All AI features tests passed!"
        exit 0
    else
        log_error "$failed test(s) failed"
        exit 1
    fi
}

main "$@"
