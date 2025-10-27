#!/usr/bin/env bash
#
# validate-naming.sh - Validate database naming conventions
#
# Usage: validate-naming.sh <sql-file>
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SQL_FILE="${1:?ERROR: SQL file path required}"
readonly CONVENTIONS_FILE="${SCRIPT_DIR}/../templates/naming-conventions.json"

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

declare -a ERRORS=()
declare -a WARNINGS=()
declare -a INFO=()

validate_file_exists() {
    if [[ ! -f "$SQL_FILE" ]]; then
        echo -e "${RED}ERROR: File not found: $SQL_FILE${NC}"
        exit 1
    fi
}

check_table_naming() {
    # Extract table names from CREATE TABLE statements
    local tables=($(grep -iE "create\s+table\s+(if\s+not\s+exists\s+)?([a-zA-Z_][a-zA-Z0-9_]*)" "$SQL_FILE" | \
                   sed -E 's/.*create\s+table\s+(if\s+not\s+exists\s+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\2/i'))

    for table in "${tables[@]}"; do
        # Check for lowercase
        if [[ "$table" =~ [A-Z] ]]; then
            ERRORS+=("Table '$table' contains uppercase letters - use lowercase with underscores")
        fi

        # Check for spaces (quoted identifiers)
        if [[ "$table" =~ [[:space:]] ]]; then
            ERRORS+=("Table '$table' contains spaces - use underscores instead")
        fi

        # Check for camelCase
        if [[ "$table" =~ [a-z][A-Z] ]]; then
            WARNINGS+=("Table '$table' appears to use camelCase - use snake_case instead")
        fi

        # Check for plural form (common convention)
        if [[ ! "$table" =~ s$ ]] && [[ ! "$table" =~ _data$ ]] && [[ ! "$table" =~ _info$ ]]; then
            INFO+=("Table '$table' is singular - consider using plural form (e.g., 'users' not 'user')")
        fi

        # Check for reserved keywords
        local reserved=("user" "group" "order" "table" "index" "view" "role" "grant")
        for keyword in "${reserved[@]}"; do
            if [[ "${table,,}" == "$keyword" ]]; then
                WARNINGS+=("Table '$table' is a PostgreSQL reserved keyword - should be quoted or renamed")
            fi
        done

        # Check for prefixes/suffixes
        if [[ "$table" =~ ^tbl_ ]]; then
            WARNINGS+=("Table '$table' uses 'tbl_' prefix - this is unnecessary in modern SQL")
        fi
    done
}

check_column_naming() {
    # Extract column definitions (basic pattern matching)
    while IFS= read -r line; do
        # Match column definitions (name followed by type)
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+(varchar|text|integer|bigint|uuid|boolean|timestamp|numeric|jsonb|date|time) ]]; then
            local column="${BASH_REMATCH[1]}"

            # Check for uppercase
            if [[ "$column" =~ [A-Z] ]]; then
                ERRORS+=("Column '$column' contains uppercase letters - use lowercase with underscores")
            fi

            # Check for camelCase
            if [[ "$column" =~ [a-z][A-Z] ]]; then
                WARNINGS+=("Column '$column' appears to use camelCase - use snake_case instead")
            fi

            # Check for plural columns (usually should be singular)
            if [[ "$column" =~ s$ ]] && [[ ! "$column" =~ _ids$ ]] && [[ ! "$column" =~ _tags$ ]]; then
                INFO+=("Column '$column' is plural - columns are typically singular unless array/JSON")
            fi

            # Check for 'id' suffix when not primary key
            if [[ "$column" =~ _id$ ]] && ! grep -iE "primary\s+key.*$column|$column.*primary\s+key" <<< "$line" > /dev/null; then
                INFO+=("Column '$column' has '_id' suffix - ensure it's a foreign key reference")
            fi
        fi
    done < "$SQL_FILE"
}

check_constraint_naming() {
    # Primary Key
    local pk_constraints=($(grep -iE "constraint\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+primary\s+key" "$SQL_FILE" | \
                           sed -E 's/.*constraint\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/i'))

    for pk in "${pk_constraints[@]}"; do
        if [[ ! "$pk" =~ ^pk_ ]]; then
            WARNINGS+=("Primary key constraint '$pk' should start with 'pk_' prefix")
        fi
    done

    # Foreign Key
    local fk_constraints=($(grep -iE "constraint\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+foreign\s+key" "$SQL_FILE" | \
                           sed -E 's/.*constraint\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/i'))

    for fk in "${fk_constraints[@]}"; do
        if [[ ! "$fk" =~ ^fk_ ]]; then
            WARNINGS+=("Foreign key constraint '$fk' should start with 'fk_' prefix")
        fi
    done

    # Unique
    local uq_constraints=($(grep -iE "constraint\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+unique" "$SQL_FILE" | \
                           sed -E 's/.*constraint\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/i'))

    for uq in "${uq_constraints[@]}"; do
        if [[ ! "$uq" =~ ^uq_ ]]; then
            WARNINGS+=("Unique constraint '$uq' should start with 'uq_' prefix")
        fi
    done

    # Check
    local ck_constraints=($(grep -iE "constraint\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+check" "$SQL_FILE" | \
                           sed -E 's/.*constraint\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/i'))

    for ck in "${ck_constraints[@]}"; do
        if [[ ! "$ck" =~ ^ck_ ]]; then
            WARNINGS+=("Check constraint '$ck' should start with 'ck_' prefix")
        fi
    done
}

check_index_naming() {
    # Extract index names
    local indexes=($(grep -iE "create\s+(unique\s+)?index\s+(if\s+not\s+exists\s+)?([a-zA-Z_][a-zA-Z0-9_]*)" "$SQL_FILE" | \
                    sed -E 's/.*create\s+(unique\s+)?index\s+(if\s+not\s+exists\s+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\3/i'))

    for index in "${indexes[@]}"; do
        # Check for uppercase
        if [[ "$index" =~ [A-Z] ]]; then
            ERRORS+=("Index '$index' contains uppercase letters - use lowercase")
        fi

        # Check for proper prefix
        if [[ "$index" =~ unique ]] || grep -iE "create\s+unique\s+index\s+$index" "$SQL_FILE" > /dev/null; then
            if [[ ! "$index" =~ ^uidx_ ]]; then
                WARNINGS+=("Unique index '$index' should start with 'uidx_' prefix")
            fi
        else
            if [[ ! "$index" =~ ^idx_ ]]; then
                WARNINGS+=("Index '$index' should start with 'idx_' prefix")
            fi
        fi

        # Check that index name includes table and column hint
        if [[ ! "$index" =~ _ ]]; then
            INFO+=("Index '$index' should include table and column names for clarity (e.g., 'idx_users_email')")
        fi
    done
}

generate_report() {
    echo "=================================="
    echo "Naming Convention Validation Report"
    echo "=================================="
    echo "File: $SQL_FILE"
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
        echo -e "${GREEN}✓ All naming conventions followed${NC}"
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

main() {
    validate_file_exists

    echo "Validating naming conventions: $SQL_FILE"
    echo ""

    check_table_naming
    check_column_naming
    check_constraint_naming
    check_index_naming

    generate_report
}

main "$@"
