# Multi-Tenant Organization Pattern

## Overview

The multi-tenant pattern enables multiple users within an organization to share memories while maintaining isolation between different organizations. Perfect for B2B SaaS applications where teams collaborate.

## Use Cases

- Team workspaces
- Enterprise SaaS applications
- Collaborative AI assistants
- Shared knowledge bases
- Multi-company platforms

## Architecture

```
Organization A
  ├─ User Alice ──┐
  ├─ User Bob ────┤──> Shared memories (org_id: "acme-corp")
  └─ User Carol ──┘

Organization B
  ├─ User Dan ────┐
  └─ User Eve ────┤──> Separate memories (org_id: "globex-inc")

RLS Policy: User must be member of organization
Result: Users see org memories + their personal memories
```

## Schema Design

### Organization Structure

```sql
-- Organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Organization members table
CREATE TABLE org_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(org_id, user_id)
);

-- Index for fast membership checks
CREATE INDEX idx_org_members_user_org ON org_members(user_id, org_id);
CREATE INDEX idx_org_members_org ON org_members(org_id);
```

### Memory Schema with Organization Support

Memories use `metadata->>'org_id'` for organization scoping:

```sql
-- Example memory with organization context
INSERT INTO memories (user_id, memory, metadata, embedding)
VALUES (
    'alice-123',
    'Company uses AWS for all infrastructure',
    '{"org_id": "acme-corp", "category": "infrastructure"}'::jsonb,
    '[...]'::vector
);
```

## RLS Policies for Multi-Tenancy

```sql
-- Enable RLS
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

-- Users can access their own personal memories
CREATE POLICY "users_access_own_memories"
ON memories FOR ALL
TO authenticated
USING ((SELECT auth.uid()::text) = user_id)
WITH CHECK ((SELECT auth.uid()::text) = user_id);

-- Users can access organization memories they're members of
CREATE POLICY "org_members_access_org_memories"
ON memories FOR SELECT
TO authenticated
USING (
    metadata->>'org_id' IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM org_members
        WHERE org_members.user_id = (SELECT auth.uid()::text)
        AND org_members.org_id::text = memories.metadata->>'org_id'
    )
);

-- Users can create org memories if they're members
CREATE POLICY "org_members_create_memories"
ON memories FOR INSERT
TO authenticated
WITH CHECK (
    metadata->>'org_id' IS NULL  -- Personal memory
    OR EXISTS (
        SELECT 1 FROM org_members
        WHERE org_members.user_id = (SELECT auth.uid()::text)
        AND org_members.org_id::text = memories.metadata->>'org_id'
        AND org_members.role IN ('owner', 'admin', 'member')  -- Viewers can't create
    )
);

-- Users can view their org memberships
CREATE POLICY "users_view_own_memberships"
ON org_members FOR SELECT
TO authenticated
USING ((SELECT auth.uid()::text) = user_id);
```

## Implementation

### 1. Organization Memory Client

```python
from mem0 import Memory
from typing import Optional, List
import os

class MultiTenantMemoryClient:
    """Memory client with organization support"""

    def __init__(self, user_id: str, org_id: Optional[str] = None):
        self.user_id = user_id
        self.org_id = org_id

        self.memory = Memory.from_config({
            "vector_store": {
                "provider": "postgres",
                "config": {
                    "url": os.getenv("SUPABASE_DB_URL")
                }
            }
        })

    def add_personal_memory(self, content: str) -> dict:
        """Add personal memory (not shared with org)"""
        return self.memory.add(
            content,
            user_id=self.user_id
        )

    def add_org_memory(self, content: str, categories: List[str] = None) -> dict:
        """Add memory shared with organization"""
        if not self.org_id:
            raise ValueError("Organization ID required for org memories")

        metadata = {"org_id": self.org_id}
        if categories:
            metadata["categories"] = categories

        return self.memory.add(
            content,
            user_id=self.user_id,  # Track who added it
            metadata=metadata
        )

    def search_personal(self, query: str, limit: int = 10) -> List[dict]:
        """Search only personal memories"""
        return self.memory.search(
            query,
            user_id=self.user_id,
            filters={"metadata": {"org_id": None}},
            limit=limit
        )

    def search_org(self, query: str, limit: int = 10) -> List[dict]:
        """Search organization memories"""
        if not self.org_id:
            return []

        return self.memory.search(
            query,
            filters={"metadata": {"org_id": self.org_id}},
            limit=limit
        )

    def search_all(self, query: str, limit: int = 20) -> dict:
        """Search both personal and org memories"""
        personal = self.search_personal(query, limit=limit // 2)
        org = self.search_org(query, limit=limit // 2)

        return {
            "personal": personal,
            "organization": org,
            "total": len(personal) + len(org)
        }
```

