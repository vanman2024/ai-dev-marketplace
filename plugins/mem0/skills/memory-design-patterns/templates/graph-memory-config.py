"""
Graph Memory Configuration
===========================

Graph-based memory setup for Mem0 with Neo4j/Memgraph. Best for:
- Knowledge management systems
- Multi-entity relationships
- Organizational hierarchies
- Social network applications
- Complex reasoning requirements

This configuration enables relationship extraction and graph queries.
"""

import os
from mem0 import Memory
from mem0.configs.base import MemoryConfig

def create_graph_memory(
    graph_provider: str = "neo4j",
    embedding_model: str = "text-embedding-3-small"
) -> Memory:
    """
    Create a graph-enabled memory instance.

    Args:
        graph_provider: Graph database provider ("neo4j" or "memgraph")
        embedding_model: OpenAI embedding model name

    Returns:
        Configured Memory instance with graph capabilities
    """

    config = MemoryConfig(
        embedder={
            "provider": "openai",
            "config": {
                "model": embedding_model,
                "api_key": os.getenv("OPENAI_API_KEY")
            }
        },
        vector_store={
            "provider": "qdrant",  # Still need vector for semantic search
            "config": {
                "host": os.getenv("QDRANT_HOST", "localhost"),
                "port": int(os.getenv("QDRANT_PORT", "6333"))
            }
        },
        graph_store={
            "provider": graph_provider,
            "config": _get_graph_store_config(graph_provider)
        }
    )

    return Memory.from_config(config)


def _get_graph_store_config(provider: str) -> dict:
    """
    Get configuration for specific graph store provider.

    Args:
        provider: Graph store provider name

    Returns:
        Configuration dict for the provider
    """
    if provider == "neo4j":
        return {
            "url": os.getenv("NEO4J_URL", "bolt://localhost:7687"),
            "username": os.getenv("NEO4J_USERNAME", "neo4j"),
            "password": os.getenv("NEO4J_PASSWORD")
        }

    elif provider == "memgraph":
        return {
            "url": os.getenv("MEMGRAPH_URL", "bolt://localhost:7687"),
            "username": os.getenv("MEMGRAPH_USERNAME", ""),
            "password": os.getenv("MEMGRAPH_PASSWORD", "")
        }

    else:
        raise ValueError(f"Unsupported graph store: {provider}")


# Example 1: Basic graph memory usage
def example_basic_graph():
    """Simple graph memory with relationship extraction"""
    memory = create_graph_memory()

    # Add memory with entity relationships
    result = memory.add(
        "Alice works with Bob on the DataPipeline project",
        user_id="system"
    )

    # Results include both memories and relationships
    print("Memories:", result.get('results'))
    print("Relations:", result.get('relations'))
    # Relations: [
    #   {'source': 'Alice', 'relationship': 'WORKS_WITH', 'target': 'Bob'},
    #   {'source': 'Alice', 'relationship': 'WORKS_ON', 'target': 'DataPipeline'},
    #   {'source': 'Bob', 'relationship': 'WORKS_ON', 'target': 'DataPipeline'}
    # ]

    # Search returns related entities
    search_results = memory.search("Alice's projects", user_id="system")
    print("Graph connections:", search_results.get('relations'))


# Example 2: Organizational hierarchy
class OrganizationMemory:
    """
    Manage organizational structure and relationships using graph memory.
    """

    def __init__(self):
        self.memory = create_graph_memory(graph_provider="neo4j")

    def add_employee(
        self,
        name: str,
        role: str,
        department: str,
        manager: str = None
    ):
        """Add employee with relationships"""
        content = f"{name} is a {role} in the {department} department"
        if manager:
            content += f" reporting to {manager}"

        return self.memory.add(content, user_id="organization")

    def add_team_structure(
        self,
        team_name: str,
        members: list,
        lead: str
    ):
        """Define team structure"""
        content = f"{lead} leads the {team_name} team with members: {', '.join(members)}"
        return self.memory.add(content, user_id="organization")

    def query_org_structure(self, query: str):
        """Query organizational relationships"""
        results = self.memory.search(
            query,
            user_id="organization",
            enable_graph=True
        )

        return {
            "memories": results.get('results', []),
            "relationships": results.get('relations', [])
        }


# Example 3: Knowledge graph for customer support
class CustomerSupportKnowledgeGraph:
    """
    Build a knowledge graph for customer support with product/issue relationships.
    """

    def __init__(self):
        self.memory = create_graph_memory()

    def add_product_info(self, product: str, features: list):
        """Add product with features"""
        content = f"{product} has features: {', '.join(features)}"
        return self.memory.add(
            content,
            agent_id="support_agent",
            metadata={"type": "product_info"}
        )

    def add_common_issue(self, product: str, issue: str, solution: str):
        """Add common issue and solution"""
        content = f"For {product}, when {issue} occurs, solution is: {solution}"
        return self.memory.add(
            content,
            agent_id="support_agent",
            metadata={"type": "issue_solution"}
        )

    def add_customer_history(self, customer_id: str, interaction: str):
        """Add customer interaction history"""
        return self.memory.add(
            interaction,
            user_id=customer_id,
            metadata={"type": "interaction_history"}
        )

    def get_support_context(
        self,
        customer_id: str,
        query: str,
        include_graph: bool = True
    ):
        """
        Get comprehensive support context including:
        - Customer history (user memory)
        - Product knowledge (agent memory)
        - Related entities (graph relationships)
        """
        # Customer-specific context
        customer_context = self.memory.search(
            query,
            user_id=customer_id,
            enable_graph=include_graph
        )

        # Agent knowledge
        agent_context = self.memory.search(
            query,
            agent_id="support_agent",
            enable_graph=include_graph
        )

        return {
            "customer": customer_context,
            "knowledge": agent_context
        }


