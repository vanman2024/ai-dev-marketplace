"""
Multi-Level Memory Pattern for Mem0
====================================

This template demonstrates how to implement a comprehensive memory architecture
that combines user, agent, and session memories with intelligent context merging.

Use this pattern for:
- Customer support systems
- Personal assistants
- Multi-agent collaboration
- Context-aware applications
"""

import os
from typing import Dict, List, Optional
from mem0 import Memory

class MultiLevelMemoryManager:
    """
    Manages memory across three levels: user, agent, and session.
    Provides intelligent context retrieval and merging.
    """

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize the memory manager.

        Args:
            api_key: Mem0 API key (defaults to MEM0_API_KEY env var)
        """
        self.memory = Memory()
        self.api_key = api_key or os.getenv('MEM0_API_KEY')

    def add_user_memory(
        self,
        content: str,
        user_id: str,
        metadata: Optional[Dict] = None
    ) -> Dict:
        """
        Add a user-level memory (persistent preferences/profile).

        Args:
            content: Memory content
            user_id: Unique user identifier
            metadata: Optional metadata (categories, tags, etc.)

        Returns:
            Result dict with memory ID and status
        """
        return self.memory.add(
            content,
            user_id=user_id,
            metadata=metadata or {}
        )

    def add_agent_memory(
        self,
        content: str,
        agent_id: str,
        metadata: Optional[Dict] = None
    ) -> Dict:
        """
        Add an agent-level memory (agent capabilities/procedures).

        Args:
            content: Memory content
            agent_id: Unique agent identifier
            metadata: Optional metadata

        Returns:
            Result dict with memory ID and status
        """
        return self.memory.add(
            content,
            agent_id=agent_id,
            metadata=metadata or {}
        )

    def add_session_memory(
        self,
        content: str,
        user_id: str,
        run_id: str,
        metadata: Optional[Dict] = None
    ) -> Dict:
        """
        Add a session-level memory (temporary conversation context).

        Args:
            content: Memory content
            user_id: User identifier
            run_id: Session/run identifier
            metadata: Optional metadata

        Returns:
            Result dict with memory ID and status
        """
        return self.memory.add(
            content,
            user_id=user_id,
            run_id=run_id,
            metadata=metadata or {}
        )

    def get_multi_level_context(
        self,
        query: str,
        user_id: str,
        agent_id: str,
        run_id: str,
        weights: Optional[Dict[str, float]] = None
    ) -> Dict[str, List[Dict]]:
        """
        Retrieve and merge context from all three memory levels.

        Args:
            query: Search query
            user_id: User identifier
            agent_id: Agent identifier
            run_id: Session identifier
            weights: Optional weight dict for context levels
                    Default: {"session": 0.4, "user": 0.35, "agent": 0.25}

        Returns:
            Dict with 'merged' context and individual level results
        """
        # Default weights
        if weights is None:
            weights = {
                "session": 0.4,   # Highest - most relevant to current task
                "user": 0.35,      # High - personalizes response
                "agent": 0.25      # Moderate - ensures consistent behavior
            }

        # Retrieve from each level
        session_results = self.memory.search(
            query,
            user_id=user_id,
            run_id=run_id,
            limit=5
        )

        user_results = self.memory.search(
            query,
            user_id=user_id,
            limit=5
        )

        agent_results = self.memory.search(
            query,
            agent_id=agent_id,
            limit=5
        )

        # Merge with weighted scoring
        merged_context = self._merge_contexts(
            session=session_results.get('results', []),
            user=user_results.get('results', []),
            agent=agent_results.get('results', []),
            weights=weights
        )

        return {
            "merged": merged_context,
            "session": session_results.get('results', []),
            "user": user_results.get('results', []),
            "agent": agent_results.get('results', [])
        }

    def _merge_contexts(
        self,
        session: List[Dict],
        user: List[Dict],
        agent: List[Dict],
        weights: Dict[str, float]
    ) -> List[Dict]:
        """
        Merge contexts from different levels with weighted scoring.

        Args:
            session: Session-level memories
            user: User-level memories
            agent: Agent-level memories
            weights: Weight dict for each level

        Returns:
            Merged and sorted list of memories
        """
        all_memories = []

        # Add session memories with weight
        for mem in session:
            mem_copy = mem.copy()
            mem_copy['weighted_score'] = mem.get('score', 1.0) * weights['session']
            mem_copy['source'] = 'session'
            all_memories.append(mem_copy)

        # Add user memories with weight
        for mem in user:
            mem_copy = mem.copy()
            mem_copy['weighted_score'] = mem.get('score', 1.0) * weights['user']
            mem_copy['source'] = 'user'
            all_memories.append(mem_copy)

        # Add agent memories with weight
        for mem in agent:
            mem_copy = mem.copy()
            mem_copy['weighted_score'] = mem.get('score', 1.0) * weights['agent']
            mem_copy['source'] = 'agent'
            all_memories.append(mem_copy)

        # Sort by weighted score
        all_memories.sort(key=lambda x: x['weighted_score'], reverse=True)

        # Return top 10
        return all_memories[:10]

    def cleanup_session(self, run_id: str) -> int:
        """
        Delete all memories for a specific session.

        Args:
            run_id: Session identifier to clean up

        Returns:
            Number of memories deleted
        """
        # Get all session memories
        all_memories = self.memory.get_all(run_id=run_id)

        count = 0
        for mem in all_memories.get('results', []):
            self.memory.delete(mem['id'])
            count += 1

        return count


# Example usage
if __name__ == "__main__":
    # Initialize manager
    manager = MultiLevelMemoryManager()

    # User info
    user_id = "alice_123"
    agent_id = "support_agent_v2"
    run_id = "session_20250127_001"

    # Add user-level memories (persistent)
    manager.add_user_memory(
        "User prefers concise responses without technical jargon",
        user_id=user_id,
        metadata={"category": "communication_style"}
    )

    manager.add_user_memory(
        "User is located in Seattle, timezone PST",
        user_id=user_id,
        metadata={"category": "profile"}
    )

    # Add agent-level memories (agent capabilities)
    manager.add_agent_memory(
        "When handling refund requests, always check order date first",
        agent_id=agent_id,
        metadata={"category": "procedure"}
    )

    manager.add_agent_memory(
        "Can process refunds up to $500 without supervisor approval",
        agent_id=agent_id,
        metadata={"category": "capability"}
    )

    # Add session-level memories (current conversation)
    manager.add_session_memory(
        "User is asking about a refund for order #12345",
        user_id=user_id,
        run_id=run_id,
        metadata={"category": "current_issue"}
    )

    manager.add_session_memory(
        "Order was placed 3 days ago, within refund window",
        user_id=user_id,
        run_id=run_id,
        metadata={"category": "current_context"}
    )

    # Retrieve multi-level context
    context = manager.get_multi_level_context(
        query="How should I handle this refund request?",
        user_id=user_id,
        agent_id=agent_id,
        run_id=run_id
    )

    # Print merged context
    print("Merged Context (top 5):")
    print("=" * 50)
    for i, mem in enumerate(context['merged'][:5], 1):
        print(f"{i}. [{mem['source'].upper()}] {mem.get('memory', 'N/A')}")
        print(f"   Score: {mem.get('weighted_score', 0):.3f}")
        print()

    # Cleanup session after conversation ends
    deleted_count = manager.cleanup_session(run_id)
    print(f"Cleaned up {deleted_count} session memories")