### 2. Usage Examples

```python
# Alice in Acme Corp
alice = MultiTenantMemoryClient(
    user_id="alice-123",
    org_id="acme-corp"
)

# Add personal memory (not shared)
alice.add_personal_memory("My personal API key is XYZ")

# Add org memory (shared with team)
alice.add_org_memory(
    "Company AWS account is 123456789",
    categories=["infrastructure", "aws"]
)

# Bob in same org can see org memory
bob = MultiTenantMemoryClient(
    user_id="bob-456",
    org_id="acme-corp"
)

# Bob searches org memories
org_results = bob.search_org("AWS account")
# Returns: ["Company AWS account is 123456789"]

# Bob searches personal memories - doesn't see Alice's personal stuff
personal_results = bob.search_personal("API key")
# Returns: [] (Alice's personal memory is isolated)

# Dan in different org can't see Acme Corp memories
dan = MultiTenantMemoryClient(
    user_id="dan-789",
    org_id="globex-inc"
)

dan_search = dan.search_org("AWS account")
# Returns: [] (no access to Acme Corp)
```

### 3. Role-Based Access Control

```python
class RBACMemoryClient(MultiTenantMemoryClient):
    """Memory client with role-based permissions"""

    def __init__(self, user_id: str, org_id: str, role: str):
        super().__init__(user_id, org_id)
        self.role = role

    def add_org_memory(self, content: str, categories: List[str] = None) -> dict:
        """Add org memory with role check"""
        if self.role == "viewer":
            raise PermissionError("Viewers cannot add memories")

        return super().add_org_memory(content, categories)

    def delete_org_memory(self, memory_id: str) -> bool:
        """Delete org memory (admin/owner only)"""
        if self.role not in ["admin", "owner"]:
            raise PermissionError("Only admins can delete org memories")

        self.memory.delete(memory_id)
        return True

    def export_org_memories(self) -> List[dict]:
        """Export all org memories (admin/owner only)"""
        if self.role not in ["admin", "owner"]:
            raise PermissionError("Only admins can export memories")

        return self.memory.get_all(
            filters={"metadata": {"org_id": self.org_id}}
        )
```

## Advanced Patterns

### Hierarchical Organizations

```python
# Support for sub-organizations or teams
class HierarchicalMemoryClient(MultiTenantMemoryClient):
    """Support for org hierarchies (org > team > user)"""

    def __init__(self, user_id: str, org_id: str, team_id: Optional[str] = None):
        super().__init__(user_id, org_id)
        self.team_id = team_id

    def add_team_memory(self, content: str) -> dict:
        """Add memory scoped to team within org"""
        if not self.team_id:
            raise ValueError("Team ID required")

        metadata = {
            "org_id": self.org_id,
            "team_id": self.team_id
        }

        return self.memory.add(
            content,
            user_id=self.user_id,
            metadata=metadata
        )

    def search_team(self, query: str, limit: int = 10) -> List[dict]:
        """Search team-specific memories"""
        if not self.team_id:
            return []

        return self.memory.search(
            query,
            filters={
                "metadata": {
                    "org_id": self.org_id,
                    "team_id": self.team_id
                }
            },
            limit=limit
        )

    def search_hierarchy(self, query: str, limit: int = 30) -> dict:
        """Search across personal, team, and org levels"""
        return {
            "personal": self.search_personal(query, limit=limit // 3),
            "team": self.search_team(query, limit=limit // 3),
            "organization": self.search_org(query, limit=limit // 3)
        }
```

