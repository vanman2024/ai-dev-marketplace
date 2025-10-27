# RLS Test Patterns

Comprehensive testing framework for Supabase Row Level Security (RLS) policies. Catch security vulnerabilities before they reach production with automated tests for user isolation, multi-tenant security, role-based access control, and anonymous user restrictions.

## Quick Start

```bash
# 1. Set up environment
cp .env.example .env
# Edit .env with your Supabase credentials

# 2. Run complete test suite
bash scripts/run-all-rls-tests.sh --report results.json

# 3. Review results
cat results.json | jq '.status'
# Output: "PASSED" or "FAILED"
```

## What This Skill Provides

### Automated Test Scripts

Six comprehensive bash scripts for RLS validation:

1. **test-user-isolation.sh** - Verify users can only access their own data
2. **test-multi-tenant-isolation.sh** - Test organization-level data separation
3. **test-role-permissions.sh** - Validate role-based access control (admin/editor/viewer)
4. **test-anonymous-access.sh** - Ensure anonymous users are properly restricted
5. **audit-rls-coverage.sh** - Check all tables have proper RLS policies
6. **run-all-rls-tests.sh** - Execute complete security test suite

### Test Templates

Ready-to-use testing templates:

- **rls-test-suite.ts** - TypeScript/Jest test suite using Supabase Client
- **user-isolation-tests.sql** - SQL-based tests using pgTAP
- **test-scenarios.json** - Common RLS test scenarios and expected results
- **security-checklist.md** - Complete security verification checklist

### Documentation & Examples

Comprehensive guides:

- **testing-workflow.md** - Complete testing workflow from setup to production
- **common-vulnerabilities.md** - 10 common RLS vulnerabilities and how to test for them
- **ci-integration.md** - Integrate RLS tests into CI/CD pipelines

## Installation

### Prerequisites

```bash
# PostgreSQL client (for bash scripts)
brew install postgresql  # macOS
apt-get install postgresql-client  # Ubuntu/Debian

# Supabase CLI (for pgTAP tests)
brew install supabase/tap/supabase  # macOS

# Node.js 18+ (for TypeScript tests)
node --version  # Should be v18 or higher
```

### Environment Setup

Create `.env` file:

```bash
# Database connection
SUPABASE_DB_URL="postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres"

# API credentials
SUPABASE_URL="https://[project-ref].supabase.co"
SUPABASE_ANON_KEY="eyJ..."
SUPABASE_SERVICE_KEY="eyJ..."  # Never expose to clients!

# Optional: Test user credentials
TEST_USER_1_EMAIL="test1@example.com"
TEST_USER_1_PASSWORD="test-password-123"
TEST_USER_2_EMAIL="test2@example.com"
TEST_USER_2_PASSWORD="test-password-456"
```

**Security:** Add `.env` to `.gitignore`

## Usage

### Test User Isolation

Verify users can only access their own data:

```bash
# Test specific tables
bash scripts/test-user-isolation.sh conversations messages profiles

# Test all tables with user_id column
bash scripts/test-user-isolation.sh --all

# Generate detailed report
bash scripts/test-user-isolation.sh --all --report isolation-report.md
```

**What it tests:**
- ✓ User A cannot read User B's data
- ✓ User A cannot modify User B's data
- ✓ User A cannot insert data claiming to be User B
- ✓ User A can only access their own records

### Test Multi-Tenant Isolation

Verify organization/team data separation:

```bash
# Test organization isolation
bash scripts/test-multi-tenant-isolation.sh organizations projects documents

# Test member access revocation
bash scripts/test-multi-tenant-isolation.sh --test-members

# Use specific org IDs
bash scripts/test-multi-tenant-isolation.sh \
  --org1 "uuid1" \
  --org2 "uuid2" \
  projects
```

**What it tests:**
- ✓ Org A members cannot access Org B data
- ✓ Users not in org cannot access org data
- ✓ Removed members lose access immediately
- ✓ Cross-org data access blocked

### Test Role-Based Permissions

Validate role hierarchy (admin/editor/viewer):

```bash
# Test RBAC policies
bash scripts/test-role-permissions.sh admin_settings sensitive_data

# Test specific roles
bash scripts/test-role-permissions.sh --roles "admin,editor,viewer"

# Test privilege escalation prevention
bash scripts/test-role-permissions.sh --test-escalation
```

**What it tests:**
- ✓ Admin has full access (CRUD)
- ✓ Editor can read/write but not delete
- ✓ Viewer has read-only access
- ✓ Users cannot escalate privileges

### Test Anonymous Access

Verify anonymous users are restricted:

```bash
# Test anonymous restrictions on all public tables
bash scripts/test-anonymous-access.sh

# Test specific tables
bash scripts/test-anonymous-access.sh public_posts comments

# Test auth.uid() null handling
bash scripts/test-anonymous-access.sh --test-null-uid
```

**What it tests:**
- ✓ Anonymous users cannot access protected data
- ✓ Anonymous users can only access designated public data
- ✓ Policies handle null auth.uid() safely

### Audit RLS Coverage

Check all tables have proper policies:

```bash
# Audit entire database
bash scripts/audit-rls-coverage.sh

# Audit specific schema
bash scripts/audit-rls-coverage.sh --schema public

# Generate markdown report
bash scripts/audit-rls-coverage.sh \
  --report coverage.md \
  --format markdown

# Generate JSON for CI/CD
bash scripts/audit-rls-coverage.sh \
  --report coverage.json \
  --format json
```

**What it checks:**
- ✓ All public schema tables have RLS enabled
- ✓ Each table has SELECT, INSERT, UPDATE, DELETE policies
- ✓ Policies target appropriate roles
- ✓ No tables accidentally exposed

