-- HNSW Index Configuration for pgvector
-- HNSW (Hierarchical Navigable Small World) is recommended for most use cases
-- Best for: < 1M vectors, high recall requirements, read-heavy workloads

-- Prerequisites:
-- 1. pgvector extension enabled
-- 2. Table with vector column exists

-- Replace these variables:
-- {TABLE_NAME} - your table name
-- {DIMENSION} - vector dimension (must match your embedding model)

-- Drop existing index if present
DROP INDEX IF EXISTS {TABLE_NAME}_embedding_idx;

-- Create HNSW index with cosine distance
CREATE INDEX {TABLE_NAME}_embedding_idx ON {TABLE_NAME}
USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,              -- Number of connections per layer
    ef_construction = 64 -- Size of dynamic candidate list during construction
);

-- Analyze table for query planner
ANALYZE {TABLE_NAME};

/*
PARAMETER TUNING GUIDE:

m (default: 16, range: 2-100):
- Controls the number of bi-directional links per node
- Higher m = better recall, more memory usage
- Recommended values:
  - 8-12: Low memory, acceptable recall
  - 16: Balanced (default)
  - 32-48: High recall, more memory

ef_construction (default: 64, range: 4-1000):
- Size of dynamic candidate list during index building
- Higher ef_construction = better index quality, slower build time
- Recommended values:
  - 32: Faster build, lower quality
  - 64: Balanced (default)
  - 128-200: High quality, slower build

MEMORY USAGE:
- Approximately 10KB per vector for m=16
- For 100K vectors: ~1GB index size
- For 1M vectors: ~10GB index size

QUERY-TIME TUNING:
Set ef_search to control recall vs speed tradeoff at query time:

-- Higher recall, slower queries
SET hnsw.ef_search = 100;

-- Balanced (default: 40)
SET hnsw.ef_search = 40;

-- Faster queries, lower recall
SET hnsw.ef_search = 20;

DISTANCE OPERATORS:
- <=> : Cosine distance (recommended for normalized vectors like OpenAI)
- <#> : Negative inner product (faster for normalized vectors)
- <-> : Euclidean distance (L2)

To use inner product instead of cosine:
CREATE INDEX {TABLE_NAME}_embedding_idx ON {TABLE_NAME}
USING hnsw (embedding vector_ip_ops);

To use L2 distance:
CREATE INDEX {TABLE_NAME}_embedding_idx ON {TABLE_NAME}
USING hnsw (embedding vector_l2_ops);

PERFORMANCE TIPS:
1. Build index AFTER loading data, not during inserts
2. For bulk loads: disable index, insert data, rebuild index
3. Monitor index size: SELECT pg_size_pretty(pg_relation_size('{TABLE_NAME}_embedding_idx'));
4. Use EXPLAIN ANALYZE to verify index is being used
5. Consider partial indexes if querying subset: WHERE user_id = $1

WHEN TO USE HNSW:
✓ Dataset < 1M vectors
✓ Read-heavy workloads
✓ High recall requirements (> 95%)
✓ Memory is available
✗ Very large datasets (> 10M vectors)
✗ Write-heavy workloads
✗ Limited memory

If you have > 1M vectors or write-heavy workload, consider IVFFlat:
See templates/ivfflat-index-config.sql
*/
