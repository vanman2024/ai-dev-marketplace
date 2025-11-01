#!/bin/bash
set -e

# pgvector Setup Script
# Installs and configures pgvector extension for PostgreSQL

# Default values
DATABASE="vectordb"
USER="postgres"
HOST="localhost"
PORT="5432"
DIMENSIONS="1536"
INDEX_TYPE="hnsw"  # or ivfflat
DISTANCE_METRIC="cosine"  # or l2, inner_product

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --database)
            DATABASE="$2"
            shift 2
            ;;
        --user)
            USER="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --dimensions)
            DIMENSIONS="$2"
            shift 2
            ;;
        --index-type)
            INDEX_TYPE="$2"
            shift 2
            ;;
        --distance)
            DISTANCE_METRIC="$2"
            shift 2
            ;;
        --password)
            export PGPASSWORD="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --database DB        Database name (default: vectordb)"
            echo "  --user USER          PostgreSQL user (default: postgres)"
            echo "  --host HOST          Database host (default: localhost)"
            echo "  --port PORT          Database port (default: 5432)"
            echo "  --dimensions DIM     Vector dimensions (default: 1536)"
            echo "  --index-type TYPE    Index type: hnsw or ivfflat (default: hnsw)"
            echo "  --distance METRIC    Distance metric: cosine, l2, or inner_product (default: cosine)"
            echo "  --password PASS      Database password (or set PGPASSWORD env var)"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "pgvector Setup Script"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Database: $DATABASE"
echo "  User: $USER"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  Dimensions: $DIMENSIONS"
echo "  Index Type: $INDEX_TYPE"
echo "  Distance Metric: $DISTANCE_METRIC"
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "ERROR: PostgreSQL client (psql) not found"
    echo "Install PostgreSQL first:"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  macOS: brew install postgresql"
    echo "  RHEL/CentOS: sudo yum install postgresql"
    exit 1
fi

# Check if we can connect
echo "Step 1: Testing database connection..."
if ! psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -c "SELECT 1" &> /dev/null; then
    echo "ERROR: Cannot connect to PostgreSQL"
    echo "Ensure PostgreSQL is running and credentials are correct"
    echo "Set PGPASSWORD environment variable or use --password flag"
    exit 1
fi
echo "✓ Connection successful"
echo ""

# Check if pgvector extension is available
echo "Step 2: Checking for pgvector extension..."
if ! psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector'" | grep -q vector; then
    echo "WARNING: pgvector extension not installed on PostgreSQL server"
    echo ""
    echo "To install pgvector:"
    echo ""
    echo "On Ubuntu/Debian:"
    echo "  sudo apt install postgresql-15-pgvector  # Replace 15 with your version"
    echo ""
    echo "From source:"
    echo "  cd /tmp"
    echo "  git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git"
    echo "  cd pgvector"
    echo "  make"
    echo "  sudo make install"
    echo ""
    echo "On managed services (Supabase, RDS, etc.), enable via dashboard/CLI"
    exit 1
fi
echo "✓ pgvector extension available"
echo ""

# Create database if it doesn't exist
echo "Step 3: Creating database '$DATABASE' if not exists..."
if ! psql -h "$HOST" -p "$PORT" -U "$USER" -lqt | cut -d \| -f 1 | grep -qw "$DATABASE"; then
    createdb -h "$HOST" -p "$PORT" -U "$USER" "$DATABASE"
    echo "✓ Database created"
else
    echo "✓ Database already exists"
fi
echo ""

# Enable pgvector extension
echo "Step 4: Enabling pgvector extension..."
psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" -c "CREATE EXTENSION IF NOT EXISTS vector;"
echo "✓ Extension enabled"
echo ""

# Create sample table with vector column
echo "Step 5: Creating sample documents table..."
psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" << EOF
-- Create documents table with vector embedding
CREATE TABLE IF NOT EXISTS documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    embedding vector($DIMENSIONS),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on metadata for filtering
CREATE INDEX IF NOT EXISTS idx_documents_metadata ON documents USING GIN (metadata);

-- Create timestamp indexes
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents (created_at);
CREATE INDEX IF NOT EXISTS idx_documents_updated_at ON documents (updated_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
\$\$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_documents_updated_at ON documents;
CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
EOF
echo "✓ Documents table created"
echo ""

# Create appropriate vector index
echo "Step 6: Creating vector index ($INDEX_TYPE)..."

# Convert distance metric to operator
case $DISTANCE_METRIC in
    cosine)
        OPERATOR="vector_cosine_ops"
        ;;
    l2)
        OPERATOR="vector_l2_ops"
        ;;
    inner_product)
        OPERATOR="vector_ip_ops"
        ;;
    *)
        echo "ERROR: Unknown distance metric: $DISTANCE_METRIC"
        exit 1
        ;;
esac

if [ "$INDEX_TYPE" = "hnsw" ]; then
    # HNSW index - better for larger datasets
    psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" << EOF
