-- Mem0 Memory Storage Schema with Graph Support
-- Version: 1.0.0
-- Description: Complete schema with vector embeddings + graph relationships

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

COMMENT ON TABLE memories IS 'Mem0 memory storage with vector embeddings';

-- Memory relationships table (graph support)
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

COMMENT ON TABLE memory_relationships IS 'Graph relationships between memories';
COMMENT ON COLUMN memory_relationships.relationship_type IS 'Type of relationship (e.g., "references", "caused_by", "related_to")';
COMMENT ON COLUMN memory_relationships.strength IS 'Relationship strength score (0.0 to 1.0)';

-- Memory history table (audit trail)
CREATE TABLE IF NOT EXISTS memory_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    memory_id UUID NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
    old_value JSONB,
    new_value JSONB,
    user_id TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE memory_history IS 'Audit trail for memory operations';

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_memories_updated_at ON memories;
CREATE TRIGGER update_memories_updated_at
    BEFORE UPDATE ON memories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Audit logging trigger
CREATE OR REPLACE FUNCTION log_memory_changes()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_memory_changes ON memories;
CREATE TRIGGER audit_memory_changes
    AFTER INSERT OR UPDATE OR DELETE ON memories
    FOR EACH ROW
    EXECUTE FUNCTION log_memory_changes();

-- Indexes for memories table
CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
CREATE INDEX IF NOT EXISTS idx_memories_agent_id ON memories(agent_id);
CREATE INDEX IF NOT EXISTS idx_memories_run_id ON memories(run_id);
CREATE INDEX IF NOT EXISTS idx_memories_hash ON memories(hash);
CREATE INDEX IF NOT EXISTS idx_memories_user_created ON memories(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_memories_user_agent ON memories(user_id, agent_id);
CREATE INDEX IF NOT EXISTS idx_memories_metadata ON memories USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_memories_categories ON memories USING gin(categories);

-- Vector index
CREATE INDEX IF NOT EXISTS idx_memories_embedding ON memories
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Indexes for relationships table
CREATE INDEX IF NOT EXISTS idx_relationships_source ON memory_relationships(source_memory_id);
CREATE INDEX IF NOT EXISTS idx_relationships_target ON memory_relationships(target_memory_id);
CREATE INDEX IF NOT EXISTS idx_relationships_type ON memory_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_relationships_user_id ON memory_relationships(user_id);
CREATE INDEX IF NOT EXISTS idx_relationships_source_type ON memory_relationships(source_memory_id, relationship_type);

-- Indexes for history table
CREATE INDEX IF NOT EXISTS idx_history_memory_id ON memory_history(memory_id);
CREATE INDEX IF NOT EXISTS idx_history_user_id ON memory_history(user_id);
CREATE INDEX IF NOT EXISTS idx_history_timestamp ON memory_history(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_history_operation ON memory_history(operation);

-- Row Level Security for memories
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_access_own_memories"
ON memories FOR ALL
TO authenticated
USING ((SELECT auth.uid()::text) = user_id)
WITH CHECK ((SELECT auth.uid()::text) = user_id);

CREATE POLICY "service_role_all_access"
ON memories FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "public_agent_knowledge"
ON memories FOR SELECT
TO authenticated
USING (agent_id IS NOT NULL AND user_id IS NULL);

-- Row Level Security for relationships
ALTER TABLE memory_relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_access_own_relationships"
ON memory_relationships FOR ALL
TO authenticated
USING ((SELECT auth.uid()::text) = user_id)
WITH CHECK ((SELECT auth.uid()::text) = user_id);

CREATE POLICY "service_role_all_relationships"
ON memory_relationships FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Row Level Security for history
ALTER TABLE memory_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_view_own_history"
ON memory_history FOR SELECT
TO authenticated
USING ((SELECT auth.uid()::text) = user_id);

CREATE POLICY "service_role_all_history"
ON memory_history FOR ALL
TO service_role
USING (true);
