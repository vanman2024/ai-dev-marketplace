# E2E Test Scenarios Skill

Complete end-to-end testing framework for Supabase applications, covering database operations, authentication flows, AI features (pgvector), realtime subscriptions, and full integration testing.

## Quick Start

### 1. Setup Test Environment

```bash
bash scripts/setup-test-env.sh
```

This creates:
- `.env.test` configuration file
- Test directory structure
- Sample test files
- Jest/Vitest configuration

### 2. Configure Test Credentials

Edit `.env.test` with your test project credentials:

```bash
SUPABASE_TEST_URL=http://localhost:54321
SUPABASE_TEST_ANON_KEY=your-test-anon-key
SUPABASE_TEST_SERVICE_ROLE_KEY=your-test-service-role-key
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
```

### 3. Run Tests

```bash
# Run complete test suite
bash scripts/run-e2e-tests.sh

# Run specific test suite
bash scripts/run-e2e-tests.sh --suite auth

# Run with coverage
bash scripts/run-e2e-tests.sh --coverage
```

## Test Suites

### Database Tests (pgTAP)

Tests schema, migrations, RLS policies, and database functions.

```bash
# Run database tests
bash scripts/test-database-workflow.sh
supabase test db
```

### Authentication Tests

Tests signup, login, sessions, password reset, and RLS enforcement.

```bash
# Run auth tests
bash scripts/test-auth-workflow.sh
npm test -- tests/auth
```

### Vector/AI Features Tests

Tests pgvector extension, embedding operations, and semantic search.

```bash
# Run AI feature tests
bash scripts/test-ai-features.sh
npm test -- tests/vector
```

### Realtime Tests

Tests database change subscriptions, broadcast, and presence.

```bash
# Run realtime tests
bash scripts/test-realtime-workflow.sh
npm test -- tests/realtime
```

### Integration Tests

Tests complete user workflows from signup to data operations.

```bash
# Run integration tests
npm test -- tests/integration
```

## Scripts

| Script | Purpose |
|--------|---------|
| `setup-test-env.sh` | Initialize test environment |
| `run-e2e-tests.sh` | Execute complete test suite |
| `test-auth-workflow.sh` | Test authentication flows |
| `test-ai-features.sh` | Test pgvector and embeddings |
| `test-realtime-workflow.sh` | Test realtime features |
| `cleanup-test-resources.sh` | Clean up test data |

## Templates

| Template | Purpose |
|----------|---------|
| `test-suite-template.ts` | Jest/Vitest test boilerplate |
| `auth-tests.ts` | Authentication flow tests |
| `vector-search-tests.ts` | pgvector and semantic search tests |
| `realtime-tests.ts` | Realtime subscription tests |
| `ci-config.yml` | GitHub Actions CI/CD configuration |

## Examples

| Example | Description |
|---------|-------------|
| `complete-test-workflow.md` | Step-by-step E2E testing guide |
| `ci-cd-integration.md` | CI/CD setup for multiple platforms |
| `test-data-strategies.md` | Test data management patterns |

## CI/CD Integration

### GitHub Actions

```bash
# Copy CI configuration
cp templates/ci-config.yml .github/workflows/supabase-tests.yml

# Configure secrets in GitHub repository settings
# - SUPABASE_TEST_URL
# - SUPABASE_TEST_ANON_KEY
# - SUPABASE_TEST_SERVICE_ROLE_KEY
```

Tests run automatically on:
- Push to main/develop branches
- Pull requests
- Manual workflow dispatch

## Test Coverage

The test suite covers:

- ✅ Database schema validation
- ✅ Migration testing
- ✅ RLS policy enforcement
- ✅ User authentication flows
- ✅ Session management
- ✅ Password reset
- ✅ Vector embedding storage
- ✅ Semantic similarity search
- ✅ HNSW/IVFFlat indexes
- ✅ Realtime subscriptions
- ✅ Broadcast messaging
- ✅ Presence tracking
- ✅ Complete user workflows

## Performance Benchmarks

Target performance metrics:

- Simple queries: < 50ms
- Vector similarity search: < 100ms
- Hybrid search: < 200ms
- Realtime message delivery: < 100ms
- Auth operations: < 500ms

## Cleanup

Clean up test resources after testing:

```bash
# Standard cleanup
bash scripts/cleanup-test-resources.sh

# Full database reset
bash scripts/cleanup-test-resources.sh --full
```

## Troubleshooting

### Supabase Not Running

```bash
supabase status  # Check status
supabase start   # Start local instance
```

### Connection Errors

Verify `.env.test` credentials and Supabase is accessible.

### Test Timeouts

Increase timeout in `.env.test`:
```bash
TEST_TIMEOUT=60000
```

### RLS Policy Failures

Use service role key for admin operations or adjust RLS policies for testing.

## Best Practices

1. **Use Local Supabase** for development and CI/CD
2. **Dedicated Test Project** for production testing
3. **Clean Up After Tests** to maintain test isolation
4. **Run Tests in Parallel** for faster execution
5. **Monitor Coverage** - maintain > 70% coverage
6. **Version Test Data** - use fixtures for consistency

## Resources

- [Supabase Testing Docs](https://supabase.com/docs/guides/getting-started/testing)
- [pgTAP Documentation](https://pgtap.org/)
- [Jest Documentation](https://jestjs.io/)
- [Vitest Documentation](https://vitest.dev/)

## Support

For issues or questions:
1. Check the `examples/` directory for detailed guides
2. Review script comments for implementation details
3. Consult Supabase documentation
4. Check GitHub Actions logs for CI failures

---

**Plugin**: supabase
**Version**: 1.0.0
**Skill**: e2e-test-scenarios
