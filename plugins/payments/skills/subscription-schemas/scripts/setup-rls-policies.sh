#!/bin/bash
# setup-rls-policies.sh
# Enable Row Level Security and create policies for all payment tables
#
# Security: NO hardcoded credentials
# Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
#
# Usage:
#   export SUPABASE_URL=your_supabase_url_here
#   export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
#   bash scripts/setup-rls-policies.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================="
echo "Setting Up Row Level Security"
echo "=================================="

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
TEMPLATES_DIR="$SCRIPT_DIR/../templates"
RLS_POLICY_FILE="$TEMPLATES_DIR/rls_policies.sql"

echo ""
echo -e "${BLUE}Applying RLS policies from: $RLS_POLICY_FILE${NC}"
echo ""

# Check if RLS policy file exists
if [ ! -f "$RLS_POLICY_FILE" ]; then
    echo -e "${RED}Error: RLS policy file not found: $RLS_POLICY_FILE${NC}"
    exit 1
fi

# Construct database connection details
DB_HOST=$(echo "$SUPABASE_URL" | sed -E 's|https?://([^/]+).*|\1|')
DB_NAME="postgres"

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: psql command not found${NC}"
    echo ""
    echo "Install PostgreSQL client:"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  macOS: brew install postgresql"
    echo "  Windows: Download from https://www.postgresql.org/download/"
    echo ""
    echo "Alternative: Apply RLS policies via Supabase Dashboard SQL Editor"
    echo "Copy contents of: $RLS_POLICY_FILE"
    exit 1
fi

echo "Applying RLS policies..."
echo ""

# Execute RLS policies
PGPASSWORD="$SUPABASE_SERVICE_ROLE_KEY" psql \
    "postgresql://postgres:$SUPABASE_SERVICE_ROLE_KEY@$DB_HOST:5432/$DB_NAME" \
    -f "$RLS_POLICY_FILE" \
    2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "=================================="
    echo -e "${GREEN}✓ RLS Policies Applied Successfully${NC}"
    echo "=================================="
    echo ""
    echo "Security Features Enabled:"
    echo "  ✓ customers table - User isolation by auth.uid()"
    echo "  ✓ subscriptions table - Owner-only access"
    echo "  ✓ payments table - Owner-only viewing"
    echo "  ✓ invoices table - Owner-only access"
    echo "  ✓ webhook_events table - Service role only"
    echo ""
    echo "Next steps:"
    echo "1. Test RLS policies: examples/rls-testing-examples.sql"
    echo "2. Validate schema: bash scripts/validate-schema.sh"
    echo ""
else
    echo ""
    echo -e "${RED}✗ Failed to apply RLS policies${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Verify SUPABASE_SERVICE_ROLE_KEY is correct"
    echo "2. Check database connection settings"
    echo "3. Review error messages above"
    echo "4. Try applying manually via Supabase Dashboard"
    exit 1
fi
