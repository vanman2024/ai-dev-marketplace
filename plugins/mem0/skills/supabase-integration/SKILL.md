---
name: supabase-integration
description: Complete Supabase setup for Mem0 OSS including PostgreSQL schema with pgvector for embeddings, memory_relationships tables for graph memory, RLS policies for user/tenant isolation, performance indexes, connection pooling, and backup/migration strategies. Use when setting up Mem0 with Supabase, configuring OSS memory backend, implementing memory persistence, migrating from Platform to OSS, or when user mentions Mem0 Supabase, memory database, pgvector for Mem0, memory isolation, or Mem0 backup.
allowed-tools: Bash, Read, Write, Edit
---

# Supabase Integration for Mem0 OSS

Complete guide for setting up Supabase as the backend for Mem0 Open Source (self-hosted) mode, including PostgreSQL schema with pgvector, RLS policies for security, and production-ready configurations.

## Instructions

### Phase 1: Supabase Project Setup

**Prerequisites Check:**
1. Verify Supabase is initialized:
   ```bash
   bash scripts/verify-supabase-setup.sh
   ```

2. If not initialized, set up Supabase first:
   - Run `/supabase:init` command
   - Note down project ID and connection details
   - Obtain connection string from Supabase dashboard

**Environment Configuration:**
```bash
# Required environment variables
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
SUPABASE_DB_URL=postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres

# Optional: Mem0-specific configs
MEM0_EMBEDDING_MODEL=text-embedding-3-small
MEM0_VECTOR_DIMENSION=1536
```

### Phase 2: Enable pgvector Extension

**Enable Extension:**
```bash
bash scripts/setup-mem0-pgvector.sh
```

This script:
1. Connects to Supabase database
2. Enables pgvector extension
3. Verifies extension is active
4. Checks PostgreSQL version compatibility (>= 12)

**Manual Verification:**
```sql
-- Check pgvector is enabled
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Test vector operations
SELECT '[1,2,3]'::vector;
```

### Phase 3: Create Memory Tables Schema

**Apply Memory Schema:**
```bash
bash scripts/apply-mem0-schema.sh
```

This creates three core tables:

**1. memories table** (vector storage):
- `id` (uuid, primary key)
- `user_id` (text, indexed) - User identifier for isolation
- `agent_id` (text, indexed, nullable) - Agent identifier
- `run_id` (text, indexed, nullable) - Session/conversation identifier
- `memory` (text) - Memory content
- `hash` (text) - Content hash for deduplication
- `metadata` (jsonb) - Flexible metadata storage
- `categories` (text[]) - Memory categorization
- `embedding` (vector(1536)) - Semantic embedding
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

**2. memory_relationships table** (graph memory):
- `id` (uuid, primary key)
- `source_memory_id` (uuid, foreign key)
- `target_memory_id` (uuid, foreign key)
- `relationship_type` (text) - e.g., "references", "caused_by", "related_to"
- `strength` (numeric) - Relationship strength (0.0-1.0)
- `metadata` (jsonb)
- `user_id` (text, indexed) - For RLS isolation
- `created_at` (timestamptz)

**3. memory_history table** (audit trail):
- `id` (uuid, primary key)
- `memory_id` (uuid)
- `operation` (text) - "create", "update", "delete"
- `old_value` (jsonb)
- `new_value` (jsonb)
- `user_id` (text)
- `timestamp` (timestamptz)

**Use Template for Custom Schema:**
```bash
# Generate schema with custom dimensions
bash scripts/generate-mem0-schema.sh \
  --dimensions 1536 \
  --include-graph true \
  --include-history true \
  > custom-mem0-schema.sql

# Apply custom schema
psql $SUPABASE_DB_URL < custom-mem0-schema.sql
```

### Phase 4: Create Performance Indexes

**Apply Optimized Indexes:**
```bash
bash scripts/create-mem0-indexes.sh
```

