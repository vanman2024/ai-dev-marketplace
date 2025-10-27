#!/bin/bash
set -euo pipefail

# Setup hybrid search (semantic + keyword) for a table
# Usage: ./setup-hybrid-search.sh <table_name> [db_url]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

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
if [ $# -lt 1 ]; then
    log_error "Missing required arguments"
    echo "Usage: $0 <table_name> [db_url]"
    echo ""
    echo "Example:"
    echo "  $0 documents"
    exit 1
fi

TABLE_NAME="$1"
DB_URL="${2:-${SUPABASE_DB_URL:-}}"

if [ -z "$DB_URL" ]; then
    log_error "Database URL required"
    echo "Provide as 2nd argument or set SUPABASE_DB_URL environment variable"
    exit 1
fi

log_info "Setting up hybrid search for table: $TABLE_NAME"

# Check table exists
TABLE_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '$TABLE_NAME';")
if [ "$TABLE_EXISTS" -eq 0 ]; then
    log_error "Table '$TABLE_NAME' does not exist"
    exit 1
fi

# Check required columns exist
CONTENT_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = '$TABLE_NAME' AND column_name = 'content';")
EMBEDDING_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = '$TABLE_NAME' AND column_name = 'embedding';")

if [ "$CONTENT_EXISTS" -eq 0 ]; then
    log_error "Table '$TABLE_NAME' must have a 'content' column for full-text search"
    exit 1
fi

if [ "$EMBEDDING_EXISTS" -eq 0 ]; then
    log_error "Table '$TABLE_NAME' must have an 'embedding' column for semantic search"
    exit 1
fi

log_info "Adding full-text search column..."

# Add tsvector column for full-text search if not exists
psql "$DB_URL" <<-SQL
	-- Add fts column if not exists
	DO \$\$
	BEGIN
	    IF NOT EXISTS (
	        SELECT 1 FROM information_schema.columns
	        WHERE table_name = '${TABLE_NAME}' AND column_name = 'fts'
	    ) THEN
	        ALTER TABLE ${TABLE_NAME} ADD COLUMN fts tsvector
	        GENERATED ALWAYS AS (to_tsvector('english', coalesce(content, ''))) STORED;
	    END IF;
	END \$\$;
SQL

log_info "Creating full-text search index..."

# Create GIN index for full-text search
psql "$DB_URL" <<-SQL
	-- Drop existing GIN index if present
	DROP INDEX IF EXISTS ${TABLE_NAME}_fts_idx;

	-- Create GIN index
	CREATE INDEX ${TABLE_NAME}_fts_idx ON ${TABLE_NAME} USING gin(fts);

	-- Analyze table
	ANALYZE ${TABLE_NAME};
SQL

log_info "Creating hybrid search function..."

# Create hybrid search function with RRF (Reciprocal Rank Fusion)
psql "$DB_URL" <<-SQL
	-- Drop existing function
	DROP FUNCTION IF EXISTS ${TABLE_NAME}_hybrid_search;

	-- Create hybrid search function
	CREATE OR REPLACE FUNCTION ${TABLE_NAME}_hybrid_search(
	    query_text TEXT,
	    query_embedding vector(1536),
	    match_count INT DEFAULT 10,
	    full_text_weight FLOAT DEFAULT 1.0,
	    semantic_weight FLOAT DEFAULT 1.0,
	    rrf_k INT DEFAULT 50
	)
	RETURNS TABLE(
	    id BIGINT,
	    content TEXT,
	    similarity FLOAT,
	    fts_rank FLOAT,
	    hybrid_score FLOAT
	)
	LANGUAGE plpgsql
	AS \$\$
	BEGIN
	    RETURN QUERY
	    WITH semantic_search AS (
	        SELECT
	            ${TABLE_NAME}.id,
	            ${TABLE_NAME}.content,
	            1 - (${TABLE_NAME}.embedding <=> query_embedding) AS similarity,
	            ROW_NUMBER() OVER (ORDER BY ${TABLE_NAME}.embedding <=> query_embedding) AS rank
	        FROM ${TABLE_NAME}
	        ORDER BY ${TABLE_NAME}.embedding <=> query_embedding
	        LIMIT least(match_count, 1000)
	    ),
	    fulltext_search AS (
	        SELECT
	            ${TABLE_NAME}.id,
	            ${TABLE_NAME}.content,
	            ts_rank(${TABLE_NAME}.fts, websearch_to_tsquery('english', query_text)) AS fts_rank,
	            ROW_NUMBER() OVER (ORDER BY ts_rank(${TABLE_NAME}.fts, websearch_to_tsquery('english', query_text)) DESC) AS rank
	        FROM ${TABLE_NAME}
	        WHERE ${TABLE_NAME}.fts @@ websearch_to_tsquery('english', query_text)
	        ORDER BY fts_rank DESC
	        LIMIT least(match_count, 1000)
	    )
	    SELECT
	        COALESCE(semantic_search.id, fulltext_search.id) AS id,
	        COALESCE(semantic_search.content, fulltext_search.content) AS content,
	        COALESCE(semantic_search.similarity, 0) AS similarity,
	        COALESCE(fulltext_search.fts_rank, 0) AS fts_rank,
	        -- RRF score: 1/(k + rank) for each search method
	        (COALESCE(1.0 / (rrf_k + semantic_search.rank), 0.0) * semantic_weight +
	         COALESCE(1.0 / (rrf_k + fulltext_search.rank), 0.0) * full_text_weight) AS hybrid_score
	    FROM semantic_search
	    FULL OUTER JOIN fulltext_search ON semantic_search.id = fulltext_search.id
	    ORDER BY hybrid_score DESC
	    LIMIT match_count;
	END;
	\$\$;
SQL

log_info "Hybrid search setup complete!"
log_info ""
log_info "Usage example:"
log_info "  SELECT * FROM ${TABLE_NAME}_hybrid_search("
log_info "    'search query text',"
log_info "    query_embedding,"
log_info "    match_count := 10,"
log_info "    full_text_weight := 1.0,"
log_info "    semantic_weight := 1.0"
log_info "  );"
log_info ""
log_info "Tuning parameters:"
log_info "  - full_text_weight: Increase for better keyword matching"
log_info "  - semantic_weight: Increase for better semantic matching"
log_info "  - rrf_k: RRF smoothing constant (default 50)"
