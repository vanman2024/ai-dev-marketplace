# Complete E2E Test Workflow

This guide walks through a complete end-to-end testing workflow for a Supabase application, from setup to CI/CD integration.

## Overview

A comprehensive E2E testing strategy for Supabase covers:

1. **Database Testing** - Schema, migrations, RLS, functions
2. **Authentication Testing** - Signup, login, sessions, security
3. **AI Features Testing** - pgvector, embeddings, semantic search
4. **Realtime Testing** - Subscriptions, broadcast, presence
5. **Integration Testing** - Complete user workflows

## Prerequisites

- Node.js 18+ installed
- Supabase CLI installed (`npm install -g supabase`)
- Test Supabase project (local or dedicated test project)
- Git repository with your application code

## Step 1: Initial Setup

### 1.1 Initialize Test Environment

```bash
# Run the setup script
bash scripts/setup-test-env.sh
```

This creates:
- `.env.test` file for test configuration
- Test directory structure
- Sample test files
- Jest/Vitest configuration

### 1.2 Configure Test Environment

Edit `.env.test`:

```bash
# Use local Supabase instance (recommended for CI/CD)
SUPABASE_TEST_URL=http://localhost:54321
SUPABASE_TEST_ANON_KEY=your-local-anon-key
SUPABASE_TEST_SERVICE_ROLE_KEY=your-local-service-key
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres

# Or use dedicated test project
SUPABASE_TEST_URL=https://xxx.supabase.co
SUPABASE_TEST_ANON_KEY=your-test-project-anon-key
SUPABASE_TEST_SERVICE_ROLE_KEY=your-test-project-service-key
```

### 1.3 Start Local Supabase (if using local testing)

```bash
supabase start
```

Get credentials:
```bash
supabase status
```

## Step 2: Database Testing

### 2.1 Create Database Tests (pgTAP)

Create `supabase/tests/database/schema.test.sql`:

```sql
begin;
select plan(5);

-- Test table exists
select has_table('public', 'users', 'users table should exist');

-- Test columns exist
select has_column('public', 'users', 'id', 'users should have id column');
select has_column('public', 'users', 'email', 'users should have email column');

-- Test RLS is enabled
select row_security_on('public', 'users', 'RLS should be enabled on users');

-- Test indexes exist
select has_index('public', 'users', 'users_email_idx', 'email index should exist');

select * from finish();
rollback;
```

### 2.2 Run Database Tests

```bash
# Run all database tests
supabase test db

# Run specific test file
supabase test db --file tests/database/schema.test.sql
```

## Step 3: Authentication Testing

### 3.1 Create Auth Test Suite

Create `tests/auth/auth-workflow.test.ts`:

```typescript
import { supabase, testHelpers } from '../setup';

describe('Authentication Workflow', () => {
  test('complete user signup and login flow', async () => {
    const email = testHelpers.randomEmail();
    const password = 'TestPassword123!';

    // 1. Signup
    const { data: signupData, error: signupError } =
      await supabase.auth.signUp({ email, password });

    expect(signupError).toBeNull();
    expect(signupData.user).toBeDefined();

    // 2. Login
    const { data: loginData, error: loginError } =
      await supabase.auth.signInWithPassword({ email, password });

    expect(loginError).toBeNull();
    expect(loginData.session).toBeDefined();

    // 3. Get user
    const { data: userData } = await supabase.auth.getUser();
    expect(userData.user?.email).toBe(email);

    // 4. Logout
    await supabase.auth.signOut();

    const { data: afterLogout } = await supabase.auth.getUser();
    expect(afterLogout.user).toBeNull();
  });
});
```

### 3.2 Run Auth Tests

```bash
# Run bash script tests
bash scripts/test-auth-workflow.sh

# Run Jest/Vitest tests
npm test -- tests/auth
```

## Step 4: Vector/AI Features Testing

### 4.1 Setup pgvector

```bash
# Enable pgvector extension
psql $DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### 4.2 Create Vector Tests

Create `tests/vector/semantic-search.test.ts`:

```typescript
describe('Semantic Search', () => {
  test('should find relevant documents', async () => {
    // Insert test documents with embeddings
    const documents = [
      { content: 'machine learning tutorial', embedding: [...] }
      { content: 'cooking recipes', embedding: [...] }
    ];

    await supabase.from('documents').insert(documents);

    // Search for similar content
    const queryEmbedding = [...]; // ML-related embedding

    const { data } = await supabase.rpc('match_documents', {
      query_embedding: queryEmbedding
      match_threshold: 0.7
      match_count: 5
    });

    expect(data[0].content).toContain('machine learning');
  });
});
```

### 4.3 Run Vector Tests

```bash
# Run bash script tests
bash scripts/test-ai-features.sh