-- Create HNSW index for approximate nearest neighbor search
-- m: max connections per layer (higher = better recall, more memory)
-- ef_construction: size of dynamic candidate list (higher = better index, slower build)
CREATE INDEX IF NOT EXISTS idx_documents_embedding_hnsw
ON documents
USING hnsw (embedding $OPERATOR)
WITH (m = 16, ef_construction = 64);
EOF
    echo "✓ HNSW index created (m=16, ef_construction=64)"

elif [ "$INDEX_TYPE" = "ivfflat" ]; then
    # IVFFlat index - better for smaller datasets
    # Lists parameter: sqrt(total_rows) is a good starting point
    LISTS=100  # Adjust based on expected dataset size

    psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" << EOF
-- Create IVFFlat index for approximate nearest neighbor search
-- lists: number of inverted lists (clusters)
CREATE INDEX IF NOT EXISTS idx_documents_embedding_ivfflat
ON documents
USING ivfflat (embedding $OPERATOR)
WITH (lists = $LISTS);
EOF
    echo "✓ IVFFlat index created (lists=$LISTS)"
else
    echo "ERROR: Unknown index type: $INDEX_TYPE"
    exit 1
fi
echo ""

# Create helper functions
echo "Step 7: Creating helper functions..."
psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" << EOF
-- Function for similarity search with cosine distance
CREATE OR REPLACE FUNCTION similarity_search_cosine(
    query_embedding vector($DIMENSIONS),
    match_threshold float DEFAULT 0.5,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id bigint,
    content text,
    metadata jsonb,
    similarity float
) AS \$\$
BEGIN
    RETURN QUERY
    SELECT
        documents.id,
        documents.content,
        documents.metadata,
        1 - (documents.embedding <=> query_embedding) as similarity
    FROM documents
    WHERE documents.embedding IS NOT NULL
        AND 1 - (documents.embedding <=> query_embedding) > match_threshold
    ORDER BY documents.embedding <=> query_embedding
    LIMIT match_count;
END;
\$\$ LANGUAGE plpgsql;

-- Function for similarity search with L2 distance
CREATE OR REPLACE FUNCTION similarity_search_l2(
    query_embedding vector($DIMENSIONS),
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id bigint,
    content text,
    metadata jsonb,
    distance float
) AS \$\$
BEGIN
    RETURN QUERY
    SELECT
        documents.id,
        documents.content,
        documents.metadata,
        documents.embedding <-> query_embedding as distance
    FROM documents
    WHERE documents.embedding IS NOT NULL
    ORDER BY documents.embedding <-> query_embedding
    LIMIT match_count;
END;
\$\$ LANGUAGE plpgsql;
EOF
echo "✓ Helper functions created"
echo ""

# Optimize PostgreSQL settings for vector operations
echo "Step 8: Recommended PostgreSQL configuration..."
echo ""
echo "Add these settings to postgresql.conf for optimal performance:"
echo ""
echo "  # Memory settings for vector operations"
echo "  shared_buffers = 256MB                    # Increase for production"
echo "  maintenance_work_mem = 256MB              # For index building"
echo "  effective_cache_size = 1GB                # Increase for production"
echo "  "
echo "  # Query planner settings"
echo "  random_page_cost = 1.1                    # For SSD storage"
echo "  "
echo "  # Connection settings"
echo "  max_connections = 100"
echo "  "
echo "For IVFFlat indexes, also set:"
echo "  SET ivfflat.probes = 10;                  # Higher = better recall, slower"
echo ""

# Create sample data insert script
echo "Step 9: Creating sample data insert script..."
cat > /tmp/insert_sample_pgvector.sql << 'EOF'
-- Sample insert with random vector (replace with actual embeddings)
-- In production, generate embeddings using your embedding model

-- Example: Insert document with embedding
INSERT INTO documents (content, metadata, embedding)
VALUES (
    'Sample document content',
    '{"source": "manual", "tags": ["sample", "test"]}'::jsonb,
    -- Replace this random vector with actual embedding from your model
    (SELECT ARRAY_AGG(random()::float4)::vector FROM generate_series(1, 1536))
);

-- Example: Bulk insert with transaction
BEGIN;
INSERT INTO documents (content, metadata, embedding)
SELECT
    'Document ' || i,
    jsonb_build_object('index', i, 'category', 'test'),
    (SELECT ARRAY_AGG(random()::float4)::vector FROM generate_series(1, 1536))
FROM generate_series(1, 100) i;
COMMIT;

-- Example: Query similar documents
-- SELECT * FROM similarity_search_cosine(
--     (SELECT embedding FROM documents WHERE id = 1),
--     0.7,  -- similarity threshold
--     5     -- number of results
-- );
EOF
echo "✓ Sample script created: /tmp/insert_sample_pgvector.sql"
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Database: $DATABASE"
echo "Table: documents"
echo "Index: idx_documents_embedding_$INDEX_TYPE"
echo "Distance: $DISTANCE_METRIC"
echo ""
echo "Next steps:"
echo "1. Review configuration recommendations above"
echo "2. Insert your documents with embeddings"
echo "3. Use similarity_search_cosine() or similarity_search_l2() functions"
echo "4. See templates/pgvector-schema.sql for more examples"
echo ""
echo "Connection string:"
echo "postgresql://$USER@$HOST:$PORT/$DATABASE"
echo ""