### Cross-Organization Sharing

```python
# Allow specific memories to be shared across orgs
def share_memory_cross_org(
    memory_id: str,
    source_org_id: str,
    target_org_ids: List[str]
):
    """Share memory with other organizations"""
    # Update metadata to include shared orgs
    memory_data = memory.get(memory_id)

    current_metadata = memory_data.get('metadata', {})
    current_metadata['shared_with_orgs'] = target_org_ids

    memory.update(memory_id, metadata=current_metadata)

# RLS policy for shared memories
CREATE POLICY "access_shared_org_memories"
ON memories FOR SELECT
TO authenticated
USING (
    metadata->'shared_with_orgs' ? (
        SELECT org_id::text FROM org_members
        WHERE user_id = (SELECT auth.uid()::text)
    )
);
```

## Performance Optimization

### Indexes for Multi-Tenancy

```sql
-- Composite index for org + created_at
CREATE INDEX idx_memories_org_created ON memories(
    (metadata->>'org_id'), created_at DESC
);

-- Partial index for org memories only
CREATE INDEX idx_org_memories ON memories(created_at DESC)
WHERE metadata->>'org_id' IS NOT NULL;

-- GIN index for metadata queries
CREATE INDEX idx_memories_metadata_gin ON memories USING gin(metadata);
```

### Query Optimization

```python
# Efficient: Uses indexes
memories = memory.search(
    query="AWS",
    filters={"metadata": {"org_id": "acme-corp"}},
    limit=10
)

# Less efficient: No index on other metadata fields
memories = memory.search(
    query="AWS",
    filters={"metadata": {"custom_field": "value"}},
    limit=10
)
```

## Monitoring & Analytics

### Organization Memory Usage

```sql
-- Memory count per organization
SELECT
    metadata->>'org_id' as org_id,
    COUNT(*) as memory_count,
    COUNT(DISTINCT user_id) as unique_contributors,
    MIN(created_at) as first_memory,
    MAX(created_at) as latest_memory
FROM memories
WHERE metadata->>'org_id' IS NOT NULL
GROUP BY metadata->>'org_id'
ORDER BY memory_count DESC;
```

### User Contributions by Org

```sql
-- Top contributors per org
SELECT
    metadata->>'org_id' as org_id,
    user_id,
    COUNT(*) as contribution_count
FROM memories
WHERE metadata->>'org_id' = 'acme-corp'
GROUP BY metadata->>'org_id', user_id
ORDER BY contribution_count DESC
LIMIT 10;
```

## Security Best Practices

### Checklist

- [ ] RLS policies on memories table
- [ ] RLS policies on org_members table
- [ ] Membership verification before org operations
- [ ] Role-based permissions implemented
- [ ] Audit logging for sensitive operations
- [ ] Regular security audits
- [ ] Cross-org access prevention tested

### Testing Multi-Tenancy

```python
def test_org_isolation():
    """Test that orgs can't access each other's memories"""
    # Setup two orgs
    acme = MultiTenantMemoryClient("alice", "acme-corp")
    globex = MultiTenantMemoryClient("dan", "globex-inc")

    # Add org-specific memory
    acme.add_org_memory("Acme secret project")

    # Verify Globex can't see it
    results = globex.search_org("secret project")
    assert len(results) == 0, "Cross-org access detected!"
```

## Summary

Multi-tenant pattern enables:
- Organization-level memory sharing
- User-level isolation within orgs
- Role-based access control
- Hierarchical organization support
- Cross-org sharing (optional)

**Next Steps:**
- See `user-isolation-pattern.md` for personal memories
- See `agent-knowledge-pattern.md` for shared agent memories
- See `performance-tuning-guide.md` for optimization
