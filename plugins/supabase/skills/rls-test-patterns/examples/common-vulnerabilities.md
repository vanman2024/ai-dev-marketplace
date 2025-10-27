# Common RLS Vulnerabilities and How to Test for Them

This guide covers the most common Row Level Security vulnerabilities in Supabase applications and provides specific tests to detect them.

## 1. Missing RLS on Public Tables

### Vulnerability

**Description:** Tables exist in the `public` schema without RLS enabled, allowing unrestricted access.

**Severity:** 🔴 **CRITICAL** - Complete data exposure

**Example:**
```sql
-- ❌ VULNERABLE: Table without RLS
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  private_data TEXT
);
-- No ALTER TABLE ... ENABLE ROW LEVEL SECURITY
```

**Impact:** All users (including anonymous) can read/write all data in the table.

### How to Test

```bash
# Detect tables without RLS
bash scripts/audit-rls-coverage.sh

# Or manually:
psql $SUPABASE_DB_URL -c "
  SELECT tablename
  FROM pg_tables
  WHERE schemaname = 'public'
  AND NOT EXISTS (
    SELECT 1 FROM pg_class
    WHERE oid = ('public.' || tablename)::regclass
    AND relrowsecurity
  );
"
```

### Fix

```sql
-- ✅ SECURE: Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Then add policies
CREATE POLICY "Users read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
```

---

## 2. Missing WITH CHECK Clause

### Vulnerability

**Description:** INSERT/UPDATE policies without `WITH CHECK` clause can be bypassed.

**Severity:** 🟠 **HIGH** - Users can create/modify data they shouldn't own

**Example:**
```sql
-- ❌ VULNERABLE: No WITH CHECK
CREATE POLICY "Users insert conversations"
  ON conversations FOR INSERT
  TO authenticated
  USING (true);  -- Anyone can insert!

-- ❌ VULNERABLE: USING without WITH CHECK
CREATE POLICY "Users update own data"
  ON conversations FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);
  -- Missing: WITH CHECK (auth.uid() = user_id)
```

**Impact:** Users can:
- Insert records claiming to be other users
- Update records to transfer ownership to themselves

### How to Test

```bash
# Test INSERT bypass
bash scripts/test-user-isolation.sh conversations

# Manual test:
psql $SUPABASE_DB_URL -c "
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims.sub = 'user-2-uuid';

  -- Try to insert with different user_id
  INSERT INTO conversations (user_id, title)
  VALUES ('user-1-uuid', 'Spoofed conversation');
"
# Should fail
```

```bash
# Detect missing WITH CHECK
psql $SUPABASE_DB_URL -c "
  SELECT tablename, policyname, cmd
  FROM pg_policies
  WHERE schemaname = 'public'
  AND cmd IN ('INSERT', 'UPDATE')
  AND with_check IS NULL;
"
```

### Fix

```sql
-- ✅ SECURE: Add WITH CHECK
CREATE POLICY "Users insert own conversations"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own conversations"
  ON conversations FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

## 3. Improper NULL Handling

### Vulnerability

**Description:** Policies don't handle `auth.uid()` returning `null` for anonymous users.

**Severity:** 🟠 **HIGH** - Anonymous users can access protected data

**Example:**
```sql
-- ❌ VULNERABLE: NULL comparison always fails
CREATE POLICY "Users read own data"
  ON conversations FOR SELECT
  TO authenticated  -- ⚠️ Still vulnerable!
  USING (auth.uid() = user_id);
-- If auth.uid() is NULL, this becomes NULL = 'some-uuid'
-- NULL = anything is NULL (not false), so comparison fails silently
```

**Impact:**
- Anonymous users might access data if role check is missing
- Queries return unexpected results
- Data leaks in edge cases

### How to Test

```bash
# Test anonymous access
bash scripts/test-anonymous-access.sh --test-null-uid

# Manual test:
psql $SUPABASE_DB_URL -c "
  SET LOCAL ROLE anon;  -- Anonymous role

  -- Try to read data (should return nothing)
  SELECT COUNT(*) FROM conversations;
"
# Should return 0
```

### Fix

```sql
-- ✅ SECURE: Explicit NULL check
CREATE POLICY "Users read own data"
  ON conversations FOR SELECT
  TO authenticated
  USING (
    auth.uid() IS NOT NULL
    AND auth.uid() = user_id
  );

-- ✅ ALTERNATIVE: Use role restriction
CREATE POLICY "Users read own data"
  ON conversations FOR SELECT
  TO authenticated  -- Only applies to authenticated role
  USING (auth.uid() = user_id);
-- Safer because anon role is excluded
```

---

## 4. Using user_metadata for Authorization

### Vulnerability

**Description:** Policies check `user_metadata` instead of `app_metadata` for roles.

**Severity:** 🟠 **HIGH** - Users can escalate privileges

**Example:**
```sql
-- ❌ VULNERABLE: user_metadata is user-modifiable
CREATE POLICY "Admins only"
  ON admin_settings FOR ALL
  TO authenticated
  USING (
    (auth.jwt()->>'user_metadata')::jsonb->>'role' = 'admin'
  );
