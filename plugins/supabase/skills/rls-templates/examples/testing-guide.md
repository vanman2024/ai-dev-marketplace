# RLS Testing Guide

Comprehensive guide to testing Row Level Security policies in Supabase.

## Why Test RLS?

Row Level Security is your last line of defense. A single misconfigured policy can:
- ❌ Expose user data to other users
- ❌ Allow unauthorized modifications
- ❌ Create data breaches
- ❌ Violate compliance requirements (GDPR, HIPAA)

**Testing is not optional.**

---

## Testing Levels

### Level 1: Automated Script Testing

Use the provided test script for quick validation:

```bash
# Test all policies on a table
bash scripts/test-rls-policies.sh conversations

# Test with specific user context
bash scripts/test-rls-policies.sh messages --user-id "550e8400-e29b-41d4-a716-446655440000"

# Test organization isolation
bash scripts/test-rls-policies.sh documents --org-id "org-uuid-here"
```

**What it tests:**
- ✓ RLS is enabled
- ✓ Policies exist
- ✓ Anonymous access is denied
- ✓ Authenticated users can access their data
- ✓ Users cannot access other users' data
- ✓ Performance indexes exist

---

### Level 2: SQL-Based Testing

Test policies directly in SQL for granular control:

#### Test 1: Anonymous Access (Should Fail)

```sql
-- Switch to anon role
SET ROLE anon;

-- Try to select data (should return 0 rows or error)
SELECT COUNT(*) FROM conversations;
-- Expected: 0

-- Reset role
RESET ROLE;
```

#### Test 2: User Isolation

```sql
-- Create two test users (in your app or via SQL)
-- user1: '550e8400-e29b-41d4-a716-446655440000'
-- user2: '660f8400-e29b-41d4-a716-446655440001'

-- Set session as user1
SET ROLE authenticated;
SET request.jwt.claim.sub = '550e8400-e29b-41d4-a716-446655440000';

-- User1 should see their own data
SELECT COUNT(*) FROM conversations WHERE user_id = '550e8400-e29b-41d4-a716-446655440000';
-- Expected: > 0 (if user1 has conversations)

-- User1 should NOT see user2's data
SELECT COUNT(*) FROM conversations WHERE user_id = '660f8400-e29b-41d4-a716-446655440001';
-- Expected: 0

RESET ROLE;
```

#### Test 3: INSERT Policy

```sql
SET ROLE authenticated;
SET request.jwt.claim.sub = '550e8400-e29b-41d4-a716-446655440000';

-- Try to insert with correct user_id (should succeed)
INSERT INTO conversations (user_id, title)
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'Test Chat 1');
-- Expected: SUCCESS

-- Try to insert with wrong user_id (should fail)
INSERT INTO conversations (user_id, title)
VALUES ('660f8400-e29b-41d4-a716-446655440001', 'Test Chat 2');
-- Expected: ERROR (policy violation)

RESET ROLE;
```

#### Test 4: UPDATE Policy

```sql
SET ROLE authenticated;
SET request.jwt.claim.sub = '550e8400-e29b-41d4-a716-446655440000';

-- Update own record (should succeed)
UPDATE conversations
SET title = 'Updated Title'
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000';
-- Expected: SUCCESS

-- Try to update another user's record (should fail)
UPDATE conversations
SET title = 'Hacked!'
WHERE user_id = '660f8400-e29b-41d4-a716-446655440001';
-- Expected: 0 rows updated (policy blocks)

RESET ROLE;
```

#### Test 5: DELETE Policy

```sql
SET ROLE authenticated;
SET request.jwt.claim.sub = '550e8400-e29b-41d4-a716-446655440000';

-- Delete own record (should succeed)
DELETE FROM conversations
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
AND title = 'Test Chat 1';
-- Expected: SUCCESS

-- Try to delete another user's record (should fail)
DELETE FROM conversations
WHERE user_id = '660f8400-e29b-41d4-a716-446655440001';
-- Expected: 0 rows deleted (policy blocks)

RESET ROLE;
```

