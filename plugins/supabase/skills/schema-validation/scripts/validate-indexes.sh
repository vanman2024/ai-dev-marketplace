#!/usr/bin/env bash
#
# validate-indexes.sh - Validate database indexes
#
# Usage: validate-indexes.sh <sql-file>
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SQL_FILE="${1:?ERROR: SQL file path required}"

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

declare -a ERRORS=()
declare -a WARNINGS=()
declare -a INFO=()
declare -A INDEXES=()
declare -a FK_COLUMNS=()

validate_file_exists() {
    if [[ ! -f "$SQL_FILE" ]]; then
        echo -e "${RED}ERROR: File not found: $SQL_FILE${NC}"
        exit 1
    fi
}

extract_indexes() {
    # Extract all index definitions
    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+(unique[[:space:]]+)?index.*on[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(([^)]+)\) ]]; then
            local table="${BASH_REMATCH[2]}"
            local columns="${BASH_REMATCH[3]}"

            # Store index for duplicate detection
            local key="${table}:${columns}"
            if [[ -n "${INDEXES[$key]:-}" ]]; then
                WARNINGS+=("Duplicate index on table '$table' columns ($columns)")
            else
                INDEXES[$key]=1
            fi
        fi
    done < "$SQL_FILE"
}

extract_foreign_key_columns() {
    # Extract columns that are foreign keys
    while IFS= read -r line; do
        if [[ "$line" =~ foreign[[:space:]]+key[[:space:]]*\(([^)]+)\) ]]; then
            local fk_col="${BASH_REMATCH[1]}"
            fk_col=$(echo "$fk_col" | tr -d ' ')
            FK_COLUMNS+=("$fk_col")
        fi
    done < "$SQL_FILE"
}

check_foreign_key_indexes() {
    # Check if all foreign key columns have indexes
    for fk_col in "${FK_COLUMNS[@]}"; do
        local has_index=false

        for index_key in "${!INDEXES[@]}"; do
            local columns="${index_key#*:}"
            # Check if FK column is first column in any index
            if [[ "$columns" =~ ^$fk_col[[:space:]]*,?|^$fk_col$ ]]; then
                has_index=true
                break
            fi
        done

        if [[ "$has_index" == false ]]; then
            WARNINGS+=("Foreign key column '$fk_col' has no index - this can cause performance issues")
        fi
    done
}

check_rls_policy_columns() {
    # Check if columns used in RLS policies have indexes
    local rls_columns=()

    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+policy ]] || [[ "$line" =~ using[[:space:]]*\( ]]; then
            # Extract commonly used auth columns
            if [[ "$line" =~ auth\.uid\(\) ]]; then
                rls_columns+=("user_id")
            fi
            if [[ "$line" =~ auth\.role\(\) ]]; then
                rls_columns+=("role")
            fi
        fi
    done < "$SQL_FILE"

    # Remove duplicates
    rls_columns=($(printf '%s\n' "${rls_columns[@]}" | sort -u))

    for col in "${rls_columns[@]}"; do
        local has_index=false

        for index_key in "${!INDEXES[@]}"; do
            local columns="${index_key#*:}"
            if [[ "$columns" =~ $col ]]; then
                has_index=true
                break
            fi
        done

        if [[ "$has_index" == false ]]; then
            WARNINGS+=("Column '$col' used in RLS policy has no index - add index for better RLS performance")
        fi
    done
}

check_common_query_patterns() {
    # Check for common columns that should be indexed
    local search_columns=("email" "username" "slug" "code" "status")

    for col in "${search_columns[@]}"; do
        if grep -iE "^[[:space:]]*$col[[:space:]]+" "$SQL_FILE" > /dev/null; then
            local has_index=false

            for index_key in "${!INDEXES[@]}"; do
                local columns="${index_key#*:}"
                if [[ "$columns" =~ $col ]]; then
                    has_index=true
                    break
                fi
            done

            if [[ "$has_index" == false ]]; then
                INFO+=("Column '$col' is commonly searched - consider adding an index")
            fi
        fi
    done

    # Check for timestamp columns used for sorting
    local time_columns=("created_at" "updated_at" "published_at")

    for col in "${time_columns[@]}"; do
        if grep -iE "^[[:space:]]*$col[[:space:]]+" "$SQL_FILE" > /dev/null; then
            local has_index=false

            for index_key in "${!INDEXES[@]}"; do
                local columns="${index_key#*:}"
                if [[ "$columns" =~ $col ]]; then
                    has_index=true
                    break
                fi
            done

            if [[ "$has_index" == false ]]; then
                INFO+=("Timestamp column '$col' often used for sorting - consider adding an index")
            fi
        fi
    done
}