# Example 4: Multi-hop graph queries
def example_multi_hop_queries():
    """Demonstrate multi-hop relationship traversal"""
    memory = create_graph_memory()

    # Build a relationship chain
    memory.add("Alice is friends with Bob", user_id="social")
    memory.add("Bob is friends with Charlie", user_id="social")
    memory.add("Charlie works at OpenAI", user_id="social")

    # Query can traverse relationships
    # "Who does Alice know that works at OpenAI?"
    results = memory.search(
        "Alice's connections to OpenAI",
        user_id="social",
        enable_graph=True
    )

    # Graph will show: Alice -> Bob -> Charlie -> OpenAI
    return results.get('relations', [])


# Example 5: Complete production setup
class GraphMemoryApp:
    """
    Production-ready graph memory application.
    """

    def __init__(self, environment: str = "development"):
        """
        Initialize graph memory for environment.

        Args:
            environment: "development", "staging", or "production"
        """
        self.environment = environment

        # Select graph provider based on environment
        if environment == "production":
            # Production: Managed Neo4j Aura
            graph_provider = "neo4j"
            os.environ["NEO4J_URL"] = os.getenv("NEO4J_AURA_URL")
        else:
            # Development/Staging: Local Neo4j
            graph_provider = "neo4j"

        self.memory = create_graph_memory(graph_provider=graph_provider)

    def add_with_relationships(
        self,
        content: str,
        user_id: str = None,
        agent_id: str = None,
        extract_entities: bool = True
    ):
        """
        Add memory with automatic relationship extraction.

        Args:
            content: Memory content
            user_id: Optional user identifier
            agent_id: Optional agent identifier
            extract_entities: Whether to extract entity relationships

        Returns:
            Result with memories and extracted relationships
        """
        return self.memory.add(
            content,
            user_id=user_id,
            agent_id=agent_id
        )

    def search_with_graph_context(
        self,
        query: str,
        user_id: str = None,
        agent_id: str = None,
        max_depth: int = 2
    ):
        """
        Search with graph relationship context.

        Args:
            query: Search query
            user_id: Optional user filter
            agent_id: Optional agent filter
            max_depth: Maximum relationship traversal depth

        Returns:
            Results with graph relationships
        """
        kwargs = {
            "enable_graph": True
        }

        if user_id:
            kwargs["user_id"] = user_id
        if agent_id:
            kwargs["agent_id"] = agent_id

        return self.memory.search(query, **kwargs)


# Usage examples
if __name__ == "__main__":
    # Example 1: Organization hierarchy
    org = OrganizationMemory()

    org.add_employee("Alice Johnson", "Senior Engineer", "Engineering", manager="Bob Smith")
    org.add_employee("Bob Smith", "Engineering Manager", "Engineering")
    org.add_team_structure("Backend Team", ["Alice Johnson", "Charlie Davis"], lead="Bob Smith")

    results = org.query_org_structure("Who reports to Bob Smith?")
    print("Organization structure:", results['relationships'])

    # Example 2: Customer support knowledge graph
    support = CustomerSupportKnowledgeGraph()

    support.add_product_info("CloudSync Pro", ["real-time sync", "encryption", "mobile apps"])
    support.add_common_issue(
        "CloudSync Pro",
        "sync fails",
        "Check network connection and restart app"
    )
    support.add_customer_history("customer_123", "Had sync issues last month, resolved")

    context = support.get_support_context("customer_123", "CloudSync sync problems")
    print("Support context:", context)


# Best Practices for Graph Memory
"""
GRAPH MEMORY BEST PRACTICES:
=============================

1. When to Use Graph:
   ✓ Complex entity relationships
   ✓ Multi-hop queries needed
   ✓ Organizational hierarchies
   ✓ Knowledge graphs
   ✗ Simple preference storage (use vector only)

2. Relationship Design:
   - Keep relationships semantic and clear
   - Use consistent naming (WORKS_WITH, REPORTS_TO, FRIEND_OF)
   - Limit traversal depth (2-3 hops maximum)
   - Index key properties (user_id, entity names)

3. Performance:
   - Index frequently queried properties
   - Limit result sets
   - Cache common queries
   - Monitor graph database size

4. Cost Considerations:
   - Graph DB adds $20-100/month
   - Still need vector store ($5-15/month)
   - Total: $25-115/month vs $5-15 vector-only
   - Only use if relationships are critical

5. Query Optimization:
   - Use filters to reduce search space
   - Limit traversal depth
   - Cache relationship queries
   - Monitor slow queries (>100ms)

6. Scaling:
   - < 10k entities: Single Neo4j instance
   - 10k-100k: Optimized indexes, consider sharding
   - > 100k: Neo4j cluster or managed service

7. Monitoring:
   - Track relationship count growth
   - Monitor query latency
   - Alert on slow queries
   - Regular graph cleanup
"""
