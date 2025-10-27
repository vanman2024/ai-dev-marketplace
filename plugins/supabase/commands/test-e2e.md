---
description: Run end-to-end tests - parallel test execution across database, auth, realtime, AI features
argument-hint: [--suite=all|auth|database|realtime|ai|storage] [--parallel]
allowed-tools: Task(supabase-tester), Task(supabase-schema-validator), Task(supabase-security-auditor)
---

**Arguments**: $ARGUMENTS

# Phase 1: Test Configuration
Goal: Parse test requirements and prepare environment

Actions:

Parse test suite from arguments (default: all):
- `all` - All test suites in parallel
- `auth` - Authentication tests only
- `database` - Database CRUD tests only
- `realtime` - Realtime features only
- `ai` - AI/pgvector features only
- `storage` - Storage operations only

Verify environment variables:
- $SUPABASE_PROJECT_REF
- $SUPABASE_ACCESS_TOKEN
- $SUPABASE_DB_URL
- $SUPABASE_ANON_KEY
- $SUPABASE_SERVICE_KEY

Detect configured features from project to scope tests appropriately.

# Phase 2: Test Environment Setup
Goal: Prepare clean test environment

Actions:

Invoke the supabase-tester agent for environment setup:
- Clean previous test data
- Seed test data
- Verify test isolation

# Phase 3: Parallel Test Execution
Goal: Run comprehensive test suites in parallel

Actions:

## Suite: all (default - maximum parallelism)

Launch the following test agents IN PARALLEL (all at once):

**Agent 1 - Database Tests:**
Invoke the supabase-tester agent to run database test suite.
Focus on: CRUD operations, queries, transactions, constraints, triggers, functions
Deliverable: Database test results with performance metrics

**Agent 2 - Auth Tests:**
Invoke the supabase-tester agent to run authentication test suite.
Focus on: OAuth flows, email auth, magic links, password reset, sessions, MFA
Deliverable: Auth test results with flow success rates

**Agent 3 - Realtime Tests (if configured):**
Invoke the supabase-tester agent to run realtime test suite.
Focus on: Subscriptions, presence, broadcast, connection stability
Deliverable: Realtime test results with latency metrics

**Agent 4 - AI Features Tests (if pgvector configured):**
Invoke the supabase-tester agent to run AI features test suite.
Focus on: Vector search, embeddings, hybrid search, Edge Functions
Deliverable: AI test results with search accuracy and performance

**Agent 5 - Storage Tests (if buckets exist):**
Invoke the supabase-tester agent to run storage test suite.
Focus on: Upload/download, bucket policies, CDN, metadata
Deliverable: Storage test results with upload/download speeds

**Agent 6 - Schema Validation:**
Invoke the supabase-schema-validator agent to validate schema integrity.
Focus on: Foreign keys, constraints, indexes, data consistency
Deliverable: Schema integrity report

**Agent 7 - Security Validation:**
Invoke the supabase-security-auditor agent to validate RLS during tests.
Focus on: RLS enforcement, user isolation, no data leaks
Deliverable: Security validation report

Wait for ALL test agents to complete before proceeding.

## Suite-Specific Execution

For suite-specific tests (auth, database, etc.), launch only relevant agents in parallel based on the selected suite.

# Phase 4: Results Aggregation
Goal: Collect and analyze test results

Actions:

Aggregate test results from all agents:

Display overall test summary:
- Total tests run, passed, failed, skipped
- Test results by suite (database, auth, realtime, AI, storage)
- Performance metrics (query times, latency, speeds)
- Schema integrity status
- Security validation status

# Phase 5: Failure Analysis
Goal: Categorize and analyze failures

Actions:

For each failed test:
- Test name and suite
- Failure type and error message
- Root cause analysis
- Impact assessment (critical/high/medium/low)
- Fix suggestion

Group failures by category:
- Configuration issues
- Code bugs
- Performance issues
- Security issues
- Infrastructure issues

# Phase 6: Recommendations
Goal: Provide actionable next steps

Actions:

**If all tests passed:**
Display success message with production readiness confirmation.

**If tests failed:**
Prioritize fixes by severity (CRITICAL > HIGH > MEDIUM > LOW).

Display next steps:
1. Fix all CRITICAL failures immediately
2. Address HIGH priority issues
3. Re-run failed suites: `/supabase:test-e2e --suite=X`
4. Run full suite before deployment
5. Set up CI/CD for automated testing

Save test results to:
- `supabase-test-results-{timestamp}.json`
- `supabase-test-results-{timestamp}.md`
- `supabase-performance-{timestamp}.json`
