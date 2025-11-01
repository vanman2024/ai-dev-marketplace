-- pgvector Schema and Configuration Template
-- PostgreSQL with pgvector extension for vector storage

-- ============================================
-- Extension Setup
-- ============================================

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================
-- Basic Documents Table with Vector Column
-- ============================================

CREATE TABLE IF NOT EXISTS documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    embedding vector(1536),  -- Adjust dimensions as needed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- Indexes
-- ============================================

-- GIN index for JSONB metadata filtering
CREATE INDEX idx_documents_metadata ON documents USING GIN (metadata);

-- B-tree indexes for timestamps
CREATE INDEX idx_documents_created_at ON documents (created_at);
CREATE INDEX idx_documents_updated_at ON documents (updated_at);

-- Vector index for similarity search
-- Choose ONE of the following based on your needs:

-- Option 1: HNSW index (recommended for most cases, 1M+ vectors)
-- Best for: Large datasets, balanced speed/accuracy
CREATE INDEX idx_documents_embedding_hnsw
ON documents
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Option 2: IVFFlat index (good for 100K-1M vectors)
-- Best for: Medium datasets, when you need faster index building
-- CREATE INDEX idx_documents_embedding_ivfflat
-- ON documents
-- USING ivfflat (embedding vector_cosine_ops)
-- WITH (lists = 100);

-- Distance operator options:
--   vector_cosine_ops    - Cosine distance (1 - cosine similarity)
--   vector_l2_ops        - Euclidean distance (L2)
--   vector_ip_ops        - Inner product (negative for max)

-- ============================================
-- Triggers
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_documents_updated_at ON documents;
CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Helper Functions
-- ============================================

