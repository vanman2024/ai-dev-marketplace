# RLS Migration Guide

Guide for adding Row Level Security to existing Supabase tables safely.

## Overview

Adding RLS to production tables requires careful planning to avoid:
- ❌ Breaking existing application functionality
- ❌ Causing downtime
- ❌ Performance degradation
- ❌ Data access issues

This guide provides step-by-step migration strategies.

---

## Migration Strategy 1: Greenfield (New Tables)

**Best for:** New features, new projects, new tables

### Step 1: Enable RLS from the Start

```sql
-- Create table with RLS enabled from day 1
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    title TEXT
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS immediately
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Add policies before any data
CREATE POLICY "conversations_select_own" ON conversations
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "conversations_insert_own" ON conversations
    FOR INSERT TO authenticated
    WITH CHECK ((SELECT auth.uid()) = user_id);
-- etc...

-- Add performance index
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
```

**Result:** ✅ Secure from day 1, no migration needed

---

## Migration Strategy 2: Low-Risk (Non-Production)

**Best for:** Development, staging, internal tools

### Step 1: Backup Data

```bash
# Export table data
pg_dump "$SUPABASE_DB_URL" \
  --table=conversations \
  --data-only \
  --file=conversations-backup.sql
```

### Step 2: Enable RLS and Add Policies

```sql
BEGIN;

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Add indexes first (improves policy performance)
CREATE INDEX idx_conversations_user_id ON conversations(user_id);

-- Add policies
\i templates/user-isolation.sql

COMMIT;
```

### Step 3: Test Application

```bash
# Run test suite
npm test

# Manual testing
# - Login as different users
# - Verify data access
# - Check CRUD operations
```

### Step 4: Rollback if Needed

```sql
-- If issues found, disable RLS temporarily
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;

-- Fix policies, then re-enable
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
```

---

## Migration Strategy 3: Production (Zero Downtime)

**Best for:** Live production systems, critical tables

### Phase 1: Preparation (No Impact)

#### Step 1.1: Audit Current State

```bash
# Check current RLS status
bash scripts/audit-rls.sh conversations > pre-migration-audit.txt
```

#### Step 1.2: Add Indexes (No Breaking Changes)

```sql
-- Add indexes first (safe operation)
CREATE INDEX CONCURRENTLY idx_conversations_user_id ON conversations(user_id);
```

**Note:** `CONCURRENTLY` allows index creation without locking the table.

#### Step 1.3: Test Policies in Staging

```sql
-- Copy production data to staging
-- Enable RLS in staging
-- Test all application functionality
```

### Phase 2: Enable RLS with Permissive Policy (No Breaking Changes)

#### Step 2.1: Enable RLS with Temporary Bypass Policy

```sql
BEGIN;

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Add temporary permissive policy (allows everything)
CREATE POLICY "conversations_temp_allow_all" ON conversations
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

COMMIT;
```

**Result:** RLS enabled, but app still works (policy allows all access)

#### Step 2.2: Monitor Application

```bash
# Watch for errors in next 24-48 hours
# Check application logs
# Monitor user reports
```

### Phase 3: Add Restrictive Policies (Staged Rollout)

#### Step 3.1: Add SELECT Policy First

```sql
-- Add restrictive SELECT policy
CREATE POLICY "conversations_select_own" ON conversations
    FOR SELECT
    TO authenticated
    USING ((SELECT auth.uid()) = user_id);

-- Keep temp policy for INSERT/UPDATE/DELETE
```

**Test:** Verify users can only see their own conversations

#### Step 3.2: Add INSERT Policy

```sql
CREATE POLICY "conversations_insert_own" ON conversations
    FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = user_id);
```

**Test:** Verify users can create conversations

#### Step 3.3: Add UPDATE Policy

```sql
CREATE POLICY "conversations_update_own" ON conversations
    FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
```

**Test:** Verify users can update their conversations

#### Step 3.4: Add DELETE Policy

```sql
CREATE POLICY "conversations_delete_own" ON conversations
    FOR DELETE
    TO authenticated
    USING ((SELECT auth.uid()) = user_id);
```

**Test:** Verify users can delete their conversations

### Phase 4: Remove Temporary Policy

#### Step 4.1: Drop Permissive Policy

```sql
-- Once all restrictive policies are tested and working
DROP POLICY "conversations_temp_allow_all" ON conversations;
```

#### Step 4.2: Final Testing

```bash
# Run full test suite
bash scripts/test-rls-policies.sh conversations

# Audit final state
bash scripts/audit-rls.sh conversations > post-migration-audit.txt

# Compare before/after
diff pre-migration-audit.txt post-migration-audit.txt
```

