# CI/CD Integration for RLS Testing

Complete guide for integrating RLS security tests into continuous integration and deployment pipelines.

## Overview

Automated RLS testing in CI/CD ensures:
- No security regressions reach production
- All pull requests are security-verified
- Deployment blocked on security failures
- Consistent security standards across team

## GitHub Actions Integration

### Basic Workflow

Create `.github/workflows/rls-security-tests.yml`:

```yaml
name: RLS Security Tests

on:
  pull_request:
    paths:
      - 'supabase/migrations/**'
      - 'supabase/seed.sql'
      - 'database/**'
  push:
    branches: [main, develop, staging]
  workflow_dispatch:  # Manual trigger

jobs:
  rls-tests:
    name: Test RLS Policies
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        with:
          version: latest

      - name: Start Supabase Local
        run: supabase start

      - name: Run migrations
        run: supabase db reset --db-url postgresql://postgres:postgres@localhost:54322/postgres

      - name: Run RLS test suite
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:54322/postgres
        run: |
          bash scripts/run-all-rls-tests.sh \
            --ci \
            --fail-fast \
            --report rls-test-results.json

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: rls-test-results
          path: rls-test-results.json
          retention-days: 30

      - name: Comment on PR
        if: failure() && github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('rls-test-results.json', 'utf8'));

            const body = `## ❌ RLS Security Tests Failed

            **Results:**
            - Total Tests: ${results.results.total}
            - Passed: ${results.results.passed} ✅
            - Failed: ${results.results.failed} ❌

            **Critical security issues detected.** Please review the test results and fix before merging.

            [View detailed results](https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }})
            `;

            github.rest.issues.createComment({
              issue_number: context.issue.number
              owner: context.repo.owner
              repo: context.repo.repo
              body: body
            });

      - name: Stop Supabase
        if: always()
        run: supabase stop

      - name: Fail workflow if tests failed
        if: failure()
        run: exit 1
```

### Advanced Workflow with Coverage Reports

```yaml
name: RLS Security Suite

on:
  pull_request:
  push:
    branches: [main]
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Monday

jobs:
  audit-coverage:
    name: Audit RLS Coverage
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1

      - name: Start Supabase
        run: supabase start

      - name: Audit RLS coverage
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:54322/postgres
        run: |
          bash scripts/audit-rls-coverage.sh \
            --report coverage-audit.md \
            --format markdown

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: rls-coverage-audit
          path: coverage-audit.md

      - name: Comment coverage on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const coverage = fs.readFileSync('coverage-audit.md', 'utf8');

            github.rest.issues.createComment({
              issue_number: context.issue.number
              owner: context.repo.owner
              repo: context.repo.repo
              body: `## 🔍 RLS Coverage Report\n\n${coverage}`
            });

  test-user-isolation:
    name: Test User Isolation
    runs-on: ubuntu-latest
    needs: audit-coverage

    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1

      - name: Start Supabase
        run: supabase start

      - name: Test user isolation
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:54322/postgres
        run: |
          bash scripts/test-user-isolation.sh \
            --all \
            --report user-isolation-results.md

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: user-isolation-results
          path: user-isolation-results.md

  test-multi-tenant:
    name: Test Multi-Tenant Isolation
    runs-on: ubuntu-latest
    needs: audit-coverage

    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1

      - name: Start Supabase
        run: supabase start

      - name: Test multi-tenant isolation
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:54322/postgres
        run: |
          bash scripts/test-multi-tenant-isolation.sh \
            projects documents \
            --test-members \
            --report multi-tenant-results.md

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: multi-tenant-results
          path: multi-tenant-results.md

  test-anonymous-access:
    name: Test Anonymous Access
    runs-on: ubuntu-latest
    needs: audit-coverage

    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1

      - name: Start Supabase
        run: supabase start

      - name: Test anonymous restrictions
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:54322/postgres
        run: |
          bash scripts/test-anonymous-access.sh \
            --test-null-uid \
            --report anon-access-results.md

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: anonymous-access-results
          path: anon-access-results.md

  summarize:
    name: Summary Report
    runs-on: ubuntu-latest
    needs: [test-user-isolation, test-multi-tenant, test-anonymous-access]
    if: always()

    steps:
      - name: Download all artifacts
        uses: actions/download-artifact@v4

      - name: Generate summary
        run: |
          echo "# RLS Security Test Summary" > summary.md
          echo "" >> summary.md
          echo "## Coverage Audit" >> summary.md
          cat rls-coverage-audit/coverage-audit.md >> summary.md || echo "N/A" >> summary.md
          echo "" >> summary.md
          echo "## User Isolation Tests" >> summary.md
          cat user-isolation-results/user-isolation-results.md >> summary.md || echo "N/A" >> summary.md
          echo "" >> summary.md
          echo "## Multi-Tenant Tests" >> summary.md
          cat multi-tenant-results/multi-tenant-results.md >> summary.md || echo "N/A" >> summary.md
          echo "" >> summary.md
          echo "## Anonymous Access Tests" >> summary.md
          cat anonymous-access-results/anon-access-results.md >> summary.md || echo "N/A" >> summary.md

      - name: Upload summary
        uses: actions/upload-artifact@v4
        with:
          name: complete-security-report
          path: summary.md
