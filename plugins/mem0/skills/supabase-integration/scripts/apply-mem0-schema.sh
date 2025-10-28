#!/bin/bash
# Create Mem0 memory tables in Supabase PostgreSQL

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
VECTOR_DIMENSION=${MEM0_VECTOR_DIMENSION:-1536}
INCLUDE_GRAPH=${MEM0_INCLUDE_GRAPH:-true}
INCLUDE_HISTORY=${MEM0_INCLUDE_HISTORY:-true}

echo "Creating Mem0 memory tables..."
echo ""
echo "Configuration:"
echo "  Vector dimension: $VECTOR_DIMENSION"
echo "  Include graph support: $INCLUDE_GRAPH"
echo "  Include history: $INCLUDE_HISTORY"
echo ""

# Check prerequisites
if [ -z "$SUPABASE_DB_URL" ]; then
    echo -e "${RED}✗${NC} SUPABASE_DB_URL not set"
    exit 1
fi

# Check pgvector is enabled
echo "Checking pgvector extension..."
if ! psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_extension WHERE extname = 'vector';" | grep -q 1; then
    echo -e "${RED}✗${NC} pgvector extension not enabled"
    echo "Run: bash scripts/setup-mem0-pgvector.sh"
    exit 1
fi
echo -e "${GREEN}✓${NC} pgvector extension enabled"

# Create schema
echo ""
echo "Creating tables..."

psql "$SUPABASE_DB_URL" <<SQL
-- Create memories table (core storage)
CREATE TABLE IF NOT EXISTS memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    agent_id TEXT,
    run_id TEXT,
    memory TEXT NOT NULL,
    hash TEXT UNIQUE,
    metadata JSONB DEFAULT '{}'::jsonb,
    categories TEXT[] DEFAULT ARRAY[]::TEXT[],
    embedding VECTOR($VECTOR_DIMENSION),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment
COMMENT ON TABLE memories IS 'Mem0 memory storage with vector embeddings';

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_memories_updated_at ON memories;
CREATE TRIGGER update_memories_updated_at
    BEFORE UPDATE ON memories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create memory_relationships table (graph support)
$(if [ "$INCLUDE_GRAPH" = "true" ]; then
cat <<GRAPH_SQL
CREATE TABLE IF NOT EXISTS memory_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    target_memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL,
    strength NUMERIC(3,2) DEFAULT 1.0 CHECK (strength >= 0.0 AND strength <= 1.0),
    metadata JSONB DEFAULT '{}'::jsonb,
    user_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT no_self_reference CHECK (source_memory_id != target_memory_id),
    CONSTRAINT unique_relationship UNIQUE (source_memory_id, target_memory_id, relationship_type)
);

COMMENT ON TABLE memory_relationships IS 'Mem0 graph memory relationships';
GRAPH_SQL
fi)

-- Create memory_history table (audit trail)
$(if [ "$INCLUDE_HISTORY" = "true" ]; then
cat <<HISTORY_SQL
CREATE TABLE IF NOT EXISTS memory_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    memory_id UUID NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
    old_value JSONB,
    new_value JSONB,
    user_id TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE memory_history IS 'Mem0 memory audit trail';

-- Create audit trigger
CREATE OR REPLACE FUNCTION log_memory_changes()
RETURNS TRIGGER AS \$\$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO memory_history (memory_id, operation, old_value, user_id)
        VALUES (OLD.id, 'delete', row_to_json(OLD), OLD.user_id);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO memory_history (memory_id, operation, old_value, new_value, user_id)
        VALUES (NEW.id, 'update', row_to_json(OLD), row_to_json(NEW), NEW.user_id);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO memory_history (memory_id, operation, new_value, user_id)
        VALUES (NEW.id, 'create', row_to_json(NEW), NEW.user_id);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
\$\$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_memory_changes ON memories;
CREATE TRIGGER audit_memory_changes
    AFTER INSERT OR UPDATE OR DELETE ON memories
    FOR EACH ROW
    EXECUTE FUNCTION log_memory_changes();
HISTORY_SQL
fi)

SQL

# Verify tables were created
echo ""
echo "Verifying table creation..."

TABLES=("memories")
if [ "$INCLUDE_GRAPH" = "true" ]; then
    TABLES+=("memory_relationships")
fi
if [ "$INCLUDE_HISTORY" = "true" ]; then
    TABLES+=("memory_history")
fi

ALL_CREATED=true
for table in "${TABLES[@]}"; do
    if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_tables WHERE tablename = '$table';" | grep -q 1; then
        echo -e "${GREEN}✓${NC} Table created: $table"
    else
        echo -e "${RED}✗${NC} Failed to create: $table"
        ALL_CREATED=false
    fi
done

if [ "$ALL_CREATED" = true ]; then
    echo ""
    echo -e "${GREEN}Success!${NC} Mem0 schema created"
    echo ""
    echo "Tables created:"
    echo "  - memories (core storage with vector embeddings)"
    if [ "$INCLUDE_GRAPH" = "true" ]; then
        echo "  - memory_relationships (graph memory)"
    fi
    if [ "$INCLUDE_HISTORY" = "true" ]; then
        echo "  - memory_history (audit trail)"
    fi
    echo ""
    echo "Next step: bash scripts/create-mem0-indexes.sh"
else
    echo -e "${RED}✗${NC} Some tables failed to create"
    exit 1
fi
