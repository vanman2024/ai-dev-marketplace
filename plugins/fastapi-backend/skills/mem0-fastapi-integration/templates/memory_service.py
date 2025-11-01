"""
Mem0 Memory Service for FastAPI
Complete implementation of memory management with Mem0
"""

from typing import List, Dict, Optional, Any
from mem0 import Memory, AsyncMemory, MemoryClient
from mem0.configs.base import MemoryConfig
import asyncio
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class MemoryService:
    """
    Memory service integrating Mem0 with FastAPI.
    Supports both hosted and self-hosted configurations.
    """

    def __init__(self, settings):
        """
        Initialize Mem0 memory client.

        Args:
            settings: Application settings with Mem0 configuration
        """
        self.settings = settings
        self.memory: Optional[AsyncMemory] = None
        self.client: Optional[MemoryClient] = None
        self._initialize_memory()

    def _initialize_memory(self):
        """Initialize Mem0 memory client based on configuration"""
        try:
            if self.settings.MEM0_API_KEY:
                # Use hosted Mem0 platform
                self.client = MemoryClient(api_key=self.settings.MEM0_API_KEY)
                logger.info("Initialized Mem0 hosted client")
            else:
                # Use self-hosted configuration
                config = MemoryConfig(
                    vector_store={
                        "provider": "qdrant",
                        "config": {
                            "host": self.settings.QDRANT_HOST,
                            "port": self.settings.QDRANT_PORT,
                            "api_key": self.settings.QDRANT_API_KEY,
                        },
                    },
                    llm={
                        "provider": "openai",
                        "config": {
                            "model": "gpt-4",
                            "api_key": self.settings.OPENAI_API_KEY,
                        },
                    },
                    embedder={
                        "provider": "openai",
                        "config": {
                            "model": "text-embedding-3-small",
                            "api_key": self.settings.OPENAI_API_KEY,
                        },
                    },
                )
                self.memory = AsyncMemory(config)
                logger.info("Initialized self-hosted Mem0 client")

        except Exception as e:
            logger.error(f"Failed to initialize Mem0: {e}")
            raise

    async def add_conversation(
        self,
        user_id: str,
        messages: List[Dict[str, str]],
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Optional[Dict]:
        """
        Add conversation to user's memory.

        Args:
            user_id: Unique user identifier
            messages: List of conversation messages
            metadata: Additional metadata for the conversation

        Returns:
            Dict with operation result or None on failure
        """
        try:
            enhanced_metadata = {
                "timestamp": datetime.now().isoformat(),
                "conversation_type": "chat",
                **(metadata or {}),
            }

            if self.client:
                # Hosted client
                result = self.client.add(
                    messages=messages, user_id=user_id, metadata=enhanced_metadata
                )
            elif self.memory:
                # Self-hosted client
                result = await self.memory.add(
                    messages=messages, user_id=user_id, metadata=enhanced_metadata
                )
            else:
                logger.error("No memory client available")
                return None

            logger.info(f"Added conversation to memory for user {user_id}")
            return result

        except Exception as e:
            logger.error(f"Error adding conversation to memory: {e}")
            return None

    async def search_memories(
        self,
        query: str,
        user_id: str,
        limit: int = 5,
        filters: Optional[Dict] = None,
    ) -> List[Dict]:
        """
        Search user memories for relevant context.

        Args:
            query: Search query
            user_id: User identifier
            limit: Maximum number of results
            filters: Optional filters for search

        Returns:
            List of relevant memories
        """
        try:
            if self.client:
                # Hosted client
                result = self.client.search(query=query, user_id=user_id, limit=limit)
            elif self.memory:
                # Self-hosted client
                result = await self.memory.search(
                    query=query, user_id=user_id, limit=limit
                )
            else:
                logger.error("No memory client available")
                return []

            memories = result.get("results", [])
            logger.info(f"Found {len(memories)} relevant memories for user {user_id}")
            return memories

        except Exception as e:
            logger.error(f"Error searching memories: {e}")
            return []

    async def get_all_memories(
        self, user_id: str, limit: int = 100
    ) -> List[Dict]:
        """
        Get all memories for a user.

        Args:
            user_id: User identifier
            limit: Maximum number of memories to retrieve

        Returns:
            List of all user memories
        """
        try:
            if self.client:
                result = self.client.get_all(user_id=user_id, limit=limit)
            elif self.memory:
                result = await self.memory.get_all(user_id=user_id, limit=limit)
            else:
                logger.error("No memory client available")
                return []

            memories = result.get("results", [])
            return memories

        except Exception as e:
            logger.error(f"Error getting all memories: {e}")
            return []

    async def get_user_summary(self, user_id: str) -> Dict[str, Any]:
        """
        Get user memory summary and statistics.

        Args:
            user_id: User identifier

        Returns:
            Dict with user memory summary
        """
        try:
            all_memories = await self.get_all_memories(user_id=user_id, limit=100)

            # Basic analysis
            summary = {
                "total_memories": len(all_memories),
                "recent_conversations": all_memories[:5],
                "memory_categories": {},
                "user_preferences": [],
            }

            # Categorize memories
            for memory in all_memories:
                metadata = memory.get("metadata", {})
                conv_type = metadata.get("conversation_type", "general")
                summary["memory_categories"][conv_type] = (
                    summary["memory_categories"].get(conv_type, 0) + 1
                )

                # Extract preferences
                if metadata.get("type") == "preference":
                    summary["user_preferences"].append(
                        {
                            "preference": memory.get("memory", ""),
                            "category": metadata.get("category", "general"),
                        }
                    )

            return summary

        except Exception as e:
            logger.error(f"Error getting user summary: {e}")
            return {"error": str(e)}

    async def add_user_preference(
        self, user_id: str, preference: str, category: str = "general"
    ) -> bool:
        """
        Add user preference to memory.

        Args:
            user_id: User identifier
            preference: User preference description
            category: Preference category

        Returns:
            True if successful, False otherwise
        """
        try:
            preference_message = {
                "role": "system",
                "content": f"User preference ({category}): {preference}",
            }

            metadata = {
                "type": "preference",
                "category": category,
                "timestamp": datetime.now().isoformat(),
            }

            if self.client:
                self.client.add(
                    messages=[preference_message], user_id=user_id, metadata=metadata
                )
            elif self.memory:
                await self.memory.add(
                    messages=[preference_message], user_id=user_id, metadata=metadata
                )
            else:
                return False

            logger.info(f"Added preference for user {user_id}: {preference}")
            return True

        except Exception as e:
            logger.error(f"Error adding preference: {e}")
            return False

    async def delete_memory(self, memory_id: str, user_id: str) -> bool:
        """
        Delete a specific memory.

        Args:
            memory_id: Memory identifier
            user_id: User identifier (for verification)

        Returns:
            True if successful, False otherwise
        """
        try:
            if self.client:
                self.client.delete(memory_id=memory_id)
            elif self.memory:
                await self.memory.delete(memory_id=memory_id)
            else:
                return False

            logger.info(f"Deleted memory {memory_id} for user {user_id}")
            return True

        except Exception as e:
            logger.error(f"Error deleting memory: {e}")
            return False

    async def delete_all_memories(self, user_id: str) -> bool:
        """
        Delete all memories for a user.

        Args:
            user_id: User identifier

        Returns:
            True if successful, False otherwise
        """
        try:
            if self.client:
                self.client.delete_all(user_id=user_id)
            elif self.memory:
                await self.memory.delete_all(user_id=user_id)
            else:
                return False

            logger.info(f"Deleted all memories for user {user_id}")
            return True

        except Exception as e:
            logger.error(f"Error deleting all memories: {e}")
            return False

    async def update_memory(
        self, memory_id: str, user_id: str, data: Dict[str, Any]
    ) -> bool:
        """
        Update a specific memory.

        Args:
            memory_id: Memory identifier
            user_id: User identifier
            data: Updated memory data

        Returns:
            True if successful, False otherwise
        """
        try:
            if self.client:
                self.client.update(memory_id=memory_id, data=data)
            elif self.memory:
                await self.memory.update(memory_id=memory_id, data=data)
            else:
                return False

            logger.info(f"Updated memory {memory_id} for user {user_id}")
            return True

        except Exception as e:
            logger.error(f"Error updating memory: {e}")
            return False

    def get_memory_stats(self) -> Dict[str, Any]:
        """
        Get overall memory service statistics.

        Returns:
            Dict with service statistics
        """
        return {
            "client_type": "hosted" if self.client else "self-hosted",
            "status": "active" if (self.client or self.memory) else "inactive",
            "timestamp": datetime.now().isoformat(),
        }
