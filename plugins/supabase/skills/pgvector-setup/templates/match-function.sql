-- Basic Semantic Search Match Function
-- Returns most similar documents based on vector cosine similarity
-- This is the foundation for semantic search in Supabase

-- Prerequisites:
-- 1. Table with vector column exists
-- 2. Vector index created (HNSW or IVFFlat)

-- Replace these variables:
-- {TABLE_NAME} - your table name
-- {DIMENSION} - vector dimension (e.g., 1536 for OpenAI)

-- Drop existing function if present
DROP FUNCTION IF EXISTS match_{TABLE_NAME};

-- Create match function for semantic search
CREATE OR REPLACE FUNCTION match_{TABLE_NAME}(
    query_embedding vector({DIMENSION}),
    match_threshold FLOAT DEFAULT 0.78,
    match_count INT DEFAULT 10
)
RETURNS TABLE(
    id BIGINT,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        {TABLE_NAME}.id,
        {TABLE_NAME}.content,
        {TABLE_NAME}.metadata,
        1 - ({TABLE_NAME}.embedding <=> query_embedding) AS similarity
    FROM {TABLE_NAME}
    WHERE 1 - ({TABLE_NAME}.embedding <=> query_embedding) > match_threshold
    ORDER BY {TABLE_NAME}.embedding <=> query_embedding
    LIMIT least(match_count, 200);
$$;

/*
USAGE FROM APPLICATION CODE:

JavaScript/TypeScript (Supabase Client):
```javascript
const { data, error } = await supabase.rpc('match_{TABLE_NAME}', {
    query_embedding: embedding,        // array of numbers
    match_threshold: 0.78,            // 0.0 to 1.0
    match_count: 10                   // max results
});
```

Python (Supabase Client):
```python
response = supabase.rpc(
    'match_{TABLE_NAME}',
    {
        'query_embedding': embedding,   # list of floats
        'match_threshold': 0.78,       # 0.0 to 1.0
        'match_count': 10              # max results
    }
).execute()
```

SQL (Direct):
```sql
SELECT * FROM match_{TABLE_NAME}(
    query_embedding := '[0.1, 0.2, ..., 0.5]',
    match_threshold := 0.78,
    match_count := 10
);
```

PARAMETER EXPLANATION:

query_embedding (required):
- Vector to search for
- Must be same dimension as table vectors
- Generate using your embedding model (OpenAI, Cohere, etc.)

match_threshold (default: 0.78):
- Minimum similarity score (0.0 to 1.0)
- Higher = more similar, fewer results
- Lower = less similar, more results
- Recommended ranges:
  - 0.5-0.7: Broad search, many results
  - 0.7-0.8: Balanced (default)
  - 0.8-0.9: High relevance, fewer results
  - 0.9+: Very strict matching

match_count (default: 10):
- Maximum number of results to return
- Capped at 200 for performance
- Consider pagination for large result sets

SIMILARITY SCORING:

The function returns similarity as: 1 - cosine_distance

- 1.0 = identical vectors
- 0.9+ = very similar
- 0.7-0.9 = moderately similar
- 0.5-0.7 = somewhat similar
- < 0.5 = not very similar

Cosine similarity formula:
similarity = 1 - (A · B) / (||A|| × ||B||)

ADVANCED CUSTOMIZATIONS:

1. Add user filtering:
CREATE OR REPLACE FUNCTION match_{TABLE_NAME}(
    query_embedding vector({DIMENSION}),
    match_threshold FLOAT DEFAULT 0.78,
    match_count INT DEFAULT 10,
    filter_user_id UUID DEFAULT NULL
)
RETURNS TABLE(...) AS $$
    SELECT ...
    FROM {TABLE_NAME}
    WHERE
        1 - ({TABLE_NAME}.embedding <=> query_embedding) > match_threshold
        AND (filter_user_id IS NULL OR {TABLE_NAME}.user_id = filter_user_id)
    ...
$$;

2. Add metadata filtering:
CREATE OR REPLACE FUNCTION match_{TABLE_NAME}(
    query_embedding vector({DIMENSION}),
    match_threshold FLOAT DEFAULT 0.78,
    match_count INT DEFAULT 10,
    filter_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE(...) AS $$
    SELECT ...
    FROM {TABLE_NAME}
    WHERE
        1 - ({TABLE_NAME}.embedding <=> query_embedding) > match_threshold
        AND {TABLE_NAME}.metadata @> filter_metadata
    ...
$$;

3. Add date range filtering:
CREATE OR REPLACE FUNCTION match_{TABLE_NAME}(
    query_embedding vector({DIMENSION}),
    match_threshold FLOAT DEFAULT 0.78,
    match_count INT DEFAULT 10,
    start_date TIMESTAMP DEFAULT NULL,
    end_date TIMESTAMP DEFAULT NULL
)
RETURNS TABLE(...) AS $$
    SELECT ...
    FROM {TABLE_NAME}
    WHERE
        1 - ({TABLE_NAME}.embedding <=> query_embedding) > match_threshold
        AND (start_date IS NULL OR {TABLE_NAME}.created_at >= start_date)
        AND (end_date IS NULL OR {TABLE_NAME}.created_at <= end_date)
    ...
$$;

4. Return additional columns:
RETURNS TABLE(
    id BIGINT,
    content TEXT,
    metadata JSONB,
    similarity FLOAT,
    created_at TIMESTAMP,
    user_id UUID
)

5. Use different distance metrics:

Inner product (faster for normalized vectors):
CREATE OR REPLACE FUNCTION match_{TABLE_NAME}(...) AS $$
    SELECT
        ...,
        ({TABLE_NAME}.embedding <#> query_embedding) * -1 AS similarity
    FROM {TABLE_NAME}
    ORDER BY {TABLE_NAME}.embedding <#> query_embedding
    ...
$$;

Euclidean distance (L2):
CREATE OR REPLACE FUNCTION match_{TABLE_NAME}(...) AS $$
    SELECT
        ...,
        1 / (1 + ({TABLE_NAME}.embedding <-> query_embedding)) AS similarity
    FROM {TABLE_NAME}
    ORDER BY {TABLE_NAME}.embedding <-> query_embedding
    ...
$$;

PERFORMANCE TIPS:

1. Ensure vector index exists:
-- Check if index is being used
EXPLAIN ANALYZE
SELECT * FROM match_{TABLE_NAME}('[...]', 0.78, 10);

-- Should show "Index Scan using {TABLE_NAME}_embedding_idx"

2. Adjust match_count limit:
-- Lower limit = faster queries
-- Higher limit = more comprehensive results
-- Maximum capped at 200 to prevent slow queries

3. Pre-filter with WHERE clauses:
-- Add indexed columns to WHERE clause
-- Filter before similarity calculation
-- Use composite indexes if filtering by multiple columns

4. Monitor query performance:
SELECT
    query,
    mean_exec_time,
    calls
FROM pg_stat_statements
WHERE query LIKE '%match_{TABLE_NAME}%'
ORDER BY mean_exec_time DESC;

SECURITY CONSIDERATIONS:

1. Enable RLS on table:
-- Function respects RLS policies automatically
ALTER TABLE {TABLE_NAME} ENABLE ROW LEVEL SECURITY;

2. Grant execute permission:
GRANT EXECUTE ON FUNCTION match_{TABLE_NAME} TO authenticated;

3. Limit match_count:
-- Prevent resource exhaustion
LIMIT least(match_count, 200);

ERROR HANDLING:

Common errors and solutions:

1. "vector must be same length"
   - Ensure query_embedding dimension matches table
   - Check embedding model output dimension

2. "Index scan not used"
   - Create index: scripts/create-indexes.sh
   - Analyze table: ANALYZE {TABLE_NAME};

3. "No results returned"
   - Lower match_threshold
   - Check if embeddings exist in table
   - Verify query_embedding is valid

4. "Query too slow"
   - Create/rebuild index
   - Reduce match_count
   - Add WHERE clause filters
   - Check EXPLAIN ANALYZE output

TESTING:

1. Test with known similar documents:
-- Get embedding from existing document
WITH test_doc AS (
    SELECT embedding FROM {TABLE_NAME} WHERE id = 123
)
SELECT * FROM match_{TABLE_NAME}(
    (SELECT embedding FROM test_doc),
    0.7,
    5
);

2. Benchmark performance:
EXPLAIN ANALYZE
SELECT * FROM match_{TABLE_NAME}('[...]', 0.78, 10);

3. Test threshold ranges:
-- Try different thresholds
SELECT match_threshold, COUNT(*) as result_count
FROM generate_series(0.5, 0.95, 0.05) as match_threshold
CROSS JOIN LATERAL (
    SELECT * FROM match_{TABLE_NAME}('[...]', match_threshold, 100)
) results
GROUP BY match_threshold
ORDER BY match_threshold;

See examples/vector-search-examples.md for more patterns
*/
