# User Isolation Pattern

## Overview

The user isolation pattern ensures complete data separation between users, where each user can only access their own memories. This is the most common pattern for SaaS applications and consumer-facing AI products.

## Use Cases

- Personal AI assistants
- Individual user preferences
- Private conversation history
- User-specific recommendations
- Single-tenant applications

## Architecture

```
User A memories -----> user_id: "alice-123"
User B memories -----> user_id: "bob-456"
User C memories -----> user_id: "charlie-789"

RLS Policy: auth.uid() = user_id
Result: Perfect isolation, no cross-user access
```

## Implementation

### 1. Database Setup

The schema already includes user isolation via RLS policies:

```sql
-- RLS policy ensures users only see their own data
CREATE POLICY "users_access_own_memories"
ON memories FOR ALL
TO authenticated
USING ((SELECT auth.uid()::text) = user_id)
WITH CHECK ((SELECT auth.uid()::text) = user_id);
```

### 2. Application Code

```python
from mem0 import Memory
import os

# Initialize Mem0 client
memory = Memory.from_config({
    "vector_store": {
        "provider": "postgres"
        "config": {
            "url": os.getenv("SUPABASE_DB_URL")
        }
    }
})

# Always scope operations by user_id
def add_user_memory(user_id: str, content: str):
    """Add memory for specific user"""
    return memory.add(content, user_id=user_id)

def search_user_memories(user_id: str, query: str):
    """Search only this user's memories"""
    return memory.search(query, user_id=user_id, limit=10)

def get_user_preferences(user_id: str):
    """Get all memories for a user"""
    return memory.get_all(user_id=user_id)
```

### 3. Example Workflow

```python
# User Alice adds her preferences
alice_id = "alice-123"
memory.add(
    "I prefer dark mode and concise responses"
    user_id=alice_id
)

memory.add(
    "I'm allergic to peanuts"
    user_id=alice_id
)

# User Bob adds his preferences
bob_id = "bob-456"
memory.add(
    "I prefer detailed explanations with examples"
    user_id=bob_id
)

# Alice searches her memories - only sees her own
alice_results = memory.search(
    "preferences"
    user_id=alice_id
)
# Returns: ["I prefer dark mode...", "I'm allergic to peanuts"]

# Bob searches - completely isolated from Alice
bob_results = memory.search(
    "preferences"
    user_id=bob_id
)
# Returns: ["I prefer detailed explanations..."]

# Attempting to access Bob's memories as Alice fails
try:
    memory.search("preferences", user_id=bob_id)  # Uses Alice's auth token
except Exception as e:
    print("Access denied: RLS policy blocks cross-user access")
```

## Security Considerations

### RLS Testing

Always test that RLS policies are working:

```bash
# Test RLS enforcement
bash scripts/test-mem0-rls.sh --user-id "alice-123"
```

### Validation Checklist

- [ ] RLS enabled on memories table
- [ ] User_id always provided in operations
- [ ] Auth tokens properly scoped to users
- [ ] No service key used in client apps
- [ ] Cross-user access returns empty results (not errors)

### Common Pitfalls

**1. Using service key in client:**
```python
# ❌ WRONG - bypasses RLS
supabase.auth.set_service_key(service_key)
memory.search(query, user_id=alice_id)  # Can see ALL users

# ✅ CORRECT - uses user's JWT
supabase.auth.set_session(user_jwt_token)
memory.search(query, user_id=alice_id)  # Only sees alice's data
```

**2. Forgetting to filter by user_id:**
```python
# ❌ WRONG - may return other users' data if RLS disabled
memory.search(query)  # No user_id filter

# ✅ CORRECT - explicit user scope
memory.search(query, user_id=current_user_id)
```

**3. Not validating user_id matches authenticated user:**
```python
# ❌ WRONG - allows impersonation
def get_memories(requested_user_id):
    return memory.get_all(user_id=requested_user_id)

# ✅ CORRECT - validate against auth
def get_memories(requested_user_id):
    current_user = get_authenticated_user()
    if requested_user_id != current_user.id:
        raise PermissionError("Cannot access other users' memories")
    return memory.get_all(user_id=requested_user_id)
```

## Performance Optimization

### Index Strategy

User isolation benefits from composite indexes:

```sql
-- Fast user + timestamp queries
CREATE INDEX idx_memories_user_created ON memories(user_id, created_at DESC);

-- Fast user + category queries
CREATE INDEX idx_memories_user_category ON memories(user_id, categories);
```

### Query Patterns

```python
# Efficient: Uses user_id index
memories = memory.search(
    query="preferences"
    user_id=alice_id
    limit=10
)

# Less efficient: Full table scan without user filter
memories = memory.search(query="preferences")  # Don't do this
```

### Caching User Memories

```python
import redis
from functools import lru_cache

redis_client = redis.Redis()

def get_user_memories_cached(user_id: str):
    """Cache frequently accessed user preferences"""
    cache_key = f"user_memories:{user_id}"

    # Check cache
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)

    # Fetch from Mem0
    memories = memory.get_all(user_id=user_id)

    # Cache for 5 minutes
    redis_client.setex(
        cache_key
        300,  # 5 minutes
        json.dumps(memories)
    )

    return memories

def invalidate_user_cache(user_id: str):
    """Invalidate cache when memories change"""
    redis_client.delete(f"user_memories:{user_id}")
```

