# RLS Testing Workflow

Complete workflow for testing Row Level Security policies in Supabase applications.

## Overview

Testing RLS policies ensures your security model works correctly before deploying to production. This workflow covers setup, execution, and continuous monitoring.

## Workflow Phases

### Phase 1: Initial Setup (One-time)

#### 1.1 Install Dependencies

```bash
# PostgreSQL client (for bash scripts)
brew install postgresql  # macOS
apt-get install postgresql-client  # Ubuntu/Debian

# Node.js dependencies (for TypeScript tests)
npm install --save-dev @supabase/supabase-js jest @types/jest

# Supabase CLI (for pgTAP tests)
brew install supabase/tap/supabase  # macOS
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git  # Windows
scoop install supabase
```

#### 1.2 Configure Environment

Create `.env` file:
```bash
# Database connection
SUPABASE_DB_URL="postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres"

# API credentials
SUPABASE_URL="https://[project-ref].supabase.co"
SUPABASE_ANON_KEY="eyJ..."
SUPABASE_SERVICE_KEY="eyJ..."

# Test users (optional)
TEST_USER_1_EMAIL="test1@example.com"
TEST_USER_1_PASSWORD="test-password-123"
TEST_USER_2_EMAIL="test2@example.com"
TEST_USER_2_PASSWORD="test-password-456"
```

**Security Note:** Never commit `.env` to version control. Add to `.gitignore`.

#### 1.3 Create Test Users

```sql
-- Using Supabase Dashboard > Authentication > Users
-- Or via service key:

INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
VALUES
  ('test1@example.com', crypt('test-password-123', gen_salt('bf')), NOW())
  ('test2@example.com', crypt('test-password-456', gen_salt('bf')), NOW());
```

### Phase 2: Development Testing (Per Feature)

When creating or modifying RLS policies, run these tests:

#### 2.1 Quick Validation

```bash
# Check RLS is enabled on new table
psql $SUPABASE_DB_URL -c "
  SELECT relrowsecurity
  FROM pg_class
  WHERE oid = 'public.your_new_table'::regclass;
"
# Should return: t (true)

# Check policies exist
psql $SUPABASE_DB_URL -c "
  SELECT policyname, cmd
  FROM pg_policies
  WHERE tablename = 'your_new_table';
"
# Should show SELECT, INSERT, UPDATE, DELETE policies
```

#### 2.2 Test Specific Table

```bash
# Test user isolation on the table
bash scripts/test-user-isolation.sh your_new_table

# Test multi-tenant isolation (if applicable)
bash scripts/test-multi-tenant-isolation.sh your_new_table

# Test anonymous access
bash scripts/test-anonymous-access.sh your_new_table
```

#### 2.3 Review Results

- **All tests pass:** Policy is correct, proceed to commit
- **Tests fail:** Fix policy, re-test until passing
- **Cannot insert test data:** Verify table schema, adjust scripts if needed

### Phase 3: Pre-Commit Testing

Before committing RLS policy changes:

#### 3.1 Run Full Test Suite

```bash
# Run all tests with detailed report
bash scripts/run-all-rls-tests.sh \
  --verbose \
  --report rls-test-results.json

# Check exit code
echo $?  # Should be 0 (success)
```

#### 3.2 Audit Coverage

```bash
# Generate coverage report
bash scripts/audit-rls-coverage.sh \
  --report coverage.md \
  --format markdown

# Review report for missing policies
cat coverage.md
```

#### 3.3 Fix Issues

If tests fail:

```bash
# Review detailed output
cat rls-test-results.json | jq '.results'

# Common fixes:
# - Add missing WITH CHECK clause
# - Fix auth.uid() null handling
# - Add missing policy for operation
# - Create index on policy column
```

### Phase 4: CI/CD Integration

#### 4.1 GitHub Actions Workflow

Create `.github/workflows/rls-tests.yml`:

```yaml
name: RLS Security Tests

on:
  pull_request:
    paths:
      - 'supabase/migrations/**'
      - 'database/**'
  push:
    branches: [main, develop]

jobs:
  rls-tests:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1

      - name: Start Supabase
        run: supabase start

      - name: Run Migrations
        run: supabase db reset

      - name: Run RLS Tests
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:54322/postgres
        run: |
          bash scripts/run-all-rls-tests.sh \
            --ci \
            --fail-fast \
            --report rls-results.json

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: rls-test-results
          path: rls-results.json

      - name: Comment PR
        if: failure()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number
              owner: context.repo.owner
              repo: context.repo.repo
              body: '❌ RLS security tests failed. Review test results artifact.'
            })
```

#### 4.2 Pre-commit Hook (Optional)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run RLS tests before commit if migrations changed

if git diff --cached --name-only | grep -q "supabase/migrations"; then
  echo "RLS migration detected, running tests..."

  bash scripts/run-all-rls-tests.sh --ci

  if [ $? -ne 0 ]; then
    echo "❌ RLS tests failed. Commit aborted."
    echo "Fix issues and try again."
    exit 1
  fi

  echo "✅ RLS tests passed"
fi
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Phase 5: Pre-Production Testing

Before deploying to production:

#### 5.1 Staging Environment Tests

```bash
# Test against staging database
export SUPABASE_DB_URL="$STAGING_DB_URL"

# Run full suite
bash scripts/run-all-rls-tests.sh \
  --verbose \
  --report staging-rls-results.json

# Verify all tests pass
cat staging-rls-results.json | jq '.status'
# Should output: "PASSED"
```

#### 5.2 Load Testing with RLS

