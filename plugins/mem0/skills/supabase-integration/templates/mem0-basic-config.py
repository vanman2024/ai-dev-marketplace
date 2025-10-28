"""
Basic Mem0 configuration for Supabase backend
Use this for simple vector-based memory storage
"""

import os
from mem0 import Memory

# Basic configuration with PostgreSQL vector store
config = {
    "vector_store": {
        "provider": "postgres",
        "config": {
            "url": os.getenv("SUPABASE_DB_URL"),
            "table_name": "memories",
            "embedding_dimension": 1536  # OpenAI text-embedding-3-small
        }
    },
    "embedder": {
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small",
            "api_key": os.getenv("OPENAI_API_KEY")
        }
    },
    "version": "v1.1"
}

# Initialize Mem0 client
memory = Memory.from_config(config)

# Example usage
if __name__ == "__main__":
    # Add a memory
    result = memory.add(
        "User prefers concise technical responses without jargon",
        user_id="customer-123"
    )
    print(f"Memory added: {result}")

    # Search memories
    results = memory.search(
        "communication preferences",
        user_id="customer-123",
        limit=5
    )
    print(f"Found {len(results)} memories:")
    for mem in results:
        print(f"  - {mem['memory']} (score: {mem.get('score', 'N/A')})")

    # Get all memories for a user
    all_memories = memory.get_all(user_id="customer-123")
    print(f"Total memories: {len(all_memories)}")

    # Delete a memory
    # memory.delete(memory_id="uuid-here")
