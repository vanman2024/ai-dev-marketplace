#!/bin/bash
set -euo pipefail

# Setup pgvector extension in Supabase
# Usage: ./setup-pgvector.sh [SUPABASE_DB_URL]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if DB URL is provided
if [ -z "${1:-}" ]; then
    if [ -z "${SUPABASE_DB_URL:-}" ]; then
        log_error "Database URL required"
        echo "Usage: $0 <SUPABASE_DB_URL>"
        echo "Or set SUPABASE_DB_URL environment variable"
        exit 1
    fi
    DB_URL="$SUPABASE_DB_URL"
else
    DB_URL="$1"
fi

log_info "Setting up pgvector extension..."

# Enable pgvector extension
log_info "Enabling pgvector extension..."
psql "$DB_URL" -c "create extension if not exists vector with schema extensions;" || {
    log_error "Failed to create pgvector extension"
    exit 1
}

# Verify extension is installed
EXTENSION_CHECK=$(psql "$DB_URL" -t -c "select count(*) from pg_extension where extname = 'vector';")
if [ "$EXTENSION_CHECK" -eq 1 ]; then
    log_info "pgvector extension enabled successfully"
else
    log_error "pgvector extension not found after installation"
    exit 1
fi

# Check pgvector version
VERSION=$(psql "$DB_URL" -t -c "select extversion from pg_extension where extname = 'vector';")
log_info "pgvector version: $VERSION"

log_info "Setup complete!"
log_info ""
log_info "Next steps:"
log_info "1. Create embedding tables using templates/embedding-table-schema.sql"
log_info "2. Create indexes with scripts/create-indexes.sh"
log_info "3. Test setup with scripts/test-vector-search.sh"
