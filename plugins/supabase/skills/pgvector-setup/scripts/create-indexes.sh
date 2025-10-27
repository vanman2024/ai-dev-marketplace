#!/bin/bash
set -euo pipefail

# Create vector indexes (HNSW or IVFFlat) for pgvector
# Usage: ./create-indexes.sh <hnsw|ivfflat> <table_name> <dimension> [db_url]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
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

# Validate arguments
if [ $# -lt 3 ]; then
    log_error "Missing required arguments"
    echo "Usage: $0 <hnsw|ivfflat> <table_name> <dimension> [db_url]"
    echo ""
    echo "Examples:"
    echo "  $0 hnsw documents 1536"
    echo "  $0 ivfflat products 1024 \$SUPABASE_DB_URL"
    exit 1
fi

INDEX_TYPE="$1"
TABLE_NAME="$2"
DIMENSION="$3"
DB_URL="${4:-${SUPABASE_DB_URL:-}}"

if [ -z "$DB_URL" ]; then
    log_error "Database URL required"
    echo "Provide as 4th argument or set SUPABASE_DB_URL environment variable"
    exit 1
fi

# Validate index type
if [ "$INDEX_TYPE" != "hnsw" ] && [ "$INDEX_TYPE" != "ivfflat" ]; then
    log_error "Invalid index type: $INDEX_TYPE"
    echo "Must be 'hnsw' or 'ivfflat'"
    exit 1
fi

# Validate table exists
TABLE_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '$TABLE_NAME';")
if [ "$TABLE_EXISTS" -eq 0 ]; then
    log_error "Table '$TABLE_NAME' does not exist"
    exit 1
fi

# Check if embedding column exists
COLUMN_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = '$TABLE_NAME' AND column_name = 'embedding';")
if [ "$COLUMN_EXISTS" -eq 0 ]; then
    log_error "Column 'embedding' does not exist in table '$TABLE_NAME'"
    echo "Create the table with an embedding column first"
    exit 1
fi

log_info "Creating $INDEX_TYPE index on $TABLE_NAME.embedding (dimension: $DIMENSION)..."

if [ "$INDEX_TYPE" = "hnsw" ]; then
    # HNSW index parameters
    M=16              # Number of connections per layer (16 is default, higher = better recall)
    EF_CONSTRUCTION=64 # Size of dynamic candidate list (higher = better quality, slower build)

    log_info "HNSW parameters: m=$M, ef_construction=$EF_CONSTRUCTION"

    # Create HNSW index with cosine distance
    psql "$DB_URL" <<-SQL
		-- Drop existing index if present
		DROP INDEX IF EXISTS ${TABLE_NAME}_embedding_idx;

		-- Create HNSW index
		CREATE INDEX ${TABLE_NAME}_embedding_idx ON ${TABLE_NAME}
		USING hnsw (embedding vector_cosine_ops)
		WITH (m = ${M}, ef_construction = ${EF_CONSTRUCTION});

		-- Analyze table for query planner
		ANALYZE ${TABLE_NAME};
	SQL

    log_info "HNSW index created successfully"
    log_info "To tune query performance, adjust ef_search parameter in queries:"
    log_info "  SET hnsw.ef_search = 100; -- Higher = better recall, slower queries"

elif [ "$INDEX_TYPE" = "ivfflat" ]; then
    # IVFFlat parameters
    # Number of lists should be rows/1000 for small datasets, sqrt(rows) for large
    ROW_COUNT=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM ${TABLE_NAME};")

    if [ "$ROW_COUNT" -lt 100000 ]; then
        LISTS=$((ROW_COUNT / 1000))
        [ "$LISTS" -lt 10 ] && LISTS=10
    else
        LISTS=$(echo "sqrt($ROW_COUNT)" | bc)
    fi

    log_info "IVFFlat parameters: lists=$LISTS (based on $ROW_COUNT rows)"
    log_warn "IVFFlat requires training data. Ensure table has sufficient rows."

    # Create IVFFlat index with cosine distance
    psql "$DB_URL" <<-SQL
		-- Drop existing index if present
		DROP INDEX IF EXISTS ${TABLE_NAME}_embedding_idx;

		-- Create IVFFlat index (this will train on existing data)
		CREATE INDEX ${TABLE_NAME}_embedding_idx ON ${TABLE_NAME}
		USING ivfflat (embedding vector_cosine_ops)
		WITH (lists = ${LISTS});

		-- Analyze table for query planner
		ANALYZE ${TABLE_NAME};
	SQL

    log_info "IVFFlat index created successfully"
    log_info "To tune query performance, adjust probes parameter in queries:"
    log_info "  SET ivfflat.probes = 10; -- Higher = better recall, slower queries"
fi

# Verify index was created
INDEX_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_indexes WHERE tablename = '$TABLE_NAME' AND indexname = '${TABLE_NAME}_embedding_idx';")
if [ "$INDEX_EXISTS" -eq 1 ]; then
    log_info "Index verification: SUCCESS"
else
    log_error "Index verification: FAILED"
    exit 1
fi

# Show index size
INDEX_SIZE=$(psql "$DB_URL" -t -c "SELECT pg_size_pretty(pg_relation_size('${TABLE_NAME}_embedding_idx'));")
log_info "Index size: $INDEX_SIZE"

log_info ""
log_info "Index creation complete!"
log_info "Run scripts/test-vector-search.sh to validate performance"