---

## Migration Strategy 4: Multi-Tenant Migration

**Best for:** Converting single-tenant to multi-tenant

### Step 1: Add Organization Column

```sql
-- Add nullable organization_id column first
ALTER TABLE documents
ADD COLUMN organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;

-- Backfill data (set default org for existing rows)
UPDATE documents
SET organization_id = (
    SELECT id FROM organizations
    WHERE name = 'Default Organization'
    LIMIT 1
);

-- Make column required after backfill
ALTER TABLE documents
ALTER COLUMN organization_id SET NOT NULL;

-- Add index
CREATE INDEX idx_documents_org_id ON documents(organization_id);
```

### Step 2: Create org_members Table

```sql
CREATE TABLE org_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    role TEXT NOT NULL DEFAULT 'member'
    created_at TIMESTAMPTZ DEFAULT NOW()
    UNIQUE(organization_id, user_id)
);

-- Add RLS to org_members
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_members_select_own" ON org_members
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);
```

### Step 3: Backfill User Memberships

```sql
-- Assign all existing users to their organizations
-- Based on existing data relationships
INSERT INTO org_members (organization_id, user_id, role)
SELECT DISTINCT d.organization_id, d.user_id, 'admin'
FROM documents d
WHERE NOT EXISTS (
    SELECT 1 FROM org_members om
    WHERE om.organization_id = d.organization_id
    AND om.user_id = d.user_id
);
```

### Step 4: Apply Multi-Tenant RLS

```sql
-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Apply multi-tenant policies
\i templates/multi-tenant.sql
```

### Step 5: Test Organization Isolation

```typescript
// User in Org A
const { data: orgADocs } = await supabase
  .from('documents')
  .select('*');

// Should only see Org A documents
console.assert(
  orgADocs.every(doc => doc.organization_id === currentOrgId)
  'User should only see their org documents'
);
```

---

## Migration Strategy 5: Shared/Collaborative Access

**Best for:** Adding sharing features to existing data

### Step 1: Create Sharing Table

```sql
CREATE TABLE document_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
    permission TEXT NOT NULL DEFAULT 'view'
    created_at TIMESTAMPTZ DEFAULT NOW()
    UNIQUE(document_id, user_id)
);

CREATE INDEX idx_shares_user_doc ON document_shares(user_id, document_id);

ALTER TABLE document_shares ENABLE ROW LEVEL SECURITY;
```

### Step 2: Update Existing Policies

```sql
-- Replace simple user isolation with shared access policy
DROP POLICY IF EXISTS "documents_select_own" ON documents;

CREATE POLICY "documents_select_shared" ON documents
    FOR SELECT TO authenticated
    USING (
        -- Owner can access
        user_id = (SELECT auth.uid())
        -- Or shared with user
        OR EXISTS (
            SELECT 1 FROM document_shares
            WHERE document_id = documents.id
            AND user_id = (SELECT auth.uid())
        )
    );
```

### Step 3: Add Share Management

```typescript
// Share document with another user
const { data, error } = await supabase
  .from('document_shares')
  .insert({
    document_id: docId
    user_id: recipientUserId
    permission: 'edit'
  });
```

---

## Common Migration Issues

### Issue 1: Missing user_id on Existing Rows

**Problem:**
```sql
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
-- Users can't see any data (user_id is NULL)
```

**Solution:**
```sql
-- Backfill user_id before enabling RLS
UPDATE conversations
SET user_id = (
    SELECT user_id FROM some_reference_table
    WHERE some_reference_table.id = conversations.reference_id
);

-- Make NOT NULL after backfill
ALTER TABLE conversations
ALTER COLUMN user_id SET NOT NULL;
```

### Issue 2: Service Role Queries Break

**Problem:**
```typescript
// Background job using service role
const { data } = await supabaseAdmin
  .from('conversations')
  .select('*');
// Returns 0 rows after RLS enabled
```

**Solution:**
Service role ALWAYS bypasses RLS. If this breaks, you're likely using anon key instead.

```typescript
// ❌ Wrong - uses anon key
const supabaseAdmin = createClient(url, SUPABASE_ANON_KEY);

// ✓ Correct - uses service role key (bypasses RLS)
const supabaseAdmin = createClient(url, SUPABASE_SERVICE_ROLE_KEY);
```

### Issue 3: Slow Queries After RLS

**Problem:**
Queries become 10x slower after enabling RLS.

**Solution:**
Add indexes on columns used in policies:

```sql
-- Check execution plan
EXPLAIN ANALYZE
SELECT * FROM conversations WHERE user_id = 'user-id';

-- Add index
CREATE INDEX idx_conversations_user_id ON conversations(user_id);

-- Verify improvement
EXPLAIN ANALYZE
SELECT * FROM conversations WHERE user_id = 'user-id';
```

