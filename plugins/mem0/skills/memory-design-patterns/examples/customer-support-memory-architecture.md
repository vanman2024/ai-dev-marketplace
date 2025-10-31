# Customer Support Memory Architecture

Complete memory architecture implementation for a customer support system using Mem0.

## System Overview

**Use Case**: Multi-tenant customer support platform with AI-powered agents.

**Requirements**:
- Remember customer preferences and history
- Track product knowledge and common issues
- Maintain conversation context
- Support multiple support agents
- GDPR-compliant data handling

## Architecture Design

### Memory Type Distribution

```
┌─────────────────────────────────────────────────────────────┐
│                   MEMORY ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  USER MEMORY (Persistent)                                    │
│  ├─ Customer profile                                         │
│  ├─ Communication preferences                                │
│  ├─ Product ownership                                        │
│  ├─ Historical issues (resolved)                             │
│  └─ Custom preferences                                       │
│                                                               │
│  AGENT MEMORY (Shared Knowledge)                             │
│  ├─ Product documentation                                    │
│  ├─ Common issues & solutions                                │
│  ├─ Escalation procedures                                    │
│  ├─ Agent capabilities & limitations                         │
│  └─ Company policies                                         │
│                                                               │
│  SESSION MEMORY (Temporary)                                  │
│  ├─ Current issue description                                │
│  ├─ Steps already attempted                                  │
│  ├─ Sentiment/urgency                                        │
│  ├─ Related tickets                                          │
│  └─ Conversation flow                                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### Step 1: Memory Manager Setup

```python
from mem0 import Memory
from datetime import datetime
from typing import Dict, List, Optional

class CustomerSupportMemory:
    """
    Memory manager for customer support operations.
    """

    def __init__(self):
        self.memory = Memory()

    # USER MEMORY METHODS
    def add_customer_profile(self, customer_id: str, profile_data: dict):
        """Store customer profile information."""
        content = f"""
        Customer profile:
        - Name: {profile_data.get('name')}
        - Tier: {profile_data.get('tier', 'standard')}
        - Communication preference: {profile_data.get('comm_pref', 'email')}
        - Timezone: {profile_data.get('timezone', 'UTC')}
        """

        return self.memory.add(
            content
            user_id=customer_id
            metadata={
                "type": "profile"
                "tier": profile_data.get('tier', 'standard')
                "created_at": datetime.utcnow().isoformat()
            }
        )

    def add_customer_issue_history(
        self
        customer_id: str
        issue: str
        resolution: str
        product: str
    ):
        """Store resolved issue for future reference."""
        content = f"""
        Previous issue with {product}: {issue}
        Resolution: {resolution}
        """

        return self.memory.add(
            content
            user_id=customer_id
            metadata={
                "type": "issue_history"
                "product": product
                "resolved": True
                "resolved_at": datetime.utcnow().isoformat()
            }
        )

    # AGENT MEMORY METHODS
    def add_product_knowledge(
        self
        agent_id: str
        product: str
        knowledge: str
    ):
        """Store product-specific knowledge."""
        content = f"{product}: {knowledge}"

        return self.memory.add(
            content
            agent_id=agent_id
            metadata={
                "type": "product_knowledge"
                "product": product
            }
        )

    def add_common_issue_solution(
        self
        agent_id: str
        issue: str
        solution: str
        product: str = None
    ):
        """Store common issue and its solution."""
        content = f"""
        Common issue: {issue}
        Solution: {solution}
        """
        if product:
            content += f"\nProduct: {product}"

        return self.memory.add(
            content
            agent_id=agent_id
            metadata={
                "type": "solution"
                "product": product
            }
        )

    # SESSION MEMORY METHODS
    def add_session_context(
        self
        customer_id: str
        session_id: str
        context: str
    ):
        """Store session-specific context."""
        return self.memory.add(
            context
            user_id=customer_id
            run_id=session_id
            metadata={
                "type": "session_context"
                "timestamp": datetime.utcnow().isoformat()
            }
        )

    # CONTEXT RETRIEVAL
    def get_support_context(
        self
        customer_id: str
        agent_id: str
        session_id: str
        query: str
    ) -> dict:
        """
        Retrieve comprehensive support context.

        Returns:
            Dict with customer, agent, and session contexts
        """
        # Customer history
        customer_context = self.memory.search(
            query
            user_id=customer_id
            limit=5
        )

        # Agent knowledge
        agent_context = self.memory.search(
            query
            agent_id=agent_id
            limit=5
        )

        # Current session
        session_context = self.memory.search(
            query
            user_id=customer_id
            run_id=session_id
            limit=3
        )

        return {
            "customer": customer_context.get('results', [])
            "agent": agent_context.get('results', [])
            "session": session_context.get('results', [])
        }