**Index Strategy:**

1. **Vector Search Indexes (HNSW)**:
   ```sql
   -- Main embedding index (cosine distance)
   CREATE INDEX idx_memories_embedding ON memories
   USING hnsw (embedding vector_cosine_ops)
   WITH (m = 16, ef_construction = 64);
   ```

2. **User/Agent Isolation Indexes**:
   ```sql
   CREATE INDEX idx_memories_user_id ON memories(user_id);
   CREATE INDEX idx_memories_agent_id ON memories(agent_id);
   CREATE INDEX idx_memories_run_id ON memories(run_id);
   ```

3. **Composite Indexes for Common Queries**:
   ```sql
   -- User + timestamp for chronological retrieval
   CREATE INDEX idx_memories_user_created ON memories(user_id, created_at DESC);

   -- User + agent for agent-specific memories
   CREATE INDEX idx_memories_user_agent ON memories(user_id, agent_id);
   ```

4. **Graph Relationship Indexes**:
   ```sql
   CREATE INDEX idx_relationships_source ON memory_relationships(source_memory_id);
   CREATE INDEX idx_relationships_target ON memory_relationships(target_memory_id);
   CREATE INDEX idx_relationships_type ON memory_relationships(relationship_type);
   ```

5. **Full-Text Search Index (optional)**:
   ```sql
   CREATE INDEX idx_memories_content_fts ON memories
   USING gin(to_tsvector('english', memory));
   ```

**Index Selection Guide:**
- Small dataset (< 100K memories): Start with basic indexes
- Medium dataset (100K-1M): Add HNSW with m=16
- Large dataset (> 1M): Use HNSW with m=32, consider IVFFlat
- Write-heavy workload: Consider IVFFlat over HNSW

### Phase 5: Implement Row Level Security (RLS)

**Apply RLS Policies:**
```bash
bash scripts/apply-mem0-rls.sh
```

**Security Patterns:**

**1. User Isolation (Default)**:
```sql
-- Users can only access their own memories
CREATE POLICY "Users access own memories"
ON memories FOR ALL
USING (auth.uid()::text = user_id);

-- Users can only see their own relationships
CREATE POLICY "Users access own relationships"
ON memory_relationships FOR ALL
USING (auth.uid()::text = user_id);
```

**2. Multi-Tenant Isolation (Enterprise)**:
```sql
-- Check organization membership
CREATE POLICY "Organization members access memories"
ON memories FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM org_members
    WHERE org_members.user_id = auth.uid()::text
    AND org_members.org_id = memories.metadata->>'org_id'
  )
);
```

**3. Agent-Specific Policies**:
```sql
-- Public agent memories (shared across users)
CREATE POLICY "Agent memories readable by all"
ON memories FOR SELECT
USING (agent_id IS NOT NULL AND user_id IS NULL);

-- Agent can write to their own memory space
CREATE POLICY "Agent writes own memories"
ON memories FOR INSERT
WITH CHECK (agent_id = current_setting('app.agent_id', true));
```

**Test RLS Enforcement:**
```bash
bash scripts/test-mem0-rls.sh --user-id "test-user-123"
```

### Phase 6: Configure Connection Pooling

**Setup PgBouncer (Recommended for Production):**
```bash
bash scripts/configure-connection-pool.sh
```

**Connection Pooling Strategy:**

**For Mem0 OSS:**
- Transaction mode (default): Each memory operation gets fresh connection
- Session mode: Use for graph traversals requiring multiple queries
- Pool size: Start with 20 connections, scale based on load

**Configuration:**
```python
# Mem0 with connection pooling
from mem0 import Memory

config = {
    "vector_store": {
        "provider": "postgres"
        "config": {
            "url": "postgresql://user:pass@pooler.project.supabase.co:6543/postgres"
            "pool_size": 20
            "max_overflow": 10
            "pool_timeout": 30
            "pool_recycle": 3600
        }
    }
}

memory = Memory.from_config(config)
```

