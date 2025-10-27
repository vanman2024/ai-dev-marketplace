# pgvector Setup Skill

Complete pgvector configuration for Supabase databases, enabling vector search capabilities for AI applications, RAG systems, and semantic search.

## Quick Start

```bash
# 1. Enable pgvector extension
bash scripts/setup-pgvector.sh $SUPABASE_DB_URL

# 2. Create embedding table
psql $SUPABASE_DB_URL < templates/embedding-table-schema.sql

# 3. Create vector index (choose HNSW or IVFFlat)
bash scripts/create-indexes.sh hnsw documents 1536 $SUPABASE_DB_URL

# 4. Optional: Setup hybrid search
bash scripts/setup-hybrid-search.sh documents $SUPABASE_DB_URL

# 5. Test setup
bash scripts/test-vector-search.sh documents $SUPABASE_DB_URL
```

## Directory Structure

```
pgvector-setup/
├── SKILL.md                          # Main skill documentation
├── README.md                         # This file
├── scripts/                          # Automation scripts
│   ├── setup-pgvector.sh            # Enable pgvector extension
│   ├── create-indexes.sh            # Create HNSW/IVFFlat indexes
│   ├── setup-hybrid-search.sh       # Configure hybrid search
│   └── test-vector-search.sh        # Validate setup
├── templates/                        # SQL templates
│   ├── embedding-table-schema.sql   # Table structure with RLS
│   ├── hnsw-index-config.sql        # HNSW index configuration
│   ├── ivfflat-index-config.sql     # IVFFlat index configuration
│   ├── hybrid-search-function.sql   # Hybrid search with RRF
│   └── match-function.sql           # Basic semantic search
└── examples/                         # Implementation patterns
    ├── embedding-strategies.md      # Index selection guide
    ├── vector-search-examples.md    # Common search patterns
    └── document-search-pattern.md   # Complete implementation
```

## Features

### Scripts
- **setup-pgvector.sh**: Enables pgvector extension and validates installation
- **create-indexes.sh**: Creates HNSW or IVFFlat indexes with optimal parameters
- **setup-hybrid-search.sh**: Configures hybrid search combining semantic + keyword
- **test-vector-search.sh**: Validates setup and measures performance

### Templates
- **embedding-table-schema.sql**: Production-ready table with RLS policies
- **hnsw-index-config.sql**: HNSW index with tuning guide
- **ivfflat-index-config.sql**: IVFFlat index with parameter recommendations
- **hybrid-search-function.sql**: RRF-based hybrid search
- **match-function.sql**: Basic semantic search function

### Examples
- **embedding-strategies.md**: HNSW vs IVFFlat decision matrix, model selection
- **vector-search-examples.md**: 9+ search patterns with code
- **document-search-pattern.md**: Complete RAG implementation

## Use Cases

### RAG (Retrieval Augmented Generation)
```bash
# Setup document chunks table
psql $SUPABASE_DB_URL < templates/embedding-table-schema.sql

# Create HNSW index for fast retrieval
bash scripts/create-indexes.sh hnsw documents 1536

# See examples/document-search-pattern.md for full implementation
```

### Semantic Search
```bash
# Basic setup
bash scripts/setup-pgvector.sh
psql $SUPABASE_DB_URL < templates/embedding-table-schema.sql
bash scripts/create-indexes.sh hnsw documents 1536

# See examples/vector-search-examples.md for query patterns
```

### Hybrid Search (Semantic + Keyword)
```bash
# Setup both vector and full-text search
bash scripts/setup-hybrid-search.sh documents

# See templates/hybrid-search-function.sql for usage
```

## Index Selection Guide

| Dataset Size | Write Frequency | Memory Available | Recommended Index |
|--------------|-----------------|------------------|-------------------|
| < 100K       | Any            | Any              | HNSW             |
| 100K - 1M    | Low/Medium     | 16GB+            | HNSW             |
| 100K - 1M    | High           | Limited          | IVFFlat          |
| > 1M         | Any            | Limited          | IVFFlat          |
| > 1M         | Low            | 64GB+            | HNSW (if memory available) |

**See examples/embedding-strategies.md for detailed decision matrix**

## Embedding Model Recommendations

| Model | Dimension | Use Case | Cost |
|-------|-----------|----------|------|
| OpenAI text-embedding-3-small | 1536 | General purpose (recommended) | $0.02/1M tokens |
| OpenAI text-embedding-3-large | 3072 | High accuracy | $0.13/1M tokens |
| Cohere embed-english-v3.0 | 1024 | Cost-sensitive | $0.10/1M tokens |
| Sentence Transformers | 384-768 | Self-hosted/privacy | Free |

**See examples/embedding-strategies.md for complete guide**

## Performance Benchmarks

### HNSW Index
- Query time: 1-10ms
- Insert time: 10-100ms
- Recall: 95-99%
- Memory: ~10KB per vector

### IVFFlat Index
- Query time: 10-50ms
- Insert time: 1-10ms
- Recall: 90-95%
- Memory: ~1-2KB per vector

## Common Issues

### Slow Queries
1. Check if index exists: `bash scripts/test-vector-search.sh documents`
2. Verify index is being used: `EXPLAIN ANALYZE SELECT ...`
3. Tune HNSW ef_search or IVFFlat probes
4. See SKILL.md troubleshooting section

### Poor Recall
1. Lower match_threshold (e.g., 0.7 instead of 0.8)
2. Increase HNSW m/ef_construction parameters
3. Increase IVFFlat probes parameter
4. Verify embeddings are normalized

### High Memory Usage
1. Switch from HNSW to IVFFlat
2. Reduce HNSW m parameter
3. Use partial indexes for subset of data
4. See examples/embedding-strategies.md optimization section

## Environment Variables

```bash
# Set Supabase DB URL
export SUPABASE_DB_URL="postgresql://user:pass@host:5432/database"

# For Edge Functions (processing documents)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
export OPENAI_API_KEY="sk-..."
```

## Documentation

- **SKILL.md**: Complete skill documentation with 6-phase setup guide
- **examples/embedding-strategies.md**: Index selection, model selection, tuning
- **examples/vector-search-examples.md**: 9+ search patterns with code examples
- **examples/document-search-pattern.md**: Full RAG implementation with Edge Functions

## Testing

```bash
# Validate complete setup
bash scripts/test-vector-search.sh documents

# Expected output:
# [PASS] pgvector extension enabled
# [PASS] Table 'documents' exists
# [PASS] Embedding column exists
# [PASS] Vector index exists (type: hnsw)
# [PASS] Query performance: EXCELLENT (< 100ms)
```

## Security

All templates include:
- Row Level Security (RLS) policies
- User isolation (user_id filtering)
- Service role vs authenticated role separation
- No hardcoded credentials

See templates/embedding-table-schema.sql for RLS examples.

## Contributing

When extending this skill:
1. Keep scripts focused and single-purpose
2. Include error handling and validation
3. Add usage examples to templates
4. Update this README with new patterns
5. Test with multiple embedding dimensions

## References

- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [Supabase Vector Docs](https://supabase.com/docs/guides/ai)
- [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings)
- [HNSW Paper](https://arxiv.org/abs/1603.09320)
- [Reciprocal Rank Fusion](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf)

## License

Part of the ai-dev-marketplace plugin framework.

## Version

1.0.0 - Initial release (2025-10-26)
