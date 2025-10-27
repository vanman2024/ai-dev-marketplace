-- IVFFlat Index Configuration for pgvector
-- IVFFlat (Inverted File with Flat Compression) is better for large datasets
-- Best for: > 1M vectors, write-heavy workloads, lower memory requirements

-- Prerequisites:
-- 1. pgvector extension enabled
-- 2. Table with vector column exists
-- 3. Table has sufficient training data (recommended > 1000 rows)

-- Replace these variables:
-- {TABLE_NAME} - your table name
-- {DIMENSION} - vector dimension (must match your embedding model)
-- {LISTS} - number of lists (calculated below)

-- Calculate number of lists based on dataset size
-- Rule of thumb:
-- - Small datasets (< 100K): rows/1000
-- - Large datasets (> 100K): sqrt(rows)
-- - Minimum: 10 lists
-- - Maximum: rows/10

-- Drop existing index if present
DROP INDEX IF EXISTS {TABLE_NAME}_embedding_idx;

-- Create IVFFlat index with cosine distance
-- IMPORTANT: This index requires training on existing data
CREATE INDEX {TABLE_NAME}_embedding_idx ON {TABLE_NAME}
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = {LISTS});

-- Analyze table for query planner
ANALYZE {TABLE_NAME};

/*
PARAMETER TUNING GUIDE:

lists (calculated based on dataset size):
- Determines the number of clusters/partitions
- More lists = faster queries, lower recall
- Recommended values by dataset size:

  Rows        | Lists Formula  | Example
  ------------|----------------|--------
  1K - 10K    | rows/1000      | 10
  10K - 100K  | rows/1000      | 50-100
  100K - 1M   | sqrt(rows)     | 316-1000
  1M - 10M    | sqrt(rows)     | 1000-3162
  > 10M       | sqrt(rows)     | 3162+

QUERY-TIME TUNING:
Set probes to control recall vs speed tradeoff:

-- Higher recall, slower queries (scan more lists)
SET ivfflat.probes = 10;

-- Balanced (default: 1)
SET ivfflat.probes = 3;

-- Faster queries, lower recall
SET ivfflat.probes = 1;

RECALL vs SPEED:
- probes = 1: Fastest, ~60-70% recall
- probes = 10: Slower, ~90-95% recall
- probes = lists/10: ~98% recall (essentially brute force)

TRAINING REQUIREMENTS:
IVFFlat requires training data to create clusters:
- Minimum: 1000 rows
- Recommended: 10,000+ rows for good quality
- Training samples: Uses existing data in table

If table is empty or has few rows:
1. Insert representative sample data first
2. Create index (trains on sample)
3. Continue inserting remaining data

DISTANCE OPERATORS:
- <=> : Cosine distance (recommended for most embeddings)
- <#> : Negative inner product (for normalized vectors)
- <-> : Euclidean distance (L2)

To use inner product:
CREATE INDEX {TABLE_NAME}_embedding_idx ON {TABLE_NAME}
USING ivfflat (embedding vector_ip_ops)
WITH (lists = {LISTS});

To use L2 distance:
CREATE INDEX {TABLE_NAME}_embedding_idx ON {TABLE_NAME}
USING ivfflat (embedding vector_l2_ops)
WITH (lists = {LISTS});

MEMORY USAGE:
- Significantly lower than HNSW
- Approximately 1-2KB per vector
- For 1M vectors: ~1-2GB index size
- For 10M vectors: ~10-20GB index size

PERFORMANCE OPTIMIZATION:

1. Bulk Loading Strategy:
   -- Disable index during bulk insert
   DROP INDEX {TABLE_NAME}_embedding_idx;
   -- Insert all data
   COPY {TABLE_NAME} FROM 'data.csv';
   -- Rebuild index after loading
   CREATE INDEX ...;

2. Monitor index quality:
   -- Check list distribution
   SELECT count(*) FROM {TABLE_NAME};

3. Verify index usage:
   EXPLAIN ANALYZE
   SELECT * FROM {TABLE_NAME}
   ORDER BY embedding <=> '[0,1,2,...]'
   LIMIT 10;

4. Adjust probes dynamically:
   -- For high-precision queries
   SET LOCAL ivfflat.probes = 10;
   SELECT ...;

   -- For fast approximate queries
   SET LOCAL ivfflat.probes = 1;
   SELECT ...;

WHEN TO USE IVFFLAT:
✓ Dataset > 1M vectors
✓ Write-heavy workloads
✓ Limited memory
✓ Can tolerate lower recall (90-95%)
✓ Need faster inserts
✗ Small datasets (< 100K)
✗ Require 99%+ recall
✗ Empty or very sparse tables

COMPARISON: IVFFLAT vs HNSW

Metric          | IVFFlat      | HNSW
----------------|--------------|-------------
Build Time      | Fast         | Slow
Insert Speed    | Fast         | Slow
Query Speed     | Medium       | Fast
Recall          | 90-95%       | 95-99%
Memory Usage    | Low          | High
Best Dataset    | > 1M         | < 1M
Training        | Required     | Not required

MIGRATION FROM HNSW:
If switching from HNSW to IVFFlat:
1. DROP INDEX {TABLE_NAME}_embedding_idx;
2. CREATE INDEX ... USING ivfflat ...;
3. Test query performance and recall
4. Adjust lists and probes parameters
5. Update application queries if needed

See templates/hnsw-index-config.sql for HNSW alternative
*/
