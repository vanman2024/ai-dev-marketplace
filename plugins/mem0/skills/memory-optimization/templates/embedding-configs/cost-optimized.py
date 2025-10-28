"""
Cost-optimized Mem0 configuration
Minimizes costs while maintaining acceptable performance
"""

from mem0 import Memory
from mem0.configs.base import MemoryConfig

# COST-OPTIMIZED CONFIGURATION
config = MemoryConfig(
    # Cheapest embedding model
    embedder={
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small",  # $0.02/1M (85% cheaper than large)
            # Could use ada-002 for even lower cost ($0.0001/1M) but lower quality
        }
    },

    # Lightweight vector store
    vector_store={
        "provider": "chroma",  # Easy setup, no infrastructure costs
        "config": {
            "collection_name": "memories",
            "path": "./chroma_db"  # Local storage
        }
    },

    # No reranker to save costs
    # reranker=None (default)

    # No graph store to save infrastructure
    # graph_store=None (default)
)

memory = Memory(config)

# Cost-optimized usage patterns
def cost_optimized_search(query: str, user_id: str):
    """Search with minimal cost"""
    return memory.search(
        query,
        user_id=user_id,
        limit=3,  # Minimal results to reduce costs
        filters={"user_id": user_id},  # Always filter
        rerank=False  # No reranking
    )

def batch_add_for_cost(messages: list, user_id: str):
    """Batch to reduce embedding API calls"""
    # Group messages for batching
    return memory.add(messages, user_id=user_id)

# Expected costs (for 10,000 operations/month):
# - Embedding: ~$0.50/month
# - Storage: $0 (local Chroma)
# - Infrastructure: $0 (self-hosted)
# Total: ~$0.50/month + your server costs