check_index_column_order() {
    # Check for multi-column indexes and suggest proper ordering
    for index_key in "${!INDEXES[@]}"; do
        local columns="${index_key#*:}"

        if [[ "$columns" =~ , ]]; then
            INFO+=("Multi-column index on ($columns) - ensure column order matches query patterns (most selective first)")
        fi
    done
}

check_partial_indexes() {
    # Check for opportunities to use partial indexes
    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+index ]] && [[ "$line" =~ where ]]; then
            INFO+=("Partial index detected - good for filtered queries")
        fi
    done < "$SQL_FILE"

    # Suggest partial indexes for soft-delete patterns
    if grep -iE "deleted_at|is_deleted|status" "$SQL_FILE" > /dev/null; then
        if ! grep -iE "create[[:space:]]+index.*where.*deleted_at\s+is\s+null" "$SQL_FILE" > /dev/null; then
            INFO+=("Soft-delete pattern detected - consider partial index WHERE deleted_at IS NULL")
        fi
    fi
}

check_index_type() {
    # Check for proper index types
    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+index ]]; then
            # Check for JSONB columns
            if [[ "$line" =~ jsonb ]] && [[ ! "$line" =~ using[[:space:]]+gin ]]; then
                WARNINGS+=("JSONB column in index - consider using GIN index (USING GIN)")
            fi

            # Check for text search columns
            if [[ "$line" =~ tsvector ]] && [[ ! "$line" =~ using[[:space:]]+gin ]]; then
                WARNINGS+=("tsvector column in index - should use GIN index (USING GIN)")
            fi

            # Check for array columns
            if [[ "$line" =~ \[\] ]] && [[ ! "$line" =~ using[[:space:]]+gin ]]; then
                INFO+=("Array column in index - consider using GIN index (USING GIN)")
            fi
        fi
    done < "$SQL_FILE"
}

check_covering_indexes() {
    # Suggest covering indexes for common patterns
    if grep -iE "select.*from.*where.*order\s+by" "$SQL_FILE" > /dev/null; then
        INFO+=("Found SELECT...WHERE...ORDER BY pattern - consider covering indexes with INCLUDE clause")
    fi
}

generate_report() {
    echo "=================================="
    echo "Index Validation Report"
    echo "=================================="
    echo "File: $SQL_FILE"
    echo ""
    echo "Indexes found: ${#INDEXES[@]}"
    echo "Foreign key columns: ${#FK_COLUMNS[@]}"
    echo ""

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo -e "${RED}ERRORS (${#ERRORS[@]}):${NC}"
        printf '  - %s\n' "${ERRORS[@]}"
        echo ""
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}WARNINGS (${#WARNINGS[@]}):${NC}"
        printf '  - %s\n' "${WARNINGS[@]}"
        echo ""
    fi

    if [[ ${#INFO[@]} -gt 0 ]]; then
        echo "INFO (${#INFO[@]}):"
        printf '  - %s\n' "${INFO[@]}"
        echo ""
    fi

    if [[ ${#ERRORS[@]} -eq 0 ]] && [[ ${#WARNINGS[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓ All index validations passed${NC}"
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

main() {
    validate_file_exists

    echo "Validating database indexes: $SQL_FILE"
    echo ""

    extract_indexes
    extract_foreign_key_columns
    check_foreign_key_indexes
    check_rls_policy_columns
    check_common_query_patterns
    check_index_column_order
    check_partial_indexes
    check_index_type
    check_covering_indexes

    generate_report
}

main "$@"
