#!/bin/bash
# Complete validation of Mem0 + Supabase setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "==================================================================="
echo "Mem0 + Supabase Setup Validation"
echo "==================================================================="
echo ""

# Track validation status
VALIDATION_PASSED=true

# Check 1: Environment variables
echo -e "${BLUE}[1/9]${NC} Checking environment variables..."
REQUIRED_VARS=("SUPABASE_URL" "SUPABASE_DB_URL" "SUPABASE_ANON_KEY")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "  ${RED}✗${NC} Missing: $var"
        VALIDATION_PASSED=false
    else
        echo -e "  ${GREEN}✓${NC} Found: $var"
    fi
done

# Check 2: Database connection
echo ""
echo -e "${BLUE}[2/9]${NC} Testing database connection..."
if psql "$SUPABASE_DB_URL" -c "SELECT 1;" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Database connection successful"
    PG_VERSION=$(psql "$SUPABASE_DB_URL" -t -c "SHOW server_version;" | xargs)
    echo -e "  ${GREEN}✓${NC} PostgreSQL version: $PG_VERSION"
else
    echo -e "  ${RED}✗${NC} Database connection failed"
    VALIDATION_PASSED=false
fi

# Check 3: pgvector extension
echo ""
echo -e "${BLUE}[3/9]${NC} Checking pgvector extension..."
if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_extension WHERE extname = 'vector';" | grep -q 1; then
    EXT_VERSION=$(psql "$SUPABASE_DB_URL" -t -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';" | xargs)
    echo -e "  ${GREEN}✓${NC} pgvector enabled (version: $EXT_VERSION)"

    # Test vector operations
    if psql "$SUPABASE_DB_URL" -t -c "SELECT '[1,2,3]'::vector;" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Vector operations working"
    else
        echo -e "  ${RED}✗${NC} Vector operations failed"
        VALIDATION_PASSED=false
    fi
else
    echo -e "  ${RED}✗${NC} pgvector extension not enabled"
    VALIDATION_PASSED=false
fi

# Check 4: Tables existence
echo ""
echo -e "${BLUE}[4/9]${NC} Checking table structure..."
REQUIRED_TABLES=("memories")
OPTIONAL_TABLES=("memory_relationships" "memory_history")

for table in "${REQUIRED_TABLES[@]}"; do
    if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_tables WHERE tablename = '$table';" | grep -q 1; then
        echo -e "  ${GREEN}✓${NC} Table exists: $table"

        # Check row count
        ROW_COUNT=$(psql "$SUPABASE_DB_URL" -t -c "SELECT COUNT(*) FROM $table;" | xargs)
        echo -e "    Rows: $ROW_COUNT"
    else
        echo -e "  ${RED}✗${NC} Table missing: $table"
        VALIDATION_PASSED=false
    fi
done

for table in "${OPTIONAL_TABLES[@]}"; do
    if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_tables WHERE tablename = '$table';" | grep -q 1; then
        ROW_COUNT=$(psql "$SUPABASE_DB_URL" -t -c "SELECT COUNT(*) FROM $table;" | xargs)
        echo -e "  ${GREEN}✓${NC} Optional table: $table (rows: $ROW_COUNT)"
    fi
done

# Check 5: Indexes
echo ""
echo -e "${BLUE}[5/9]${NC} Checking indexes..."
CRITICAL_INDEXES=(
    "idx_memories_user_id"
    "idx_memories_embedding_hnsw"
)

for index in "${CRITICAL_INDEXES[@]}"; do
    if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_indexes WHERE indexname = '$index';" | grep -q 1; then
        echo -e "  ${GREEN}✓${NC} Index exists: $index"
    else
        # Check if ivfflat alternative exists
        if [ "$index" = "idx_memories_embedding_hnsw" ]; then
            if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_indexes WHERE indexname = 'idx_memories_embedding_ivfflat';" | grep -q 1; then
                echo -e "  ${GREEN}✓${NC} Index exists: idx_memories_embedding_ivfflat (IVFFlat)"
                continue
            fi
        fi
        echo -e "  ${YELLOW}⚠${NC} Index missing: $index"
    fi
done

# Check 6: RLS policies
echo ""
echo -e "${BLUE}[6/9]${NC} Checking Row Level Security..."
for table in "memories" "memory_relationships" "memory_history"; do
    if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_tables WHERE tablename = '$table';" | grep -q 1; then
        RLS_STATUS=$(psql "$SUPABASE_DB_URL" -t -c "SELECT rowsecurity FROM pg_tables WHERE tablename = '$table';" | xargs)
        if [ "$RLS_STATUS" = "t" ]; then
            POLICY_COUNT=$(psql "$SUPABASE_DB_URL" -t -c "SELECT COUNT(*) FROM pg_policies WHERE tablename = '$table';" | xargs)
            echo -e "  ${GREEN}✓${NC} RLS enabled on $table ($POLICY_COUNT policies)"
        else
            echo -e "  ${RED}✗${NC} RLS not enabled on $table"
            VALIDATION_PASSED=false
        fi
    fi
done

# Check 7: Test memory CRUD operations
echo ""
echo -e "${BLUE}[7/9]${NC} Testing memory operations..."

# Generate test user_id
TEST_USER_ID="test-validation-$(date +%s)"

# Test INSERT
if psql "$SUPABASE_DB_URL" -c "
    INSERT INTO memories (user_id, memory, embedding)
    VALUES ('$TEST_USER_ID', 'Test memory for validation', '[0.1,0.2,0.3]'::vector);
" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Memory insertion working"

    # Test SELECT
    if psql "$SUPABASE_DB_URL" -t -c "SELECT memory FROM memories WHERE user_id = '$TEST_USER_ID';" | grep -q "Test memory"; then
        echo -e "  ${GREEN}✓${NC} Memory retrieval working"
    else
        echo -e "  ${RED}✗${NC} Memory retrieval failed"
        VALIDATION_PASSED=false
    fi

    # Test UPDATE
    if psql "$SUPABASE_DB_URL" -c "UPDATE memories SET memory = 'Updated test memory' WHERE user_id = '$TEST_USER_ID';" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Memory update working"
    else
        echo -e "  ${RED}✗${NC} Memory update failed"
        VALIDATION_PASSED=false
    fi

    # Test DELETE (cleanup)
    if psql "$SUPABASE_DB_URL" -c "DELETE FROM memories WHERE user_id = '$TEST_USER_ID';" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Memory deletion working"
    else
        echo -e "  ${RED}✗${NC} Memory deletion failed"
        VALIDATION_PASSED=false
    fi
else
    echo -e "  ${RED}✗${NC} Memory insertion failed"
    VALIDATION_PASSED=false
fi

# Check 8: Vector search test
echo ""
echo -e "${BLUE}[8/9]${NC} Testing vector similarity search..."

# Insert test memory with embedding
TEST_EMBEDDING="[$(for i in {1..1536}; do echo -n "0.001"; [ $i -lt 1536 ] && echo -n ","; done)]"
if psql "$SUPABASE_DB_URL" -c "
    INSERT INTO memories (user_id, memory, embedding)
    VALUES ('$TEST_USER_ID', 'Vector search test', '$TEST_EMBEDDING'::vector);
" &>/dev/null; then

    # Test cosine similarity search
    SEARCH_RESULT=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT memory, 1 - (embedding <=> '$TEST_EMBEDDING'::vector) as similarity
        FROM memories
        WHERE user_id = '$TEST_USER_ID'
        ORDER BY embedding <=> '$TEST_EMBEDDING'::vector
        LIMIT 1;
    ")

    if echo "$SEARCH_RESULT" | grep -q "Vector search test"; then
        echo -e "  ${GREEN}✓${NC} Vector similarity search working"
    else
        echo -e "  ${RED}✗${NC} Vector similarity search failed"
        VALIDATION_PASSED=false
    fi

    # Cleanup
    psql "$SUPABASE_DB_URL" -c "DELETE FROM memories WHERE user_id = '$TEST_USER_ID';" &>/dev/null
else
    echo -e "  ${YELLOW}⚠${NC} Vector search test skipped (insertion failed)"
fi

# Check 9: Performance metrics
echo ""
echo -e "${BLUE}[9/9]${NC} Checking performance metrics..."

# Database size
DB_SIZE=$(psql "$SUPABASE_DB_URL" -t -c "SELECT pg_size_pretty(pg_database_size(current_database()));" | xargs)
echo -e "  Database size: $DB_SIZE"

# Table sizes
echo -e "  Table sizes:"
psql "$SUPABASE_DB_URL" -t -c "
    SELECT
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
    FROM pg_tables
    WHERE tablename IN ('memories', 'memory_relationships', 'memory_history')
    ORDER BY tablename;
" | while read line; do
    echo -e "    $line"
done

# Active connections
ACTIVE_CONNECTIONS=$(psql "$SUPABASE_DB_URL" -t -c "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = current_database();" | xargs)
echo -e "  Active connections: $ACTIVE_CONNECTIONS"

# Final summary
echo ""
echo "==================================================================="
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✓ Validation PASSED${NC}"
    echo "==================================================================="
    echo ""
    echo "Your Mem0 + Supabase setup is ready to use!"
    echo ""
    echo "Quick start:"
    echo "  1. Configure Mem0 client with Supabase connection"
    echo "  2. Start adding memories"
    echo "  3. Use vector search for semantic retrieval"
    echo ""
    echo "Example Python config:"
    echo '  config = {'
    echo '      "vector_store": {'
    echo '          "provider": "postgres",'
    echo '          "config": {"url": os.getenv("SUPABASE_DB_URL")}'
    echo '      }'
    echo '  }'
else
    echo -e "${RED}✗ Validation FAILED${NC}"
    echo "==================================================================="
    echo ""
    echo "Please fix the issues above before using Mem0 with Supabase"
    echo ""
    echo "Common fixes:"
    echo "  - Run: bash scripts/setup-mem0-pgvector.sh"
    echo "  - Run: bash scripts/apply-mem0-schema.sh"
    echo "  - Run: bash scripts/create-mem0-indexes.sh"
    echo "  - Run: bash scripts/apply-mem0-rls.sh"
fi
echo ""