```

### Step 2: Support Ticket Flow

```python
class SupportTicketHandler:
    """
    Handle support ticket lifecycle with memory integration.
    """

    def __init__(self):
        self.memory_manager = CustomerSupportMemory()

    def create_ticket(
        self
        customer_id: str
        issue_description: str
        product: str
    ) -> str:
        """
        Create new support ticket and session.

        Returns:
            session_id
        """
        session_id = f"ticket_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

        # Store initial issue in session memory
        self.memory_manager.add_session_context(
            customer_id=customer_id
            session_id=session_id
            context=f"New issue: {issue_description} (Product: {product})"
        )

        return session_id

    def handle_ticket(
        self
        customer_id: str
        agent_id: str
        session_id: str
        customer_message: str
    ) -> str:
        """
        Process customer message and generate response.

        Returns:
            Agent response
        """
        # Get comprehensive context
        context = self.memory_manager.get_support_context(
            customer_id=customer_id
            agent_id=agent_id
            session_id=session_id
            query=customer_message
        )

        # Build context summary for LLM
        context_summary = self._build_context_summary(context)

        # Store current message in session
        self.memory_manager.add_session_context(
            customer_id=customer_id
            session_id=session_id
            context=f"Customer: {customer_message}"
        )

        # Generate response (LLM call would go here)
        response = self._generate_response(
            customer_message
            context_summary
        )

        # Store response in session
        self.memory_manager.add_session_context(
            customer_id=customer_id
            session_id=session_id
            context=f"Agent: {response}"
        )

        return response

    def resolve_ticket(
        self
        customer_id: str
        session_id: str
        resolution: str
        product: str
    ):
        """
        Mark ticket as resolved and promote learning to permanent memory.
        """
        # Get all session context
        session_memories = self.memory_manager.memory.get_all(
            run_id=session_id
        )

        # Extract issue from session
        issue = self._extract_issue(session_memories)

        # Store resolution in customer history
        self.memory_manager.add_customer_issue_history(
            customer_id=customer_id
            issue=issue
            resolution=resolution
            product=product
        )

        # If common issue, add to agent knowledge
        if self._is_common_issue(issue):
            self.memory_manager.add_common_issue_solution(
                agent_id="support_agent"
                issue=issue
                solution=resolution
                product=product
            )

        # Cleanup session memory
        for mem in session_memories.get('results', []):
            self.memory_manager.memory.delete(mem['id'])

    def _build_context_summary(self, context: dict) -> str:
        """Build formatted context summary for LLM."""
        summary = []

        # Customer context
        if context['customer']:
            summary.append("Customer History:")
            for mem in context['customer'][:3]:
                summary.append(f"- {mem.get('memory')}")

        # Agent knowledge
        if context['agent']:
            summary.append("\nRelevant Knowledge:")
            for mem in context['agent'][:3]:
                summary.append(f"- {mem.get('memory')}")

        # Session context
        if context['session']:
            summary.append("\nCurrent Conversation:")
            for mem in context['session']:
                summary.append(f"- {mem.get('memory')}")

        return "\n".join(summary)

    def _generate_response(self, message: str, context: str) -> str:
        """Generate agent response (placeholder for LLM call)."""
        # In production, this would call your LLM with context
        return f"Response based on: {message[:50]}..."

    def _extract_issue(self, session_memories: dict) -> str:
        """Extract main issue from session memories."""
        # Find first user message about the issue
        for mem in session_memories.get('results', []):
            memory_text = mem.get('memory', '')
            if 'New issue:' in memory_text:
                return memory_text.replace('New issue:', '').strip()
        return "Issue description not found"

    def _is_common_issue(self, issue: str) -> bool:
        """Determine if issue is common enough to add to knowledge base."""
        # In production, check frequency of similar issues
        return True  # Simplified for example
