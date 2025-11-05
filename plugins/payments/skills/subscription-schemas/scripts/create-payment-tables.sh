#!/bin/bash
# create-payment-tables.sh
# Create all payment-related tables in Supabase
#
# Security: NO hardcoded credentials
# Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
#
# Usage:
#   export SUPABASE_URL=your_supabase_url_here
#   export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
#   bash scripts/create-payment-tables.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "Creating Payment Tables"
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

# Function to execute SQL file via Supabase REST API
execute_sql_file() {
    local sql_file=$1
    local table_name=$2

    echo -e "${YELLOW}Creating $table_name table...${NC}"

    if [ ! -f "$sql_file" ]; then
        echo -e "${RED}Error: SQL file not found: $sql_file${NC}"
        return 1
    fi

    # Read SQL file
    SQL_CONTENT=$(cat "$sql_file")

    # Execute via Supabase REST API
    RESPONSE=$(curl -s -X POST \
        "$SUPABASE_URL/rest/v1/rpc/exec" \
        -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"query\": $(echo "$SQL_CONTENT" | jq -Rs .)}" \
        2>&1)

    # Alternative: Use psql if available
    # Construct connection string (without hardcoding credentials)
    DB_HOST=$(echo "$SUPABASE_URL" | sed -E 's|https?://([^/]+).*|\1|')
    DB_NAME="postgres"

    # Check if psql is available
    if command -v psql &> /dev/null; then
        echo "Using psql for migration..."
        PGPASSWORD="$SUPABASE_SERVICE_ROLE_KEY" psql \
            "postgresql://postgres:$SUPABASE_SERVICE_ROLE_KEY@$DB_HOST:5432/$DB_NAME" \
            -f "$sql_file" \
            2>&1

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ $table_name table created successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to create $table_name table${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}psql not found. Install PostgreSQL client or use Supabase Dashboard.${NC}"
        echo "SQL file location: $sql_file"
        return 1
    fi
}

# Create tables in order (respecting foreign key dependencies)
echo ""
echo "Step 1: Creating customers table..."
execute_sql_file "$TEMPLATES_DIR/customers_table.sql" "customers"

echo ""
echo "Step 2: Creating subscriptions table..."
execute_sql_file "$TEMPLATES_DIR/subscriptions_table.sql" "subscriptions"

echo ""
echo "Step 3: Creating payments table..."
execute_sql_file "$TEMPLATES_DIR/payments_table.sql" "payments"

echo ""
echo "Step 4: Creating invoices table..."
execute_sql_file "$TEMPLATES_DIR/invoices_table.sql" "invoices"

echo ""
echo "Step 5: Creating webhook_events table..."
execute_sql_file "$TEMPLATES_DIR/webhook_events_table.sql" "webhook_events"

echo ""
echo "=================================="
echo -e "${GREEN}All payment tables created!${NC}"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Enable RLS: bash scripts/setup-rls-policies.sh"
echo "2. Validate schema: bash scripts/validate-schema.sh"
echo ""
echo -e "${YELLOW}IMPORTANT: Tables are NOT protected yet!${NC}"
echo "Run setup-rls-policies.sh to enable Row Level Security."
echo ""
