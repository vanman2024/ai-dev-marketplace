# CI/CD Integration Guide

Complete guide for integrating Supabase E2E tests into your CI/CD pipeline with GitHub Actions, GitLab CI, and other platforms.

## GitHub Actions Integration

### Basic Workflow

The simplest CI configuration runs tests on every push:

```yaml
name: Supabase Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm install -g supabase
      - run: supabase start
      - run: bash scripts/setup-test-env.sh
      - run: npm test
      - run: supabase stop
```

### Advanced Configuration

For production-grade CI with parallel test execution, coverage, and reporting:

```yaml
name: Comprehensive E2E Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # Run different test suites in parallel
  test-matrix:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        suite: [database, auth, vector, realtime, integration]
      fail-fast: false

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Supabase CLI
        run: npm install -g supabase

      - name: Start Supabase
        run: |
          supabase init
          supabase start

      - name: Setup test environment
        run: bash scripts/setup-test-env.sh

      - name: Run ${{ matrix.suite }} tests
        run: bash scripts/run-e2e-tests.sh --suite ${{ matrix.suite }}

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.suite }}
          path: coverage/

      - name: Cleanup
        if: always()
        run: supabase stop

  # Aggregate results and report
  report:
    needs: test-matrix
    runs-on: ubuntu-latest
    if: always()

    steps:
      - uses: actions/download-artifact@v3
        with:
          path: test-results

      - name: Generate report
        run: |
          echo "## Test Results" >> $GITHUB_STEP_SUMMARY
          echo "All test suites completed" >> $GITHUB_STEP_SUMMARY
```

## GitLab CI Integration

### .gitlab-ci.yml Configuration

```yaml
stages:
  - test
  - report

variables:
  NODE_VERSION: "20"

# Test jobs run in parallel
.test-template:
  stage: test
  image: node:${NODE_VERSION}
  services:
    - postgres:15
  variables:
    POSTGRES_DB: postgres
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
  before_script:
    - npm ci
    - npm install -g supabase
    - supabase init
    - supabase start
    - bash scripts/setup-test-env.sh
  after_script:
    - bash scripts/cleanup-test-resources.sh
    - supabase stop
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    paths:
      - coverage/

database-tests:
  extends: .test-template
  script:
    - bash scripts/run-e2e-tests.sh --suite database

auth-tests:
  extends: .test-template
  script:
    - bash scripts/run-e2e-tests.sh --suite auth

vector-tests:
  extends: .test-template
  script:
    - bash scripts/run-e2e-tests.sh --suite vector

realtime-tests:
  extends: .test-template
  script:
    - bash scripts/run-e2e-tests.sh --suite realtime

integration-tests:
  extends: .test-template
  script:
    - bash scripts/run-e2e-tests.sh --suite integration

# Generate combined report
test-report:
  stage: report
  image: node:${NODE_VERSION}
  script:
    - echo "All tests completed"
    - cat coverage/*/lcov.info > coverage/combined.info
  artifacts:
    paths:
      - coverage/combined.info
  coverage: '/Statements\s*:\s*(\d+\.\d+)%/'
```

## CircleCI Integration

### .circleci/config.yml

```yaml
version: 2.1

orbs:
  node: circleci/node@5.1

jobs:
  test:
    docker:
      - image: cimg/node:20.10
      - image: supabase/postgres:15.1.0.117
        environment:
          POSTGRES_PASSWORD: postgres

    steps:
      - checkout

      - node/install-packages:
          pkg-manager: npm

      - run:
          name: Install Supabase CLI
          command: npm install -g supabase

      - run:
          name: Setup Supabase
          command: |
            supabase init
            supabase start

      - run:
          name: Setup test environment
          command: bash scripts/setup-test-env.sh

      - run:
          name: Run tests
          command: bash scripts/run-e2e-tests.sh --coverage

      - store_test_results:
          path: test-results

      - store_artifacts:
          path: coverage

workflows:
  test-workflow:
    jobs:
      - test
```

## Jenkins Pipeline

### Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        NODE_VERSION = '20'
    }

    stages {
        stage('Setup') {
            steps {
                sh 'npm ci'
                sh 'npm install -g supabase'
            }
        }

        stage('Start Supabase') {
            steps {
                sh 'supabase init'
                sh 'supabase start'
                sh 'bash scripts/setup-test-env.sh'
            }
        }

        stage('Test') {
            parallel {
                stage('Database') {
                    steps {
                        sh 'bash scripts/run-e2e-tests.sh --suite database'
                    }
                }
                stage('Auth') {
                    steps {
                        sh 'bash scripts/run-e2e-tests.sh --suite auth'
                    }
                }
                stage('Vector') {
                    steps {
                        sh 'bash scripts/run-e2e-tests.sh --suite vector'
                    }
                }
                stage('Realtime') {
                    steps {
                        sh 'bash scripts/run-e2e-tests.sh --suite realtime'
                    }
                }
                stage('Integration') {
                    steps {
                        sh 'bash scripts/run-e2e-tests.sh --suite integration'
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'bash scripts/cleanup-test-resources.sh'
            sh 'supabase stop'
            junit 'junit.xml'
            publishHTML([
                reportDir: 'coverage',
                reportFiles: 'index.html',
                reportName: 'Coverage Report'
            ])
        }
    }
}
```

## Docker-based Testing

### Dockerfile.test

```dockerfile
FROM node:20-alpine

# Install PostgreSQL client for psql commands
RUN apk add --no-cache postgresql-client

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Install Supabase CLI
RUN npm install -g supabase

# Copy application code
COPY . .

# Setup test environment
RUN bash scripts/setup-test-env.sh

# Run tests
CMD ["bash", "scripts/run-e2e-tests.sh"]
```

### docker-compose.test.yml

```yaml
version: '3.8'

services:
  postgres:
    image: supabase/postgres:15.1.0.117
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  test:
    build:
      context: .
      dockerfile: Dockerfile.test
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/postgres
      SUPABASE_TEST_URL: http://localhost:54321
      SUPABASE_TEST_ANON_KEY: test-key
    volumes:
      - ./coverage:/app/coverage
      - ./test-results:/app/test-results
```

Run with:
```bash
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## Environment-Specific Testing

### Testing Against Multiple Environments

```yaml
# .github/workflows/multi-env-tests.yml
name: Multi-Environment Tests

on: [workflow_dispatch]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [staging, production-test]

    environment: ${{ matrix.environment }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - run: npm ci

      - name: Create .env.test
        run: |
          cat > .env.test <<EOF
          SUPABASE_TEST_URL=${{ secrets.SUPABASE_URL }}
          SUPABASE_TEST_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
          SUPABASE_TEST_SERVICE_ROLE_KEY=${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
          DATABASE_URL=${{ secrets.DATABASE_URL }}
          EOF

      - name: Run tests
        run: npm test

      - name: Cleanup
        if: always()
        run: bash scripts/cleanup-test-resources.sh
```

## Best Practices

### 1. Cache Dependencies

Speed up CI by caching node_modules:

```yaml
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### 2. Parallel Test Execution

Run independent test suites in parallel:

```yaml
strategy:
  matrix:
    suite: [database, auth, vector, realtime, integration]
  max-parallel: 5
```

### 3. Test Result Reporting

Generate and upload test reports:

```yaml
- name: Generate test report
  if: always()
  run: npm test -- --coverage --reporters=default --reporters=jest-junit

- name: Publish test results
  uses: EnricoMi/publish-unit-test-result-action@v2
  if: always()
  with:
    files: junit.xml
```

### 4. Coverage Requirements

Enforce minimum coverage:

```yaml
- name: Check coverage
  run: |
    npm test -- --coverage --coverageThreshold='{"global":{"branches":70,"functions":70,"lines":70,"statements":70}}'
```

### 5. Scheduled Tests

Run tests on a schedule to catch issues early:

```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
```

## Debugging CI Failures

### Enable Debug Logging

```yaml
- name: Run tests with debug logging
  run: DEBUG=* npm test
  env:
    CI: true
```

### SSH into CI Environment (GitHub Actions)

```yaml
- name: Setup tmate session
  if: failure()
  uses: mxschmitt/action-tmate@v3
```

### Artifact Upload

Always upload artifacts on failure:

```yaml
- name: Upload logs
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: test-logs
    path: |
      *.log
      coverage/
```

## Security Considerations

### Secrets Management

- Never commit `.env.test` files
- Use CI environment variables/secrets
- Rotate test credentials regularly
- Use dedicated test projects (not production)

### Access Control

- Limit who can trigger CI workflows
- Use branch protection rules
- Require approvals for production tests
- Use separate credentials per environment

## Performance Optimization

### Reduce Test Duration

1. **Parallel execution**: Run test suites concurrently
2. **Selective testing**: Only run affected tests
3. **Caching**: Cache dependencies and build artifacts
4. **Fast feedback**: Run quick tests first

### Resource Management

```yaml
# Limit concurrent jobs
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Set timeouts
timeout-minutes: 30
```

## Monitoring and Alerts

### Slack Notifications

```yaml
- name: Notify Slack on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'E2E tests failed!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### GitHub Status Checks

Configure required status checks in repository settings to block merges on test failures.

## Next Steps

1. Adapt templates to your CI platform
2. Configure environment-specific credentials
3. Setup monitoring and alerts
4. Document CI workflow for your team
5. Regularly review and optimize test performance
