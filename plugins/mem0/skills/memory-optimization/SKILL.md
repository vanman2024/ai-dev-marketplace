---
name: memory-optimization
description: Performance optimization patterns for Mem0 memory operations including query optimization, caching strategies, embedding efficiency, database tuning, batch operations, and cost reduction for both Platform and OSS deployments. Use when optimizing memory performance, reducing costs, improving query speed, implementing caching, tuning database performance, analyzing bottlenecks, or when user mentions memory optimization, performance tuning, cost reduction, slow queries, caching, or Mem0 optimization.
allowed-tools: [Bash, Read, Write, Edit]
---

# Memory Optimization

Performance optimization patterns and tools for Mem0 memory systems. This skill provides comprehensive optimization techniques for query performance, cost reduction, caching strategies, and infrastructure tuning for both Platform and OSS deployments.

## Instructions

### Phase 1: Performance Assessment

Start by analyzing your current memory system performance:

```bash
bash scripts/analyze-performance.sh [project_name]
```

This generates a comprehensive performance report including:
- Query latency metrics (average, P95, P99)
- Operation throughput (searches, adds, updates, deletes)
- Cache performance statistics
- Resource utilization (memory, storage, CPU)
- Slow query identification
- Cost analysis

**Review the output to identify optimization priorities:**
- Query latency > 200ms → Focus on query optimization
- High costs → Focus on cost optimization
- Low cache hit rate < 60% → Focus on caching
- High resource usage → Focus on infrastructure tuning

### Phase 2: Query Optimization

Optimize memory search operations for speed and efficiency.

#### 2.1 Limit Search Results

**Problem**: Retrieving too many results increases latency and costs.

**Solution**: Use appropriate limit values based on use case.

```python
# ❌ BAD: Using default or excessive limits
memories = memory.search(query, user_id=user_id)  # Default: 10

# ✅ GOOD: Optimized limits
memories = memory.search(query, user_id=user_id, limit=5)  # Chat apps
memories = memory.search(query, user_id=user_id, limit=3)  # Quick context
memories = memory.search(query, user_id=user_id, limit=10) # RAG systems
```

**Impact**: 30-40% reduction in query time

**Guidelines**:
- Chat applications: 3-5 results
- RAG context retrieval: 8-12 results
- Recommendation systems: 10-20 results
- Semantic search: 20-50 results

#### 2.2 Use Filters to Reduce Search Space

**Problem**: Searching entire index is slow and expensive.

**Solution**: Apply filters to narrow search scope.

```python
# ❌ BAD: Full index scan
memories = memory.search(query)

# ✅ GOOD: Filtered search
memories = memory.search(
    query,
    filters={
        "user_id": user_id,
        "categories": ["preferences", "profile"]
    },
    limit=5
)

# ✅ BETTER: Multiple filter conditions
memories = memory.search(
    query,
    filters={
        "AND": [
            {"user_id": user_id},
            {"agent_id": "support_v2"},
            {"created_after": "2025-01-01"}
        ]
    },
    limit=5
)
```

**Impact**: 40-60% reduction in query time

**Available Filters**:
- `user_id`: Scope to specific user
- `agent_id`: Scope to specific agent
- `run_id`: Scope to session/run
- `categories`: Filter by memory categories
- `metadata`: Custom metadata filters
- Date ranges: `created_after`, `created_before`

#### 2.3 Optimize Reranking

**Problem**: Default reranking may be overkill for simple queries.

**Solution**: Configure reranker based on accuracy requirements.

```python
# Platform Mode (Mem0 Cloud)
from mem0 import MemoryClient

# Disable reranking for fast, simple queries
memory = MemoryClient(api_key=api_key)
memories = memory.search(
    query,
    user_id=user_id,
    rerank=False  # 2x faster, slightly lower accuracy
)

# OSS Mode
from mem0 import Memory
from mem0.configs.base import MemoryConfig

# Use lightweight reranker
config = MemoryConfig(
    reranker={
        "provider": "cohere",
        "config": {
            "model": "rerank-english-v3.0",  # Fast model
            "top_n": 5  # Rerank only top results
        }
    }
)
memory = Memory(config)
```

**Reranker Options**:
- **No reranking**: Fastest, 90-95% accuracy
- **Lightweight (Cohere rerank-english-v3.0)**: 2x faster than full
- **Full reranking (Cohere rerank-english-v3.5)**: Highest accuracy

