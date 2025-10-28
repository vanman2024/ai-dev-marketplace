# Memory Optimization Skill

Comprehensive performance optimization toolkit for Mem0 memory systems, covering query optimization, caching strategies, embedding efficiency, database tuning, and cost reduction for both Platform and OSS deployments.

## Quick Start

### 1. Assess Current Performance

```bash
cd plugins/mem0/skills/memory-optimization
bash scripts/analyze-performance.sh my_project
```

This generates a comprehensive performance report identifying optimization priorities.

### 2. Review Optimization Recommendations

The performance analyzer will categorize issues:
- **Critical**: P99 latency > 500ms, error rate > 5%
- **High Impact**: Average latency > 200ms, cache hit rate < 50%
- **Medium Impact**: Cost above budget, storage growth > 15%/month
- **Low Impact**: Minor tuning opportunities

### 3. Implement Top 3 Optimizations

Start with highest impact, lowest effort optimizations:

**Easy Wins** (< 30 minutes):
1. Reduce search result limits
2. Add user_id/agent_id filters
3. Implement in-memory caching

**Medium Effort** (1-2 hours):
4. Set up Redis caching
5. Switch to smaller embedding model
6. Configure batch operations

**Advanced** (1 day):
7. Implement memory archival
8. Set up monitoring and alerts
9. Optimize database indexes

## What This Skill Provides

### Performance Analysis Tools

- **analyze-performance.sh**: Comprehensive performance profiling
- **benchmark-performance.sh**: Load testing and benchmarking
- **diagnose-slow-queries.sh**: Query-specific diagnostics
- **compare-configs.sh**: A/B test configurations

### Cost Optimization Tools

- **analyze-costs.sh**: Detailed cost breakdown and projections
- **diagnose-high-costs.sh**: Cost diagnostics and recommendations
- **deduplicate-memories.sh**: Remove duplicate memories
- **prune-low-value-memories.sh**: Remove unused/low-value memories
- **setup-memory-archival.sh**: Configure tiered storage

### Caching Tools

- **generate-cache-config.sh**: Create cache configurations
- **optimize-cache.sh**: Cache tuning recommendations
- In-memory caching templates (Python LRU)
- Redis caching templates with TTL management
- Edge caching configurations

### Database Optimization

- **suggest-vector-db.sh**: Vector database selection advisor
- Database-specific optimization configs:
  - Qdrant: HNSW tuning, quantization
  - pgvector: Index optimization, connection pooling
  - Milvus: Partition strategies, replica settings
  - Chroma: Collection optimization

### Monitoring and Alerting

- **setup-monitoring.sh**: Configure performance monitoring
- **generate-alert-config.sh**: Create alert rules
- Prometheus metrics templates
- Grafana dashboard templates
- Cost tracking dashboards

## Optimization Techniques Overview

### Query Optimization (30-60% latency reduction)

```python
# Before
memories = memory.search(query, user_id=user_id)

# After
memories = memory.search(
    query,
    user_id=user_id,
    limit=5,  # Reduce results
    filters={"categories": ["preferences"]},  # Narrow scope
    rerank=False  # Disable for simple queries
)
```

### Caching (50-70% API call reduction)

```python
# Redis caching with 5-minute TTL
cache_key = f"mem0:{user_id}:{query_hash}"
cached = redis.get(cache_key)
if cached:
    return json.loads(cached)

result = memory.search(query, user_id=user_id)
redis.setex(cache_key, 300, json.dumps(result))
return result
```

### Embedding Optimization (70-85% cost reduction)

```python
# Switch from large to small model
config = MemoryConfig(
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small",  # Was: 3-large
        }
    }
)
```

### Batch Operations (40-60% efficiency gain)

```python
# Batch instead of individual operations
memory.add(messages, user_id=user_id)  # Single API call
```

## Use Cases

### High-Traffic Chat Applications

**Challenge**: 10,000 queries/minute, P99 latency > 800ms

**Solution**:
1. Redis caching (70% hit rate)
2. Reduce limit to 3 results
3. Add user_id filters
4. Async operations

**Result**: P99 latency < 200ms, 65% cost reduction

### RAG Systems with Large Context

**Challenge**: Retrieving 50+ memories per query, high embedding costs

**Solution**:
1. Implement two-stage retrieval (coarse → fine)
2. Cache embeddings for frequent queries
3. Use smaller model for initial search
4. Rerank only top 20 results

**Result**: 40% latency reduction, 55% cost reduction

### Multi-Tenant SaaS

**Challenge**: 1000+ customers, unpredictable usage, cost control

**Solution**:
1. Per-tenant memory limits
2. Automatic archival after 90 days
3. Deduplication for power users
4. Cost alerts per tenant

**Result**: Predictable costs, 50% storage reduction

### Enterprise Knowledge Base

**Challenge**: Millions of memories, complex queries, 99.9% uptime requirement