**Supabase Pooler URLs:**
- Transaction mode: `pooler.project.supabase.co:6543`
- Session mode: `pooler.project.supabase.co:5432`

### Phase 7: Implement Backup Strategy

**Setup Automated Backups:**
```bash
bash scripts/setup-mem0-backup.sh --schedule daily --retention 30
```

**Backup Strategies:**

**1. Point-in-Time Recovery (Supabase Built-in)**:
- Automatic backups (Pro plan and above)
- Restore to any point in last 7-30 days
- No manual configuration needed

**2. Manual SQL Dumps**:
```bash
# Full database backup
bash scripts/backup-mem0-memories.sh

# Incremental backup (changes since last backup)
bash scripts/backup-mem0-memories.sh --incremental --since "2025-10-01"

# Backup to S3
bash scripts/backup-mem0-memories.sh --destination s3://my-bucket/mem0-backups/
```

**3. Selective Backups**:
```bash
# Backup specific user's memories
bash scripts/backup-user-memories.sh --user-id "customer-123"

# Backup by date range
bash scripts/backup-mem0-memories.sh --from "2025-01-01" --to "2025-10-27"
```

**Restore Procedures:**
```bash
# Restore from backup file
bash scripts/restore-mem0-backup.sh backup-2025-10-27.sql

# Restore specific user
bash scripts/restore-user-memories.sh backup-user-123.sql --user-id "customer-123"
```

### Phase 8: Migration from Platform to OSS

**Export from Mem0 Platform:**
```bash
bash scripts/export-from-platform.sh \
  --api-key "your-platform-api-key" \
  --output platform-export.json
```

**Transform and Import to Supabase:**
```bash
bash scripts/migrate-platform-to-oss.sh \
  --input platform-export.json \
  --supabase-url $SUPABASE_URL \
  --dry-run  # Test first

# After validation, run actual migration
bash scripts/migrate-platform-to-oss.sh \
  --input platform-export.json \
  --supabase-url $SUPABASE_URL
```

**Migration Steps:**
1. Export memories from Platform API
2. Transform format (Platform JSON → Postgres schema)
3. Generate embeddings if missing
4. Validate data integrity
5. Batch insert to Supabase
6. Verify counts and sample queries
7. Update application configs to use OSS

**Rollback Plan:**
```bash
# Create migration checkpoint before starting
bash scripts/create-migration-checkpoint.sh

# Rollback if issues occur
bash scripts/rollback-migration.sh --checkpoint checkpoint-2025-10-27
```

### Phase 9: Validation and Testing

**Run Complete Validation Suite:**
```bash
bash scripts/validate-mem0-setup.sh
```

**Validation Checks:**
- ✅ pgvector extension enabled
- ✅ All tables created with correct schema
- ✅ Indexes created and being used
- ✅ RLS policies active and enforcing
- ✅ Connection pooling configured
- ✅ Backup system operational
- ✅ Sample memory CRUD operations working
- ✅ Vector search returning results
- ✅ Graph relationships functional (if enabled)

**Performance Benchmarks:**
```bash
bash scripts/benchmark-mem0-performance.sh
```

**Expected Performance (1K-10K memories):**
- Memory insertion: < 50ms
- Vector search (top 10): < 100ms
- Memory retrieval by ID: < 10ms
- Graph traversal (1-2 hops): < 150ms

## Configuration Templates

### Template 1: Basic Mem0 OSS + Supabase

Use template: `templates/mem0-basic-config.py`

```python
from mem0 import Memory

config = {
    "vector_store": {
        "provider": "postgres"
        "config": {
            "url": "postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres"
            "table_name": "memories"
            "embedding_dimension": 1536
        }
    }
}

memory = Memory.from_config(config)
```

### Template 2: Full-Featured (Vector + Graph)

Use template: `templates/mem0-graph-config.py`

