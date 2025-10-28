"""
Production-optimized Mem0 configuration
Balances performance, cost, and reliability
"""

from mem0 import Memory
from mem0.configs.base import MemoryConfig

# OPTIMIZED CONFIGURATION FOR PRODUCTION
config = MemoryConfig(
    # Embedding Configuration - Cost-optimized
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small",  # 85% cheaper than large
            "dimensions": 1536,
        }
    },

    # Vector Store - High performance
    vector_store={
        "provider": "qdrant",
        "config": {
            "collection_name": "memories",
            "host": "localhost",
            "port": 6333,
            "on_disk": True,  # Reduce memory usage
            "prefer_grpc": True,  # Faster than HTTP
            "timeout": 5,

            # HNSW Index Optimization
            "hnsw_config": {
                "m": 16,  # Connections per node (balance speed/memory)
                "ef_construct": 200,  # Build quality (higher = better)
            },

            # Quantization - 4x storage reduction
            "quantization_config": {
                "scalar": {
                    "type": "int8",
                    "quantile": 0.99
                }
            },

            # Connection Pooling
            "connection_pool_size": 50,
        }
    },

    # Reranker - Lightweight for cost/performance
    reranker={
        "provider": "cohere",
        "config": {
            "model": "rerank-english-v3.0",  # Fast model
            "top_n": 5,  # Rerank only top results
        }
    },

    # Graph Store (Optional) - For relationship-heavy use cases
    # graph_store={
    #     "provider": "neo4j",
    #     "config": {
    #         "url": "bolt://localhost:7687",
    #         "username": "neo4j",
    #         "password": "password"
    #     }
    # },

    # Custom Configuration
    version="v1.1",
)

# Initialize Memory with optimized config
memory = Memory(config)

# USAGE PATTERNS

# 1. Optimized Search (with caching)
def optimized_search(query: str, user_id: str, use_cache: bool = True):
    """Search with all optimizations enabled"""

    if use_cache:
        from cache_config_redis import cached_search
        return cached_search(
            memory,
            query,
            user_id=user_id,
            limit=5,  # Reduced for speed
            filters={"user_id": user_id},  # Always filter
            rerank=False  # Disable for simple queries
        )

    return memory.search(
        query,
        user_id=user_id,
        limit=5,
        filters={"user_id": user_id}
    )

# 2. Batch Operations
def batch_add_memories(messages: list, user_id: str):
    """Add multiple memories efficiently"""
    return memory.add(messages, user_id=user_id)  # Single API call

# 3. Async Operations for High Throughput
async def async_search_multiple(queries: list, user_id: str):
    """Search multiple queries concurrently"""
    import asyncio
    from mem0 import AsyncMemory

    async_memory = AsyncMemory(config)

    return await asyncio.gather(*[
        async_memory.search(q, user_id=user_id, limit=3)
        for q in queries
    ])

# MONITORING
def get_memory_stats():
    """Get memory system statistics"""
    # Implement based on your monitoring setup
    return {
        "total_memories": "...",
        "storage_size": "...",
        "query_latency_avg": "...",
    }

# CONFIGURATION PRESETS

def get_chat_app_config():
    """Optimized for chat applications"""
    return MemoryConfig(
        embedder={
            "provider": "openai",
            "config": {"model": "text-embedding-3-small"}
        },
        vector_store={
            "provider": "qdrant",
            "config": {
                "on_disk": True,
                "hnsw_config": {"m": 12, "ef_construct": 100}
            }
        }
    )

def get_rag_config():
    """Optimized for RAG systems"""
    return MemoryConfig(
        embedder={
            "provider": "openai",
            "config": {"model": "text-embedding-3-small"}
        },
        vector_store={
            "provider": "qdrant",
            "config": {
                "on_disk": True,
                "hnsw_config": {"m": 16, "ef_construct": 200}  # Higher quality
            }
        },
        reranker={
            "provider": "cohere",
            "config": {"model": "rerank-english-v3.5"}  # Better accuracy
        }
    )

def get_high_performance_config():
    """Maximum performance (higher cost)"""
    return MemoryConfig(
        embedder={
            "provider": "openai",
            "config": {"model": "text-embedding-3-large"}  # Best quality
        },
        vector_store={
            "provider": "qdrant",
            "config": {
                "on_disk": False,  # All in-memory
                "hnsw_config": {"m": 32, "ef_construct": 400}
            }
        }
    )

def get_cost_optimized_config():
    """Minimum cost (acceptable performance)"""
    return MemoryConfig(
        embedder={
            "provider": "openai",
            "config": {"model": "text-embedding-ada-002"}  # Cheapest
        },
        vector_store={
            "provider": "chroma",
            "config": {"collection_name": "memories"}
        }
        # No reranker to save costs
    )

# Usage: Select preset based on your use case
# memory = Memory(get_chat_app_config())
