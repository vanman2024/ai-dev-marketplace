# Vector Database Configurations Skill

Comprehensive vector database configuration skill for RAG pipelines supporting 6 major vector databases.

## Overview

This skill provides everything needed to set up, configure, and optimize vector databases for RAG (Retrieval-Augmented Generation) pipelines. It includes functional setup scripts, configuration templates, migration guides, and performance tuning documentation.

## Supported Databases

1. **pgvector** - PostgreSQL extension for vector storage
2. **Chroma** - Embedded vector database for development
3. **Pinecone** - Managed cloud vector database
4. **Weaviate** - GraphQL-based vector database
5. **Qdrant** - High-performance vector database with filtering
6. **FAISS** - Meta's vector search library

## Directory Structure

```
vector-database-configs/
├── SKILL.md                           # Main skill documentation with comparison
├── README.md                          # This file
├── scripts/                           # Functional setup scripts
│   ├── setup-pgvector.sh             # PostgreSQL pgvector setup
│   ├── setup-chroma.sh               # Chroma setup and initialization
│   ├── setup-pinecone.sh             # Pinecone cloud setup
│   ├── setup-weaviate.sh             # Weaviate Docker/cloud setup
│   ├── setup-qdrant.sh               # Qdrant setup (Docker/local/cloud)
│   └── setup-faiss.sh                # FAISS installation and config
├── templates/                         # Configuration templates
│   ├── pgvector-schema.sql           # SQL schema with indexes
│   ├── chroma-config.py              # Python configuration
│   ├── pinecone-config.py            # Python configuration
│   ├── weaviate-schema.py            # Python schema definition
│   ├── qdrant-config.py              # Python configuration
│   └── faiss-config.py               # Python index factory
└── examples/                          # Migration and tuning guides
    ├── migration-guide.md            # Database migration procedures
    └── performance-tuning.md         # Performance optimization guide
```

## Quick Start

### 1. Choose Your Database

Read `SKILL.md` for detailed comparison table and selection guide based on:
- Scale requirements (number of vectors)
- Infrastructure preferences (self-hosted vs managed)
- Budget constraints
- Feature needs (filtering, GraphQL, etc.)

### 2. Run Setup Script

All scripts are executable and fully functional:

```bash
# PostgreSQL pgvector
bash scripts/setup-pgvector.sh --database mydb --dimensions 1536

# Chroma (local)
bash scripts/setup-chroma.sh --persist-dir ./chroma_data

# Pinecone (cloud)
export PINECONE_API_KEY="your-key"
bash scripts/setup-pinecone.sh --index production --dimensions 1536

# Weaviate (Docker)
bash scripts/setup-weaviate.sh --mode docker

# Qdrant (Docker)
bash scripts/setup-qdrant.sh --mode docker --collection documents

# FAISS (local)
bash scripts/setup-faiss.sh --index-type HNSW --dimensions 1536
```

### 3. Use Configuration Templates

Copy and customize templates for your application:

```bash
# PostgreSQL
psql -U postgres -d mydb -f templates/pgvector-schema.sql

# Python-based databases
cp templates/chroma-config.py ./config/vector_db.py
# Edit and integrate into your application
```

### 4. Optimize Performance

See `examples/performance-tuning.md` for:
- Index type selection by dataset size
- Parameter tuning (m, ef, nprobe)
- Query optimization techniques
- Hardware recommendations
- Benchmarking templates

## Features

### Setup Scripts

All scripts include:
- ✅ Dependency checking
- ✅ Connection validation
- ✅ Sample data insertion
- ✅ Helpful error messages
- ✅ Configuration recommendations
- ✅ Usage examples

### Configuration Templates

All templates provide:
- ✅ Client initialization
- ✅ Collection/index creation
- ✅ CRUD operations
- ✅ Query examples
- ✅ Metadata filtering
- ✅ Batch operations
- ✅ Error handling

### Migration Support

Detailed guides for common paths:
- Chroma → pgvector
- pgvector → Pinecone
- Pinecone → Qdrant
- Weaviate → FAISS
- FAISS → Qdrant
- Any → Chroma

### Performance Tuning

Comprehensive optimization guides:
- Index selection by scale
- Parameter tuning
- Query optimization
- Hardware sizing
- Monitoring templates
- Benchmarking code

## Usage Examples

### Example 1: Set Up pgvector for Production

```bash
# 1. Run setup script
bash scripts/setup-pgvector.sh \
  --database production_rag \
  --user postgres \
  --dimensions 1536 \
  --index-type hnsw \
  --distance cosine

# 2. Apply schema
psql -U postgres -d production_rag -f templates/pgvector-schema.sql

# 3. Configure PostgreSQL (see output recommendations)

# 4. Start inserting vectors
```

