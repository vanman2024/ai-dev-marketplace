# pgvector Setup - Quick Start Guide

## 1-Minute Setup

```bash
# Set your database URL
export SUPABASE_DB_URL="postgresql://postgres:password@db.project.supabase.co:5432/postgres"

# Run the complete setup
cd /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/pgvector-setup

# Step 1: Enable pgvector (5 seconds)
bash scripts/setup-pgvector.sh

# Step 2: Create embedding table (10 seconds)
psql $SUPABASE_DB_URL < templates/embedding-table-schema.sql

# Step 3: Create HNSW index (10 seconds for small tables)
bash scripts/create-indexes.sh hnsw documents 1536

# Step 4: Test setup (5 seconds)
bash scripts/test-vector-search.sh documents
```

Expected output:
```
[PASS] pgvector extension enabled
[PASS] Table 'documents' exists
[PASS] Embedding column exists
[PASS] Vector index exists (type: hnsw)
[PASS] All tests passed! Vector search is configured correctly.
```

## Next Steps

### For RAG Applications
See: `examples/document-search-pattern.md`

### For Semantic Search
See: `examples/vector-search-examples.md`

### For Hybrid Search (Semantic + Keyword)
```bash
bash scripts/setup-hybrid-search.sh documents
```

## Common Commands

```bash
# Create different index types
bash scripts/create-indexes.sh hnsw documents 1536    # Fast queries
bash scripts/create-indexes.sh ivfflat documents 1536 # Large datasets

# Test performance
bash scripts/test-vector-search.sh documents

# View all available templates
ls -lh templates/

# View all examples
ls -lh examples/
```

## Choosing Embedding Dimensions

| Model | Dimension | Command |
|-------|-----------|---------|
| OpenAI text-embedding-3-small | 1536 | `bash scripts/create-indexes.sh hnsw documents 1536` |
| OpenAI text-embedding-3-large | 3072 | `bash scripts/create-indexes.sh hnsw documents 3072` |
| Cohere embed-english-v3.0 | 1024 | `bash scripts/create-indexes.sh hnsw documents 1024` |

## Troubleshooting

### "pgvector extension not found"
```bash
# Re-run setup
bash scripts/setup-pgvector.sh

# Verify manually
psql $SUPABASE_DB_URL -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
```

### "No vector index found"
```bash
# Create index
bash scripts/create-indexes.sh hnsw documents 1536

# Verify
psql $SUPABASE_DB_URL -c "\di documents_embedding_idx"
```

### "Slow queries"
```bash
# Run diagnostics
bash scripts/test-vector-search.sh documents

# Check if index is being used
psql $SUPABASE_DB_URL -c "EXPLAIN ANALYZE SELECT * FROM documents ORDER BY embedding <=> '[...]' LIMIT 10;"
```

## Documentation

- **SKILL.md**: Complete setup guide (6 phases)
- **README.md**: Full documentation
- **examples/embedding-strategies.md**: Index selection guide
- **examples/vector-search-examples.md**: Code patterns
- **examples/document-search-pattern.md**: Full RAG implementation
