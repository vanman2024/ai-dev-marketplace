# Memory Optimization - Quick Start Guide

Get started with Mem0 optimization in 15 minutes.

## Step 1: Assess Current Performance (5 minutes)

```bash
cd plugins/mem0/skills/memory-optimization
bash scripts/analyze-performance.sh my_project
```

**Look for**:
- P99 latency > 500ms → **Critical**
- Cache hit rate < 50% → **High priority**
- Embedding model: text-embedding-3-large → **Cost optimization opportunity**

## Step 2: Quick Wins (10 minutes)

### A. Reduce Search Limits

```python
# Before
memories = memory.search(query, user_id=user_id)

# After (add these 2 parameters)
memories = memory.search(
    query,
    user_id=user_id,
    limit=5,  # ← Add this
    filters={"user_id": user_id}  # ← Add this
)
```

**Impact**: -40% latency immediately

### B. Disable Unnecessary Reranking

```python
# For simple preference lookups
memories = memory.search(
    query,
    user_id=user_id,
    limit=5,
    rerank=False  # ← Add this for simple queries
)
```

**Impact**: 2x faster for simple queries

## Step 3: Monitor Results (Re-run analysis)

```bash
bash scripts/analyze-performance.sh my_project
```

**Expected after 10 minutes**:
- Average latency: -35%
- P99 latency: -45%
- No code complexity added

## Next Steps (Choose Based on Priority)

### High Traffic? → Implement Caching (1 hour)

```bash
bash scripts/generate-cache-config.sh redis 300
```

**Impact**: -60% API calls, -50% latency for cached queries

### High Costs? → Switch Embedding Model (30 minutes)

```python
from mem0.configs.base import MemoryConfig

config = MemoryConfig(
    embedder={
        "provider": "openai",
        "config": {"model": "text-embedding-3-small"}
    }
)
```

**Impact**: -85% embedding costs

### Large Scale? → Optimize Database (1 day)

See `templates/vector-db-optimization/` for database-specific configs.

**Impact**: -50% storage, -40% query time

## Common Patterns

### Pattern 1: Chat Application
```python
# 3-5 results, no reranking, 5-min cache
memories = cached_search(
    memory, query, user_id=user_id, limit=3, rerank=False, ttl=300
)
```

### Pattern 2: RAG System
```python
# 10 results, enable reranking, 10-min cache
memories = cached_search(
    memory, query, user_id=user_id, limit=10, rerank=True, ttl=600
)
```

### Pattern 3: Batch Operations
```python
# Always batch when adding multiple memories
memory.add(messages, user_id=user_id)  # Not: for msg in messages
```

## Troubleshooting

**Still slow?**
→ `bash scripts/diagnose-slow-queries.sh`

**Costs still high?**
→ `bash scripts/analyze-costs.sh`

**Need caching help?**
→ `templates/cache-strategies/redis-cache.py`

## Full Documentation

- **Complete guide**: `SKILL.md`
- **Detailed README**: `README.md`
- **Case studies**: `examples/optimization-case-studies.md`
- **Benchmarks**: `examples/before-after-benchmarks.md`

## Expected Results

**After 15 minutes** (quick wins):
- Latency: -40%
- Effort: Minimal
- Risk: None

**After 1 day** (full optimization):
- Latency: -70%
- Costs: -60%
- Effort: ~8 hours
- ROI: 2-6 months

## Get Help

Run the diagnostic scripts - they provide specific recommendations for your use case.