---

### Level 3: Client SDK Testing

Test through your application's client code:

#### TypeScript/JavaScript Example

```typescript
import { createClient } from '@supabase/supabase-js';

// Test user credentials
const USER1_EMAIL = 'user1@test.com';
const USER1_PASSWORD = 'testpass123';
const USER2_EMAIL = 'user2@test.com';
const USER2_PASSWORD = 'testpass456';

async function testRLS() {
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  // Test 1: Anonymous access (should fail)
  console.log('Test 1: Anonymous access');
  const { data: anonData, error: anonError } = await supabase
    .from('conversations')
    .select('*');

  console.assert(
    anonData?.length === 0 || anonError !== null
    'Anonymous access should be denied'
  );

  // Test 2: User1 can see their data
  console.log('Test 2: User1 authentication');
  const { data: { user: user1 } } = await supabase.auth.signInWithPassword({
    email: USER1_EMAIL
    password: USER1_PASSWORD
  });

  const { data: user1Data } = await supabase
    .from('conversations')
    .select('*')
    .eq('user_id', user1!.id);

  console.assert(
    user1Data?.every(conv => conv.user_id === user1!.id)
    'User1 should only see their own conversations'
  );

  // Test 3: User1 cannot see User2's data
  console.log('Test 3: User isolation');
  const { data: { user: user2 } } = await supabase.auth.signInWithPassword({
    email: USER2_EMAIL
    password: USER2_PASSWORD
  });

  // Sign back in as user1
  await supabase.auth.signInWithPassword({
    email: USER1_EMAIL
    password: USER1_PASSWORD
  });

  const { data: crossUserData } = await supabase
    .from('conversations')
    .select('*')
    .eq('user_id', user2!.id);  // Try to get user2's data

  console.assert(
    crossUserData?.length === 0
    'User1 should not see User2\'s conversations'
  );

  // Test 4: User1 can insert their own data
  console.log('Test 4: Insert policy');
  const { data: insertData, error: insertError } = await supabase
    .from('conversations')
    .insert({
      user_id: user1!.id
      title: 'RLS Test Conversation'
    })
    .select()
    .single();

  console.assert(
    insertError === null && insertData !== null
    'User1 should be able to insert their own data'
  );

  // Test 5: User1 cannot insert for User2
  console.log('Test 5: INSERT validation');
  const { error: invalidInsertError } = await supabase
    .from('conversations')
    .insert({
      user_id: user2!.id,  // Wrong user_id
      title: 'Should Fail'
    });

  console.assert(
    invalidInsertError !== null
    'User1 should not be able to insert data for User2'
  );

  // Test 6: User1 can update their own data
  console.log('Test 6: Update policy');
  const { error: updateError } = await supabase
    .from('conversations')
    .update({ title: 'Updated Title' })
    .eq('id', insertData!.id);

  console.assert(
    updateError === null
    'User1 should be able to update their own data'
  );

  // Test 7: User1 can delete their own data
  console.log('Test 7: Delete policy');
  const { error: deleteError } = await supabase
    .from('conversations')
    .delete()
    .eq('id', insertData!.id);

  console.assert(
    deleteError === null
    'User1 should be able to delete their own data'
  );

  console.log('✅ All RLS tests passed!');
}

// Run tests
testRLS().catch(console.error);
```

---

### Level 4: Integration Testing

Test RLS in realistic application scenarios:

#### Multi-Tenant Organization Test