-- Users can set their own user_metadata!
```

**Impact:** Users can:
- Promote themselves to admin
- Access restricted features
- Modify sensitive settings

### How to Test

```bash
# Test privilege escalation
bash scripts/test-role-permissions.sh --test-escalation

# Manual test:
psql $SUPABASE_DB_URL -c "
  -- User sets their own role in user_metadata
  UPDATE auth.users
  SET raw_user_meta_data = '{\"role\": \"admin\"}'::jsonb
  WHERE id = 'regular-user-uuid';

  -- Try to access admin settings
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims.sub = 'regular-user-uuid';

  SELECT * FROM admin_settings;
"
# Should be blocked if using app_metadata correctly
```

### Fix

```sql
-- ✅ SECURE: Use app_metadata (server-side only)
CREATE POLICY "Admins only"
  ON admin_settings FOR ALL
  TO authenticated
  USING (
    (auth.jwt()->>'app_metadata')::jsonb->>'role' = 'admin'
  );

-- Set role server-side only
UPDATE auth.users
SET raw_app_meta_data = '{\"role\": \"admin\"}'::jsonb
WHERE id = 'actual-admin-uuid';
```

---

## 5. Missing Indexes on Policy Columns

### Vulnerability

**Description:** Columns used in RLS policies lack indexes, causing slow queries or DoS.

**Severity:** 🟡 **MEDIUM** - Performance degradation, potential DoS

**Example:**
```sql
-- ❌ VULNERABLE: No index on user_id
CREATE TABLE conversations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  title TEXT
);
-- No index on user_id!

CREATE POLICY "Users read own conversations"
  ON conversations FOR SELECT
  USING (auth.uid() = user_id);
-- Every query does full table scan
```

**Impact:**
- Queries slow down as table grows
- Database overload
- Poor user experience
- Potential DoS attack

### How to Test

```bash
# Check for missing indexes
psql $SUPABASE_DB_URL -c "
  SELECT
    t.tablename,
    c.column_name
  FROM information_schema.columns c
  JOIN pg_tables t ON t.tablename = c.table_name
  WHERE t.schemaname = 'public'
  AND c.column_name IN ('user_id', 'organization_id')
  AND NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE tablename = t.tablename
    AND indexdef LIKE '%' || c.column_name || '%'
  );
"
```

```bash
# Performance test
time psql $SUPABASE_DB_URL -c "
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims.sub = 'user-uuid';
  SELECT COUNT(*) FROM conversations;
"
# Should be < 100ms
```

### Fix

```sql
-- ✅ SECURE: Add indexes
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_projects_org_id ON projects(organization_id);

-- For multi-column policies
CREATE INDEX idx_docs_org_user ON documents(organization_id, user_id);
```

---

## 6. Cross-Tenant Data Leaks

### Vulnerability

**Description:** Policies allow joining data across organization boundaries.

**Severity:** 🔴 **CRITICAL** - Multi-tenant data exposure

**Example:**
```sql
-- ❌ VULNERABLE: Join allows cross-org access
CREATE POLICY "Users access org projects"
  ON projects FOR SELECT
  TO authenticated
  USING (
    user_id IN (
      SELECT user_id FROM organization_members
      WHERE organization_id = projects.organization_id
    )
  );
-- If organization_members policy is weak, this leaks data
```

**Impact:**
- Organization A can access Organization B's data
- Complete multi-tenant security failure
- Regulatory violations (GDPR, etc.)

### How to Test

```bash
# Test multi-tenant isolation
bash scripts/test-multi-tenant-isolation.sh --test-members

# Manual test:
# 1. Create two orgs with different users
# 2. Create data in org1
# 3. Try to read as org2 user
# Should return no data
```

### Fix

```sql
-- ✅ SECURE: Explicit org check at every level
CREATE POLICY "Org members access org projects"
  ON projects FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM organization_members
      WHERE organization_id = projects.organization_id
      AND user_id = auth.uid()
    )
  );

-- ✅ ALTERNATIVE: Security definer function
CREATE FUNCTION user_organizations()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT organization_id
  FROM organization_members
  WHERE user_id = auth.uid();
$$;

CREATE POLICY "Org members access org projects"
  ON projects FOR SELECT
  TO authenticated
  USING (organization_id IN (SELECT user_organizations()));
```

---

## 7. Service Key Exposure

### Vulnerability

**Description:** Service key (bypass RLS) exposed in client-side code.

**Severity:** 🔴 **CRITICAL** - Complete security bypass

**Example:**
```javascript
// ❌ VULNERABLE: Service key in client code
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://xxx.supabase.co',
  'eyJhbGc...service_role_key'  // ⚠️ NEVER DO THIS
)
```

**Impact:**
- Complete RLS bypass
- Unrestricted database access
- Ability to delete all data

### How to Test

```bash
# Code search for exposed keys
grep -r "service_role" .
grep -r "eyJhbGc" . --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx"

# Check committed history
git log -p | grep -i "service"
```

### Fix

```javascript
// ✅ SECURE: Use anon key in client
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!  // ✅ Anon key
)