### Example 2: Migrate from Chroma to Qdrant

```bash
# 1. Set up Qdrant
bash scripts/setup-qdrant.sh --mode docker --collection documents

# 2. Follow migration guide
# See examples/migration-guide.md → "Chroma to Qdrant" section

# 3. Validate migration
# Run validation scripts from migration guide

# 4. Update application config

# 5. Monitor performance
```

### Example 3: Optimize FAISS Performance

```bash
# 1. Choose index type based on dataset size
# See examples/performance-tuning.md

# 2. For 1M vectors, use HNSW
bash scripts/setup-faiss.sh \
  --index-type HNSW \
  --dimensions 1536 \
  --m 32

# 3. Benchmark
python templates/faiss-config.py  # See usage examples in template

# 4. Tune parameters
# Adjust M and efSearch based on recall/speed tradeoff
```

## Database Comparison Quick Reference

| Database  | Best For              | Scale        | Hosting       | Cost      |
|-----------|-----------------------|--------------|---------------|-----------|
| pgvector  | PostgreSQL users      | Millions     | Self/managed  | Low       |
| Chroma    | Development, local    | Millions     | Embedded      | Free      |
| Pinecone  | Production, managed   | Billions     | Cloud only    | Paid      |
| Weaviate  | GraphQL, hybrid       | Billions     | Self/cloud    | Free/paid |
| Qdrant    | Performance, filters  | Billions     | Self/cloud    | Free/paid |
| FAISS     | Research, max perf    | Billions     | Self-managed  | Free      |

## Integration with RAG Pipeline

This skill is part of the `rag-pipeline` plugin and integrates with:

- **document-chunking** → Generates chunks to be embedded
- **embedding-models** → Generates vectors to be stored
- **vector-database-configs** → Stores and retrieves vectors ← YOU ARE HERE
- **retrieval-strategies** → Queries vector database for context

## Common Commands

```bash
# Get help for any setup script
bash scripts/setup-pgvector.sh --help
bash scripts/setup-chroma.sh --help
bash scripts/setup-pinecone.sh --help

# Check database status
# pgvector: psql -U postgres -c "SELECT count(*) FROM documents;"
# Chroma: python -c "import chromadb; print(chromadb.PersistentClient().heartbeat())"
# Qdrant: curl http://localhost:6333/collections

# Benchmark performance
# See templates for language-specific benchmarking code
```

## Troubleshooting

### Scripts

**Issue**: Permission denied
**Solution**: `chmod +x scripts/*.sh`

**Issue**: Dependency not found
**Solution**: Follow error message instructions for installation

### Configuration

**Issue**: Connection refused
**Solution**: Verify database is running, check host/port

**Issue**: Index build fails
**Solution**: Increase memory allocation, reduce batch size

### Performance

**Issue**: Slow queries
**Solution**: See `examples/performance-tuning.md` for optimization steps

**Issue**: Out of memory
**Solution**: Use quantization (IVF+PQ), reduce index parameters

## Resources

### Documentation Links

- pgvector: https://github.com/pgvector/pgvector
- Chroma: https://docs.trychroma.com/
- Pinecone: https://docs.pinecone.io/
- Weaviate: https://weaviate.io/developers/weaviate
- Qdrant: https://qdrant.tech/documentation/
- FAISS: https://faiss.ai/

### Files in This Skill

- `SKILL.md` - Main documentation, database comparison, selection guide
- `examples/migration-guide.md` - Database migration procedures
- `examples/performance-tuning.md` - Performance optimization guide
- `scripts/setup-*.sh` - Functional setup scripts for each database
- `templates/*-config.*` - Configuration templates for each database

## Contributing

When updating this skill:

1. Keep scripts functional and tested
2. Update SKILL.md comparison table if database features change
3. Add new migration paths to migration-guide.md
4. Update performance recommendations based on real benchmarks
5. Ensure all examples work with current database versions

## Skill Metadata

- **Name**: vector-database-configs
- **Plugin**: rag-pipeline
- **Allowed Tools**: Bash, Read, Write, Edit, Grep, Glob
- **Total Files**: 15 (1 skill manifest, 6 scripts, 6 templates, 2 examples)
- **Total Lines**: ~6,500 lines of functional code and documentation

---

**Note**: All scripts are production-ready and fully functional. All templates are complete with working examples. All guides include detailed procedures and validation steps.
