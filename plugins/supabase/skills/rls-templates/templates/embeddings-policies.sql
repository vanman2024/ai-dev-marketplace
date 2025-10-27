-- Vector Embeddings RLS Policies
-- Pattern: Secure vector/embedding data for RAG systems
-- Use for: RAG applications, semantic search, vector databases, AI knowledge bases

-- ============================================
-- Table: documents
-- ============================================
-- Source documents that will be embedded

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_organization_id ON documents(organization_id);

-- SELECT: Users can view their own documents (or org documents if multi-tenant)
CREATE POLICY "documents_select_own" ON documents
    FOR SELECT
    TO authenticated
    USING (
        (SELECT auth.uid()) = user_id
        -- OR auth.user_has_org_access(organization_id)  -- Uncomment for multi-tenant
    );

-- INSERT: Users can upload their own documents
CREATE POLICY "documents_insert_own" ON documents
    FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = user_id
        -- OR auth.user_has_org_access(organization_id)  -- Uncomment for multi-tenant
    );

-- UPDATE: Users can update their own documents (metadata, processing status)
CREATE POLICY "documents_update_own" ON documents
    FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- DELETE: Users can delete their own documents
CREATE POLICY "documents_delete_own" ON documents
    FOR DELETE
    TO authenticated
    USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- Table: document_embeddings
-- ============================================
-- Vector embeddings generated from documents

ALTER TABLE document_embeddings ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_embeddings_document_id ON document_embeddings(document_id);
-- pgvector index for similarity search
-- CREATE INDEX ON document_embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- SELECT: Users can view embeddings for their documents
CREATE POLICY "embeddings_select_own_documents" ON document_embeddings
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM documents
            WHERE documents.id = document_embeddings.document_id
            AND documents.user_id = (SELECT auth.uid())
        )
    );

-- INSERT: Users can create embeddings for their documents
-- (Usually done by backend/edge function, not directly by users)
CREATE POLICY "embeddings_insert_own_documents" ON document_embeddings
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM documents
            WHERE documents.id = document_embeddings.document_id
            AND documents.user_id = (SELECT auth.uid())
        )
    );

-- UPDATE: Users can update embeddings metadata
CREATE POLICY "embeddings_update_own_documents" ON document_embeddings
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM documents
            WHERE documents.id = document_embeddings.document_id
            AND documents.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM documents
            WHERE documents.id = document_embeddings.document_id
            AND documents.user_id = (SELECT auth.uid())
        )
    );

-- DELETE: Users can delete embeddings for their documents
CREATE POLICY "embeddings_delete_own_documents" ON document_embeddings
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM documents
            WHERE documents.id = document_embeddings.document_id
            AND documents.user_id = (SELECT auth.uid())
        )
    );

-- ============================================
-- Service Role Policies (for embedding generation)
-- ============================================
-- Edge functions using service role key bypass RLS
-- But you can create explicit service role policies for audit trail

-- CREATE POLICY "embeddings_service_role_all" ON document_embeddings
--     FOR ALL
--     TO service_role
--     USING (true)
--     WITH CHECK (true);

-- ============================================
-- Function: Search User's Embeddings
-- ============================================
-- Security definer function for vector similarity search
-- Only searches within user's own documents

CREATE OR REPLACE FUNCTION search_embeddings(
    query_embedding vector(1536),  -- Adjust dimension for your model
    match_threshold float DEFAULT 0.5,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id uuid,
    document_id uuid,
    content text,
    similarity float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        document_embeddings.id,
        document_embeddings.document_id,
        document_embeddings.content,
        1 - (document_embeddings.embedding <=> query_embedding) as similarity
    FROM document_embeddings
    INNER JOIN documents ON documents.id = document_embeddings.document_id
    WHERE documents.user_id = auth.uid()  -- Security: only user's docs
    AND 1 - (document_embeddings.embedding <=> query_embedding) > match_threshold
    ORDER BY document_embeddings.embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Optional: Document Chunks Table
-- ============================================
-- For chunked documents before embedding

-- CREATE TABLE IF NOT EXISTS document_chunks (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
--     chunk_index INT NOT NULL,
--     content TEXT NOT NULL,
--     metadata JSONB,
--     created_at TIMESTAMPTZ DEFAULT NOW()
-- );

-- ALTER TABLE document_chunks ENABLE ROW LEVEL SECURITY;

-- CREATE INDEX IF NOT EXISTS idx_chunks_document_id ON document_chunks(document_id);

-- -- Inherit security from documents table
-- CREATE POLICY "chunks_select_own_documents" ON document_chunks
--     FOR SELECT TO authenticated
--     USING (EXISTS (
--         SELECT 1 FROM documents
--         WHERE documents.id = document_chunks.document_id
--         AND documents.user_id = (SELECT auth.uid())
--     ));

-- ============================================
-- Multi-Tenant RAG Alternative
-- ============================================
-- If embeddings should be organization-scoped instead of user-scoped

-- CREATE POLICY "embeddings_select_org" ON document_embeddings
--     FOR SELECT
--     TO authenticated
--     USING (
--         EXISTS (
--             SELECT 1
--             FROM documents
--             WHERE documents.id = document_embeddings.document_id
--             AND auth.user_has_org_access(documents.organization_id)
--         )
--     );

-- ============================================
-- Notes:
-- ============================================
-- 1. Embeddings inherit security from parent documents table
-- 2. Use pgvector extension: CREATE EXTENSION vector;
-- 3. Vector dimension must match your embedding model (e.g., 1536 for OpenAI)
-- 4. Consider IVFFlat or HNSW index for large datasets
-- 5. Security definer search function prevents RLS performance penalty
-- 6. Always use cosine similarity (<=>), L2 (<->), or inner product (<#>)
-- 7. Service role key should only be used in edge functions, never client
-- 8. Consider adding document.processing_status to track embedding progress
-- 9. Use triggers to automatically delete embeddings when document is deleted
-- 10. Add metadata JSONB column for filters (category, tags, etc.)