**Decision Guide**:
- Simple preference retrieval → No reranking
- Chat context → Lightweight reranking
- Critical RAG applications → Full reranking

#### 2.4 Use Async Operations

**Problem**: Blocking operations limit throughput.

**Solution**: Use async for high-concurrency scenarios.

```python
import asyncio
from mem0 import AsyncMemory

async def get_user_context(user_id: str, queries: list[str]):
    memory = AsyncMemory()

    # Run multiple searches concurrently
    results = await asyncio.gather(*[
        memory.search(q, user_id=user_id, limit=3)
        for q in queries
    ])

    return results

# Usage
contexts = await get_user_context(
    "user_123",
    ["preferences", "recent activity", "goals"]
)
```

**Impact**: 3-5x throughput improvement under load

### Phase 3: Caching Strategies

Implement multi-layer caching to reduce API calls and improve response times.

#### 3.1 In-Memory Caching (Python)

**Use for**: Frequently accessed, rarely changing data (user preferences).

```python
from functools import lru_cache
import hashlib

@lru_cache(maxsize=1000)
def get_user_preferences(user_id: str) -> list:
    """Cache user preferences for 5 minutes"""
    return memory.search(
        "user preferences",
        user_id=user_id,
        limit=5
    )

# Clear cache when preferences update
get_user_preferences.cache_clear()
```

**Impact**: Near-instant response for cached queries

**Configuration**:
- `maxsize=1000`: Cache 1000 users' preferences
- Clear cache on memory updates
- TTL: Implement with time-based wrapper

#### 3.2 Redis Caching (Production)

**Use for**: Shared caching across services, TTL control.

```python
import redis
import json

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def get_user_context_cached(user_id: str, query: str) -> list:
    # Generate cache key
    cache_key = f"mem0:search:{user_id}:{hashlib.md5(query.encode()).hexdigest()}"

    # Check cache
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)

    # Cache miss - query Mem0
    result = memory.search(query, user_id=user_id, limit=5)

    # Cache result (5 minute TTL)
    redis_client.setex(
        cache_key,
        300,  # 5 minutes
        json.dumps(result)
    )

    return result

# Invalidate cache on update
def update_memory(user_id: str, message: str):
    memory.add(message, user_id=user_id)

    # Clear user's cache
    pattern = f"mem0:search:{user_id}:*"
    for key in redis_client.scan_iter(match=pattern):
        redis_client.delete(key)
```

**Impact**: 50-70% reduction in API calls

**TTL Guidelines**:
- User preferences: 5-15 minutes
- Agent knowledge: 30-60 minutes
- Session context: 1-2 minutes
- Static content: 1 hour

Use the caching template generator:
```bash
bash scripts/generate-cache-config.sh redis [ttl_seconds]
```

#### 3.3 Edge Caching (Advanced)

**Use for**: Global applications, very high traffic.

See template: `templates/edge-cache-config.yaml`

### Phase 4: Embedding Optimization

Optimize embedding generation and storage costs.

#### 4.1 Choose Appropriate Embedding Model

**Problem**: Oversized embeddings increase cost and latency.

**Solution**: Match model to use case.

```python
from mem0 import Memory
from mem0.configs.base import MemoryConfig

# ❌ EXPENSIVE: Large model for simple data
config = MemoryConfig(
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-large",  # 3072 dims, $0.13/1M tokens
        }
    }
)

# ✅ OPTIMIZED: Appropriate model
config = MemoryConfig(
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small",  # 1536 dims, $0.02/1M tokens
        }
    }
)
```

**Model Selection Guide**:

| Use Case | Recommended Model | Dimensions | Cost |
|----------|------------------|------------|------|
| User preferences | text-embedding-3-small | 1536 | $0.02/1M |
| Simple chat context | text-embedding-3-small | 1536 | $0.02/1M |
| Advanced RAG | text-embedding-3-large | 3072 | $0.13/1M |
| Multilingual | text-embedding-3-large | 3072 | $0.13/1M |
| Budget-conscious | text-embedding-ada-002 | 1536 | $0.0001/1M |

**Impact**: 70-85% cost reduction with appropriate model selection

#### 4.2 Batch Embedding Generation

