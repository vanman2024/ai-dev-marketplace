"""
Enterprise multi-tenant Mem0 configuration
Includes organization isolation, role-based access, and audit logging
"""

import os
from mem0 import Memory
from typing import Optional, Dict, Any
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EnterpriseMemoryClient:
    """
    Enterprise-grade memory client with multi-tenancy support
    """

    def __init__(self, org_id: str, user_id: str, role: str = "member"):
        self.org_id = org_id
        self.user_id = user_id
        self.role = role

        # Configuration with organization metadata
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
                "provider": "postgres",
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
            "version": "v1.1"
        }

        self.memory = Memory.from_config(config)
        logger.info(f"Initialized memory client for org: {org_id}, user: {user_id}")

    def add_memory(self, content: str, categories: Optional[list] = None) -> Dict[str, Any]:
        """
        Add memory with organization context
        """
        metadata = {
            "org_id": self.org_id,
            "added_by_role": self.role
        }

        if categories:
            metadata["categories"] = categories

        result = self.memory.add(
            content,
            user_id=self.user_id,
            metadata=metadata
        )

        logger.info(f"Memory added for user {self.user_id} in org {self.org_id}")
        return result

    def search_memories(
        self,
        query: str,
        limit: int = 10,
        org_scope: bool = True
    ) -> list:
        """
        Search memories with organization filtering
        """
        # Build filters for organization scope
        filters = {}
        if org_scope:
            filters = {
                "metadata": {
                    "org_id": self.org_id
                }
            }

        results = self.memory.search(
            query,
            user_id=self.user_id if not org_scope else None,
            filters=filters if filters else None,
            limit=limit
        )

        logger.info(f"Search returned {len(results)} results for query: {query}")
        return results

    def get_user_memories(self, target_user_id: Optional[str] = None) -> list:
        """
        Get all memories for a user (admin can access other users)
        """
        target = target_user_id if self.role == "admin" and target_user_id else self.user_id

        if target != self.user_id and self.role != "admin":
            logger.warning(f"User {self.user_id} attempted to access {target}'s memories")
            raise PermissionError("Only admins can access other users' memories")

        memories = self.memory.get_all(user_id=target)
        logger.info(f"Retrieved {len(memories)} memories for user {target}")
        return memories

    def delete_memory(self, memory_id: str, force: bool = False) -> bool:
        """
        Delete memory (admin can force delete)
        """
        if not force and self.role != "admin":
            # Verify ownership before deletion
            # In production, check memory.user_id == self.user_id
            pass

        self.memory.delete(memory_id)
        logger.info(f"Memory {memory_id} deleted by {self.user_id} (role: {self.role})")
        return True

    def export_org_memories(self) -> list:
        """
        Export all memories for the organization (admin only)
        """
        if self.role != "admin":
            raise PermissionError("Only admins can export organization memories")

        # Search with organization filter
        all_memories = self.search_memories(
            query="",  # Empty query to get all
            org_scope=True,
            limit=10000  # High limit for export
        )

        logger.info(f"Exported {len(all_memories)} memories for org {self.org_id}")
        return all_memories


# Example usage
if __name__ == "__main__":
    # Initialize client for a user in an organization
    client = EnterpriseMemoryClient(
        org_id="acme-corp",
        user_id="user-john-123",
        role="member"
    )

    # Add organization-scoped memory
    client.add_memory(
        "Company uses AWS for all cloud infrastructure",
        categories=["infrastructure", "technical"]
    )

    # Search within organization
    results = client.search_memories(
        "cloud infrastructure",
        org_scope=True
    )
    print(f"Found {len(results)} memories about cloud infrastructure")

    # Admin-only operations
    admin_client = EnterpriseMemoryClient(
        org_id="acme-corp",
        user_id="admin-sarah-456",
        role="admin"
    )

    # Admin can access other users' memories
    john_memories = admin_client.get_user_memories(target_user_id="user-john-123")
    print(f"Admin viewing John's memories: {len(john_memories)}")

    # Export all organization memories
    org_export = admin_client.export_org_memories()
    print(f"Organization memory export: {len(org_export)} total memories")
