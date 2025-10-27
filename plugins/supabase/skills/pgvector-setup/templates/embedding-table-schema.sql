-- Embedding table schema for pgvector
-- This template creates a table structure for storing embeddings with metadata
-- Customize: table name, vector dimensions, metadata columns, RLS policies

-- Create documents table with embeddings
CREATE TABLE IF NOT EXISTS documents (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,

    -- Content
    content TEXT NOT NULL,

    -- Vector embedding (adjust dimension to match your model)
    -- OpenAI text-embedding-3-small: 1536
    -- OpenAI text-embedding-3-large: 3072
    -- Cohere embed-english-v3.0: 1024
    embedding vector(1536),

    -- Metadata columns (customize as needed)
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Optional: Full-text search support (for hybrid search)
    fts tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED,

    -- User/tenant isolation (important for multi-tenant apps)
    user_id UUID,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for filtering
CREATE INDEX IF NOT EXISTS documents_user_id_idx ON documents(user_id);

-- Create GIN index for full-text search (optional, for hybrid search)
CREATE INDEX IF NOT EXISTS documents_fts_idx ON documents USING gin(fts);

-- Create index on metadata JSONB (optional, if querying metadata frequently)
CREATE INDEX IF NOT EXISTS documents_metadata_idx ON documents USING gin(metadata);

-- Enable Row Level Security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own documents
CREATE POLICY "Users can view their own documents"
    ON documents
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only insert their own documents
CREATE POLICY "Users can insert their own documents"
    ON documents
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can only update their own documents
CREATE POLICY "Users can update their own documents"
    ON documents
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can only delete their own documents
CREATE POLICY "Users can delete their own documents"
    ON documents
    FOR DELETE
    USING (auth.uid() = user_id);

-- Optional: Service role bypass (for admin/background operations)
-- CREATE POLICY "Service role can manage all documents"
--     ON documents
--     FOR ALL
--     USING (auth.jwt() ->> 'role' = 'service_role');

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (adjust as needed)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON documents TO authenticated;
-- GRANT USAGE ON SEQUENCE documents_id_seq TO authenticated;

/*
CUSTOMIZATION CHECKLIST:
[ ] Update table name ('documents' -> your table name)
[ ] Update vector dimension to match your embedding model
[ ] Add/remove metadata columns as needed
[ ] Adjust RLS policies for your security model
[ ] Consider partitioning for very large tables (> 10M rows)
[ ] Add constraints (e.g., CHECK on metadata structure)

NEXT STEPS:
1. Apply this schema: psql $SUPABASE_DB_URL < embedding-table-schema.sql
2. Create vector index: bash scripts/create-indexes.sh hnsw documents 1536
3. Test setup: bash scripts/test-vector-search.sh documents
*/
