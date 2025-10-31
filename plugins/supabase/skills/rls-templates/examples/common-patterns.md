# Common RLS Patterns for Supabase

This guide covers the most frequently used Row Level Security patterns for AI applications and SaaS products.

## Pattern 1: User-Owned Data (User Isolation)

**Use case:** User profiles, settings, personal documents, preferences

**Schema:**
```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    full_name TEXT
    avatar_url TEXT
    preferences JSONB
    created_at TIMESTAMPTZ DEFAULT NOW()
    UNIQUE(user_id)
);
```

**Apply policies:**
```bash
bash scripts/apply-rls-policies.sh user-isolation user_profiles
```

**Or manually:**
```sql
\i templates/user-isolation.sql
```

**Client usage:**
```typescript
// Automatically filtered by RLS
const { data: profile } = await supabase
  .from('user_profiles')
  .select('*')
  .eq('user_id', user.id)  // Explicit filter for performance
  .single();

// Insert with user_id
const { data, error } = await supabase
  .from('user_profiles')
  .insert({
    user_id: user.id
    full_name: 'John Doe'
    preferences: { theme: 'dark' }
  });
```

---

## Pattern 2: Multi-Tenant Organization Data

**Use case:** SaaS applications, team workspaces, shared resources

**Schema:**
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    name TEXT NOT NULL
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE org_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    role TEXT NOT NULL DEFAULT 'member',  -- 'admin', 'editor', 'member'
    created_at TIMESTAMPTZ DEFAULT NOW()
    UNIQUE(organization_id, user_id)
);

-- Add performance index
CREATE INDEX idx_org_members_user_org ON org_members(user_id, organization_id);

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE
    name TEXT NOT NULL
    description TEXT
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Apply policies:**
```bash
bash scripts/apply-rls-policies.sh multi-tenant organizations org_members projects
```

**Client usage:**
```typescript
// User's organizations (via org_members)
const { data: orgs } = await supabase
  .from('org_members')
  .select('organization_id, organizations(*)')
  .eq('user_id', user.id);

// Projects in organization (automatically filtered by RLS)
const { data: projects } = await supabase
  .from('projects')
  .select('*')
  .eq('organization_id', currentOrgId);
```

---

## Pattern 3: Role-Based Access Control

**Use case:** Admin panels, content management, hierarchical permissions

**Schema:**
```sql
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    title TEXT NOT NULL
    content TEXT
    status TEXT DEFAULT 'draft',  -- 'draft', 'published'
    author_id UUID REFERENCES auth.users(id)
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Set user roles (server-side only):**
```typescript
// In Supabase Edge Function or Admin API
await supabase.auth.admin.updateUserById(userId, {
  app_metadata: { role: 'editor' }
});
```

**Apply policies:**
```bash
bash scripts/apply-rls-policies.sh role-based-access articles
```

**Client usage:**
```typescript
// All users can read (policy allows)
const { data: articles } = await supabase
  .from('articles')
  .select('*')
  .eq('status', 'published');

// Editors can create
const { data, error } = await supabase
  .from('articles')
  .insert({
    title: 'New Article'
    content: 'Content here...'
    author_id: user.id
  });
// ✓ Success if user role is 'editor' or 'admin'
// ✗ Error if user role is 'viewer' or 'user'
```

---

## Pattern 4: AI Chat Application

**Use case:** Chatbots, AI assistants, conversation history

**Schema:**
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    title TEXT
    model TEXT DEFAULT 'gpt-4'
    created_at TIMESTAMPTZ DEFAULT NOW()
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE
    role TEXT NOT NULL,  -- 'user', 'assistant', 'system'
    content TEXT NOT NULL
    metadata JSONB
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
```

**Apply policies:**
```bash
bash scripts/apply-rls-policies.sh ai-chat conversations messages
```

