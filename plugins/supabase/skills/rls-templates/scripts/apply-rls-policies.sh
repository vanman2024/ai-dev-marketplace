#!/bin/bash
# Apply RLS policies to Supabase tables
# Usage: apply-rls-policies.sh <template> <table1> [table2] [table3]...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $0 <template> <table1> [table2] [table3]...

Templates:
  user-isolation      - User owns row directly (user_id column)
  multi-tenant        - Organization/team-based isolation
  role-based-access   - Different permissions per role
  ai-chat            - Chat/conversation data policies
  embeddings         - Vector/embedding data policies

Environment Variables (required):
  SUPABASE_DB_URL    - PostgreSQL connection string

Examples:
  $0 user-isolation profiles settings
  $0 multi-tenant organizations documents
  $0 ai-chat conversations messages
EOF
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
        log_error "SUPABASE_DB_URL environment variable not set"
        exit 1
    fi

    if ! command -v psql &> /dev/null; then
        log_error "psql not found. Install PostgreSQL client tools."
        exit 1
    fi
}

enable_rls() {
    local table="$1"

    log_info "Enabling RLS on table: $table"

    psql "$SUPABASE_DB_URL" -c "ALTER TABLE $table ENABLE ROW LEVEL SECURITY;" 2>/dev/null || {
        log_error "Failed to enable RLS on $table"
        return 1
    }

    log_info "RLS enabled on $table"
}

create_index() {
    local table="$1"
    local column="$2"
    local index_name="idx_${table}_${column}"

    log_info "Creating index on ${table}.${column}"

    psql "$SUPABASE_DB_URL" -c "
        CREATE INDEX IF NOT EXISTS $index_name ON $table($column);
    " 2>/dev/null || {
        log_warn "Index creation failed or already exists"
    }
}

apply_template() {
    local template="$1"
    local table="$2"
    local template_file="$TEMPLATES_DIR/${template}.sql"

    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template_file"
        return 1
    fi

    log_info "Applying $template policies to $table"

    # Replace TABLE_NAME placeholder in template and apply
    sed "s/TABLE_NAME/$table/g" "$template_file" | psql "$SUPABASE_DB_URL" 2>&1 | while read -r line; do
        if [[ "$line" =~ ERROR ]]; then
            log_warn "$line"
        fi
    done

    log_info "Policies applied to $table"
}

validate_policy_count() {
    local table="$1"

    local count=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*)
        FROM pg_policies
        WHERE tablename = '$table';
    " 2>/dev/null | tr -d ' ')

    if [[ "$count" -gt 0 ]]; then
        log_info "Table $table has $count policies"
        return 0
    else
        log_warn "Table $table has no policies!"
        return 1
    fi
}

main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    check_prerequisites

    local template="$1"
    shift
    local tables=("$@")

    log_info "Starting RLS policy application"
    log_info "Template: $template"
    log_info "Tables: ${tables[*]}"
    echo

    local failed=0

    for table in "${tables[@]}"; do
        echo "----------------------------------------"
        log_info "Processing table: $table"

        # Enable RLS
        if ! enable_rls "$table"; then
            ((failed++))
            continue
        fi

        # Create performance index based on template
        case "$template" in
            user-isolation)
                create_index "$table" "user_id"
                ;;
            multi-tenant)
                create_index "$table" "organization_id"
                ;;
            ai-chat)
                create_index "$table" "user_id"
                create_index "$table" "conversation_id"
                ;;
            embeddings)
                create_index "$table" "document_id"
                ;;
        esac

        # Apply template policies
        if ! apply_template "$template" "$table"; then
            ((failed++))
            continue
        fi

        # Validate policies were created
        validate_policy_count "$table"

        echo
    done

    echo "========================================"
    if [[ $failed -eq 0 ]]; then
        log_info "All policies applied successfully!"
        exit 0
    else
        log_error "$failed table(s) failed"
        exit 1
    fi
}

main "$@"