### Run Complete Test Suite

Execute all RLS tests:

```bash
# Run with default settings
bash scripts/run-all-rls-tests.sh

# Verbose output with detailed report
bash scripts/run-all-rls-tests.sh --verbose --report results.json

# CI mode (exit 1 on failure, fail fast)
bash scripts/run-all-rls-tests.sh --ci --fail-fast

# Custom database URL
bash scripts/run-all-rls-tests.sh --db-url "postgresql://..."
```

**Test sequence:**
1. Audit RLS coverage
2. Test anonymous access
3. Test user isolation
4. Test multi-tenant isolation
5. Test role permissions
6. Generate summary report

## TypeScript/Jest Tests

For client-side testing using Supabase Client:

```bash
# Install dependencies
npm install --save-dev @supabase/supabase-js jest @types/jest

# Copy test template
cp templates/rls-test-suite.ts tests/rls.test.ts

# Customize for your schema
# Edit tests/rls.test.ts

# Run tests
npm test -- tests/rls.test.ts
```

## pgTAP Tests

For SQL-based testing:

```bash
# Copy template to Supabase tests directory
cp templates/user-isolation-tests.sql supabase/tests/database/rls-user-isolation.test.sql

# Customize for your schema
# Edit supabase/tests/database/rls-user-isolation.test.sql

# Run with Supabase CLI
supabase test db
```

## CI/CD Integration

### GitHub Actions

```yaml
name: RLS Security Tests

on: [pull_request, push]

jobs:
  test-rls:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1

      - name: Start Supabase
        run: supabase start

      - name: Run RLS tests
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:54322/postgres
        run: bash scripts/run-all-rls-tests.sh --ci --fail-fast

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: rls-test-results
          path: results.json
```

See [examples/ci-integration.md](examples/ci-integration.md) for complete CI/CD guide.

## Security Checklist

Before deploying to production:

```bash
# 1. All tests pass
bash scripts/run-all-rls-tests.sh --ci

# 2. Coverage is complete
bash scripts/audit-rls-coverage.sh

# 3. Review security checklist
cat templates/security-checklist.md
```

Work through each item in the checklist, verifying:
- RLS enabled on all public tables
- Policies for all operations (SELECT, INSERT, UPDATE, DELETE)
- User isolation working correctly
- Multi-tenant isolation enforced
- Anonymous access restricted
- Performance acceptable (< 100ms queries)

## Common Vulnerabilities Tested

This framework detects:

1. **Missing RLS** - Tables without RLS enabled (CRITICAL)
2. **Missing WITH CHECK** - INSERT/UPDATE policies that can be bypassed (HIGH)
3. **Improper NULL handling** - auth.uid() null not handled safely (HIGH)
4. **user_metadata abuse** - Authorization using user-modifiable metadata (HIGH)
5. **Missing indexes** - Unindexed policy columns causing slow queries (MEDIUM)
6. **Cross-tenant leaks** - Organization boundaries not enforced (CRITICAL)
7. **Service key exposure** - Service key in client code (CRITICAL)
8. **Overly permissive anonymous** - Too much public access (MEDIUM)
9. **Stale member access** - Removed users retain access (HIGH)
10. **Cascade bypasses** - Foreign key cascades bypass RLS (MEDIUM)

See [examples/common-vulnerabilities.md](examples/common-vulnerabilities.md) for details.

## Test Output Examples

### Success Output

```
🔒 RLS Test Suite v1.0.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Test Summary
  Tables tested: 5
  Total tests: 48
  Passed: 48 ✓
  Failed: 0
  Duration: 12.3s

✅ All RLS policies working correctly!
```

### Failure Output

```
❌ SECURITY ISSUE DETECTED

Table: conversations
Test: User isolation - SELECT
Issue: User B could read User A's conversations
Expected: 0 rows
Actual: 5 rows

Recommendation: Add USING clause to SELECT policy:
  USING (auth.uid() = user_id)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Test Summary
  Total tests: 48
  Passed: 43 ✓
  Failed: 5 ❌

❌ Critical security issues found. Do not deploy.
```

## Project Structure

```
skills/rls-test-patterns/
├── SKILL.md                          # Main skill manifest
├── README.md                         # This file
├── scripts/                          # Executable test scripts
│   ├── test-user-isolation.sh        # User isolation tests
│   ├── test-multi-tenant-isolation.sh # Multi-tenant tests
│   ├── test-role-permissions.sh      # RBAC tests
│   ├── test-anonymous-access.sh      # Anonymous access tests
│   ├── audit-rls-coverage.sh         # Coverage audit
│   └── run-all-rls-tests.sh          # Complete test suite
├── templates/                        # Test templates
│   ├── rls-test-suite.ts             # TypeScript test template
│   ├── user-isolation-tests.sql      # pgTAP test template
│   ├── test-scenarios.json           # Test scenarios reference
│   └── security-checklist.md         # Pre-deploy checklist
└── examples/                         # Documentation
    ├── testing-workflow.md           # Complete workflow guide
    ├── common-vulnerabilities.md     # Vulnerability detection guide
    └── ci-integration.md             # CI/CD integration guide
```

## Related Skills

- **rls-templates** - Create RLS policies (this skill tests them)
- **schema-patterns** - Database schema design patterns
- **auth-configs** - Supabase authentication configuration

## Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS Documentation](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [pgTAP Testing Framework](https://pgtap.org/)

## Support

For issues or questions:
1. Check [examples/testing-workflow.md](examples/testing-workflow.md)
2. Review [examples/common-vulnerabilities.md](examples/common-vulnerabilities.md)
3. Consult [templates/security-checklist.md](templates/security-checklist.md)

## License

Part of the Supabase plugin for Claude Code framework.
