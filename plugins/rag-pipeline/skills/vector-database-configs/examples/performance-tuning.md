# Vector Database Performance Tuning Guide

Comprehensive guide for optimizing vector database performance across all supported databases.

## Table of Contents

1. [General Performance Principles](#general-performance-principles)
2. [Database-Specific Tuning](#database-specific-tuning)
3. [Query Optimization](#query-optimization)
4. [Indexing Strategies](#indexing-strategies)
5. [Hardware Considerations](#hardware-considerations)
6. [Monitoring and Benchmarking](#monitoring-and-benchmarking)

## General Performance Principles

### The Performance Triangle

```
        Accuracy
         /    \
        /      \
       /        \
    Speed ---- Cost
```

You can typically optimize for 2 out of 3:
- **Fast + Accurate** = Expensive (large instances, HNSW indexes)
- **Fast + Cheap** = Less accurate (aggressive quantization, low nprobe)
- **Accurate + Cheap** = Slower (exact search, smaller instances)

### Key Performance Metrics

1. **Query Latency**: Time to return results (p50, p95, p99)
2. **Throughput**: Queries per second (QPS)
3. **Recall**: Percentage of true nearest neighbors found
4. **Index Build Time**: Time to build/rebuild indexes
5. **Memory Usage**: RAM required for index
6. **Storage Cost**: Disk space and cloud costs

### Universal Best Practices

1. **Batch operations** whenever possible
2. **Pre-filter on metadata** before vector search
3. **Use appropriate index type** for dataset size
4. **Monitor and optimize** continuously
5. **Cache frequently accessed queries**
6. **Use connection pooling**
7. **Benchmark with realistic queries**

## Database-Specific Tuning

### pgvector (PostgreSQL)

#### Index Selection

```sql
-- For < 100K vectors: Consider no index (exact search is fast enough)

-- For 100K - 1M vectors: IVFFlat
CREATE INDEX idx_embedding_ivfflat ON documents
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);  -- lists = sqrt(rows) is a good starting point

-- For 1M+ vectors: HNSW (recommended)
CREATE INDEX idx_embedding_hnsw ON documents
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

#### HNSW Parameters

```sql
-- m: Number of connections per layer
-- Lower m = faster build, less memory, lower recall
-- Higher m = slower build, more memory, higher recall
-- Recommended: 16 for balanced, 32 for high recall

CREATE INDEX idx_hnsw_balanced ON documents
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

CREATE INDEX idx_hnsw_high_recall ON documents
USING hnsw (embedding vector_cosine_ops)
WITH (m = 32, ef_construction = 128);
```

#### IVFFlat Parameters

```sql
-- lists: Number of inverted lists (clusters)
-- Too few = slow queries
-- Too many = slow index build, poor recall
-- Formula: sqrt(total_rows)

-- For 100K rows:
CREATE INDEX idx_ivfflat_100k ON documents
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 316);  -- sqrt(100000) ≈ 316

-- Adjust probes at query time:
SET ivfflat.probes = 10;  -- Check 10 lists (higher = slower but better recall)
```

#### PostgreSQL Configuration

```ini
# postgresql.conf

# Memory settings
shared_buffers = 4GB                    # 25% of RAM
effective_cache_size = 12GB             # 75% of RAM
maintenance_work_mem = 2GB              # For index building
work_mem = 64MB                         # Per query operation

# Query planner
random_page_cost = 1.1                  # For SSD (default 4.0 is for HDD)
effective_io_concurrency = 200          # For SSD

# Parallel query
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_worker_processes = 8

# Connections
max_connections = 100
```

#### Query Optimization

```sql
-- BAD: Filter after vector search
SELECT * FROM (
    SELECT * FROM documents
    ORDER BY embedding <=> '[...]'::vector
    LIMIT 100
) WHERE category = 'ml'
LIMIT 10;

-- GOOD: Filter before vector search
SELECT *
FROM documents
WHERE category = 'ml'
ORDER BY embedding <=> '[...]'::vector
LIMIT 10;

-- BETTER: Use partial index for common filters
CREATE INDEX idx_ml_embedding_hnsw ON documents
USING hnsw (embedding vector_cosine_ops)
WHERE category = 'ml';
```

### Chroma

#### Collection Configuration

```python
import chromadb
from chromadb.config import Settings

# Optimize for performance
client = chromadb.PersistentClient(
    path="./chroma_data",
    settings=Settings(
        anonymized_telemetry=False,
        allow_reset=False,
        # Use memory-mapped files for faster access
        persist_directory="./chroma_data"
    )
)

# Configure HNSW parameters
collection = client.create_collection(
    name="documents",
    metadata={
        "hnsw:space": "cosine",
        "hnsw:construction_ef": 100,  # Higher = better index quality
        "hnsw:search_ef": 100,        # Higher = better recall
        "hnsw:M": 16                   # Connections per layer
    }
)
```

#### Batch Operations

```python
# BAD: Insert one at a time
for doc in documents:
    collection.add(documents=[doc], ids=[doc.id])

# GOOD: Batch insert
collection.add(
    documents=documents,
    ids=ids,
    metadatas=metadatas
)

# BEST: Large batch with chunking
batch_size = 5000
for i in range(0, len(documents), batch_size):
    batch = documents[i:i+batch_size]
    collection.add(
        documents=batch,
        ids=ids[i:i+batch_size],
        metadatas=metadatas[i:i+batch_size]
    )
```

### Pinecone

#### Index Configuration

```python
from pinecone import Pinecone, ServerlessSpec

pc = Pinecone(api_key="...")

# Serverless (auto-scaling, pay-per-use)
index = pc.create_index(
    name="documents",
    dimension=1536,
    metric="cosine",
    spec=ServerlessSpec(
        cloud="aws",
        region="us-east-1"  # Choose closest region
    )
)

# Pod-based (dedicated resources, predictable latency)
# Use for > 10M vectors or consistent high QPS
index = pc.create_index(
    name="documents-prod",
    dimension=1536,
    metric="cosine",
    spec=PodSpec(
        environment="us-east-1-aws",
        pod_type="p2.x1",  # Larger pods for better performance
        pods=2,            # Horizontal scaling
        replicas=1         # For high availability
    )
)
```

#### Query Optimization

```python
# Use top_k wisely
results = index.query(
    vector=query_embedding,
    top_k=10,  # Only request what you need
    include_metadata=True,
    include_values=False  # Don't return vectors unless needed
)

# Pre-filter with metadata
results = index.query(
    vector=query_embedding,
    top_k=10,
    filter={
        "category": {"$eq": "ml"},
        "rating": {"$gte": 4.0}
    }
)

# Use namespaces for isolation
index.upsert(vectors=vectors, namespace="production")
index.query(vector=query, namespace="production", top_k=10)
```

### Weaviate

#### Schema Optimization

```python
import weaviate
from weaviate.classes.config import Configure

# Configure HNSW index
collection = client.collections.create(
    name="Documents",
    vectorizer_config=Configure.Vectorizer.none(),
    vector_index_config=Configure.VectorIndex.hnsw(
        distance_metric="cosine",
        ef=100,              # Higher = better recall
        ef_construction=128, # Higher = better index quality
        max_connections=32   # Higher = better recall, more memory
    )
)

# Configure product quantization for memory efficiency
collection_pq = client.collections.create(
    name="DocumentsPQ",
    vector_index_config=Configure.VectorIndex.hnsw(
        quantizer=Configure.VectorIndex.Quantizer.pq(
            segments=512,         # Divide vector into segments
            centroids=256,        # Centroids per segment
            training_limit=10000  # Vectors to use for training
        )
    )
)
```

#### Query Performance

```python
# Use hybrid search for better results
results = collection.query.hybrid(
    query="machine learning",
    alpha=0.5,  # Balance keyword (0) vs vector (1)
    limit=10
)

# Pre-filter before vector search
from weaviate.classes.query import Filter

results = collection.query.near_vector(
    near_vector=query_embedding,
    limit=10,
    filters=Filter.by_property("category").equal("ml")
)

# Use grouping for deduplication
results = collection.query.near_text(
    query="AI",
    limit=10,
    group_by="source"  # Group results by source field
)
```

### Qdrant

#### Collection Configuration

```python
from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance, HnswConfigDiff

client = QdrantClient(url="http://localhost:6333")

# Optimize HNSW parameters
client.create_collection(
    collection_name="documents",
    vectors_config=VectorParams(
        size=1536,
        distance=Distance.COSINE,
        hnsw_config=HnswConfigDiff(
            m=16,                    # Connections per layer
            ef_construct=100,        # Index build quality
            full_scan_threshold=10000  # Use exact search below this
        )
    ),
    optimizers_config={
        "indexing_threshold": 20000,  # Start indexing after N vectors
        "memmap_threshold": 100000    # Use memory-mapped files above N
    }
)
```

#### Payload Indexing

```python
# Create indexes on frequently filtered fields
client.create_payload_index(
    collection_name="documents",
    field_name="category",
    field_schema="keyword"  # Fast exact match
)

client.create_payload_index(
    collection_name="documents",
    field_name="rating",
    field_schema="float"  # For range queries
)

client.create_payload_index(
    collection_name="documents",
    field_name="description",
    field_schema="text"  # Full-text search
)
```

#### Search Optimization

```python
# Use search parameters
results = client.search(
    collection_name="documents",
    query_vector=query_embedding,
    limit=10,
    search_params={
        "hnsw_ef": 128,  # Higher = better recall, slower
        "exact": False   # Set True for exact search
    }
)

# Batch search for multiple queries
from qdrant_client.models import SearchRequest

results = client.search_batch(
    collection_name="documents",
    requests=[
        SearchRequest(vector=query1, limit=10),
        SearchRequest(vector=query2, limit=10),
    ]
)
```

### FAISS

#### Index Selection by Scale

```python
import faiss

dimensions = 1536

# < 10K vectors: Flat (exact search)
index = faiss.IndexFlatL2(dimensions)

# 10K - 100K: IVFFlat
nlist = 100
quantizer = faiss.IndexFlatL2(dimensions)
index = faiss.IndexIVFFlat(quantizer, dimensions, nlist)

# 100K - 1M: HNSW
index = faiss.IndexHNSWFlat(dimensions, 32)

# 1M - 10M: IVF + HNSW
nlist = 1000
quantizer = faiss.IndexHNSWFlat(dimensions, 32)
index = faiss.IndexIVFFlat(quantizer, dimensions, nlist)

# 10M+: IVF + PQ (product quantization)
nlist = 4096
m = 8  # Subdivisions
index = faiss.IndexIVFPQ(quantizer, dimensions, nlist, m, 8)
```

#### Search Parameters

```python
# IVFFlat: Adjust nprobe
index.nprobe = 10  # Check 10 clusters (higher = slower, better recall)

# HNSW: Adjust efSearch
index.hnsw.efSearch = 64  # Higher = better recall

# Search
distances, indices = index.search(query_vectors, k=10)
```

#### GPU Acceleration

```python
import faiss

# Move to GPU
res = faiss.StandardGpuResources()
gpu_index = faiss.index_cpu_to_gpu(res, 0, index)

# Search on GPU (much faster)
distances, indices = gpu_index.search(query_vectors, k=10)

# Multi-GPU
co = faiss.GpuMultipleClonerOptions()
co.shard = True  # Shard index across GPUs
gpu_index = faiss.index_cpu_to_all_gpus(index, co=co)
```

## Query Optimization

### 1. Reduce Result Count

```python
# Request only what you need
results = store.search(query, k=10)  # Not k=100

# Use pagination for large result sets
results = store.search(query, k=10, offset=0)
```

### 2. Pre-filter Metadata

```python
# BAD: Post-filter
results = store.search(query, k=100)
filtered = [r for r in results if r["category"] == "ml"][:10]

# GOOD: Pre-filter
results = store.search(query, k=10, filter={"category": "ml"})
```

### 3. Cache Common Queries

```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=1000)
def cached_search(query_hash, k=10):
    query_vector = embedding_cache[query_hash]
    return store.search(query_vector, k=k)

# Use
query_hash = hashlib.md5(query.encode()).hexdigest()
results = cached_search(query_hash)
```

### 4. Use Approximate Search

Most vector databases use approximate nearest neighbor (ANN) search by default, which is much faster than exact search with minimal accuracy loss.

**Recall vs Speed Tradeoff:**
- 95% recall is usually sufficient for RAG
- Exact search is 10-100x slower
- Use exact search only for < 10K vectors or critical applications

## Indexing Strategies

### Index Type Selection

```
Dataset Size    | Recommended Index    | Typical Latency
----------------|---------------------|----------------
< 10K           | Flat (exact)        | < 1ms
10K - 100K      | IVFFlat             | 1-10ms
100K - 1M       | HNSW                | 5-20ms
1M - 10M        | HNSW                | 10-50ms
10M - 100M      | IVF + PQ            | 20-100ms
100M+           | Sharded HNSW/IVF    | 50-200ms
```

### Rebuild Indexes

```python
# Rebuild after bulk inserts for optimal performance

# pgvector
# REINDEX INDEX CONCURRENTLY idx_embedding_hnsw;

# Qdrant
client.update_collection(
    collection_name="documents",
    optimizer_config={"indexing_threshold": 0}  # Force reindex
)

# FAISS
# Rebuild from scratch with all vectors
```

## Hardware Considerations

### Memory Requirements

```
Index Type      | Memory Formula
----------------|--------------------------------
Flat            | vectors * dimensions * 4 bytes
IVFFlat         | ~1.2x vector data
HNSW (m=16)     | ~1.5x vector data
HNSW (m=32)     | ~2x vector data
IVF + PQ        | ~0.2-0.5x vector data
```

### CPU vs GPU

**Use GPU when:**
- > 1M vectors
- High QPS requirements (> 100 QPS)
- Batch processing large datasets
- Using FAISS or GPU-enabled databases

**Stick with CPU when:**
- < 1M vectors
- Low to moderate QPS (< 100 QPS)
- Budget constraints
- Using managed services (they handle this)

### Storage: SSD vs HDD

Always use SSD for vector databases:
- 10-100x faster random access
- Essential for index lookups
- Lower latency variance

## Monitoring and Benchmarking

### Key Metrics to Track

```python
import time

def monitor_search(store, queries, k=10):
    latencies = []
    recalls = []

    for query, expected in queries:
        start = time.time()
        results = store.search(query, k=k)
        latency = time.time() - start

        # Calculate recall
        result_ids = set(r["id"] for r in results)
        expected_ids = set(expected)
        recall = len(result_ids & expected_ids) / len(expected_ids)

        latencies.append(latency)
        recalls.append(recall)

    return {
        "p50_latency": np.percentile(latencies, 50),
        "p95_latency": np.percentile(latencies, 95),
        "p99_latency": np.percentile(latencies, 99),
        "avg_recall": np.mean(recalls),
        "qps": len(queries) / sum(latencies)
    }
```

### Load Testing

```python
import concurrent.futures

def load_test(store, queries, num_workers=10):
    """Concurrent load test"""

    def query_worker(query):
        return store.search(query, k=10)

    with concurrent.futures.ThreadPoolExecutor(max_workers=num_workers) as executor:
        start = time.time()
        results = list(executor.map(query_worker, queries))
        duration = time.time() - start

    qps = len(queries) / duration
    print(f"QPS with {num_workers} workers: {qps:.2f}")
    return qps
```

### Benchmark Template

```python
# benchmark.py

databases = {
    "pgvector": pgvector_store,
    "pinecone": pinecone_store,
    "qdrant": qdrant_store
}

test_queries = [...]  # Your test queries
k = 10

for name, store in databases.items():
    print(f"\nBenchmarking {name}:")

    metrics = monitor_search(store, test_queries, k=k)

    print(f"  P50 latency: {metrics['p50_latency']*1000:.2f}ms")
    print(f"  P95 latency: {metrics['p95_latency']*1000:.2f}ms")
    print(f"  P99 latency: {metrics['p99_latency']*1000:.2f}ms")
    print(f"  Avg recall: {metrics['avg_recall']*100:.1f}%")
    print(f"  QPS: {metrics['qps']:.2f}")
```

## Performance Checklist

- [ ] Choose appropriate index type for dataset size
- [ ] Tune index parameters (m, ef, nprobe)
- [ ] Use batch operations for inserts
- [ ] Pre-filter on metadata before vector search
- [ ] Request only needed result count (k)
- [ ] Don't return vectors in results unless needed
- [ ] Use connection pooling
- [ ] Monitor p50/p95/p99 latencies
- [ ] Benchmark recall vs speed tradeoff
- [ ] Use SSD storage
- [ ] Configure database memory settings
- [ ] Consider GPU for > 1M vectors
- [ ] Cache frequent queries
- [ ] Use approximate search (not exact)
- [ ] Monitor and alert on performance degradation