```

### Step 3: Usage Example

```python
# Initialize handlers
ticket_handler = SupportTicketHandler()

# Customer info
customer_id = "cust_12345"
agent_id = "support_agent_v2"

# Set up customer profile
ticket_handler.memory_manager.add_customer_profile(
    customer_id=customer_id
    profile_data={
        "name": "Alice Johnson"
        "tier": "premium"
        "comm_pref": "email"
        "timezone": "America/Los_Angeles"
    }
)

# Add agent knowledge
ticket_handler.memory_manager.add_product_knowledge(
    agent_id=agent_id
    product="CloudSync Pro"
    knowledge="Supports Windows, Mac, Linux. Max 10GB file size."
)

ticket_handler.memory_manager.add_common_issue_solution(
    agent_id=agent_id
    issue="Sync fails with large files"
    solution="Split files into smaller chunks or use compression"
    product="CloudSync Pro"
)

# Create ticket
session_id = ticket_handler.create_ticket(
    customer_id=customer_id
    issue_description="Unable to sync 15GB video file"
    product="CloudSync Pro"
)

# Handle conversation
response = ticket_handler.handle_ticket(
    customer_id=customer_id
    agent_id=agent_id
    session_id=session_id
    customer_message="I'm trying to sync a large video file but it keeps failing"
)

print(f"Agent response: {response}")

# Resolve ticket
ticket_handler.resolve_ticket(
    customer_id=customer_id
    session_id=session_id
    resolution="Advised customer to compress file or split into chunks. Issue resolved."
    product="CloudSync Pro"
)
```

## Retention Strategy

```yaml
# Customer Support Retention Policy

user_memory:
  active_retention_days: -1  # Indefinite
  archival_after_days: 365    # Archive after 1 year of inactivity
  cleanup: user_initiated_only

agent_memory:
  active_retention_days: 180  # 6 months
  update_frequency: weekly    # Update with new learnings
  version_control: enabled

session_memory:
  active_retention_hours: 24
  cleanup_on_resolution: true
  promote_to_user: if_important
```

## Performance Optimization

### Caching Strategy

```python
import functools
from cachetools import TTLCache

# Cache customer profile (rarely changes)
customer_cache = TTLCache(maxsize=1000, ttl=300)  # 5 min TTL

@functools.lru_cache(maxsize=100)
def get_customer_profile(customer_id: str):
    """Cached customer profile retrieval."""
    return memory_manager.memory.search(
        "profile"
        user_id=customer_id
        filters={"metadata.type": "profile"}
    )
```

### Search Optimization

```python
# Use specific filters to reduce search space
def optimized_agent_search(query: str, product: str):
    """Product-specific agent knowledge search."""
    return memory.search(
        query
        agent_id="support_agent"
        filters={
            "AND": [
                {"metadata.type": "solution"}
                {"metadata.product": product}
            ]
        }
        limit=3  # Only need top 3 matches
    )
```

## Cost Analysis

**Expected Monthly Costs** (1000 customers, 500 tickets/month):

```
Memories:
- User memories: ~5,000 (5 per customer)
- Agent memories: ~500 (common knowledge)
- Session memories: ~2,500 (5 per active session)

Costs:
- Vector storage: ~$6.50/month
- Embedding generation: ~$3.00/month
- Searches: ~$4.00/month
──────────────────────────────────
Total: ~$13.50/month

With optimizations (caching, limits):
Total: ~$8.00/month (-40%)
```

## Security Considerations

1. **PII Protection**: Encrypt sensitive customer data before storing
2. **GDPR Compliance**: Implement customer data deletion on request
3. **Access Control**: Validate customer_id against authenticated user
4. **Audit Logging**: Log all memory operations for compliance
5. **Data Isolation**: Never allow cross-customer memory access

## Monitoring Metrics

Track these KPIs:
- Average resolution time (with vs without memory)
- Customer satisfaction scores
- Agent knowledge utilization rate
- Memory retrieval accuracy
- Cost per ticket handled
- Session memory cleanup rate

## Next Steps

1. Implement caching layer for performance
2. Set up retention policy automation
3. Add GDPR deletion workflow
4. Configure monitoring dashboards
5. Test at scale with production data
6. Optimize based on real usage patterns