**Solution**:
1. Qdrant with quantization (4x storage reduction)
2. Connection pooling (100 connections)
3. Multi-region replication
4. Comprehensive monitoring

**Result**: < 100ms average latency, 99.99% uptime, scalable to billions

## Performance Targets

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| Average Latency | < 100ms | > 200ms |
| P95 Latency | < 200ms | > 400ms |
| P99 Latency | < 500ms | > 1000ms |
| Cache Hit Rate | > 70% | < 50% |
| Error Rate | < 1% | > 5% |
| Cost per 1K queries (Platform) | < $0.10 | > $0.20 |
| Cost per 1K queries (OSS) | < $0.02 | > $0.05 |

## Common Optimization Patterns

### Pattern 1: Aggressive Caching for User Preferences

**When**: User preferences rarely change, frequently accessed

**Implementation**:
- Cache user preferences with 15-minute TTL
- Invalidate cache only on explicit updates
- Use in-memory cache for current session

**Expected Impact**: 80% cache hit rate, 70% API call reduction

### Pattern 2: Two-Stage Retrieval for RAG

**When**: Need high recall from large memory set

**Implementation**:
- Stage 1: Fast vector search (50 results, no rerank)
- Stage 2: Rerank top 50 to final 10
- Cache embeddings for common queries

**Expected Impact**: 40% latency reduction, same accuracy

### Pattern 3: Archival for Historical Data

**When**: Large memory growth, older memories rarely accessed

**Implementation**:
- Active: 0-30 days (vector DB)
- Archive: 30-180 days (compressed JSON)
- Cold: > 180 days (S3 Glacier)

**Expected Impact**: 60% storage cost reduction

### Pattern 4: Smart Deduplication

**When**: Users repeat similar information

**Implementation**:
- Detect semantic similarity > 0.95
- Merge duplicate memories
- Preserve most recent/complete version

**Expected Impact**: 30% storage reduction, better relevance

## Monitoring Checklist

Daily:
- [ ] Review error rate dashboard
- [ ] Check P99 latency trends
- [ ] Monitor cost vs budget

Weekly:
- [ ] Review slow query log
- [ ] Analyze cache hit rate trends
- [ ] Check storage growth rate
- [ ] Review top cost drivers

Monthly:
- [ ] Full performance benchmark
- [ ] Cost optimization review
- [ ] Database maintenance (vacuum, analyze)
- [ ] Capacity planning for next quarter

## Integration with Other Skills

This skill works alongside:

- **memory-design-patterns**: Architecture and retention strategies
- **supabase-integration**: pgvector-specific optimizations
- **Platform-specific tools**: For Mem0 Platform optimizations

## Templates Included

**Configuration Templates**:
- `optimized-memory-config.py` - Production-ready config
- `cost-optimized.py` - Minimal cost configuration
- `performance-optimized.py` - Maximum performance
- `balanced.py` - Cost/performance balance

**Caching Templates**:
- `in-memory-cache.py` - Python LRU implementation
- `redis-cache.py` - Redis layer with TTL
- `edge-cache-config.yaml` - CDN/edge caching

**Database Configs**:
- `qdrant-config.py` - Optimized Qdrant
- `pgvector-config.py` - Optimized pgvector
- `milvus-config.py` - Optimized Milvus

**Monitoring Templates**:
- `prometheus-metrics.yaml` - Metrics collection
- `grafana-dashboard.json` - Performance dashboard
- `alert-rules.yaml` - Alert configurations

## Examples and Case Studies

See `examples/` directory for:
- Real-world optimization case studies
- Before/after performance benchmarks
- Cost reduction success stories
- Platform vs OSS optimization strategies

## Best Practices

1. **Always measure first**: Run analysis before optimizing
2. **Start with easy wins**: Limit reduction and filters first
3. **Implement incrementally**: One optimization at a time
4. **Test thoroughly**: Benchmark before/after every change
5. **Monitor continuously**: Set up alerts from day 1
6. **Cache intelligently**: Only cache frequently accessed data
7. **Right-size everything**: Models, limits, TTLs
8. **Plan for growth**: Monitor trends, not just current metrics
9. **Document changes**: Track what worked (and what didn't)
10. **Review regularly**: Monthly optimization reviews

## Troubleshooting

**Still slow after optimization?**
→ Run `scripts/diagnose-slow-queries.sh` for deeper analysis

**Cache not helping?**
→ Check TTL settings, cache key consistency, eviction rate

**Costs still high?**
→ Review deduplication, archival, embedding model choice

**Database performance degraded?**
→ Check indexes, connection pool, resource utilization

## Getting Help

1. Run diagnostic scripts (analyze-performance.sh, diagnose-*)
2. Review generated recommendations
3. Check examples/ for similar use cases
4. Consult SKILL.md for detailed implementation guidance

## Version History

**1.0.0** (2025-10-27)
- Initial release
- Comprehensive optimization toolkit
- Platform and OSS support
- Production-ready scripts and templates