```bash
# Create load test script
cat > load-test-rls.js <<'EOF'
import { createClient } from '@supabase/supabase-js'

const client = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!)

async function loadTest() {
  const start = Date.now()

  // Simulate 100 concurrent requests
  const promises = Array(100).fill(null).map(async () => {
    const { data } = await client.from('conversations').select('*')
    return data?.length
  })

  await Promise.all(promises)

  const duration = Date.now() - start
  console.log(`100 requests completed in ${duration}ms`)
  console.log(`Average: ${duration / 100}ms per request`)
}

loadTest()
EOF

# Run load test
node load-test-rls.js
```

Expected performance:
- < 100ms per request with proper indexes
- > 500ms indicates missing indexes on policy columns

#### 5.3 Security Checklist

Use security checklist:
```bash
cat templates/security-checklist.md
```

Work through each item, checking off as verified.

### Phase 6: Production Monitoring

After deploying to production:

#### 6.1 Monitor Slow Queries

```sql
-- View slow queries (in Supabase Dashboard > Logs > Postgres)
SELECT
  query
  mean_exec_time
  calls
FROM pg_stat_statements
WHERE query LIKE '%FROM public.%'
ORDER BY mean_exec_time DESC
LIMIT 10;
```

#### 6.2 Check for Failed Access Attempts

```sql
-- If you have audit logging:
SELECT
  user_id
  table_name
  operation
  COUNT(*) as failed_attempts
FROM audit.access_denied_log
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY user_id, table_name, operation
ORDER BY failed_attempts DESC;
```

#### 6.3 Weekly Security Audit

```bash
# Schedule weekly (via cron):
0 9 * * 1 cd /path/to/project && bash scripts/audit-rls-coverage.sh --report weekly-audit.md
```

### Phase 7: Regression Testing

When bugs are found:

#### 7.1 Create Regression Test

```typescript
// tests/rls-regression.test.ts
it('Issue #123: User could read deleted conversations', async () => {
  // Create conversation
  const { data: conv } = await user1Client
    .from('conversations')
    .insert({ user_id: user1Id, deleted_at: new Date() })
    .select()
    .single()

  // Should not be visible
  const { data: visible } = await user1Client
    .from('conversations')
    .select()
    .eq('id', conv!.id)

  expect(visible).toHaveLength(0)

  // Cleanup
  await serviceClient.from('conversations').delete().eq('id', conv!.id)
})
```

#### 7.2 Fix and Verify

```sql
-- Fix: Add deleted_at check to SELECT policy
CREATE POLICY "Users read own active conversations"
ON conversations FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
  AND deleted_at IS NULL  -- ADD THIS
);
```

Run regression test:
```bash
npm test -- tests/rls-regression.test.ts
```

## Common Testing Scenarios

### Scenario 1: New Table Added

```bash
# 1. Enable RLS
psql $SUPABASE_DB_URL -c "
  ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;
"

# 2. Create policies (use rls-templates skill)

# 3. Test the table
bash scripts/test-user-isolation.sh new_table
bash scripts/test-anonymous-access.sh new_table

# 4. Add to CI test suite (automatic if using --all flag)
```

### Scenario 2: Policy Modified

```bash
# 1. Test before modification (baseline)
bash scripts/test-user-isolation.sh affected_table > before.log

# 2. Modify policy
# (make your changes)

# 3. Test after modification
bash scripts/test-user-isolation.sh affected_table > after.log

# 4. Compare results
diff before.log after.log
```

### Scenario 3: Multi-Tenant Feature Added

```bash
# 1. Add organization_id column
psql $SUPABASE_DB_URL -c "
  ALTER TABLE projects ADD COLUMN organization_id UUID REFERENCES organizations(id);
  CREATE INDEX idx_projects_org_id ON projects(organization_id);
"

# 2. Create multi-tenant policies (use rls-templates skill)

# 3. Test isolation
bash scripts/test-multi-tenant-isolation.sh projects --test-members

# 4. Verify removed members lose access
```

## Troubleshooting

### Tests Fail with "Cannot insert test data"

**Cause:** Table has required columns that test scripts don't know about.

**Solution:** Either:
1. Add defaults: `ALTER TABLE t ADD COLUMN c TEXT DEFAULT 'test'`
2. Make nullable: `ALTER TABLE t ALTER COLUMN c DROP NOT NULL`
3. Customize test scripts for your schema

### Tests Pass but Real Users Report Issues

**Cause:** Test scenarios don't cover all real-world use cases.

**Solution:**
1. Add failing use case to test suite
2. Fix policy to handle case
3. Re-run tests to verify

### Policies Are Slow

**Cause:** Missing indexes on columns used in policies.

**Solution:**
```sql
CREATE INDEX idx_table_user_id ON table(user_id);
CREATE INDEX idx_table_org_id ON table(organization_id);
```

## Best Practices

1. **Test early and often** - Test RLS as you develop, not after
2. **Use realistic data** - Test with data patterns similar to production
3. **Automate in CI** - Block deploys on test failures
4. **Monitor production** - Watch for slow queries and failed access
5. **Document edge cases** - Add comments explaining complex policies
6. **Keep tests fast** - Target < 30 seconds for full suite
7. **Version test data** - Track test user IDs and org IDs
8. **Test both success and failure** - Verify access granted AND denied

## Next Steps

- Review [common-vulnerabilities.md](common-vulnerabilities.md) for known issues
- Check [ci-integration.md](ci-integration.md) for advanced CI patterns
- Use [security-checklist.md](../templates/security-checklist.md) before each deploy