## Monitoring & Auditing

### Track User Memory Growth

```sql
-- User memory statistics
SELECT
    user_id
    COUNT(*) as memory_count
    AVG(LENGTH(memory)) as avg_memory_length
    MIN(created_at) as first_memory
    MAX(created_at) as latest_memory
FROM memories
GROUP BY user_id
ORDER BY memory_count DESC;
```

### Audit Access Patterns

```sql
-- Check for suspicious cross-user access attempts
SELECT
    timestamp
    user_id
    operation
    metadata->>'attempted_user_id' as attempted_access
FROM memory_history
WHERE operation = 'access_denied'
ORDER BY timestamp DESC
LIMIT 100;
```

## Integration Examples

### With Next.js API Routes

```typescript
// pages/api/memories/search.ts
import { createClient } from '@supabase/supabase-js'
import { Memory } from 'mem0'

export default async function handler(req, res) {
  // Get user from session
  const supabase = createClient(
    process.env.SUPABASE_URL!
    process.env.SUPABASE_ANON_KEY!
  )

  const { data: { user }, error } = await supabase.auth.getUser(
    req.headers.authorization?.replace('Bearer ', '')
  )

  if (error || !user) {
    return res.status(401).json({ error: 'Unauthorized' })
  }

  // Initialize Mem0 with user context
  const memory = new Memory({
    vectorStore: {
      provider: 'postgres'
      config: {
        url: process.env.SUPABASE_DB_URL
      }
    }
  })

  // Search only this user's memories
  const results = await memory.search(req.body.query, {
    userId: user.id
    limit: 10
  })

  res.json({ results })
}
```

### With FastAPI Backend

```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from supabase import create_client
from mem0 import Memory
import os

app = FastAPI()
security = HTTPBearer()

supabase = create_client(
    os.getenv("SUPABASE_URL")
    os.getenv("SUPABASE_ANON_KEY")
)

memory = Memory.from_config({
    "vector_store": {
        "provider": "postgres"
        "config": {"url": os.getenv("SUPABASE_DB_URL")}
    }
})

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Validate JWT and extract user"""
    try:
        user = supabase.auth.get_user(credentials.credentials)
        return user.user
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/memories/search")
async def search_memories(
    query: str
    current_user = Depends(get_current_user)
):
    """Search current user's memories"""
    results = memory.search(query, user_id=current_user.id, limit=10)
    return {"results": results}
```

## Testing

### Unit Tests

```python
import pytest
from mem0 import Memory

@pytest.fixture
def memory_client():
    return Memory.from_config({
        "vector_store": {
            "provider": "postgres"
            "config": {"url": os.getenv("SUPABASE_DB_URL")}
        }
    })

def test_user_isolation(memory_client):
    """Test that users can't access each other's memories"""
    # Add memories for two users
    memory_client.add("Alice's secret", user_id="alice")
    memory_client.add("Bob's secret", user_id="bob")

    # Alice searches - should only see her memory
    alice_results = memory_client.search("secret", user_id="alice")
    assert len(alice_results) == 1
    assert "Alice's secret" in alice_results[0]['memory']
    assert "Bob's secret" not in str(alice_results)

    # Bob searches - should only see his memory
    bob_results = memory_client.search("secret", user_id="bob")
    assert len(bob_results) == 1
    assert "Bob's secret" in bob_results[0]['memory']
    assert "Alice's secret" not in str(bob_results)
```

## Compliance

### GDPR Right to Deletion

```python
def delete_all_user_data(user_id: str):
    """Complete user data deletion for GDPR compliance"""
    # Get all memory IDs
    all_memories = memory.get_all(user_id=user_id)

    # Delete each memory
    for mem in all_memories:
        memory.delete(mem['id'])

    # Verify deletion
    remaining = memory.get_all(user_id=user_id)
    assert len(remaining) == 0, "Failed to delete all user memories"

    print(f"Deleted {len(all_memories)} memories for user {user_id}")
```

### Data Export

```python
def export_user_data(user_id: str) -> dict:
    """Export all user data for GDPR compliance"""
    memories = memory.get_all(user_id=user_id)

    export = {
        "user_id": user_id
        "export_date": datetime.now().isoformat()
        "total_memories": len(memories)
        "memories": [
            {
                "id": mem['id']
                "content": mem['memory']
                "created_at": mem['created_at']
                "metadata": mem.get('metadata', {})
            }
            for mem in memories
        ]
    }

    return export
```

## Summary

The user isolation pattern provides:
- Complete data separation between users
- RLS-enforced security at database level
- Simple implementation (just add user_id)
- Excellent performance with proper indexes
- GDPR compliance support

**Next Steps:**
- See `multi-tenant-pattern.md` for organization-based isolation
- See `agent-knowledge-pattern.md` for shared memories
- See `performance-tuning-guide.md` for optimization