```typescript
async function testMultiTenantRLS() {
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  // User1 in Org A
  const { data: { user: user1 } } = await supabase.auth.signInWithPassword({
    email: 'user1@orga.com'
    password: 'pass'
  });

  // Create organization A
  const { data: orgA } = await supabase
    .from('organizations')
    .insert({ name: 'Org A' })
    .select()
    .single();

  // Add user1 to org A
  await supabase.from('org_members').insert({
    organization_id: orgA!.id
    user_id: user1!.id
    role: 'admin'
  });

  // User1 creates a project in Org A
  const { data: projectA } = await supabase
    .from('projects')
    .insert({
      organization_id: orgA!.id
      name: 'Project A'
    })
    .select()
    .single();

  console.assert(projectA !== null, 'User1 should create project in their org');

  // User2 in Org B
  const { data: { user: user2 } } = await supabase.auth.signInWithPassword({
    email: 'user2@orgb.com'
    password: 'pass'
  });

  const { data: orgB } = await supabase
    .from('organizations')
    .insert({ name: 'Org B' })
    .select()
    .single();

  await supabase.from('org_members').insert({
    organization_id: orgB!.id
    user_id: user2!.id
    role: 'member'
  });

  // User2 should NOT see Org A's projects
  const { data: crossOrgProjects } = await supabase
    .from('projects')
    .select('*')
    .eq('organization_id', orgA!.id);

  console.assert(
    crossOrgProjects?.length === 0
    'User2 should not see Org A projects'
  );

  // User2 should NOT be able to create projects in Org A
  const { error: invalidOrgError } = await supabase
    .from('projects')
    .insert({
      organization_id: orgA!.id,  // Wrong org
      name: 'Should Fail'
    });

  console.assert(
    invalidOrgError !== null
    'User2 should not create projects in Org A'
  );

  console.log('✅ Multi-tenant isolation working!');
}
```

---

## Performance Testing

### Test Query Performance

```sql
-- Enable timing
\timing on

-- Test query with RLS
SET ROLE authenticated;
SET request.jwt.claim.sub = 'user-uuid-here';

-- Run query multiple times
SELECT * FROM messages WHERE conversation_id = 'conv-uuid';
SELECT * FROM messages WHERE conversation_id = 'conv-uuid';
SELECT * FROM messages WHERE conversation_id = 'conv-uuid';

-- Check execution plan
EXPLAIN ANALYZE
SELECT * FROM messages WHERE conversation_id = 'conv-uuid';

RESET ROLE;
```

**What to look for:**
- Query time < 100ms for typical queries
- Index usage in execution plan
- No sequential scans on large tables

### Benchmark with/without Indexes

```sql
-- Drop index
DROP INDEX IF EXISTS idx_messages_conversation_id;

-- Test query (should be slow)
EXPLAIN ANALYZE SELECT * FROM messages WHERE conversation_id = 'conv-uuid';

-- Recreate index
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);

-- Test again (should be fast)
EXPLAIN ANALYZE SELECT * FROM messages WHERE conversation_id = 'conv-uuid';
```

---

## Audit Testing

Run regular security audits:

```bash
# Audit all tables
bash scripts/audit-rls.sh

# Generate report
bash scripts/audit-rls.sh --report security-audit-$(date +%Y-%m-%d).md

# Check specific tables
bash scripts/audit-rls.sh conversations messages documents
```

**Add to CI/CD:**
```yaml
# .github/workflows/security-audit.yml
name: RLS Security Audit
on: [push, pull_request]
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run RLS Audit
        env:
          SUPABASE_DB_URL: ${{ secrets.SUPABASE_DB_URL }}
        run: |
          bash scripts/audit-rls.sh
```

---

## Common Test Scenarios

### Scenario 1: Shared Conversations

```typescript
// User1 creates conversation
const { data: conv } = await supabase
  .from('conversations')
  .insert({ user_id: user1.id, title: 'Shared Chat' })
  .select()
  .single();

// User1 shares with User2
await supabase
  .from('conversation_participants')
  .insert({
    conversation_id: conv.id
    user_id: user2.id
  });

// Sign in as User2
await supabase.auth.signInWithPassword({ email: 'user2@test.com', ... });

// User2 should now see the conversation
const { data: sharedConv } = await supabase
  .from('conversations')
  .select('*')
  .eq('id', conv.id)
  .single();

console.assert(sharedConv !== null, 'User2 should see shared conversation');
```