// Service key only in server-side code (API routes, edge functions)
// Never in client bundles
```

---

## 8. Overly Permissive Anonymous Access

### Vulnerability

**Description:** Anonymous role has more access than intended.

**Severity:** 🟡 **MEDIUM** - Public data exposure

**Example:**
```sql
-- ❌ VULNERABLE: Anonymous can read all profiles
CREATE POLICY "Public profiles"
  ON user_profiles FOR SELECT
  TO anon
  USING (true);  -- ⚠️ Too permissive
```

**Impact:**
- Private information exposed publicly
- Data scraping
- Privacy violations

### How to Test

```bash
# Test anonymous access
bash scripts/test-anonymous-access.sh

# Manual test:
psql $SUPABASE_DB_URL -c "
  SET LOCAL ROLE anon;
  SELECT COUNT(*) FROM user_profiles;
"
# Should return only truly public data
```

### Fix

```sql
-- ✅ SECURE: Anonymous can only see explicitly public profiles
CREATE POLICY "Public profiles"
  ON user_profiles FOR SELECT
  TO anon
  USING (is_public = true);  -- ✅ Explicit flag
```

---

## 9. Stale Member Access

### Vulnerability

**Description:** Removed organization members retain access to org data.

**Severity:** 🟠 **HIGH** - Unauthorized access persists

**Example:**
```sql
-- ❌ VULNERABLE: Caches org membership
CREATE POLICY "Org members access projects"
  ON projects FOR SELECT
  USING (
    organization_id = current_setting('app.current_org_id', true)::uuid
  );
-- If app.current_org_id is set at login, it's stale
```

**Impact:**
- Fired employees retain access
- Removed contractors see new data
- Access revocation delayed

### How to Test

```bash
# Test member removal
bash scripts/test-multi-tenant-isolation.sh --test-members

# Manual test:
# 1. Add user to org
# 2. Verify they can access org data
# 3. Remove user from org
# 4. Verify they immediately lose access
```

### Fix

```sql
-- ✅ SECURE: Check membership on every query
CREATE POLICY "Org members access projects"
  ON projects FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM organization_members
      WHERE organization_id = projects.organization_id
      AND user_id = auth.uid()
      AND removed_at IS NULL  -- ✅ Check not removed
    )
  );
```

---

## 10. Cascade Deletes Bypass RLS

### Vulnerability

**Description:** Foreign key cascade deletes bypass RLS policies.

**Severity:** 🟡 **MEDIUM** - Unintended data deletion

**Example:**
```sql
-- ❌ VULNERABLE: Cascade bypasses RLS
CREATE TABLE conversations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users
);

CREATE TABLE messages (
  id UUID PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE
  -- ⚠️ If conversation deleted, messages deleted regardless of RLS
);
```

**Impact:**
- Users can delete others' data via cascade
- Unexpected data loss
- Audit trail gaps

### How to Test

```bash
# Manual test:
# 1. Create conversation as user1
# 2. Create message as user2 (if allowed)
# 3. Delete conversation as user1
# 4. Check if user2's message was deleted
# Should respect RLS on messages table
```

### Fix

```sql
-- ✅ SECURE: Use soft deletes instead
ALTER TABLE conversations ADD COLUMN deleted_at TIMESTAMPTZ;

CREATE POLICY "Users see non-deleted conversations"
  ON conversations FOR SELECT
  USING (
    auth.uid() = user_id
    AND deleted_at IS NULL
  );

-- ✅ ALTERNATIVE: Remove CASCADE
ALTER TABLE messages
  DROP CONSTRAINT messages_conversation_id_fkey,
  ADD CONSTRAINT messages_conversation_id_fkey
    FOREIGN KEY (conversation_id)
    REFERENCES conversations(id)
    ON DELETE RESTRICT;  -- ✅ Prevent cascade
```

---

## Complete Testing Checklist

Use this checklist to test for all vulnerabilities:

```bash
# 1. Missing RLS
bash scripts/audit-rls-coverage.sh

# 2. Missing WITH CHECK
bash scripts/test-user-isolation.sh --all

# 3. NULL handling
bash scripts/test-anonymous-access.sh --test-null-uid

# 4. user_metadata abuse
bash scripts/test-role-permissions.sh --test-escalation

# 5. Missing indexes
# Check EXPLAIN ANALYZE on policy queries

# 6. Cross-tenant leaks
bash scripts/test-multi-tenant-isolation.sh --test-members

# 7. Service key exposure
grep -r "service_role" . --exclude-dir=node_modules

# 8. Anonymous access
bash scripts/test-anonymous-access.sh

# 9. Stale member access
bash scripts/test-multi-tenant-isolation.sh --test-members

# 10. Cascade bypasses
# Manual review of foreign keys

# Run complete suite
bash scripts/run-all-rls-tests.sh --ci --report results.json
```

## Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [OWASP Database Security](https://owasp.org/www-community/vulnerabilities/SQL_Injection)

---

**Remember:** Security is not a one-time task. Run these tests regularly and especially before every production deployment.