### Issue 4: Cascade Deletes Don't Work

**Problem:**
```typescript
// Delete user
await supabaseAdmin.auth.admin.deleteUser(userId);
// User's data still exists
```

**Solution:**
Ensure foreign key has ON DELETE CASCADE:

```sql
-- Check current constraint
SELECT conname, confdeltype
FROM pg_constraint
WHERE conrelid = 'conversations'::regclass;

-- Drop and recreate with CASCADE
ALTER TABLE conversations
DROP CONSTRAINT conversations_user_id_fkey
ADD CONSTRAINT conversations_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;
```

---

## Rollback Procedures

### Emergency Rollback (Disable RLS)

```sql
-- Immediately disable RLS if issues occur
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;

-- Application now works (but unsecured)
-- Fix policies, then re-enable
```

### Partial Rollback (Keep RLS, Remove Problematic Policy)

```sql
-- Drop specific policy causing issues
DROP POLICY "conversations_select_own" ON conversations;

-- Add temporary permissive policy
CREATE POLICY "conversations_temp_allow_all" ON conversations
    FOR SELECT TO authenticated
    USING (true);

-- Fix and redeploy proper policy
```

### Full Rollback (Remove RLS Completely)

```sql
BEGIN;

-- Drop all policies
DROP POLICY IF EXISTS "conversations_select_own" ON conversations;
DROP POLICY IF EXISTS "conversations_insert_own" ON conversations;
DROP POLICY IF EXISTS "conversations_update_own" ON conversations;
DROP POLICY IF EXISTS "conversations_delete_own" ON conversations;

-- Disable RLS
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;

COMMIT;
```

---

## Testing Checklist

Before migrating to production:

- [ ] Staging environment mirrors production data
- [ ] RLS policies tested in staging with production-like data
- [ ] Performance benchmarks acceptable (< 100ms queries)
- [ ] All CRUD operations tested
- [ ] User isolation verified
- [ ] Service role access still works (background jobs)
- [ ] Foreign key cascades work correctly
- [ ] Rollback procedure documented and tested
- [ ] Monitoring/alerting configured
- [ ] Team trained on RLS behavior

---

## Post-Migration Monitoring

### Week 1: High Alert

```bash
# Daily checks
bash scripts/audit-rls.sh --report audit-$(date +%Y-%m-%d).md

# Monitor slow queries
psql "$SUPABASE_DB_URL" -c "
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE query LIKE '%conversations%'
ORDER BY mean_exec_time DESC
LIMIT 10;
"

# Check error logs
# Look for permission denied errors
```

### Week 2-4: Normal Monitoring

```bash
# Weekly audits
bash scripts/audit-rls.sh

# Performance review
# Check query performance trends
```

### Ongoing: Continuous Validation

```yaml
# Add to CI/CD pipeline
- name: RLS Security Audit
  run: bash scripts/audit-rls.sh
```

---

## Migration Timeline Template

### Small Application (< 10 tables)

- **Week 1:** Add indexes, test policies in staging
- **Week 2:** Enable RLS in production with permissive policies
- **Week 3:** Add restrictive policies one by one
- **Week 4:** Remove permissive policies, final validation

### Medium Application (10-50 tables)

- **Month 1:** Audit, plan, add indexes, staging tests
- **Month 2:** Enable RLS on non-critical tables
- **Month 3:** Enable RLS on critical tables
- **Month 4:** Complete migration, final security audit

### Large Application (50+ tables)

- **Quarter 1:** Planning, architecture, tooling setup
- **Quarter 2:** Migration wave 1 (non-critical tables)
- **Quarter 3:** Migration wave 2 (critical tables)
- **Quarter 4:** Final tables, comprehensive audit, documentation

---

## Final Checklist

Before considering migration complete:

- [ ] All tables have RLS enabled
- [ ] All policies tested and validated
- [ ] Performance acceptable (queries < 100ms)
- [ ] Audit script passes with 0 critical issues
- [ ] Documentation updated
- [ ] Team trained on RLS behavior
- [ ] Monitoring in place
- [ ] Rollback procedures tested
- [ ] Security review completed
- [ ] Compliance requirements met (GDPR, HIPAA, etc.)

---

## Resources

- **Supabase RLS Docs:** https://supabase.com/docs/guides/auth/row-level-security
- **PostgreSQL RLS:** https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- **Testing Scripts:** `/scripts/test-rls-policies.sh`
- **Audit Tool:** `/scripts/audit-rls.sh`
- **Templates:** `/templates/`