### Scenario 2: Role-Based Create/Update

```typescript
// Set user role to 'viewer' (read-only)
await supabaseAdmin.auth.admin.updateUserById(user.id, {
  app_metadata: { role: 'viewer' }
});

// Sign in as viewer
await supabase.auth.signInWithPassword({ ... });

// Should NOT be able to create
const { error: createError } = await supabase
  .from('articles')
  .insert({ title: 'Should Fail' });

console.assert(createError !== null, 'Viewer should not create articles');

// Change role to 'editor'
await supabaseAdmin.auth.admin.updateUserById(user.id, {
  app_metadata: { role: 'editor' }
});

// Refresh session to get new JWT
await supabase.auth.refreshSession();

// Should now be able to create
const { error: createError2 } = await supabase
  .from('articles')
  .insert({ title: 'Should Succeed' });

console.assert(createError2 === null, 'Editor should create articles');
```

---

## Test Data Setup

### Create Test Users

```sql
-- Insert test users via Supabase Dashboard or API
-- Or use SQL (advanced):
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at)
VALUES
  ('550e8400-e29b-41d4-a716-446655440000', 'user1@test.com', crypt('password123', gen_salt('bf')), NOW(), NOW())
  ('660f8400-e29b-41d4-a716-446655440001', 'user2@test.com', crypt('password456', gen_salt('bf')), NOW(), NOW());
```

### Seed Test Data

```sql
-- User1's conversations
INSERT INTO conversations (id, user_id, title) VALUES
  ('c1111111-1111-1111-1111-111111111111', '550e8400-e29b-41d4-a716-446655440000', 'User1 Chat 1')
  ('c2222222-2222-2222-2222-222222222222', '550e8400-e29b-41d4-a716-446655440000', 'User1 Chat 2');

-- User2's conversations
INSERT INTO conversations (id, user_id, title) VALUES
  ('c3333333-3333-3333-3333-333333333333', '660f8400-e29b-41d4-a716-446655440001', 'User2 Chat 1');
```

---

## Continuous Testing

### Automated Test Suite

Create a comprehensive test script:

```bash
#!/bin/bash
# test-all-rls.sh

set -e

echo "Running RLS test suite..."

# Test user isolation
bash scripts/test-rls-policies.sh conversations
bash scripts/test-rls-policies.sh messages

# Test multi-tenant
bash scripts/test-rls-policies.sh organizations
bash scripts/test-rls-policies.sh projects

# Audit all tables
bash scripts/audit-rls.sh --report audit-$(date +%Y-%m-%d).md

echo "✅ All RLS tests passed!"
```

### Run Before Deployment

```bash
# In your deployment script
echo "Running pre-deployment security checks..."
bash test-all-rls.sh || {
  echo "❌ RLS tests failed! Aborting deployment."
  exit 1
}

echo "✅ Security checks passed. Proceeding with deployment..."
```

---

## Checklist

Before deploying to production, verify:

- [ ] RLS enabled on ALL tables in public schema
- [ ] Policies tested with anonymous users (should deny)
- [ ] Policies tested with authenticated users (correct access)
- [ ] User isolation tested (users cannot see each other's data)
- [ ] INSERT policies include WITH CHECK clause
- [ ] UPDATE policies include both USING and WITH CHECK
- [ ] Performance indexes exist on policy columns
- [ ] Audit script passes with 0 critical issues
- [ ] Client SDK tests pass for all CRUD operations
- [ ] Multi-tenant isolation tested (if applicable)
- [ ] Role-based policies tested at each permission level
- [ ] Edge cases tested (null values, edge conditions)
- [ ] Performance benchmarks acceptable (< 100ms queries)
