# Quick Start Guide - Supabase E2E Testing

Get started with Supabase E2E testing in 5 minutes.

## Prerequisites

- Node.js 18+ installed
- Supabase CLI: `npm install -g supabase`
- Your Supabase project (local or cloud)

## Step 1: Setup (2 minutes)

```bash
# Clone or navigate to your project
cd your-project

# Run setup script
bash scripts/setup-test-env.sh
```

This creates:
- `.env.test` file
- Test directories
- Configuration files

## Step 2: Configure (1 minute)

### Option A: Local Testing (Recommended)

```bash
# Start local Supabase
supabase init
supabase start

# Get credentials
supabase status
```

Copy the values to `.env.test`:
```bash
SUPABASE_TEST_URL=http://localhost:54321
SUPABASE_TEST_ANON_KEY=<copy from supabase status>
SUPABASE_TEST_SERVICE_ROLE_KEY=<copy from supabase status>
DATABASE_URL=<copy DB URL from supabase status>
```

### Option B: Cloud Testing

Use a dedicated test project (never production!):

```bash
# In .env.test
SUPABASE_TEST_URL=https://your-test-project.supabase.co
SUPABASE_TEST_ANON_KEY=your-test-anon-key
SUPABASE_TEST_SERVICE_ROLE_KEY=your-test-service-key
```

## Step 3: Install Dependencies (1 minute)

```bash
npm install --save-dev @supabase/supabase-js jest @types/jest ts-jest
```

Or if you prefer Vitest:
```bash
npm install --save-dev @supabase/supabase-js vitest
```

## Step 4: Run Your First Test (1 minute)

### Test Database

```bash
# Run database tests
supabase test db
```

### Test Authentication

```bash
# Quick auth workflow test
bash scripts/test-auth-workflow.sh
```

### Test AI Features

```bash
# Enable pgvector first
psql $DATABASE_URL -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Run AI feature tests
bash scripts/test-ai-features.sh
```

## Step 5: Run Complete Suite

```bash
# Run all tests
bash scripts/run-e2e-tests.sh

# Or with npm
npm test
```

## What You Get

After setup, you have:

✅ **Functional Test Scripts**
- Authentication workflow tests
- Database schema validation
- Vector search tests
- Realtime subscription tests

✅ **Test Templates**
- Jest/Vitest boilerplate
- Auth test examples
- Vector search examples
- Realtime test examples

✅ **CI/CD Ready**
- GitHub Actions configuration
- Automated test execution
- Coverage reporting

## Next Steps

### 1. Create Your First Test

Create `tests/my-first-test.test.ts`:

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_TEST_URL!,
  process.env.SUPABASE_TEST_ANON_KEY!
);

describe('My First Test', () => {
  test('should connect to Supabase', async () => {
    const { data, error } = await supabase
      .from('users')
      .select('count')
      .single();

    expect(error).toBeNull();
  });
});
```

Run it:
```bash
npm test -- tests/my-first-test.test.ts
```

### 2. Add to CI/CD

```bash
# Copy GitHub Actions config
cp templates/ci-config.yml .github/workflows/supabase-tests.yml

# Commit and push
git add .
git commit -m "Add E2E tests"
git push
```

Tests run automatically on every push!

### 3. Explore Templates

Check `templates/` directory for:
- `auth-tests.ts` - Complete auth testing examples
- `vector-search-tests.ts` - pgvector testing patterns
- `realtime-tests.ts` - Realtime subscription examples

### 4. Read Full Guides

- `examples/complete-test-workflow.md` - Comprehensive testing guide
- `examples/ci-cd-integration.md` - CI/CD setup for all platforms
- `examples/test-data-strategies.md` - Test data management

## Common Commands

```bash
# Setup
bash scripts/setup-test-env.sh

# Run all tests
bash scripts/run-e2e-tests.sh

# Run specific suite
bash scripts/run-e2e-tests.sh --suite auth
bash scripts/run-e2e-tests.sh --suite vector
bash scripts/run-e2e-tests.sh --suite realtime

# Run with coverage
bash scripts/run-e2e-tests.sh --coverage

# Cleanup
bash scripts/cleanup-test-resources.sh

# Local Supabase
supabase start    # Start
supabase stop     # Stop
supabase status   # Check status
supabase db reset # Reset database
```

## Troubleshooting

### "Supabase CLI not found"

```bash
npm install -g supabase
```

### "Connection refused"

```bash
# Check Supabase is running
supabase status

# If not, start it
supabase start
```

### ".env.test not found"

```bash
# Run setup script
bash scripts/setup-test-env.sh
```

### "Tests failing"

```bash
# Run with verbose output
bash scripts/run-e2e-tests.sh --verbose

# Check environment variables
cat .env.test
```

## Tips

1. **Always use local Supabase for development** - It's faster and safer
2. **Never test against production** - Use dedicated test projects
3. **Clean up after tests** - Prevents test data pollution
4. **Run tests in CI/CD** - Catch issues early
5. **Maintain test coverage** - Aim for > 70%

## Getting Help

- Check `README.md` for full documentation
- Review example files in `examples/`
- Check script comments for details
- Visit [Supabase Docs](https://supabase.com/docs)

## You're Ready! 🚀

You now have a complete E2E testing framework for your Supabase application. Start writing tests and ship with confidence!

```bash
# Run your tests
npm test

# Watch for changes
npm test -- --watch

# Generate coverage report
npm test -- --coverage
```

Happy testing! 🧪
