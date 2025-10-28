#!/bin/bash
# Verify Supabase is properly initialized for Mem0 OSS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Verifying Supabase setup for Mem0 OSS..."
echo ""

# Check for required environment variables
MISSING_VARS=()

if [ -z "$SUPABASE_URL" ]; then
    MISSING_VARS+=("SUPABASE_URL")
fi

if [ -z "$SUPABASE_DB_URL" ]; then
    MISSING_VARS+=("SUPABASE_DB_URL")
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    MISSING_VARS+=("SUPABASE_ANON_KEY")
fi

# Check .mcp.json for supabase server
MCP_FILE=".mcp.json"
HAS_SUPABASE_MCP=false

if [ -f "$MCP_FILE" ]; then
    if grep -q '"supabase"' "$MCP_FILE"; then
        HAS_SUPABASE_MCP=true
        echo -e "${GREEN}✓${NC} Supabase MCP server configured in .mcp.json"
    else
        echo -e "${YELLOW}⚠${NC} Supabase MCP server not found in .mcp.json"
    fi
else
    echo -e "${YELLOW}⚠${NC} .mcp.json not found"
fi

# Report environment variables
echo ""
echo "Environment Variables:"
if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} SUPABASE_URL: ${SUPABASE_URL:0:30}..."
    echo -e "${GREEN}✓${NC} SUPABASE_DB_URL: ${SUPABASE_DB_URL:0:40}..."
    echo -e "${GREEN}✓${NC} SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."

    # Test database connection
    echo ""
    echo "Testing database connection..."
    if psql "$SUPABASE_DB_URL" -c "SELECT version();" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Database connection successful"

        # Get PostgreSQL version
        PG_VERSION=$(psql "$SUPABASE_DB_URL" -t -c "SHOW server_version;" | xargs)
        echo -e "  PostgreSQL version: $PG_VERSION"
    else
        echo -e "${RED}✗${NC} Database connection failed"
        echo "  Check your SUPABASE_DB_URL credentials"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please set these variables before continuing:"
    echo "  export SUPABASE_URL=\"https://your-project.supabase.co\""
    echo "  export SUPABASE_DB_URL=\"postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres\""
    echo "  export SUPABASE_ANON_KEY=\"your-anon-key\""
    exit 1
fi

# Summary
echo ""
echo "Summary:"
if [ ${#MISSING_VARS[@]} -eq 0 ] && [ "$HAS_SUPABASE_MCP" = true ]; then
    echo -e "${GREEN}✓${NC} Supabase is properly configured for Mem0 OSS"
    echo ""
    echo "Next steps:"
    echo "  1. bash scripts/setup-mem0-pgvector.sh"
    echo "  2. bash scripts/apply-mem0-schema.sh"
    echo "  3. bash scripts/create-mem0-indexes.sh"
    echo "  4. bash scripts/apply-mem0-rls.sh"
elif [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC} Supabase credentials found but MCP not configured"
    echo ""
    echo "Consider running: /supabase:init to setup MCP integration"
    echo ""
    echo "You can still proceed with Mem0 setup using direct database connection"
else
    echo -e "${RED}✗${NC} Supabase not properly configured"
    echo ""
    echo "Run /supabase:init to initialize Supabase first"
fi