**Client usage:**
```typescript
// Create new conversation
const { data: conversation } = await supabase
  .from('conversations')
  .insert({
    user_id: user.id
    title: 'New Chat'
  })
  .select()
  .single();

// Add message to conversation
const { data: message } = await supabase
  .from('messages')
  .insert({
    conversation_id: conversation.id
    role: 'user'
    content: 'Hello, AI!'
  });

// Get conversation history (automatically filtered by RLS)
const { data: messages } = await supabase
  .from('messages')
  .select('*')
  .eq('conversation_id', conversationId)
  .order('created_at', { ascending: true });
```

---

## Pattern 5: RAG with Vector Embeddings

**Use case:** Semantic search, knowledge bases, document Q&A

**Prerequisites:**
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

**Schema:**
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    title TEXT NOT NULL
    content TEXT NOT NULL
    source_url TEXT
    processing_status TEXT DEFAULT 'pending',  -- 'pending', 'processing', 'completed'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE document_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE
    content TEXT NOT NULL,  -- Chunk of original document
    embedding vector(1536),  -- OpenAI ada-002 dimension
    metadata JSONB
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vector similarity index (for performance)
CREATE INDEX ON document_embeddings
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);
```

**Apply policies:**
```bash
bash scripts/apply-rls-policies.sh embeddings documents document_embeddings
```

**Client usage:**
```typescript
// Upload document
const { data: doc } = await supabase
  .from('documents')
  .insert({
    user_id: user.id
    title: 'My Knowledge Base'
    content: 'Full document content...'
    processing_status: 'pending'
  })
  .select()
  .single();

// Generate embeddings (in Edge Function with service role)
// Service role bypasses RLS for embedding generation
const { data: chunks } = await supabaseAdmin
  .from('document_embeddings')
  .insert(embeddings);

// Semantic search (uses RLS-secured function)
const { data: results } = await supabase
  .rpc('search_embeddings', {
    query_embedding: queryVector
    match_threshold: 0.7
    match_count: 5
  });
// Returns only results from user's own documents
```

---

## Pattern 6: Shared/Collaborative Data

**Use case:** Shared documents, collaborative workspaces, permissions

**Schema:**
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    owner_id UUID NOT NULL REFERENCES auth.users(id)
    title TEXT NOT NULL
    content TEXT
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE document_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    permission TEXT NOT NULL DEFAULT 'view',  -- 'view', 'edit', 'admin'
    created_at TIMESTAMPTZ DEFAULT NOW()
    UNIQUE(document_id, user_id)
);

CREATE INDEX idx_shares_user_doc ON document_shares(user_id, document_id);
```

**Custom policies:**
```sql
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Users can view documents they own or have been shared with
CREATE POLICY "documents_select_shared" ON documents
    FOR SELECT TO authenticated
    USING (
        owner_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM document_shares
            WHERE document_id = documents.id
            AND user_id = (SELECT auth.uid())
        )
    );

-- Users can update documents they own or have edit permission
CREATE POLICY "documents_update_edit_permission" ON documents
    FOR UPDATE TO authenticated
    USING (
        owner_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM document_shares
            WHERE document_id = documents.id
            AND user_id = (SELECT auth.uid())
            AND permission IN ('edit', 'admin')
        )
    )
    WITH CHECK (
        owner_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM document_shares
            WHERE document_id = documents.id
            AND user_id = (SELECT auth.uid())
            AND permission IN ('edit', 'admin')
        )
    );
```

---

## Performance Best Practices

### 1. Always Add Indexes
```sql
-- User isolation pattern
CREATE INDEX idx_table_user_id ON table_name(user_id);

-- Multi-tenant pattern
CREATE INDEX idx_table_org_id ON table_name(organization_id);
CREATE INDEX idx_org_members_user_org ON org_members(user_id, organization_id);

-- Chat/messages pattern
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);
```

### 2. Wrap Auth Functions in SELECT
```sql
-- ✓ Better (cacheable)
USING ((SELECT auth.uid()) = user_id)

-- ✗ Slower (not cached)
USING (auth.uid() = user_id)
```

### 3. Filter Queries Explicitly
```typescript
// ✓ Better - helps Postgres optimize
const { data } = await supabase
  .from('messages')
  .select('*')
  .eq('conversation_id', convId)  // Duplicate RLS logic
  .order('created_at');

// ✗ Works but slower - relies only on RLS
const { data } = await supabase
  .from('messages')
  .select('*')
  .order('created_at');
```

