-- Mem0 Memory Storage Schema for Supabase
-- Version: 1.0.0
-- Description: Base schema with vector embeddings for semantic search

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Core memories table
CREATE TABLE IF NOT EXISTS memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    agent_id TEXT,
    run_id TEXT,
    memory TEXT NOT NULL,
    hash TEXT UNIQUE,
    metadata JSONB DEFAULT '{}'::jsonb,
    categories TEXT[] DEFAULT ARRAY[]::TEXT[],
    embedding VECTOR(1536),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE memories IS 'Mem0 memory storage with vector embeddings for semantic search';

-- Column comments
COMMENT ON COLUMN memories.user_id IS 'User identifier for memory isolation (required)';
COMMENT ON COLUMN memories.agent_id IS 'Agent identifier for agent-specific memories (optional)';
COMMENT ON COLUMN memories.run_id IS 'Session/conversation identifier for ephemeral context (optional)';
COMMENT ON COLUMN memories.memory IS 'Memory content text';
COMMENT ON COLUMN memories.hash IS 'Content hash for deduplication';
COMMENT ON COLUMN memories.metadata IS 'Flexible JSON metadata (org_id, tags, etc.)';
COMMENT ON COLUMN memories.categories IS 'Memory categories for classification';
COMMENT ON COLUMN memories.embedding IS 'Semantic embedding vector (default: 1536 dimensions for OpenAI)';

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_memories_updated_at ON memories;
CREATE TRIGGER update_memories_updated_at
    BEFORE UPDATE ON memories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Basic indexes for performance
CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
CREATE INDEX IF NOT EXISTS idx_memories_agent_id ON memories(agent_id);
CREATE INDEX IF NOT EXISTS idx_memories_run_id ON memories(run_id);
CREATE INDEX IF NOT EXISTS idx_memories_hash ON memories(hash);
CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_memories_metadata ON memories USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_memories_categories ON memories USING gin(categories);

-- HNSW vector index for similarity search
CREATE INDEX IF NOT EXISTS idx_memories_embedding ON memories
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Row Level Security
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;

-- Users can only access their own memories
CREATE POLICY "users_access_own_memories"
ON memories FOR ALL
TO authenticated
USING ((SELECT auth.uid()::text) = user_id)
WITH CHECK ((SELECT auth.uid()::text) = user_id);

-- Service role can access all memories
CREATE POLICY "service_role_all_access"
ON memories FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Public agent memories (where user_id is NULL) are readable by all
CREATE POLICY "public_agent_knowledge"
ON memories FOR SELECT
TO authenticated
USING (agent_id IS NOT NULL AND user_id IS NULL);
