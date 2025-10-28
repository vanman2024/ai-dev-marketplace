"""
Performance-optimized Mem0 configuration
Maximizes speed and accuracy (higher cost)
"""

from mem0 import Memory
from mem0.configs.base import MemoryConfig

# PERFORMANCE-OPTIMIZED CONFIGURATION
config = MemoryConfig(
    # Best embedding model for accuracy
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-large",  # 3072 dims, highest quality
        }
    },

    # High-performance vector store
    vector_store={
        "provider": "qdrant",
        "config": {
            "collection_name": "memories",
            "host": "localhost",
            "port": 6333,
            "on_disk": False,  # All in-memory for maximum speed
            "prefer_grpc": True,
            "hnsw_config": {
                "m": 32,  # More connections = better accuracy
                "ef_construct": 400,  # Higher quality index
                "ef_search": 200,  # More thorough search
            },
            # No quantization for maximum accuracy
        }
    },

    # Best reranker for accuracy
    reranker={
        "provider": "cohere",
        "config": {
            "model": "rerank-english-v3.5",  # Most accurate model
            "top_n": 20,  # Rerank more results
        }
    },
)

memory = Memory(config)

# Performance-optimized usage
def high_performance_search(query: str, user_id: str):
    """Maximum accuracy search"""
    return memory.search(
        query,
        user_id=user_id,
        limit=20,  # More results for better recall
        rerank=True,  # Always rerank for accuracy
    )

# Expected performance:
# - Query latency: 150-250ms (with reranking)
# - Accuracy: 95-98%
# - Cost: ~10x cost-optimized config
