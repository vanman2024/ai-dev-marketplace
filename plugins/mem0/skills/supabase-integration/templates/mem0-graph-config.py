"""
Full-featured Mem0 configuration with graph memory support
Use this for complex relationship tracking between memories
"""

import os
from mem0 import Memory

# Configuration with vector store + graph store
config = {
    "vector_store": {
        "provider": "postgres",
        "config": {
            "url": os.getenv("SUPABASE_DB_URL"),
            "table_name": "memories",
            "embedding_dimension": 1536
        }
    },
    "graph_store": {
        "provider": "postgres",  # Using same DB for graph relationships
        "config": {
            "url": os.getenv("SUPABASE_DB_URL"),
            "relationship_table": "memory_relationships"
        }
    },
    "embedder": {
        "provider": "openai",
        "config": {
            "model": "text-embedding-3-small",
            "api_key": os.getenv("OPENAI_API_KEY")
        }
    },
    "llm": {
        "provider": "openai",
        "config": {
            "model": "gpt-4",
            "api_key": os.getenv("OPENAI_API_KEY")
        }
    },
    "version": "v1.1"
}

# Initialize Mem0 client with graph support
memory = Memory.from_config(config)

# Example usage with graph memory
if __name__ == "__main__":
    # Add memories with relationships (extracted automatically)
    result = memory.add(
        "John Smith works with Sarah Johnson at Acme Corp. "
        "Sarah is the project manager for the Alpha project. "
        "John reports to Sarah and focuses on backend development.",
        user_id="org-acme-corp"
    )
    print(f"Memories and relationships created: {result}")

    # Search with relationship context
    results = memory.search(
        "Who does John work with?",
        user_id="org-acme-corp",
        limit=10
    )

    print("\nSearch results:")
    for mem in results:
        print(f"  - {mem['memory']}")
        if 'relationships' in mem:
            print(f"    Relationships: {mem['relationships']}")

    # Query graph relationships
    # (assuming Mem0 provides graph query methods)
    try:
        # Get all memories related to John
        john_context = memory.search(
            "John",
            user_id="org-acme-corp",
            include_relationships=True
        )
        print(f"\nJohn's context: {len(john_context)} memories with relationships")
    except Exception as e:
        print(f"Note: Graph querying may require additional Mem0 setup: {e}")
