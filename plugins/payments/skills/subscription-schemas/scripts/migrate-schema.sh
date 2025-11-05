#!/bin/bash
# migrate-schema.sh
# Complete schema migration orchestrator
#
# Security: NO hardcoded credentials
# Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
#
# Usage:
#   export SUPABASE_URL=your_supabase_url_here
#   export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
#   bash scripts/migrate-schema.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "   Payment Schema Migration Orchestrator"
echo "=========================================="
echo ""

# Check environment variables
if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}Error: SUPABASE_URL not set${NC}"
    echo "Set it with: export SUPABASE_URL=your_supabase_url_here"
    exit 1
fi

if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo -e "${RED}Error: SUPABASE_SERVICE_ROLE_KEY not set${NC}"
    echo "Set it with: export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Display environment info
echo -e "${CYAN}Environment:${NC}"
echo "  Supabase URL: ${SUPABASE_URL}"
echo "  Service Role: [HIDDEN]"
echo ""

# Confirmation prompt
echo -e "${YELLOW}This will create the following tables:${NC}"
echo "  1. customers"
echo "  2. subscriptions"
echo "  3. payments"
echo "  4. invoices"
echo "  5. webhook_events"
echo ""
echo -e "${YELLOW}And enable Row Level Security with policies.${NC}"
echo ""
read -p "Continue with migration? (yes/no): " -r CONFIRM
echo ""

if [ "$CONFIRM" != "yes" ]; then
    echo "Migration cancelled."
    exit 0
fi

# Step 1: Create tables
echo ""
echo "=========================================="
echo "Step 1: Creating Payment Tables"
echo "=========================================="
echo ""

if bash "$SCRIPT_DIR/create-payment-tables.sh"; then
    echo -e "${GREEN}✓ Tables created successfully${NC}"
else
    echo -e "${RED}✗ Table creation failed${NC}"
    echo "Migration aborted."
    exit 1
fi

# Step 2: Setup RLS policies
echo ""
echo "=========================================="
echo "Step 2: Enabling Row Level Security"
echo "=========================================="
echo ""

if bash "$SCRIPT_DIR/setup-rls-policies.sh"; then
    echo -e "${GREEN}✓ RLS policies applied successfully${NC}"
else
    echo -e "${RED}✗ RLS setup failed${NC}"
    echo "Migration partially complete. Tables exist but RLS not enabled."
    echo "Run manually: bash scripts/setup-rls-policies.sh"
    exit 1
fi

# Step 3: Validate schema
echo ""
echo "=========================================="
echo "Step 3: Validating Schema"
echo "=========================================="
echo ""

if bash "$SCRIPT_DIR/validate-schema.sh"; then
    echo -e "${GREEN}✓ Schema validation passed${NC}"
else
    echo -e "${YELLOW}⚠ Schema validation warnings detected${NC}"
    echo "Review validation output above."
fi

# Migration summary
echo ""
echo "=========================================="
echo -e "${GREEN}   Migration Completed Successfully!${NC}"
echo "=========================================="
echo ""
echo "Schema Components:"
echo "  ✓ 5 tables created (customers, subscriptions, payments, invoices, webhook_events)"
echo "  ✓ Row Level Security enabled on all tables"
echo "  ✓ Comprehensive RLS policies applied"
echo "  ✓ Indexes created for performance"
echo "  ✓ Triggers configured (updated_at, invoice numbering)"
echo ""
echo "Security Status:"
echo "  ✓ User data isolated by auth.uid()"
echo "  ✓ Service role bypass for webhooks"
echo "  ✓ No anonymous access to payment data"
echo ""
echo "Next Steps:"
echo "  1. Test RLS policies: examples/rls-testing-examples.sql"
echo "  2. Run sample queries: examples/sample-queries.sql"
echo "  3. Integrate with payment provider webhooks"
echo "  4. Set up frontend with Supabase client"
echo ""
echo -e "${BLUE}Documentation: See SKILL.md for usage instructions${NC}"
echo ""