```

## GitLab CI Integration

`.gitlab-ci.yml`:

```yaml
stages:
  - audit
  - test
  - report

variables:
  SUPABASE_DB_URL: "postgresql://postgres:postgres@localhost:54322/postgres"

.supabase-setup:
  before_script:
    - apt-get update && apt-get install -y postgresql-client
    - curl -sSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
    - mv supabase /usr/local/bin/
    - supabase start

audit-rls-coverage:
  stage: audit
  extends: .supabase-setup
  script:
    - bash scripts/audit-rls-coverage.sh --report coverage.json --format json
  artifacts:
    paths:
      - coverage.json
    expire_in: 30 days

test-user-isolation:
  stage: test
  extends: .supabase-setup
  script:
    - bash scripts/test-user-isolation.sh --all --report isolation.md
  artifacts:
    paths:
      - isolation.md
    expire_in: 30 days

test-multi-tenant:
  stage: test
  extends: .supabase-setup
  script:
    - bash scripts/test-multi-tenant-isolation.sh projects documents --report tenant.md
  artifacts:
    paths:
      - tenant.md
    expire_in: 30 days

test-rls-suite:
  stage: test
  extends: .supabase-setup
  script:
    - bash scripts/run-all-rls-tests.sh --ci --fail-fast --report results.json
  artifacts:
    paths:
      - results.json
    when: always
    expire_in: 30 days
  allow_failure: false

generate-report:
  stage: report
  script:
    - cat coverage.json isolation.md tenant.md > complete-report.txt
  artifacts:
    paths:
      - complete-report.txt
  when: always
```

## CircleCI Integration

`.circleci/config.yml`:

```yaml
version: 2.1

orbs:
  supabase: supabase/cli@1.0

jobs:
  test-rls:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout

      - run:
          name: Install Supabase CLI
          command: |
            curl -sSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
            sudo mv supabase /usr/local/bin/

      - run:
          name: Start Supabase
          command: supabase start

      - run:
          name: Run RLS tests
          command: |
            export SUPABASE_DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"
            bash scripts/run-all-rls-tests.sh --ci --report results.json

      - store_artifacts:
          path: results.json
          destination: rls-test-results

      - run:
          name: Stop Supabase
          command: supabase stop
          when: always

workflows:
  version: 2
  test:
    jobs:
      - test-rls
```

## Pre-commit Hook

`.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook for RLS testing

set -e

echo "Checking for database changes..."

