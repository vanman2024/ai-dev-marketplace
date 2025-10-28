#!/bin/bash
# Create optimized indexes for Mem0 memory tables

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
VECTOR_DIMENSION=${MEM0_VECTOR_DIMENSION:-1536}
INDEX_TYPE=${MEM0_INDEX_TYPE:-hnsw}  # hnsw or ivfflat
HNSW_M=${MEM0_HNSW_M:-16}
HNSW_EF_CONSTRUCTION=${MEM0_HNSW_EF_CONSTRUCTION:-64}

echo "Creating Mem0 performance indexes..."
echo ""
echo "Configuration:"
echo "  Index type: $INDEX_TYPE"
if [ "$INDEX_TYPE" = "hnsw" ]; then
    echo "  HNSW m: $HNSW_M"
    echo "  HNSW ef_construction: $HNSW_EF_CONSTRUCTION"
fi
echo ""

# Check prerequisites
if [ -z "$SUPABASE_DB_URL" ]; then
    echo -e "${RED}✗${NC} SUPABASE_DB_URL not set"
    exit 1
fi

# Check tables exist
if ! psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_tables WHERE tablename = 'memories';" | grep -q 1; then
    echo -e "${RED}✗${NC} memories table not found"
    echo "Run: bash scripts/apply-mem0-schema.sh"
    exit 1
fi

echo "Creating indexes..."

psql "$SUPABASE_DB_URL" <<SQL
-- Basic B-tree indexes for filtering and isolation
CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
CREATE INDEX IF NOT EXISTS idx_memories_agent_id ON memories(agent_id);
CREATE INDEX IF NOT EXISTS idx_memories_run_id ON memories(run_id);
CREATE INDEX IF NOT EXISTS idx_memories_hash ON memories(hash);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_memories_user_created ON memories(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_memories_user_agent ON memories(user_id, agent_id);
CREATE INDEX IF NOT EXISTS idx_memories_user_run ON memories(user_id, run_id);

-- JSONB index for metadata queries
CREATE INDEX IF NOT EXISTS idx_memories_metadata ON memories USING gin(metadata);

-- Array index for categories
CREATE INDEX IF NOT EXISTS idx_memories_categories ON memories USING gin(categories);

-- Vector similarity index
$(if [ "$INDEX_TYPE" = "hnsw" ]; then
cat <<HNSW_SQL
-- HNSW index for vector similarity (cosine distance)
DROP INDEX IF EXISTS idx_memories_embedding_hnsw;
CREATE INDEX idx_memories_embedding_hnsw ON memories
USING hnsw (embedding vector_cosine_ops)
WITH (m = $HNSW_M, ef_construction = $HNSW_EF_CONSTRUCTION);
HNSW_SQL
elif [ "$INDEX_TYPE" = "ivfflat" ]; then
cat <<IVFFLAT_SQL
-- IVFFlat index for vector similarity (cosine distance)
-- Calculate lists parameter (sqrt of row count)
DROP INDEX IF EXISTS idx_memories_embedding_ivfflat;
CREATE INDEX idx_memories_embedding_ivfflat ON memories
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
IVFFLAT_SQL
fi)

-- Indexes for memory_relationships (if table exists)
DO \$\$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'memory_relationships') THEN
        -- Relationship lookup indexes
        CREATE INDEX IF NOT EXISTS idx_relationships_source ON memory_relationships(source_memory_id);
        CREATE INDEX IF NOT EXISTS idx_relationships_target ON memory_relationships(target_memory_id);
        CREATE INDEX IF NOT EXISTS idx_relationships_type ON memory_relationships(relationship_type);
        CREATE INDEX IF NOT EXISTS idx_relationships_user_id ON memory_relationships(user_id);

        -- Composite for graph traversal
        CREATE INDEX IF NOT EXISTS idx_relationships_source_type ON memory_relationships(source_memory_id, relationship_type);
        CREATE INDEX IF NOT EXISTS idx_relationships_user_source ON memory_relationships(user_id, source_memory_id);
    END IF;
END \$\$;

-- Indexes for memory_history (if table exists)
DO \$\$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'memory_history') THEN
        CREATE INDEX IF NOT EXISTS idx_history_memory_id ON memory_history(memory_id);
        CREATE INDEX IF NOT EXISTS idx_history_user_id ON memory_history(user_id);
        CREATE INDEX IF NOT EXISTS idx_history_timestamp ON memory_history(timestamp DESC);
        CREATE INDEX IF NOT EXISTS idx_history_operation ON memory_history(operation);
    END IF;
END \$\$;

SQL

# Verify indexes were created
echo ""
echo "Verifying indexes..."

# Check main indexes
MAIN_INDEXES=(
    "idx_memories_user_id"
    "idx_memories_agent_id"
    "idx_memories_user_created"
    "idx_memories_metadata"
)

if [ "$INDEX_TYPE" = "hnsw" ]; then
    MAIN_INDEXES+=("idx_memories_embedding_hnsw")
else
    MAIN_INDEXES+=("idx_memories_embedding_ivfflat")
fi

ALL_CREATED=true
for index in "${MAIN_INDEXES[@]}"; do
    if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_indexes WHERE indexname = '$index';" | grep -q 1; then
        echo -e "${GREEN}✓${NC} Index created: $index"
    else
        echo -e "${YELLOW}⚠${NC} Index not found: $index"
        ALL_CREATED=false
    fi
done

# Get index statistics
echo ""
echo "Index statistics:"
psql "$SUPABASE_DB_URL" -c "
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_indexes
JOIN pg_class ON pg_indexes.indexname = pg_class.relname
WHERE tablename IN ('memories', 'memory_relationships', 'memory_history')
ORDER BY tablename, indexname;
"

if [ "$ALL_CREATED" = true ]; then
    echo ""
    echo -e "${GREEN}Success!${NC} Mem0 indexes created"
    echo ""
    echo "Indexes optimized for:"
    echo "  - User/agent/session isolation"
    echo "  - Vector similarity search ($INDEX_TYPE)"
    echo "  - Metadata and category filtering"
    echo "  - Graph relationship traversal"
    echo "  - Audit history queries"
    echo ""
    echo "Next step: bash scripts/apply-mem0-rls.sh"
else
    echo -e "${YELLOW}⚠${NC} Some indexes may be missing"
fi