```python
from mem0 import Memory

config = {
    "vector_store": {
        "provider": "postgres"
        "config": {
            "url": os.getenv("SUPABASE_DB_URL")
            "table_name": "memories"
            "embedding_dimension": 1536
        }
    }
    "graph_store": {
        "provider": "postgres",  # Using same DB for graph
        "config": {
            "url": os.getenv("SUPABASE_DB_URL")
            "relationship_table": "memory_relationships"
        }
    }
    "version": "v1.1"
}

memory = Memory.from_config(config)
```

### Template 3: Enterprise Multi-Tenant

Use template: `templates/mem0-enterprise-config.py`

Includes:
- Organization-level isolation
- Role-based access control
- Audit logging
- Advanced RLS policies
- Cost tracking per tenant

## Common Patterns

### Pattern 1: User Memory Isolation

**Scenario**: SaaS app with user-specific memories

**Implementation**: See `examples/user-isolation-pattern.md`

**Key Points**:
- Always filter by user_id
- RLS policies prevent cross-user access
- Use composite indexes (user_id + created_at)

### Pattern 2: Multi-Tenant Organization

**Scenario**: Teams/organizations share memories within org

**Implementation**: See `examples/multi-tenant-pattern.md`

**Key Points**:
- Add org_id to metadata
- RLS checks org membership
- Hierarchical access (org admins see all)

### Pattern 3: Agent Knowledge Base

**Scenario**: Shared agent memories across all users

**Implementation**: See `examples/agent-knowledge-pattern.md`

**Key Points**:
- agent_id not null, user_id null for shared memories
- Separate RLS policies for public agent knowledge
- Versioning for agent memory updates

### Pattern 4: Session-Based Memory

**Scenario**: Temporary conversation context

**Implementation**: See `examples/session-memory-pattern.md`

**Key Points**:
- Use run_id for session identification
- Auto-cleanup after session expiry
- Promote important memories to user level

## Troubleshooting

### pgvector Extension Issues

**Problem**: Extension not available
```bash
ERROR: extension "vector" is not available
```

**Solution**:
1. Verify PostgreSQL version >= 12
2. Enable in Supabase dashboard: Database → Extensions → vector
3. Wait 1-2 minutes for activation
4. Verify: `SELECT * FROM pg_extension WHERE extname = 'vector';`

### Slow Vector Search

**Problem**: Queries taking > 500ms

**Solutions**:
1. Check index exists:
   ```sql
   SELECT indexname FROM pg_indexes
   WHERE tablename = 'memories' AND indexname LIKE '%embedding%';
   ```

2. Reduce search space with filters:
   ```python
   memory.search(query, user_id="specific-user", limit=5)
   ```

3. Increase HNSW parameters (rebuild index):
   ```sql
   DROP INDEX idx_memories_embedding;
   CREATE INDEX idx_memories_embedding ON memories
   USING hnsw (embedding vector_cosine_ops)
   WITH (m = 32, ef_construction = 128);
   ```

4. Switch to IVFFlat for large datasets (> 1M):
   ```bash
   bash scripts/migrate-to-ivfflat.sh
   ```

### RLS Blocking Queries

**Problem**: Queries return empty results despite data existing

**Solution**:
1. Check RLS is enabled:
   ```sql
   SELECT tablename, rowsecurity FROM pg_tables
   WHERE tablename = 'memories';
   ```

2. Verify auth context is set:
   ```python
   # Ensure user_id in JWT
   supabase.auth.get_user()
   ```

3. Test with service key (bypasses RLS):
   ```bash
   bash scripts/test-mem0-rls.sh --bypass-rls
   ```

4. Review policy logs:
   ```bash
   bash scripts/debug-rls-policies.sh
   ```

### Connection Pool Exhaustion

**Problem**: "too many connections" errors