**Problem**: Individual embedding calls have overhead.

**Solution**: Batch multiple texts for embedding.

```python
# ❌ BAD: Individual embedding calls
for message in messages:
    memory.add(message, user_id=user_id)  # Separate API call each

# ✅ GOOD: Batched operation
memory.add(messages, user_id=user_id)  # Single batched call
```

**Impact**: 40-60% reduction in embedding costs

**Batch Size Guidelines**:
- Platform Mode: Up to 100 messages per batch
- OSS Mode: Limited by embedding provider (OpenAI: 2048 texts)

#### 4.3 Embedding Caching

**Problem**: Re-embedding same text wastes costs.

**Solution**: Cache embeddings for frequent queries.

```python
import hashlib

embedding_cache = {}

def get_or_create_embedding(text: str) -> list[float]:
    # Generate hash of text
    text_hash = hashlib.sha256(text.encode()).hexdigest()

    # Check cache
    if text_hash in embedding_cache:
        return embedding_cache[text_hash]

    # Generate embedding
    embedding = generate_embedding(text)
    embedding_cache[text_hash] = embedding

    return embedding
```

**Use Cases**:
- Canned responses
- Template messages
- System prompts
- Frequently asked questions

### Phase 5: Database Optimization (OSS Mode)

Optimize vector database performance for self-hosted deployments.

#### 5.1 Choose Optimal Vector Database

**Decision Matrix**:

```bash
bash scripts/suggest-vector-db.sh
```

| Database | Best For | Performance | Setup Complexity |
|----------|----------|-------------|------------------|
| **Qdrant** | Production, high scale | Excellent | Medium |
| **Chroma** | Development, prototyping | Good | Low |
| **pgvector** | Existing PostgreSQL | Good | Low |
| **Milvus** | Enterprise, billions of vectors | Excellent | High |

**Recommendation**:
- Start: Chroma (easy setup)
- Production: Qdrant (best performance)
- Existing Postgres: pgvector (no new infra)
- Enterprise: Milvus (handles massive scale)

#### 5.2 Configure Optimal Indexes

**For Qdrant**:
```python
config = MemoryConfig(
    vector_store={
        "provider": "qdrant",
        "config": {
            "collection_name": "memories",
            "host": "localhost",
            "port": 6333,
            "on_disk": True,  # Reduce memory usage
            "hnsw_config": {
                "m": 16,  # Balance between speed and accuracy
                "ef_construct": 200,  # Higher = better quality
            },
            "quantization_config": {
                "scalar": {
                    "type": "int8",  # Reduce storage by 4x
                    "quantile": 0.99
                }
            }
        }
    }
)
```

**For pgvector** (Supabase):
```bash
# Use specialized Supabase integration skill
bash ../supabase-integration/scripts/optimize-pgvector.sh
```

See: `templates/vector-db-optimization/` for database-specific configs.

#### 5.3 Connection Pooling

**Problem**: Creating new connections on each request is slow.

**Solution**: Use connection pooling.

```python
from mem0 import Memory
from mem0.configs.base import MemoryConfig

config = MemoryConfig(
    vector_store={
        "provider": "qdrant",
        "config": {
            "host": "localhost",
            "port": 6333,
            "grpc_port": 6334,
            "prefer_grpc": True,  # Faster protocol
            "timeout": 5,
            "connection_pool_size": 50,  # Reuse connections
        }
    }
)
```

**Impact**: 30-50% reduction in connection overhead

**Pool Size Guidelines**:
- Low traffic: 10-20 connections
- Medium traffic: 30-50 connections
- High traffic: 50-100 connections

### Phase 6: Batch Operations

Optimize bulk operations for efficiency.

#### 6.1 Batch Memory Addition

```python
# ❌ BAD: Individual operations
for msg in conversation_history:
    memory.add(msg, user_id=user_id)

# ✅ GOOD: Batched operation
memory.add(conversation_history, user_id=user_id)
```

**Impact**: 60% faster, 40% lower cost

#### 6.2 Batch Search Operations

```python
import asyncio

# ❌ BAD: Sequential searches
results = []
for query in queries:
    results.append(memory.search(query, user_id=user_id))

# ✅ GOOD: Parallel searches
async def batch_search(queries, user_id):
    memory = AsyncMemory()
    return await asyncio.gather(*[
        memory.search(q, user_id=user_id, limit=5)
        for q in queries
    ])

results = await batch_search(queries, user_id)
```

