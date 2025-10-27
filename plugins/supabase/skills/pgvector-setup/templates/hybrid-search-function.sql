-- Hybrid Search Function using RRF (Reciprocal Rank Fusion)
-- Combines semantic (vector) search with keyword (full-text) search
-- Uses weighted scoring to balance both search methods

-- Prerequisites:
-- 1. Table has 'embedding' vector column
-- 2. Table has 'fts' tsvector column (or 'content' text column)
-- 3. Vector index exists (HNSW or IVFFlat)
-- 4. GIN index exists on fts column

-- Replace these variables:
-- {TABLE_NAME} - your table name
-- {DIMENSION} - vector dimension (e.g., 1536 for OpenAI)

-- Drop existing function if present
DROP FUNCTION IF EXISTS {TABLE_NAME}_hybrid_search;

-- Create hybrid search function
CREATE OR REPLACE FUNCTION {TABLE_NAME}_hybrid_search(
    query_text TEXT,
    query_embedding vector({DIMENSION}),
    match_count INT DEFAULT 10,
    full_text_weight FLOAT DEFAULT 1.0,
    semantic_weight FLOAT DEFAULT 1.0,
    rrf_k INT DEFAULT 50
)
RETURNS TABLE(
    id BIGINT,
    content TEXT,
    similarity FLOAT,
    fts_rank FLOAT,
    hybrid_score FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH semantic_search AS (
        -- Semantic search using vector similarity
        SELECT
            {TABLE_NAME}.id,
            {TABLE_NAME}.content,
            1 - ({TABLE_NAME}.embedding <=> query_embedding) AS similarity,
            ROW_NUMBER() OVER (ORDER BY {TABLE_NAME}.embedding <=> query_embedding) AS rank
        FROM {TABLE_NAME}
        ORDER BY {TABLE_NAME}.embedding <=> query_embedding
        LIMIT least(match_count * 2, 1000) -- Fetch more for better fusion
    ),
    fulltext_search AS (
        -- Full-text search using tsvector
        SELECT
            {TABLE_NAME}.id,
            {TABLE_NAME}.content,
            ts_rank({TABLE_NAME}.fts, websearch_to_tsquery('english', query_text)) AS fts_rank,
            ROW_NUMBER() OVER (
                ORDER BY ts_rank({TABLE_NAME}.fts, websearch_to_tsquery('english', query_text)) DESC
            ) AS rank
        FROM {TABLE_NAME}
        WHERE {TABLE_NAME}.fts @@ websearch_to_tsquery('english', query_text)
        ORDER BY fts_rank DESC
        LIMIT least(match_count * 2, 1000) -- Fetch more for better fusion
    )
    -- Combine results using Reciprocal Rank Fusion (RRF)
    SELECT
        COALESCE(semantic_search.id, fulltext_search.id) AS id,
        COALESCE(semantic_search.content, fulltext_search.content) AS content,
        COALESCE(semantic_search.similarity, 0.0) AS similarity,
        COALESCE(fulltext_search.fts_rank, 0.0) AS fts_rank,
        -- RRF formula: sum of 1/(k + rank) for each search method
        (
            COALESCE(1.0 / (rrf_k + semantic_search.rank), 0.0) * semantic_weight +
            COALESCE(1.0 / (rrf_k + fulltext_search.rank), 0.0) * full_text_weight
        ) AS hybrid_score
    FROM semantic_search
    FULL OUTER JOIN fulltext_search ON semantic_search.id = fulltext_search.id
    ORDER BY hybrid_score DESC
    LIMIT match_count;
END;
$$;

/*
USAGE EXAMPLES:

1. Balanced hybrid search (equal weights):
SELECT * FROM {TABLE_NAME}_hybrid_search(
    'machine learning algorithms',
    query_embedding,
    match_count := 10,
    full_text_weight := 1.0,
    semantic_weight := 1.0
);

2. Prioritize semantic search:
SELECT * FROM {TABLE_NAME}_hybrid_search(
    'natural language processing',
    query_embedding,
    match_count := 10,
    full_text_weight := 0.5,
    semantic_weight := 1.0
);

3. Prioritize keyword search:
SELECT * FROM {TABLE_NAME}_hybrid_search(
    'PostgreSQL database optimization',
    query_embedding,
    match_count := 10,
    full_text_weight := 1.0,
    semantic_weight := 0.5
);

PARAMETER TUNING:

match_count (default: 10):
- Number of final results to return
- Internally fetches 2x this amount for better fusion

full_text_weight (default: 1.0):
- Weight for keyword matching
- Increase for: technical docs, code, exact terms
- Decrease for: conversational queries, concepts

semantic_weight (default: 1.0):
- Weight for semantic similarity
- Increase for: conceptual queries, synonyms, context
- Decrease for: exact keyword matching needs

rrf_k (default: 50):
- RRF smoothing constant
- Higher k = less weight to top-ranked items
- Lower k = more weight to top-ranked items
- Typical range: 20-100

RRF SCORING EXPLAINED:

For each document, hybrid_score is calculated as:
  score = (1/(k + semantic_rank)) * semantic_weight +
          (1/(k + fulltext_rank)) * full_text_weight

Example with k=50:
- Document ranked 1st in both: 1/51 + 1/51 = 0.0392
- Document ranked 1st semantic, 10th fulltext: 1/51 + 1/60 = 0.0363
- Document ranked 10th in both: 1/60 + 1/60 = 0.0333

ADVANCED CUSTOMIZATIONS:

1. Add user filtering:
WHERE {TABLE_NAME}.user_id = $user_id

2. Add metadata filtering:
WHERE {TABLE_NAME}.metadata->>'category' = $category

3. Use different distance metrics:
-- Inner product (for normalized vectors)
1 - ({TABLE_NAME}.embedding <#> query_embedding)

-- Euclidean distance
1 / (1 + ({TABLE_NAME}.embedding <-> query_embedding))

4. Add date boosting:
hybrid_score * (1 + age_boost_factor * extract(epoch from (now() - created_at)))

5. Use different text search configurations:
-- For non-English content
websearch_to_tsquery('spanish', query_text)

-- For simple matching
plainto_tsquery('english', query_text)

PERFORMANCE OPTIMIZATION:

1. Ensure indexes exist:
-- Vector index (HNSW or IVFFlat)
CREATE INDEX {TABLE_NAME}_embedding_idx ON {TABLE_NAME}
USING hnsw (embedding vector_cosine_ops);

-- Full-text search GIN index
CREATE INDEX {TABLE_NAME}_fts_idx ON {TABLE_NAME} USING gin(fts);

2. Monitor query performance:
EXPLAIN ANALYZE
SELECT * FROM {TABLE_NAME}_hybrid_search(...);

3. Adjust internal limits:
-- Increase if results missing (up to 1000)
LIMIT least(match_count * 3, 1000)

-- Decrease for faster queries
LIMIT least(match_count * 1.5, 500)

4. Add WHERE clauses for filtering:
-- Inside semantic_search and fulltext_search CTEs
WHERE {TABLE_NAME}.user_id = $user_id

TYPICAL WEIGHT CONFIGURATIONS:

Use Case                  | FT Weight | Semantic Weight
--------------------------|-----------|----------------
General search            | 1.0       | 1.0
Technical documentation   | 1.5       | 0.8
Conversational queries    | 0.5       | 1.5
Code search               | 2.0       | 0.5
Conceptual research       | 0.3       | 1.0
Product search            | 1.0       | 1.2

TESTING & VALIDATION:

1. Test with known queries:
SELECT
    id,
    content,
    similarity,
    fts_rank,
    hybrid_score
FROM {TABLE_NAME}_hybrid_search('test query', embedding, 20)
ORDER BY hybrid_score DESC;

2. Compare methods:
-- Pure semantic
SELECT * FROM {TABLE_NAME}
ORDER BY embedding <=> query_embedding
LIMIT 10;

-- Pure full-text
SELECT * FROM {TABLE_NAME}
WHERE fts @@ websearch_to_tsquery('english', 'test query')
ORDER BY ts_rank(fts, websearch_to_tsquery('english', 'test query')) DESC
LIMIT 10;

-- Hybrid
SELECT * FROM {TABLE_NAME}_hybrid_search('test query', query_embedding, 10);

3. Measure recall:
-- Create test set with known relevant documents
-- Compare results across different weight configurations
-- Optimize weights based on your use case

See examples/hybrid-search-tuning.md for detailed tuning guide
*/
