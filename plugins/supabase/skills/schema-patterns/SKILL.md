---
name: schema-patterns
description: Production-ready database schema patterns for AI applications including chat/conversation schemas, RAG document storage with pgvector, multi-tenant organization models, user management, and AI usage tracking. Use when building AI applications, creating database schemas, setting up chat systems, implementing RAG, designing multi-tenant databases, or when user mentions supabase schemas, chat database, RAG storage, pgvector, embeddings, conversation history, or AI application database.
allowed-tools: Read, Write, Bash, Edit
---

# Database Schema Patterns for AI Applications

Production-ready PostgreSQL/Supabase database schemas optimized for AI applications including chat systems, RAG (Retrieval-Augmented Generation), multi-tenancy, and usage tracking.

## Instructions

### 1. Identify Required Pattern Type

Ask the user which schema pattern they need:
- **chat**: Conversation and messaging systems
- **rag**: Document storage with vector embeddings (pgvector)
- **multi-tenant**: Organization-based multi-tenancy
- **user-management**: Extended user profiles and metadata
- **ai-usage**: Token tracking, costs, and rate limiting
- **complete**: All patterns combined

### 2. Generate Schema

Use the generation script:
```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/schema-patterns
./scripts/generate-schema.sh <pattern-type> <output-file>
```

Pattern types: `chat`, `rag`, `multi-tenant`, `user-management`, `ai-usage`, `complete`

### 3. Validate Schema

Before applying, validate the generated schema:
```bash
./scripts/validate-schema.sh <schema-file>
```

This checks for:
- Proper table naming conventions (lowercase, underscores)
- Primary keys on all tables
- Foreign key relationships
- Index optimization
- pgvector extension usage (for RAG patterns)
- RLS policy structure
- Migration version format

### 4. Apply Migration

Apply the schema to your Supabase project:
```bash
./scripts/apply-migration.sh <schema-file> <migration-name>
```

This creates a timestamped migration file and validates before applying.

### 5. Seed Test Data (Optional)

For development, generate realistic test data:
```bash
./scripts/seed-data.sh <pattern-type>
```

## Available Templates

### Core Schemas
- `chat-schema.sql`: Complete chat/conversation system with users, conversations, messages, participants
- `rag-schema.sql`: RAG document storage with chunks, embeddings (pgvector), and similarity search
- `multi-tenant-schema.sql`: Organization-based multi-tenancy with orgs, teams, members, roles
- `user-management-schema.sql`: Extended user profiles, metadata, preferences
- `ai-usage-tracking-schema.sql`: Token usage, API costs, rate limiting, usage analytics

### Supporting Templates
- `migration-template.sql`: Boilerplate migration structure with version tracking
- `indexes-template.sql`: Performance optimization index patterns
- `rls-policies-template.sql`: Row Level Security policy patterns

## Key Features

### pgvector Integration (RAG Schemas)
All RAG schemas include:
- Vector column setup with proper dimensions
- HNSW indexing for similarity search
- Cosine distance operators
- Automatic embedding column generation
- Metadata storage alongside embeddings

### Multi-Tenancy Support
Organization-based isolation:
- Tenant identification (org_id on all tables)
- Team-based access control
- Member role management
- RLS policies for data isolation

### Chat System Optimization
Optimized for real-time messaging:
- Conversation participants tracking
- Message ordering and pagination indexes
- Read/unread status tracking
- Typing indicators support
- Message search with full-text indexes

### Performance Patterns
- Composite indexes for common queries
- Partial indexes for filtered queries
- Generated columns for computed fields
- Proper foreign key cascades
- Optimized join patterns

## Examples

See the examples directory for:
- `complete-ai-app-schema.md`: Full schema combining all patterns
- `migration-guide.md`: Schema evolution and versioning
- `indexing-strategy.md`: Performance optimization guide

## Best Practices

1. **Always use lowercase with underscores** for table/column names
2. **Enable pgvector extension** before creating vector columns
3. **Add indexes on foreign keys** for join performance
4. **Use generated columns** for computed fields (created_at, updated_at)
5. **Implement RLS policies** for security and multi-tenancy
6. **Version all migrations** with timestamps
7. **Use halfvec for embeddings** to save storage (16-bit vs 32-bit)
8. **Add metadata JSONB columns** for flexibility
9. **Plan for soft deletes** (deleted_at timestamp)
10. **Include audit trails** (created_by, updated_by)

## Common Workflows

### Setting Up a Chat Application
```bash
./scripts/generate-schema.sh chat schema.sql
./scripts/validate-schema.sh schema.sql
./scripts/apply-migration.sh schema.sql "initial-chat-schema"
./scripts/seed-data.sh chat
```

### Building a RAG System
```bash
./scripts/generate-schema.sh rag schema.sql
./scripts/validate-schema.sh schema.sql
./scripts/apply-migration.sh schema.sql "add-rag-storage"
./scripts/seed-data.sh rag
```

### Complete AI Platform
```bash
./scripts/generate-schema.sh complete schema.sql
./scripts/validate-schema.sh schema.sql
./scripts/apply-migration.sh schema.sql "complete-ai-platform"
```

## Troubleshooting

**pgvector not found**: Enable the vector extension in Supabase dashboard (Database > Extensions)

**RLS blocks queries**: Check RLS policies or temporarily disable for testing (not recommended for production)

**Slow similarity search**: Ensure HNSW index is created on vector columns with proper operator class

**Migration conflicts**: Check migration version ordering and resolve conflicts manually

---

**Skill Location**: /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/schema-patterns/
**Version**: 1.0.0