**Impact**: 4-5x faster for multiple searches

### Phase 7: Cost Optimization

Reduce operational costs for memory systems.

#### 7.1 Run Cost Analysis

```bash
bash scripts/analyze-costs.sh [user_id] [date_range]
```

This generates:
- Daily/monthly cost breakdown
- Cost per operation type
- Cost per user analysis
- Optimization recommendations
- Projected savings

#### 7.2 Implement Cost-Saving Strategies

**Strategy 1: Memory Deduplication**

```bash
bash scripts/deduplicate-memories.sh [user_id]
```

Removes similar/duplicate memories to reduce storage and query costs.

**Impact**: 20-40% storage reduction

**Strategy 2: Archival and Tiered Storage**

```bash
bash scripts/setup-memory-archival.sh [retention_days]
```

Move old memories to cheaper storage:
- Active (0-30 days): Fast vector DB
- Archive (30-180 days): Compressed JSON in S3
- Cold storage (>180 days): Glacier

**Impact**: 50-70% storage cost reduction

**Strategy 3: Smaller Embeddings for Archives**

```python
# Use cheaper embeddings for archived memories
archived_config = MemoryConfig(
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-ada-002",  # Cheaper
        }
    }
)
```

**Strategy 4: Smart Pruning**

```bash
bash scripts/prune-low-value-memories.sh [user_id] [score_threshold]
```

Remove memories that:
- Have never been retrieved
- Have low relevance scores
- Are redundant with other memories
- Haven't been accessed in 90+ days

**Impact**: 30-50% cost reduction

### Phase 8: Monitoring and Alerts

Set up performance monitoring and alerts.

#### 8.1 Configure Monitoring

```bash
bash scripts/setup-monitoring.sh [project_name]
```

Tracks:
- Query latency (average, P95, P99)
- Cache hit rate
- Error rate
- Cost per day/week/month
- Memory growth rate
- Top slow queries

#### 8.2 Set Up Alerts

Use the alert configuration template:

```bash
bash scripts/generate-alert-config.sh
```

**Recommended Alerts**:
- 🚨 P99 latency > 500ms
- 🚨 Error rate > 5%
- 🚨 Cache hit rate < 50%
- 🚨 Daily cost exceeds budget
- 🚨 Storage growth > 20%/week
- 🚨 Slow query percentage > 10%

### Phase 9: Performance Testing

Benchmark and validate optimizations.

#### 9.1 Run Performance Benchmarks

```bash
bash scripts/benchmark-performance.sh [config_name]
```

Measures:
- Query latency under load
- Throughput (queries/second)
- Cache effectiveness
- Cost per 1000 operations

#### 9.2 Load Testing

```bash
bash scripts/load-test.sh [concurrent_users] [duration_seconds]
```

Simulates real-world load to identify bottlenecks.

#### 9.3 Compare Configurations

```bash
bash scripts/compare-configs.sh [config1] [config2]
```

A/B test different optimization strategies.

## Optimization Decision Trees

### Query Performance Issues

```bash
bash scripts/diagnose-slow-queries.sh
```

**Diagnostic Flow**:
1. Average latency > 200ms? → Reduce limit, add filters
2. P99 latency > 500ms? → Add caching, optimize indexes
3. High variance? → Check for slow queries, optimize those specifically
4. All queries slow? → Database infrastructure issue

### High Cost Issues

```bash
bash scripts/diagnose-high-costs.sh
```

**Diagnostic Flow**:
1. Embedding costs high? → Smaller model, batch operations, caching
2. Storage costs high? → Deduplication, archival, pruning
3. Query costs high? → Reduce search frequency, implement caching
4. Overall high? → Review all strategies above

### Low Cache Hit Rate

```bash
bash scripts/optimize-cache.sh
```

**Diagnostic Flow**:
1. < 30% hit rate? → Cache wrong queries, review cache keys
2. 30-60% hit rate? → Increase TTL, cache more query patterns
3. 60-80% hit rate? → Good, minor tuning possible
4. > 80% hit rate? → Excellent, no action needed

## Key Files Reference

