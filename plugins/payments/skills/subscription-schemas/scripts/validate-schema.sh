#!/bin/bash
# validate-schema.sh
# Validate payment schema structure, indexes, and RLS policies
#
# Security: NO hardcoded credentials
# Environment: SUPABASE_URL, SUPABASE_ANON_KEY (or SERVICE_ROLE_KEY)
#
# Usage:
#   export SUPABASE_URL=your_supabase_url_here
#   export SUPABASE_ANON_KEY=your_supabase_anon_key_here
#   bash scripts/validate-schema.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================="
echo "Validating Payment Schema"
echo "=================================="

# Check environment variables
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}Error: SUPABASE_URL not set${NC}"
    echo "Set it with: export SUPABASE_URL=your_supabase_url_here"
    exit 1
fi

# Use SERVICE_ROLE_KEY if available, otherwise ANON_KEY
if [ -n "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    API_KEY="$SUPABASE_SERVICE_ROLE_KEY"
    echo "Using SERVICE_ROLE_KEY for validation"
elif [ -n "$SUPABASE_ANON_KEY" ]; then
    API_KEY="$SUPABASE_ANON_KEY"
    echo "Using ANON_KEY for validation"
else
    echo -e "${RED}Error: Neither SUPABASE_SERVICE_ROLE_KEY nor SUPABASE_ANON_KEY is set${NC}"
    echo "Set one with: export SUPABASE_SERVICE_ROLE_KEY=your_key_here"
    exit 1
fi

# Construct database connection
DB_HOST=$(echo "$SUPABASE_URL" | sed -E 's|https?://([^/]+).*|\1|')
DB_NAME="postgres"

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}Warning: psql not found, limited validation available${NC}"
    echo ""
    echo "For full validation, install PostgreSQL client:"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  macOS: brew install postgresql"
    echo ""
    echo "Performing basic validation..."
    echo ""

    # Basic validation without psql
    echo -e "${BLUE}Checking Supabase connection...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        "$SUPABASE_URL/rest/v1/" \
        -H "apikey: $API_KEY")

    if [ "$RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ Supabase connection successful${NC}"
    else
        echo -e "${RED}✗ Supabase connection failed (HTTP $RESPONSE)${NC}"
        exit 1
    fi

    echo ""
    echo "Install psql for comprehensive validation."
    exit 0
fi

echo ""
echo "Running comprehensive validation..."
echo ""

# Create temporary SQL validation script
VALIDATION_SQL=$(cat <<'EOF'
-- Validation script for payment schema

\set QUIET on
\pset format unaligned
\pset tuples_only on

-- Check if tables exist
\echo ''
\echo '=== Table Existence Check ==='
\echo ''

SELECT
    CASE
        WHEN COUNT(*) = 5 THEN '✓ All 5 payment tables exist'
        ELSE '✗ Missing tables (expected 5, found ' || COUNT(*) || ')'
    END as result
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events');

-- List existing tables
\echo ''
\echo 'Existing tables:'
SELECT '  - ' || table_name as tables
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events')
ORDER BY
    CASE table_name
        WHEN 'customers' THEN 1
        WHEN 'subscriptions' THEN 2
        WHEN 'payments' THEN 3
        WHEN 'invoices' THEN 4
        WHEN 'webhook_events' THEN 5
    END;

-- Check RLS status
\echo ''
\echo '=== Row Level Security Status ==='
\echo ''

SELECT
    '  ' || c.relname || ': ' ||
    CASE WHEN c.relrowsecurity THEN '✓ Enabled' ELSE '✗ Disabled' END as rls_status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
AND c.relname IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events')
ORDER BY c.relname;

-- Check indexes
\echo ''
\echo '=== Index Validation ==='
\echo ''

SELECT
    CASE
        WHEN COUNT(*) >= 15 THEN '✓ Sufficient indexes created (' || COUNT(*) || ' total)'
        ELSE '⚠ Limited indexes (' || COUNT(*) || ' found, expected 15+)'
    END as index_status
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events');

-- Count policies
\echo ''
\echo '=== RLS Policy Count ==='
\echo ''

SELECT
    tablename || ': ' || COUNT(*) || ' policies' as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events')
GROUP BY tablename
ORDER BY tablename;

-- Check foreign keys
\echo ''
\echo '=== Foreign Key Relationships ==='
\echo ''

SELECT
    CASE
        WHEN COUNT(*) >= 4 THEN '✓ Foreign keys configured (' || COUNT(*) || ' total)'
        ELSE '⚠ Missing foreign keys (' || COUNT(*) || ' found, expected 4+)'
    END as fk_status
FROM information_schema.table_constraints
WHERE constraint_schema = 'public'
AND constraint_type = 'FOREIGN KEY'
AND table_name IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events');

-- Check triggers
\echo ''
\echo '=== Triggers ==='
\echo ''

SELECT
    event_object_table || '.' || trigger_name as triggers
FROM information_schema.triggers
WHERE event_object_schema = 'public'
AND event_object_table IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events')
ORDER BY event_object_table, trigger_name;

\echo ''
\echo '=== Validation Summary ==='
\echo ''

SELECT
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events')
        ) = 5
        AND (
            SELECT COUNT(*)
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public'
            AND c.relname IN ('customers', 'subscriptions', 'payments', 'invoices', 'webhook_events')
            AND c.relrowsecurity = true
        ) = 5
        THEN '✓ Schema validation PASSED'
        ELSE '✗ Schema validation FAILED'
    END as final_result;

\echo ''
EOF
)

# Execute validation
echo "$VALIDATION_SQL" | PGPASSWORD="$API_KEY" psql \
    "postgresql://postgres:$API_KEY@$DB_HOST:5432/$DB_NAME" \
    2>&1 | grep -v "^$"

VALIDATION_EXIT_CODE=$?

echo ""
echo "=================================="
if [ $VALIDATION_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}Validation Complete${NC}"
else
    echo -e "${YELLOW}Validation completed with warnings${NC}"
fi
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Review any warnings or errors above"
echo "  2. Test RLS policies: examples/rls-testing-examples.sql"
echo "  3. Run sample queries: examples/sample-queries.sql"
echo ""