### 4. Use Security Definer Functions
For complex authorization logic that requires joins:
```sql
CREATE OR REPLACE FUNCTION auth.user_has_access(resource_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Complex logic here bypasses RLS on lookup tables
    RETURN EXISTS (
        SELECT 1 FROM permissions
        WHERE user_id = auth.uid() AND resource = resource_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Use in policy
USING (auth.user_has_access(id))
```

---

## Testing Your Policies

```bash
# Test all policies on a table
bash scripts/test-rls-policies.sh conversations

# Test with specific user
bash scripts/test-rls-policies.sh messages --user-id "uuid-here"

# Audit all tables
bash scripts/audit-rls.sh

# Generate audit report
bash scripts/audit-rls.sh --report security-audit.md
```

---

## Common Pitfalls

### ❌ Pitfall 1: No RLS on Public Tables
```sql
-- ❌ DANGEROUS - table is fully exposed via API
CREATE TABLE users (id UUID, email TEXT);
```

```sql
-- ✓ SAFE - RLS enforced
CREATE TABLE users (id UUID, email TEXT);
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY ... ON users ...;
```

### ❌ Pitfall 2: Using user_metadata for Authorization
```sql
-- ❌ DANGEROUS - user can modify this
USING (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin')
```

```sql
-- ✓ SAFE - server-controlled
USING (auth.jwt() -> 'app_metadata' ->> 'role' = 'admin')
```

### ❌ Pitfall 3: Missing WITH CHECK on INSERT/UPDATE
```sql
-- ❌ INCOMPLETE - no validation on new data
CREATE POLICY "table_insert" ON table_name
    FOR INSERT TO authenticated
    USING (auth.uid() = user_id);  -- Wrong: no WITH CHECK
```

```sql
-- ✓ COMPLETE - validates new rows
CREATE POLICY "table_insert" ON table_name
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);
```

### ❌ Pitfall 4: No Index on Policy Columns
```sql
-- ❌ SLOW - no index on user_id
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY ... USING (auth.uid() = user_id);
```

```sql
-- ✓ FAST - index added
CREATE INDEX idx_messages_user_id ON messages(user_id);
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY ... USING (auth.uid() = user_id);
```

---

## Migration Strategy

### Adding RLS to Existing Tables

1. **Enable RLS in maintenance window:**
```sql
BEGIN;
ALTER TABLE existing_table ENABLE ROW LEVEL SECURITY;
-- Add policies...
COMMIT;
```

2. **Test with service role first:**
```typescript
// Service role bypasses RLS - verify app still works
const { data } = await supabaseAdmin
  .from('existing_table')
  .select('*');
```

3. **Add policies incrementally:**
```sql
-- Start with SELECT only
CREATE POLICY "existing_select" ON existing_table
    FOR SELECT TO authenticated
    USING (...);

-- Test in staging
-- Add INSERT, UPDATE, DELETE policies
```

4. **Monitor performance:**
```sql
-- Check slow queries
SELECT * FROM pg_stat_statements
WHERE query LIKE '%existing_table%'
ORDER BY mean_exec_time DESC;
```

---

## Quick Reference

| Pattern | Use Case | Key Column | Template |
|---------|----------|------------|----------|
| User Isolation | Personal data | `user_id` | `user-isolation.sql` |
| Multi-Tenant | SaaS/Teams | `organization_id` | `multi-tenant.sql` |
| Role-Based | Admin panels | JWT claims | `role-based-access.sql` |
| AI Chat | Conversations | `conversation_id` | `ai-chat-policies.sql` |
| Embeddings | RAG/Search | `document_id` | `embeddings-policies.sql` |

**Apply template:**
```bash
bash scripts/apply-rls-policies.sh <template> <table1> [table2]...
```

**Generate custom policy:**
```bash
bash scripts/generate-policy.sh <template> <table> [column] > policy.sql
```