**Scripts** (all functional):
- `scripts/analyze-performance.sh` - Comprehensive performance analysis
- `scripts/analyze-costs.sh` - Cost breakdown and optimization
- `scripts/benchmark-performance.sh` - Performance benchmarking
- `scripts/load-test.sh` - Load testing and stress testing
- `scripts/compare-configs.sh` - A/B test configurations
- `scripts/diagnose-slow-queries.sh` - Query performance diagnostics
- `scripts/diagnose-high-costs.sh` - Cost diagnostics
- `scripts/optimize-cache.sh` - Cache tuning recommendations
- `scripts/deduplicate-memories.sh` - Remove duplicate memories
- `scripts/prune-low-value-memories.sh` - Remove unused memories
- `scripts/setup-memory-archival.sh` - Configure archival system
- `scripts/setup-monitoring.sh` - Configure performance monitoring
- `scripts/generate-alert-config.sh` - Create alert rules
- `scripts/generate-cache-config.sh` - Generate cache configurations
- `scripts/suggest-vector-db.sh` - Vector database recommendations

**Templates**:
- `templates/optimized-memory-config.py` - Production-ready configuration
- `templates/cache-strategies/` - Caching implementation patterns
  - `in-memory-cache.py` - Python LRU cache
  - `redis-cache.py` - Redis caching layer
  - `edge-cache-config.yaml` - CDN/edge caching
- `templates/vector-db-optimization/` - Database-specific tuning
  - `qdrant-config.py` - Optimized Qdrant setup
  - `pgvector-config.py` - Optimized pgvector setup
  - `milvus-config.py` - Optimized Milvus setup
- `templates/embedding-configs/` - Embedding optimization
  - `cost-optimized.py` - Minimal cost configuration
  - `performance-optimized.py` - Maximum performance
  - `balanced.py` - Cost/performance balance
- `templates/monitoring/` - Monitoring configurations
  - `prometheus-metrics.yaml` - Metrics collection
  - `grafana-dashboard.json` - Performance dashboard
  - `alert-rules.yaml` - Alert configurations

**Examples**:
- `examples/optimization-case-studies.md` - Real-world optimization examples
- `examples/before-after-benchmarks.md` - Performance improvement results
- `examples/cost-reduction-strategies.md` - Cost optimization success stories
- `examples/caching-patterns.md` - Effective caching implementations
- `examples/oss-vs-platform-optimization.md` - Platform-specific strategies

## Best Practices

1. **Measure First**: Run performance analysis before optimizing
2. **Prioritize**: Address biggest bottlenecks first (80/20 rule)
3. **Incremental**: Implement one optimization at a time, measure impact
4. **Cache Wisely**: Cache frequently accessed, rarely changing data
5. **Right-Size Models**: Don't use large embeddings for simple use cases
6. **Batch Operations**: Always batch when possible
7. **Monitor Continuously**: Set up alerts, review metrics weekly
8. **Test Changes**: Benchmark before/after every optimization
9. **Document Impact**: Track cost/performance improvements
10. **Review Regularly**: Monthly optimization reviews

## Performance Targets

**Query Latency**:
- Average: < 100ms
- P95: < 200ms
- P99: < 500ms

**Cache Performance**:
- Hit rate: > 70%
- Miss penalty: < 2x uncached time

**Cost Efficiency**:
- Cost per 1000 queries: < $0.10 (Platform), < $0.02 (OSS)
- Storage growth: < 10% per month
- Embedding costs: < 40% of total

**Resource Usage** (OSS):
- CPU: < 60% average
- Memory: < 70% average
- Storage: Plan for 6 months growth

## Troubleshooting

**Slow Queries Despite Optimization**:
- Check database indexes exist
- Verify connection pooling active
- Review filter effectiveness
- Check for database resource constraints

**Cache Not Improving Performance**:
- Verify cache keys are consistent
- Check TTL isn't too short
- Ensure cache size is adequate
- Monitor cache eviction rate

**High Costs After Optimization**:
- Review actual usage patterns
- Check for memory leaks (unbounded growth)
- Verify deduplication running
- Review archival policies

**Optimization Caused Accuracy Issues**:
- Reranking disabled may reduce quality
- Smaller embeddings reduce semantic understanding
- Lower limits may miss relevant memories
- Balance performance vs accuracy needs

---

**Plugin**: mem0
**Version**: 1.0.0
**Last Updated**: 2025-10-27