-- Cosine similarity search with threshold
CREATE OR REPLACE FUNCTION similarity_search_cosine(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.5,
    match_count int DEFAULT 10,
    filter_metadata jsonb DEFAULT NULL
)
RETURNS TABLE (
    id bigint,
    content text,
    metadata jsonb,
    similarity float,
    distance float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        documents.id,
        documents.content,
        documents.metadata,
        1 - (documents.embedding <=> query_embedding) as similarity,
        documents.embedding <=> query_embedding as distance
    FROM documents
    WHERE documents.embedding IS NOT NULL
        AND 1 - (documents.embedding <=> query_embedding) > match_threshold
        AND (filter_metadata IS NULL OR documents.metadata @> filter_metadata)
    ORDER BY documents.embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- L2 distance search
CREATE OR REPLACE FUNCTION similarity_search_l2(
    query_embedding vector(1536),
    match_count int DEFAULT 10,
    filter_metadata jsonb DEFAULT NULL
)
RETURNS TABLE (
    id bigint,
    content text,
    metadata jsonb,
    distance float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        documents.id,
        documents.content,
        documents.metadata,
        documents.embedding <-> query_embedding as distance
    FROM documents
    WHERE documents.embedding IS NOT NULL
        AND (filter_metadata IS NULL OR documents.metadata @> filter_metadata)
    ORDER BY documents.embedding <-> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- Inner product search
CREATE OR REPLACE FUNCTION similarity_search_inner_product(
    query_embedding vector(1536),
    match_count int DEFAULT 10,
    filter_metadata jsonb DEFAULT NULL
)
RETURNS TABLE (
    id bigint,
    content text,
    metadata jsonb,
    score float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        documents.id,
        documents.content,
        documents.metadata,
        (documents.embedding <#> query_embedding) * -1 as score
    FROM documents
    WHERE documents.embedding IS NOT NULL
        AND (filter_metadata IS NULL OR documents.metadata @> filter_metadata)
    ORDER BY documents.embedding <#> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Usage Examples
-- ============================================

-- Insert document with embedding
/*
INSERT INTO documents (content, metadata, embedding)
VALUES (
    'Sample document content here',
    '{"source": "api", "category": "ml", "tags": ["sample", "test"]}'::jsonb,
    '[0.1, 0.2, 0.3, ...]'::vector(1536)  -- Replace with actual embedding
);
*/

-- Bulk insert with transaction
/*
BEGIN;
INSERT INTO documents (content, metadata, embedding)
SELECT
    content_text,
    metadata_json,
    embedding_vector
FROM external_data_source;
COMMIT;
*/

-- Search similar documents (cosine)
/*
SELECT * FROM similarity_search_cosine(
    '[0.1, 0.2, 0.3, ...]'::vector(1536),  -- query embedding
    0.7,   -- similarity threshold (0.0 to 1.0)
    10     -- number of results
);
*/

-- Search with metadata filter
/*
SELECT * FROM similarity_search_cosine(
    '[0.1, 0.2, 0.3, ...]'::vector(1536),
    0.5,
    10,
    '{"category": "ml"}'::jsonb  -- only match documents with category=ml
);
*/

-- Direct query with distance operator
/*
SELECT
    id,
    content,
    1 - (embedding <=> '[0.1, 0.2, ...]'::vector(1536)) as similarity
FROM documents
WHERE metadata @> '{"category": "ml"}'::jsonb
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector(1536)
LIMIT 10;
*/

-- Update embedding for existing document
/*
UPDATE documents
SET embedding = '[0.1, 0.2, ...]'::vector(1536)
WHERE id = 1;
*/

-- ============================================
-- Performance Optimization Settings
-- ============================================

-- Add these to postgresql.conf for optimal vector performance:

/*
# Memory settings
shared_buffers = 256MB                     # Increase for production (25% of RAM)
maintenance_work_mem = 256MB               # For index building
effective_cache_size = 1GB                 # Increase for production (50-75% of RAM)
work_mem = 16MB                            # For sorting operations

# Query planner
random_page_cost = 1.1                     # For SSD storage
effective_io_concurrency = 200             # For SSD storage

# Parallel query execution
max_parallel_workers_per_gather = 4
max_parallel_workers = 8

# IVFFlat specific (set per session)
SET ivfflat.probes = 10;                   # Higher = better recall, slower
*/

-- ============================================
-- Index Maintenance
-- ============================================

-- Rebuild index if needed (after bulk inserts)
/*
REINDEX INDEX CONCURRENTLY idx_documents_embedding_hnsw;
*/

-- Analyze table for query planner
/*
ANALYZE documents;
*/

-- Check index usage
/*
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE tablename = 'documents';
*/

-- ============================================
-- Multi-Vector Support (Advanced)
-- ============================================

-- Table with multiple vector columns for multi-modal embeddings
/*
CREATE TABLE multimodal_documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    text_embedding vector(1536),      -- Text embedding
    image_embedding vector(512),      -- Image embedding
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Separate indexes for each embedding
CREATE INDEX idx_multimodal_text_embedding
ON multimodal_documents
USING hnsw (text_embedding vector_cosine_ops);

CREATE INDEX idx_multimodal_image_embedding
ON multimodal_documents
USING hnsw (image_embedding vector_cosine_ops);
*/

-- ============================================
-- Partitioning for Large Datasets
-- ============================================

-- Partition by date for time-series data
/*
CREATE TABLE documents_partitioned (
    id BIGSERIAL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    embedding vector(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE documents_2024_01 PARTITION OF documents_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE documents_2024_02 PARTITION OF documents_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Create indexes on each partition
CREATE INDEX idx_documents_2024_01_embedding
ON documents_2024_01
USING hnsw (embedding vector_cosine_ops);
*/

-- ============================================
-- Cleanup
-- ============================================

-- Drop all vector-related objects
/*
DROP FUNCTION IF EXISTS similarity_search_cosine;
DROP FUNCTION IF EXISTS similarity_search_l2;
DROP FUNCTION IF EXISTS similarity_search_inner_product;
DROP TRIGGER IF EXISTS update_documents_updated_at ON documents;
DROP FUNCTION IF EXISTS update_updated_at_column;
DROP TABLE IF EXISTS documents;
DROP EXTENSION IF EXISTS vector;
*/
