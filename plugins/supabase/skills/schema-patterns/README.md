# Database Schema Patterns Skill

Production-ready PostgreSQL/Supabase database schemas for AI applications.

## Quick Start

```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/schema-patterns

# Generate schema
./scripts/generate-schema.sh <pattern-type> schema.sql

# Validate schema
./scripts/validate-schema.sh schema.sql

# Apply migration
./scripts/apply-migration.sh schema.sql "migration-name"

# Seed test data (optional)
./scripts/seed-data.sh <pattern-type>
```

## Available Patterns

- **chat**: Conversation and messaging systems
- **rag**: Document storage with vector embeddings (pgvector)
- **multi-tenant**: Organization-based multi-tenancy
- **user-management**: Extended user profiles and metadata
- **ai-usage**: Token tracking, costs, and rate limiting
- **complete**: All patterns combined

## Directory Structure

```
schema-patterns/
├── SKILL.md                 # Main skill documentation
├── README.md                # This file
├── scripts/                 # Functional scripts
│   ├── generate-schema.sh   # Generate schema from pattern
│   ├── validate-schema.sh   # Validate schema best practices
│   ├── apply-migration.sh   # Apply migration with validation
│   └── seed-data.sh         # Generate test data
├── templates/               # SQL schema templates
│   ├── chat-schema.sql
│   ├── rag-schema.sql
│   ├── multi-tenant-schema.sql
│   ├── user-management-schema.sql
│   ├── ai-usage-tracking-schema.sql
│   └── migration-template.sql
└── examples/                # Documentation and examples
    ├── complete-ai-app-schema.md
    ├── migration-guide.md
    └── indexing-strategy.md
```

## Example Usage

### Create a Chat Application Schema

```bash
# Generate chat schema
./scripts/generate-schema.sh chat chat-schema.sql

# Validate
./scripts/validate-schema.sh chat-schema.sql

# Apply
./scripts/apply-migration.sh chat-schema.sql "initial-chat-schema"

# Add test data
./scripts/seed-data.sh chat
```

### Build a RAG System

```bash
# Generate RAG schema with pgvector
./scripts/generate-schema.sh rag rag-schema.sql

# Validate (checks for pgvector extension and HNSW indexes)
./scripts/validate-schema.sh rag-schema.sql

# Apply
./scripts/apply-migration.sh rag-schema.sql "add-rag-storage"

# Seed with sample documents
./scripts/seed-data.sh rag
```

### Complete AI Platform

```bash
# Generate complete schema (all patterns)
./scripts/generate-schema.sh complete complete-schema.sql

# Validate
./scripts/validate-schema.sh complete-schema.sql

# Apply
./scripts/apply-migration.sh complete-schema.sql "complete-ai-platform"
```

## Features

### Chat Schema
- Users, conversations, messages, participants
- Message reactions and replies
- Typing indicators
- Full-text message search
- Unread message tracking
- RLS policies for privacy

### RAG Schema
- Document collections and storage
- Automatic chunking support
- pgvector integration (384, 768, 1536, 3072 dimensions)
- HNSW indexes for similarity search
- Hybrid search (semantic + keyword)
- Processing status tracking
- Query logging and analytics

### Multi-Tenant Schema
- Organizations and teams
- Role-based access control (owner, admin, member, viewer)
- Team membership management
- API key management
- Audit logging
- Invitation system

### User Management Schema
- Extended user profiles
- User preferences (JSONB)
- User metadata (key-value store)
- Session tracking
- Social connections (OAuth providers)
- Achievements/badges
- Activity logging
- Notifications
- User follows (social features)

### AI Usage Tracking Schema
- Detailed API usage records
- Token usage summaries (by hour/day/week/month)
- Cost tracking and breakdowns
- Usage quotas and limits
- Rate limiting
- Model pricing table
- Usage alerts
- Analytics functions

## Schema Validation

The `validate-schema.sh` script checks for:

- ✓ Proper naming conventions (lowercase, underscores)
- ✓ Primary keys on all tables
- ✓ Foreign key relationships with ON DELETE/ON UPDATE
- ✓ pgvector extension enabled (for RAG patterns)
- ✓ Vector indexes (HNSW or IVFFlat)
- ✓ Timestamp defaults
- ✓ UUID defaults
- ✓ Indexes on foreign keys
- ✓ RLS policies

## Documentation

- **SKILL.md**: Complete skill documentation with instructions
- **complete-ai-app-schema.md**: Full example combining all patterns
- **migration-guide.md**: Best practices for schema evolution
- **indexing-strategy.md**: Performance optimization guide

## Requirements

- PostgreSQL 12+ (for generated columns)
- Supabase CLI (optional, for automatic migration application)
- pgvector extension (for RAG patterns)

## Best Practices

1. Always use lowercase with underscores for table/column names
2. Enable pgvector extension before creating vector columns
3. Add indexes on foreign keys for join performance
4. Use generated columns for computed fields
5. Implement RLS policies for security and multi-tenancy
6. Version all migrations with timestamps
7. Use halfvec for embeddings to save storage
8. Add metadata JSONB columns for flexibility
9. Plan for soft deletes (deleted_at timestamp)
10. Include audit trails (created_by, updated_by)

## Troubleshooting

**pgvector not found**: Enable the vector extension in Supabase dashboard (Database > Extensions)

**RLS blocks queries**: Check RLS policies or temporarily disable for testing (not recommended for production)

**Slow similarity search**: Ensure HNSW index is created on vector columns with proper operator class

**Migration conflicts**: Check migration version ordering and resolve conflicts manually

## Version

1.0.0

## License

Part of the ai-dev-marketplace Supabase plugin
