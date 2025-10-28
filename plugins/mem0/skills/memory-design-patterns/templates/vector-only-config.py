"""
Vector-Only Memory Configuration
=================================

Simple vector-based memory setup for Mem0. Best for:
- Basic preference storage
- Semantic search use cases
- Quick prototyping
- Small to medium scale applications

This configuration uses vector embeddings only, without graph capabilities.
"""

import os
from mem0 import Memory
from mem0.configs.base import MemoryConfig

def create_vector_memory(
    vector_store: str = "qdrant",
    embedding_model: str = "text-embedding-3-small",
    embedding_dims: int = 1536
) -> Memory:
    """
    Create a vector-only memory instance.

    Args:
        vector_store: Vector database provider ("qdrant", "pinecone", "chroma")
        embedding_model: OpenAI embedding model name
        embedding_dims: Embedding dimensions (1536 for small, 3072 for large)

    Returns:
        Configured Memory instance
    """

    # Basic configuration (uses defaults)
    config = MemoryConfig(
        embedder={
            "provider": "openai",
            "config": {
                "model": embedding_model,
                "embedding_dims": embedding_dims,
                "api_key": os.getenv("OPENAI_API_KEY")
            }
        },
        vector_store={
            "provider": vector_store,
            "config": _get_vector_store_config(vector_store)
        }
    )

    return Memory.from_config(config)


def _get_vector_store_config(provider: str) -> dict:
    """
    Get configuration for specific vector store provider.

    Args:
        provider: Vector store provider name

    Returns:
        Configuration dict for the provider
    """
    if provider == "qdrant":
        return {
            "host": os.getenv("QDRANT_HOST", "localhost"),
            "port": int(os.getenv("QDRANT_PORT", "6333")),
            "collection_name": os.getenv("QDRANT_COLLECTION", "mem0_memories")
        }

    elif provider == "pinecone":
        return {
            "api_key": os.getenv("PINECONE_API_KEY"),
            "environment": os.getenv("PINECONE_ENV", "us-west1-gcp"),
            "index_name": os.getenv("PINECONE_INDEX", "mem0-memories")
        }

    elif provider == "chroma":
        return {
            "host": os.getenv("CHROMA_HOST", "localhost"),
            "port": int(os.getenv("CHROMA_PORT", "8000")),
            "collection_name": os.getenv("CHROMA_COLLECTION", "mem0_memories")
        }

    else:
        raise ValueError(f"Unsupported vector store: {provider}")


# Example 1: Default configuration (Qdrant local)
def example_default():
    """Simple default configuration"""
    memory = Memory()

    # Add memories
    memory.add("User prefers dark mode", user_id="alice")
    memory.add("Lives in Seattle", user_id="alice")

    # Search
    results = memory.search("location", user_id="alice")
    print(results)


# Example 2: Optimized for cost (smaller embeddings)
def example_cost_optimized():
    """Cost-optimized configuration with smaller embeddings"""
    memory = create_vector_memory(
        vector_store="qdrant",
        embedding_model="text-embedding-3-small",  # Cheaper than large
        embedding_dims=1536  # Half the size of large model
    )

    return memory


# Example 3: Optimized for quality (larger embeddings)
def example_quality_optimized():
    """Quality-optimized configuration with larger embeddings"""
    memory = create_vector_memory(
        vector_store="pinecone",
        embedding_model="text-embedding-3-large",  # Best quality
        embedding_dims=3072  # Full dimension size
    )

    return memory


# Example 4: With custom vector store (Pinecone)
def example_pinecone():
    """Pinecone-based configuration for production scale"""
    from mem0 import Memory
    from mem0.configs.base import MemoryConfig

    config = MemoryConfig(
        vector_store={
            "provider": "pinecone",
            "config": {
                "api_key": os.getenv("PINECONE_API_KEY"),
                "environment": "us-west1-gcp",
                "index_name": "mem0-production",
                "metric": "cosine",  # cosine, euclidean, or dotproduct
                "dimension": 1536
            }
        }
    )

    return Memory.from_config(config)


# Example 5: Complete application setup
class VectorMemoryApp:
    """
    Complete application-ready vector memory setup.
    """

    def __init__(self, environment: str = "development"):
        """
        Initialize memory based on environment.

        Args:
            environment: "development", "staging", or "production"
        """
        self.environment = environment

        if environment == "production":
            # Production: Pinecone with quality embeddings
            self.memory = create_vector_memory(
                vector_store="pinecone",
                embedding_model="text-embedding-3-large",
                embedding_dims=3072
            )
        elif environment == "staging":
            # Staging: Pinecone with cost-optimized embeddings
            self.memory = create_vector_memory(
                vector_store="pinecone",
                embedding_model="text-embedding-3-small",
                embedding_dims=1536
            )
        else:
            # Development: Local Qdrant
            self.memory = create_vector_memory(
                vector_store="qdrant",
                embedding_model="text-embedding-3-small",
                embedding_dims=1536
            )

    def add_user_preference(self, user_id: str, preference: str):
        """Add a user preference memory."""
        return self.memory.add(
            preference,
            user_id=user_id,
            metadata={"type": "preference"}
        )

    def get_user_context(self, user_id: str, query: str, limit: int = 5):
        """Retrieve user context for a query."""
        return self.memory.search(
            query,
            user_id=user_id,
            limit=limit
        )


# Usage example
if __name__ == "__main__":
    # Initialize for your environment
    app = VectorMemoryApp(environment="development")

    # Add memories
    app.add_user_preference("bob", "Prefers email notifications")
    app.add_user_preference("bob", "Interested in AI and machine learning")

    # Retrieve context
    context = app.get_user_context("bob", "communication preferences")

    print("User context:")
    for mem in context.get('results', []):
        print(f"- {mem.get('memory')}")


# Configuration Best Practices
"""
BEST PRACTICES:
===============

1. Embedding Model Selection:
   - text-embedding-3-small: Cost-optimized, good quality
   - text-embedding-3-large: Best quality, higher cost
   - Start with small, upgrade to large if quality issues

2. Vector Store Selection:
   - Development: Qdrant (local, free, easy setup)
   - Staging: Qdrant or Pinecone (test at scale)
   - Production: Pinecone or managed Qdrant (reliability, scale)

3. Search Limits:
   - Chat applications: 3-5 results
   - RAG systems: 5-10 results
   - Don't use more than 10 (diminishing returns)

4. Metadata Usage:
   - Add categories for filtering: {"category": "preferences"}
   - Add timestamps: {"created_at": "2025-01-27"}
   - Add custom tags: {"tags": ["important", "verified"]}

5. Performance:
   - Cache frequently accessed memories
   - Use filters to reduce search space
   - Batch operations when possible
   - Monitor query latency

6. Cost Optimization:
   - Use smaller embeddings (1536 vs 3072)
   - Implement deduplication
   - Archive old memories
   - Set up retention policies
"""