# Run Jest/Vitest tests
npm test -- tests/vector
```

## Step 5: Realtime Testing

### 5.1 Create Realtime Tests

Create `tests/realtime/subscriptions.test.ts`:

```typescript
describe('Realtime Subscriptions', () => {
  test('should receive database changes', async () => {
    const receivedEvents: any[] = [];

    const channel = supabase
      .channel('test-channel')
      .on('postgres_changes'
        { event: 'INSERT', schema: 'public', table: 'messages' }
        (payload) => receivedEvents.push(payload)
      )
      .subscribe();

    // Wait for subscription
    await testHelpers.waitFor(() => channel.state === 'joined', 3000);

    // Insert data
    await supabase.from('messages').insert({ content: 'test' });

    // Wait for event
    await testHelpers.waitFor(() => receivedEvents.length > 0, 5000);

    expect(receivedEvents).toHaveLength(1);

    await supabase.removeChannel(channel);
  });
});
```

### 5.2 Run Realtime Tests

```bash
# Run bash script tests
bash scripts/test-realtime-workflow.sh

# Run Jest/Vitest tests
npm test -- tests/realtime
```

## Step 6: Integration Testing

### 6.1 Create Integration Tests

Create `tests/integration/user-workflow.test.ts`:

```typescript
describe('Complete User Workflow', () => {
  test('user signup -> create content -> search -> delete', async () => {
    // 1. User signup
    const email = testHelpers.randomEmail();
    const { data: user } = await supabase.auth.signUp({
      email
      password: 'Test123!'
    });

    // 2. Login
    await supabase.auth.signInWithPassword({
      email
      password: 'Test123!'
    });

    // 3. Create content
    const { data: note } = await supabase
      .from('notes')
      .insert({ content: 'My test note' })
      .select()
      .single();

    expect(note).toBeDefined();
    expect(note.user_id).toBe(user.user!.id);

    // 4. Query content
    const { data: notes } = await supabase
      .from('notes')
      .select('*');

    expect(notes).toHaveLength(1);

    // 5. Delete content
    await supabase.from('notes').delete().eq('id', note.id);

    // 6. Verify deletion
    const { data: afterDelete } = await supabase
      .from('notes')
      .select('*');

    expect(afterDelete).toHaveLength(0);

    // 7. Logout
    await supabase.auth.signOut();
  });
});
```

### 6.2 Run Integration Tests

```bash
npm test -- tests/integration
```

## Step 7: Run Complete Test Suite

### 7.1 Run All Tests

```bash
# Run complete E2E test suite
bash scripts/run-e2e-tests.sh

# Run with coverage
bash scripts/run-e2e-tests.sh --coverage

# Run specific suite
bash scripts/run-e2e-tests.sh --suite auth
```

### 7.2 Review Results

The script provides a summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Test Results Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Total Tests:   25
  Passed:        24
  Failed:        1
  Skipped:       0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 8: CI/CD Integration

### 8.1 Setup GitHub Actions

Copy the CI configuration:

```bash
cp templates/ci-config.yml .github/workflows/supabase-tests.yml
```

### 8.2 Configure Secrets

In GitHub repository settings, add:

- `SUPABASE_PROD_TEST_URL`
- `SUPABASE_PROD_TEST_ANON_KEY`
- `SUPABASE_PROD_TEST_SERVICE_ROLE_KEY`
- `SUPABASE_PROD_TEST_DB_URL`

### 8.3 Commit and Push

```bash
git add .
git commit -m "Add E2E tests with CI/CD"
git push
```

Tests will run automatically on:
- Push to main/develop
- Pull requests
- Manual trigger

## Step 9: Monitoring and Maintenance

### 9.1 Review Test Reports

Check GitHub Actions for:
- Test results
- Coverage reports
- Performance metrics

### 9.2 Update Tests

As your schema evolves:

1. Update pgTAP tests for schema changes
2. Add new integration tests for features
3. Update fixtures and test data
4. Maintain test coverage > 70%

### 9.3 Cleanup Test Resources

```bash
# Manual cleanup
bash scripts/cleanup-test-resources.sh

# With full database reset
bash scripts/cleanup-test-resources.sh --full
```

## Best Practices

### Test Isolation

- Each test should be independent
- Use transactions or cleanup in `afterEach`
- Don't rely on test execution order

### Test Data Management

- Use factories for creating test data
- Use unique identifiers (timestamps, random strings)
- Clean up after tests

### Performance

- Run tests in parallel when possible
- Use test suites to organize tests
- Mock external services

### Debugging Failed Tests

```bash
# Run with verbose output
bash scripts/run-e2e-tests.sh --verbose

# Run single test file
npm test -- tests/auth/auth-workflow.test.ts

# Run with debugger
node --inspect-brk node_modules/.bin/jest tests/auth
```

## Common Issues

### Connection Errors

**Problem**: `ECONNREFUSED` errors

**Solution**:
```bash
# Check Supabase is running
supabase status

# Restart if needed
supabase stop && supabase start
```

### RLS Policy Failures

**Problem**: Tests can't access data

**Solution**: Check RLS policies allow test operations or use service role key

### Timeout Errors

**Problem**: Tests timeout waiting for events

**Solution**: Increase timeout in test or `.env.test`:
```bash
TEST_TIMEOUT=60000
```

## Next Steps

1. Add more test scenarios for your specific features
2. Implement performance benchmarks
3. Add visual regression tests (if applicable)
4. Setup monitoring and alerting for test failures
5. Document test patterns for your team

## Resources

- [Supabase Testing Guide](https://supabase.com/docs/guides/getting-started/testing)
- [pgTAP Documentation](https://pgtap.org/)
- [Jest Documentation](https://jestjs.io/)
- [Vitest Documentation](https://vitest.dev/)