# Check if migrations changed
if git diff --cached --name-only | grep -q "supabase/migrations"; then
  echo "📋 Database migration detected"

  # Check if Supabase is running
  if ! supabase status > /dev/null 2>&1; then
    echo "Starting Supabase..."
    supabase start
  fi

  echo "Running RLS security tests..."

  # Run quick validation
  if ! bash scripts/audit-rls-coverage.sh; then
    echo "❌ RLS coverage audit failed"
    echo "Fix issues and try again"
    exit 1
  fi

  # Run tests on changed tables
  CHANGED_TABLES=$(git diff --cached supabase/migrations/*.sql | grep -oP '(?<=TABLE )\w+' | sort -u)

  if [ -n "$CHANGED_TABLES" ]; then
    echo "Testing changed tables: $CHANGED_TABLES"

    if ! bash scripts/test-user-isolation.sh $CHANGED_TABLES; then
      echo "❌ User isolation tests failed"
      exit 1
    fi
  fi

  echo "✅ RLS tests passed"
fi

exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Staging Environment Tests

Run against staging before production:

```bash
#!/bin/bash
# staging-rls-tests.sh

set -e

echo "🔍 Running RLS tests against staging environment"

# Load staging credentials
export SUPABASE_DB_URL="$STAGING_DB_URL"
export SUPABASE_URL="$STAGING_SUPABASE_URL"
export SUPABASE_ANON_KEY="$STAGING_ANON_KEY"

# Run complete test suite
bash scripts/run-all-rls-tests.sh \
  --verbose \
  --report staging-rls-results.json

# Check results
if [ $? -eq 0 ]; then
  echo "✅ All staging RLS tests passed"
  echo "Safe to deploy to production"
else
  echo "❌ Staging RLS tests failed"
  echo "Do NOT deploy to production"
  exit 1
fi
```

Integrate into deployment workflow:

```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  test-staging:
    name: Test on Staging
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Test RLS on staging
        env:
          STAGING_DB_URL: ${{ secrets.STAGING_DB_URL }}
          STAGING_SUPABASE_URL: ${{ secrets.STAGING_SUPABASE_URL }}
          STAGING_ANON_KEY: ${{ secrets.STAGING_ANON_KEY }}
        run: bash staging-rls-tests.sh

  deploy-production:
    name: Deploy to Production
    needs: test-staging
    runs-on: ubuntu-latest

    steps:
      - name: Deploy migrations
        run: supabase db push --db-url ${{ secrets.PRODUCTION_DB_URL }}

      - name: Verify RLS in production
        env:
          SUPABASE_DB_URL: ${{ secrets.PRODUCTION_DB_URL }}
        run: bash scripts/audit-rls-coverage.sh
```

## Scheduled Security Audits

Weekly comprehensive security scan:

```yaml
# .github/workflows/weekly-security-audit.yml
name: Weekly Security Audit

on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM
  workflow_dispatch:

jobs:
  comprehensive-audit:
    name: Comprehensive RLS Security Audit
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Supabase
        uses: supabase/setup-cli@v1

      - name: Connect to production (read-only)
        env:
          SUPABASE_DB_URL: ${{ secrets.PRODUCTION_DB_URL_READONLY }}
        run: |
          # Audit coverage
          bash scripts/audit-rls-coverage.sh \
            --report weekly-audit.md \
            --format markdown

          # Check for common vulnerabilities
          psql $SUPABASE_DB_URL -f scripts/security-checks.sql > vulnerabilities.txt

      - name: Create GitHub Issue if issues found
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const audit = fs.readFileSync('weekly-audit.md', 'utf8');

            github.rest.issues.create({
              owner: context.repo.owner
              repo: context.repo.repo
              title: `🔴 Weekly Security Audit: Issues Detected`
              body: `## Security Issues Found\n\n${audit}`
              labels: ['security', 'priority-high']
            });

      - name: Send Slack notification
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Weekly RLS security audit completed'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Performance Monitoring

Track RLS policy performance in CI:

```bash
#!/bin/bash
# performance-benchmark.sh

export SUPABASE_DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"

echo "Benchmarking RLS policy performance..."

# Test SELECT performance
time_select=$(psql $SUPABASE_DB_URL -c "
  SET LOCAL ROLE authenticated;
  SET LOCAL request.jwt.claims.sub = '$(uuidgen)';
  EXPLAIN ANALYZE SELECT * FROM conversations LIMIT 100;
" | grep "Execution Time" | awk '{print $3}')

echo "SELECT query time: ${time_select}ms"

# Fail if too slow
if (( $(echo "$time_select > 100" | bc -l) )); then
  echo "❌ Query too slow (>${time_select}ms)"
  exit 1
fi

echo "✅ Performance acceptable"
```

Add to CI:

```yaml
- name: Benchmark performance
  run: bash performance-benchmark.sh
```

## Best Practices

1. **Run on every PR** - Catch issues early
2. **Block merges on failure** - Enforce security
3. **Test staging before production** - Final verification
4. **Schedule regular audits** - Catch regressions
5. **Monitor performance** - Prevent DoS
6. **Archive test results** - Audit trail
7. **Alert on failures** - Immediate notification

## Troubleshooting

### Tests timeout in CI

```yaml
# Increase timeout
jobs:
  test-rls:
    timeout-minutes: 15  # Default is 10
```

### Flaky tests

```bash
# Add retries
- name: Run RLS tests
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 5
    max_attempts: 3
    command: bash scripts/run-all-rls-tests.sh
```

### Connection issues

```yaml
# Wait for Supabase to be ready
- name: Wait for Supabase
  run: |
    timeout 60 bash -c 'until supabase status; do sleep 2; done'
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [CI/CD Best Practices](https://www.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery-vs-deployment)
