# Supabase Integration for Mem0 OSS

Complete Supabase backend setup for Mem0 Open Source mode, including PostgreSQL schema with pgvector, RLS policies, performance optimization, and production-ready configurations.

## Overview

This skill provides everything needed to deploy Mem0 OSS (self-hosted) with Supabase as the backend:

- **Database Schema**: Memory storage tables with pgvector for embeddings
- **Graph Memory**: Relationship tables for entity connections
- **Security**: Row Level Security (RLS) policies for user/tenant isolation
- **Performance**: Optimized indexes and connection pooling
- **Backup**: Automated backup and restore procedures
- **Migration**: Tools to migrate from Mem0 Platform to OSS

## Quick Start

### Prerequisites

1. Supabase project initialized:
   ```bash
   /supabase:init
   ```

2. Environment variables configured:
   ```bash
   export SUPABASE_URL="https://your-project.supabase.co"
   export SUPABASE_DB_URL="postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres"
   export SUPABASE_ANON_KEY="your-anon-key"
   export SUPABASE_SERVICE_KEY="your-service-key"
   ```

### Installation

1. **Enable pgvector**:
   ```bash
   bash scripts/setup-mem0-pgvector.sh
   ```

2. **Create tables**:
   ```bash
   bash scripts/apply-mem0-schema.sh
   ```

3. **Setup indexes**:
   ```bash
   bash scripts/create-mem0-indexes.sh
   ```

4. **Apply security policies**:
   ```bash
   bash scripts/apply-mem0-rls.sh
   ```

5. **Validate setup**:
   ```bash
   bash scripts/validate-mem0-setup.sh
   ```

## Architecture

### Database Schema

**memories** table (core storage):
```
id              uuid PRIMARY KEY
user_id         text NOT NULL (indexed)
agent_id        text (indexed, nullable)
run_id          text (indexed, nullable)
memory          text NOT NULL
hash            text UNIQUE
metadata        jsonb
categories      text[]
embedding       vector(1536)
created_at      timestamptz
updated_at      timestamptz
```

**memory_relationships** table (graph memory):
```
id                  uuid PRIMARY KEY
source_memory_id    uuid REFERENCES memories(id)
target_memory_id    uuid REFERENCES memories(id)
relationship_type   text
strength            numeric(3,2)
metadata            jsonb
user_id             text (indexed)
created_at          timestamptz
```

**memory_history** table (audit trail):
```
id          uuid PRIMARY KEY
memory_id   uuid
operation   text (create/update/delete)
old_value   jsonb
new_value   jsonb
user_id     text
timestamp   timestamptz
```

### Security Model

**Row Level Security (RLS)** enforces data isolation:

1. **User Isolation**: Users only access their own memories
2. **Multi-Tenant**: Organizations share memories within org
3. **Agent Knowledge**: Public agent memories readable by all
4. **Audit Trail**: Complete history of memory operations

All policies are automatically tested and validated.

### Performance Optimization

**Indexes**:
- HNSW vector index for semantic search
- B-tree indexes on user_id, agent_id, run_id
- Composite indexes for common query patterns
- Full-text search index for keyword queries

**Connection Pooling**:
- PgBouncer configuration for transaction pooling
- Configurable pool sizes based on load
- Automatic connection recycling

## Usage Patterns

### Basic Mem0 Client Setup

```python
import os
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
}

memory = Memory.from_config(config)

# Add memory
memory.add("User prefers concise responses", user_id="customer-123")

# Search memories
results = memory.search("communication style", user_id="customer-123")
```

### Graph Memory (Relationships)

```python
config = {
    "vector_store": {
        "provider": "postgres"
        "config": {
            "url": os.getenv("SUPABASE_DB_URL")
        }
    }
    "graph_store": {
        "provider": "postgres"
        "config": {
            "url": os.getenv("SUPABASE_DB_URL")
            "relationship_table": "memory_relationships"
        }
    }
}

memory = Memory.from_config(config)

# Relationships are extracted automatically
memory.add(
    "John works with Sarah at Acme Corp. Sarah is the project manager."
    user_id="org-456"
)
```

### Multi-Tenant Configuration

```python
# Memories scoped to organization
memory.add(
    "Company uses AWS for infrastructure"
    user_id="user-123"
    metadata={"org_id": "acme-corp"}
)

# Search within organization only
results = memory.search(
    "infrastructure"
    filters={"metadata": {"org_id": "acme-corp"}}
)
```

## Scripts Reference

### Setup Scripts

- **verify-supabase-setup.sh**: Check Supabase initialization
- **setup-mem0-pgvector.sh**: Enable pgvector extension
- **apply-mem0-schema.sh**: Create memory tables
- **create-mem0-indexes.sh**: Add performance indexes
- **apply-mem0-rls.sh**: Apply security policies

### Management Scripts

- **backup-mem0-memories.sh**: Backup all memories
- **restore-mem0-backup.sh**: Restore from backup
- **configure-connection-pool.sh**: Setup pooling
- **validate-mem0-setup.sh**: Complete validation

### Migration Scripts

- **export-from-platform.sh**: Export from Mem0 Platform
- **migrate-platform-to-oss.sh**: Migrate to OSS

### Testing & Monitoring

- **test-mem0-rls.sh**: Test security policies
- **benchmark-mem0-performance.sh**: Performance testing
- **monitor-connections.sh**: Connection monitoring
- **audit-mem0-security.sh**: Security audit

## Templates

All templates are in `templates/` directory:

- **mem0-schema.sql**: Base PostgreSQL schema
- **mem0-schema-graph.sql**: Schema with graph support
- **mem0-indexes.sql**: Performance indexes
- **mem0-rls-policies.sql**: Security policies
- **mem0-basic-config.py**: Basic Python config
- **mem0-graph-config.py**: Full-featured config
- **mem0-enterprise-config.py**: Multi-tenant setup

## Examples

Comprehensive examples in `examples/` directory:

- **user-isolation-pattern.md**: User-specific memories
- **multi-tenant-pattern.md**: Organization isolation
- **agent-knowledge-pattern.md**: Shared agent knowledge
- **session-memory-pattern.md**: Temporary context
- **platform-to-oss-migration-guide.md**: Migration walkthrough
- **performance-tuning-guide.md**: Optimization strategies

## Troubleshooting

### Common Issues

**pgvector not available**: Enable in Supabase dashboard under Database → Extensions

**Slow queries**: Check indexes with `scripts/benchmark-mem0-performance.sh`

**RLS blocking queries**: Verify auth context with `scripts/test-mem0-rls.sh`

**Connection errors**: Use transaction pooler (port 6543)

See SKILL.md for detailed troubleshooting guide.

## Production Checklist

Before deploying to production:

- ✅ pgvector extension enabled
- ✅ All tables created with indexes
- ✅ RLS policies active and tested
- ✅ Connection pooling configured
- ✅ Backup strategy implemented
- ✅ Performance benchmarks pass
- ✅ Security audit completed
- ✅ Monitoring configured

## Support

For issues or questions:
- See SKILL.md for detailed instructions
- Check examples/ for implementation patterns
- Run validation scripts for diagnostics
- Review Mem0 docs: https://docs.mem0.ai
- Review Supabase docs: https://supabase.com/docs

## Version

- **Skill Version**: 1.0.0
- **Last Updated**: 2025-10-27
- **Compatible with**: Mem0 OSS 1.0+, Supabase PostgreSQL 15+
