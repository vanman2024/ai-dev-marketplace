#!/bin/bash
# Enable pgvector extension for Mem0 memory storage

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Setting up pgvector extension for Mem0..."
echo ""

# Check prerequisites
if [ -z "$SUPABASE_DB_URL" ]; then
    echo -e "${RED}✗${NC} SUPABASE_DB_URL not set"
    echo "Run: bash scripts/verify-supabase-setup.sh"
    exit 1
fi

# Check PostgreSQL version
echo "Checking PostgreSQL version..."
PG_VERSION=$(psql "$SUPABASE_DB_URL" -t -c "SHOW server_version;" | xargs | cut -d. -f1)

if [ "$PG_VERSION" -lt 12 ]; then
    echo -e "${RED}✗${NC} PostgreSQL version $PG_VERSION is too old"
    echo "pgvector requires PostgreSQL 12 or higher"
    exit 1
fi
echo -e "${GREEN}✓${NC} PostgreSQL version: $PG_VERSION"

# Enable pgvector extension
echo ""
echo "Enabling pgvector extension..."
psql "$SUPABASE_DB_URL" <<SQL
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify extension
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';
SQL

# Test vector operations
echo ""
echo "Testing vector operations..."
psql "$SUPABASE_DB_URL" -t -c "SELECT '[1,2,3]'::vector AS test_vector;" &>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} pgvector extension working correctly"
else
    echo -e "${RED}✗${NC} pgvector extension test failed"
    exit 1
fi

# Get extension version
EXT_VERSION=$(psql "$SUPABASE_DB_URL" -t -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';" | xargs)
echo -e "${GREEN}✓${NC} pgvector version: $EXT_VERSION"

echo ""
echo -e "${GREEN}Success!${NC} pgvector is enabled and ready for Mem0"
echo ""
echo "Next step: bash scripts/apply-mem0-schema.sh"