**Solutions**:
1. Use transaction pooler (port 6543)
2. Increase pool size in config
3. Implement connection retry logic
4. Monitor connection usage:
   ```bash
   bash scripts/monitor-connections.sh
   ```

### Migration Failures

**Problem**: Migration script fails partway through

**Recovery**:
```bash
# Check migration status
bash scripts/check-migration-status.sh

# Rollback to checkpoint
bash scripts/rollback-migration.sh --checkpoint last

# Resume from last successful batch
bash scripts/resume-migration.sh
```

## Security Best Practices

### Checklist

- ✅ RLS enabled on all Mem0 tables
- ✅ Service key never exposed to client
- ✅ All queries filtered by user_id/org_id
- ✅ Connection strings use environment variables
- ✅ SSL/TLS enforced for database connections
- ✅ Regular security audits run
- ✅ Sensitive memory content encrypted at rest
- ✅ Backup files encrypted
- ✅ Access logs monitored for anomalies
- ✅ GDPR/data deletion policies implemented

### Audit Script

Run regular security audits:
```bash
bash scripts/audit-mem0-security.sh --report security-audit.md
```

Checks:
- RLS policy coverage
- Unprotected tables
- Missing indexes on security columns
- Suspicious access patterns
- Cross-user query attempts
- Service key usage in logs

## Files Reference

**Scripts** (all executable, production-ready):
- `scripts/verify-supabase-setup.sh` - Check Supabase initialization
- `scripts/setup-mem0-pgvector.sh` - Enable pgvector extension
- `scripts/apply-mem0-schema.sh` - Create memory tables
- `scripts/generate-mem0-schema.sh` - Generate custom schema
- `scripts/create-mem0-indexes.sh` - Create optimized indexes
- `scripts/apply-mem0-rls.sh` - Apply RLS policies
- `scripts/test-mem0-rls.sh` - Test security policies
- `scripts/configure-connection-pool.sh` - Setup pooling
- `scripts/setup-mem0-backup.sh` - Configure backups
- `scripts/backup-mem0-memories.sh` - Manual backup
- `scripts/restore-mem0-backup.sh` - Restore from backup
- `scripts/backup-user-memories.sh` - User-specific backup
- `scripts/export-from-platform.sh` - Export Platform memories
- `scripts/migrate-platform-to-oss.sh` - Platform → OSS migration
- `scripts/validate-mem0-setup.sh` - Complete validation
- `scripts/benchmark-mem0-performance.sh` - Performance testing
- `scripts/migrate-to-ivfflat.sh` - Switch to IVFFlat index
- `scripts/debug-rls-policies.sh` - Debug RLS issues
- `scripts/monitor-connections.sh` - Connection monitoring
- `scripts/audit-mem0-security.sh` - Security audit

**Templates**:
- `templates/mem0-schema.sql` - Base schema with pgvector
- `templates/mem0-schema-graph.sql` - Schema with graph support
- `templates/mem0-indexes.sql` - Performance indexes
- `templates/mem0-rls-policies.sql` - Security policies
- `templates/mem0-basic-config.py` - Basic Python config
- `templates/mem0-graph-config.py` - Full-featured config
- `templates/mem0-enterprise-config.py` - Multi-tenant config
- `templates/backup-policy.yaml` - Backup configuration
- `templates/connection-pool-config.ini` - PgBouncer config

**Examples**:
- `examples/user-isolation-pattern.md` - User-specific memories
- `examples/multi-tenant-pattern.md` - Organization isolation
- `examples/agent-knowledge-pattern.md` - Shared agent memories
- `examples/session-memory-pattern.md` - Temporary session context
- `examples/platform-to-oss-migration-guide.md` - Complete migration walkthrough
- `examples/backup-restore-procedures.md` - Disaster recovery guide
- `examples/performance-tuning-guide.md` - Optimization strategies

---

**Plugin**: mem0
**Version**: 1.0.0
**Last Updated**: 2025-10-27
