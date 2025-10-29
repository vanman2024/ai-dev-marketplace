# Multi-Tenant CMS Example

This example demonstrates how to build a multi-tenant content management system with organization isolation using Supabase RLS policies.

## Prerequisites

- Supabase project configured
- Organizations table created
- User-organization relationships set up

## Database Schema

```sql
-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- User-organization relationship
CREATE TABLE IF NOT EXISTS user_organizations (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  PRIMARY KEY (user_id, organization_id)
);

-- Posts with organization isolation
CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  content TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  author_id UUID REFERENCES auth.users(id),
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(organization_id, slug)
);

CREATE INDEX idx_posts_organization ON posts(organization_id);
CREATE INDEX idx_posts_status ON posts(organization_id, status);
```

## RLS Policies

```sql
-- Enable RLS on all tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Users can only see organizations they belong to
CREATE POLICY "Users access own organizations"
ON organizations FOR ALL
TO authenticated
USING (
  id IN (
    SELECT organization_id FROM user_organizations
    WHERE user_id = auth.uid()
  )
);

-- Users can see their organization memberships
CREATE POLICY "Users access own memberships"
ON user_organizations FOR ALL
TO authenticated
USING (user_id = auth.uid());

-- Users can only access their organization's posts
CREATE POLICY "Users access own organization posts"
ON posts FOR ALL
TO authenticated
USING (
  organization_id IN (
    SELECT organization_id FROM user_organizations
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  organization_id IN (
    SELECT organization_id FROM user_organizations
    WHERE user_id = auth.uid()
  )
);

-- Public can read published posts from any organization
CREATE POLICY "Public read published posts"
ON posts FOR SELECT
TO public
USING (status = 'published');
```

## TypeScript Implementation

### 1. Organization Context

```typescript
// src/lib/supabase/organization-context.ts
import { supabase } from './client';

export async function getUserOrganizations() {
  const { data, error } = await supabase
    .from('user_organizations')
    .select(`
      organization_id,
      role,
      organizations (
        id,
        name,
        slug
      )
    `);

  if (error) throw error;
  return data;
}

export async function switchOrganization(orgId: string) {
  // Store current organization in local storage or session
  localStorage.setItem('currentOrganization', orgId);
}

export function getCurrentOrganization(): string | null {
  return localStorage.getItem('currentOrganization');
}
```

### 2. Organization-Scoped Content Queries

```typescript
// src/lib/supabase/org-content.ts
import { supabase } from './client';

export async function getOrganizationPosts(organizationId: string) {
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('organization_id', organizationId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}

export async function createOrganizationPost(
  organizationId: string,
  postData: {
    title: string;
    slug: string;
    content: string;
  }
) {
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) throw new Error('Not authenticated');

  const { data, error } = await supabase
    .from('posts')
    .insert({
      organization_id: organizationId,
      author_id: user.id,
      ...postData,
      status: 'draft'
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function publishOrganizationPost(
  postId: string,
  organizationId: string
) {
  const { data, error } = await supabase
    .from('posts')
    .update({
      status: 'published',
      published_at: new Date().toISOString()
    })
    .eq('id', postId)
    .eq('organization_id', organizationId)
    .select()
    .single();

  if (error) throw error;
  return data;
}
```

### 3. Organization Switcher Component

```typescript
// src/components/OrganizationSwitcher.tsx
import { useState, useEffect } from 'react';
import { getUserOrganizations, switchOrganization, getCurrentOrganization } from '@/lib/supabase/organization-context';

export function OrganizationSwitcher() {
  const [organizations, setOrganizations] = useState([]);
  const [currentOrg, setCurrentOrg] = useState(getCurrentOrganization());

  useEffect(() => {
    loadOrganizations();
  }, []);

  async function loadOrganizations() {
    const orgs = await getUserOrganizations();
    setOrganizations(orgs);

    // Set first org as default if none selected
    if (!currentOrg && orgs.length > 0) {
      handleSwitch(orgs[0].organization_id);
    }
  }

  async function handleSwitch(orgId: string) {
    await switchOrganization(orgId);
    setCurrentOrg(orgId);
    // Trigger page refresh or state update
    window.location.reload();
  }

  return (
    <select
      value={currentOrg || ''}
      onChange={(e) => handleSwitch(e.target.value)}
      className="border rounded px-3 py-2"
    >
      {organizations.map((org) => (
        <option key={org.organization_id} value={org.organization_id}>
          {org.organizations.name} ({org.role})
        </option>
      ))}
    </select>
  );
}
```

### 4. Organization-Aware Content List

```astro
---
// src/pages/dashboard/posts.astro
import { supabase } from '@/lib/supabase/client';
import { getCurrentOrganization } from '@/lib/supabase/organization-context';

const orgId = getCurrentOrganization();

if (!orgId) {
  return Astro.redirect('/select-organization');
}

const { data: posts } = await supabase
  .from('posts')
  .select('*')
  .eq('organization_id', orgId)
  .order('created_at', { ascending: false });
---

<html>
  <body>
    <h1>Organization Posts</h1>
    <div class="posts-grid">
      {posts?.map((post) => (
        <article>
          <h2>{post.title}</h2>
          <p>Status: {post.status}</p>
          <a href={`/dashboard/posts/${post.id}`}>Edit</a>
        </article>
      ))}
    </div>
  </body>
</html>
```

## Testing Organization Isolation

```typescript
// tests/multi-tenant-isolation.test.ts
import { createClient } from '@supabase/supabase-js';

describe('Multi-tenant Isolation', () => {
  it('users cannot access other organization posts', async () => {
    const supabase = createClient(url, anonKey);

    // Sign in as user in org A
    await supabase.auth.signInWithPassword({
      email: 'user-org-a@example.com',
      password: 'password'
    });

    // Try to query posts from org B
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('organization_id', 'org-b-id');

    // Should return empty or error
    expect(data).toEqual([]);
  });

  it('users can access their organization posts', async () => {
    const supabase = createClient(url, anonKey);

    await supabase.auth.signInWithPassword({
      email: 'user-org-a@example.com',
      password: 'password'
    });

    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('organization_id', 'org-a-id');

    expect(data).toBeTruthy();
    expect(data.length).toBeGreaterThan(0);
  });
});
```

## Setup Steps

1. Apply the multi-tenant schema:
   ```bash
   ./scripts/apply-migration.sh skills/supabase-cms/templates/schemas/multi-tenant-schema.sql
   ```

2. Apply RLS policies:
   ```bash
   ./scripts/apply-rls-policies.sh skills/supabase-cms/templates/rls/multi-tenant-policies.sql
   ```

3. Generate TypeScript types:
   ```bash
   npm run generate:types
   ```

4. Test organization isolation:
   ```bash
   ./scripts/test-rls-policies.sh
   ```

## Best Practices

- **Always include organization_id** in WHERE clauses for better index usage
- **Create compound indexes** on (organization_id, status) for common queries
- **Store current organization** in session/local storage for performance
- **Validate organization membership** on the server side, not just client side
- **Use foreign key constraints** to enforce referential integrity
- **Test RLS policies thoroughly** before going to production
- **Consider organization quotas** for storage, posts, users, etc.
