#!/usr/bin/env bash
#
# validate-constraints.sh - Validate database constraints
#
# Usage: validate-constraints.sh <sql-file>
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

validate_file_exists() {
    if [[ ! -f "$SQL_FILE" ]]; then
        echo -e "${RED}ERROR: File not found: $SQL_FILE${NC}"
        exit 1
    fi
}

check_primary_keys() {
    # Extract table names
    local tables=($(grep -iE "create\s+table\s+(if\s+not\s+exists\s+)?([a-zA-Z_][a-zA-Z0-9_]*)" "$SQL_FILE" | \
                   sed -E 's/.*create\s+table\s+(if\s+not\s+exists\s+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\2/i'))

    for table in "${tables[@]}"; do
        # Check if table has a primary key
        local has_pk=false

        # Check for inline PRIMARY KEY
        if grep -iE "create\s+table.*$table" -A 50 "$SQL_FILE" | grep -iE "primary\s+key" > /dev/null; then
            has_pk=true
        fi

        # Check for ALTER TABLE ADD PRIMARY KEY
        if grep -iE "alter\s+table\s+$table.*add.*primary\s+key" "$SQL_FILE" > /dev/null; then
            has_pk=true
        fi

        if [[ "$has_pk" == false ]]; then
            ERRORS+=("Table '$table' has no primary key defined")
        fi

        # Check for IDENTITY columns (modern alternative to SERIAL)
        if grep -iE "create\s+table.*$table" -A 50 "$SQL_FILE" | grep -iE "generated\s+(always|by\s+default)\s+as\s+identity" > /dev/null; then
            INFO+=("Table '$table' uses IDENTITY column (recommended over SERIAL)")
        fi
    done
}

check_foreign_keys() {
    # Extract foreign key definitions
    local fk_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ foreign[[:space:]]+key ]]; then
            ((fk_count++))

            # Check if foreign key has explicit constraint name
            if [[ ! "$line" =~ constraint[[:space:]]+[a-zA-Z_] ]]; then
                WARNINGS+=("Foreign key on line has no explicit constraint name - use CONSTRAINT fk_table_ref")
            fi

            # Check if ON DELETE/UPDATE actions are specified
            if [[ ! "$line" =~ on[[:space:]]+(delete|update) ]]; then
                INFO+=("Foreign key missing ON DELETE/UPDATE action - consider CASCADE, SET NULL, or RESTRICT")
            fi

            # Extract referenced table
            if [[ "$line" =~ references[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                local ref_table="${BASH_REMATCH[1]}"

                # Check if referenced table exists in the same file or before this FK
                if ! grep -iE "create\s+table.*$ref_table" "$SQL_FILE" > /dev/null; then
                    WARNINGS+=("Foreign key references table '$ref_table' which is not defined in this file - ensure it exists")
                fi
            fi
        fi
    done < "$SQL_FILE"

    if [[ $fk_count -eq 0 ]]; then
        INFO+=("No foreign key constraints found - ensure relationships are defined if tables are related")
    fi
}

check_unique_constraints() {
    local unique_count=0

    # Check for UNIQUE constraints
    while IFS= read -r line; do
        if [[ "$line" =~ unique ]]; then
            ((unique_count++))

            # Check if UNIQUE has explicit constraint name
            if [[ "$line" =~ unique ]] && [[ ! "$line" =~ constraint[[:space:]]+[a-zA-Z_] ]]; then
                WARNINGS+=("UNIQUE constraint has no explicit name - use CONSTRAINT uq_table_column")
            fi
        fi
    done < "$SQL_FILE"

    # Check for columns that should probably be unique
    if grep -iE "email|username|slug" "$SQL_FILE" > /dev/null; then
        INFO+=("Found common unique column names (email, username, slug) - ensure they have UNIQUE constraints")
    fi
}

check_check_constraints() {
    local check_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ check[[:space:]]*\( ]]; then
            ((check_count++))

            # Check if CHECK has explicit constraint name
            if [[ ! "$line" =~ constraint[[:space:]]+[a-zA-Z_] ]]; then
                WARNINGS+=("CHECK constraint has no explicit name - use CONSTRAINT ck_table_description")
            fi

            # Check for common validation patterns
            if [[ "$line" =~ \>[[:space:]]*0 ]]; then
                INFO+=("CHECK constraint validates positive values - good practice")
            fi

            if [[ "$line" =~ length\( ]]; then
                INFO+=("CHECK constraint validates string length - good practice")
            fi
        fi
    done < "$SQL_FILE"

    # Suggest CHECK constraints for numeric fields
    if grep -iE "(price|amount|quantity|age|rating)" "$SQL_FILE" > /dev/null; then
        INFO+=("Found numeric fields that might benefit from CHECK constraints (price > 0, age >= 0, etc.)")
    fi
}

check_not_null_constraints() {
    local not_null_count=0

    while IFS= read -r line; do
        # Match column definitions
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+(varchar|text|integer|bigint|uuid|boolean|timestamp|numeric|jsonb) ]]; then
            local column="${BASH_REMATCH[1]}"
            local type="${BASH_REMATCH[2]}"

            # Check for NOT NULL
            if [[ "$line" =~ not[[:space:]]+null ]]; then
                ((not_null_count++))
            else
                # Warn about common fields that should be NOT NULL
                case "$column" in
                    id|created_at|updated_at|user_id|email|name|status)
                        WARNINGS+=("Column '$column' should probably be NOT NULL")
                        ;;
                esac
            fi

            # Check for DEFAULT values on NOT NULL columns
            if [[ "$line" =~ not[[:space:]]+null ]] && [[ ! "$line" =~ default ]]; then
                case "$type" in
                    timestamp|timestamptz)
                        INFO+=("Column '$column' is NOT NULL - consider adding DEFAULT now() for timestamps")
                        ;;
                    boolean)
                        INFO+=("Column '$column' is NOT NULL - consider adding DEFAULT true/false for booleans")
                        ;;
                esac
            fi
        fi
    done < "$SQL_FILE"

    if [[ $not_null_count -eq 0 ]]; then
        WARNINGS+=("No NOT NULL constraints found - ensure nullable columns are intentional")
    fi
}

check_default_values() {
    # Check for proper default values
    while IFS= read -r line; do
        if [[ "$line" =~ default ]]; then
            # Check UUID defaults
            if [[ "$line" =~ uuid ]] && [[ ! "$line" =~ gen_random_uuid\(\)|uuid_generate_v4\(\) ]]; then
                WARNINGS+=("UUID column has DEFAULT but not using gen_random_uuid() - might cause issues")
            fi

            # Check timestamp defaults
            if [[ "$line" =~ timestamp ]] && [[ "$line" =~ default ]] && [[ ! "$line" =~ now\(\)|current_timestamp ]]; then
                INFO+=("Timestamp column has DEFAULT value - consider using now() or CURRENT_TIMESTAMP")
            fi

            # Check for empty string defaults
            if [[ "$line" =~ default[[:space:]]+\'\' ]]; then
                WARNINGS+=("Empty string '' used as DEFAULT - consider NULL instead")
            fi
        fi
    done < "$SQL_FILE"
}

check_constraint_validation_on_data() {
    # Check for constraints that might fail on existing data
    if grep -iE "alter\s+table.*add\s+constraint" "$SQL_FILE" > /dev/null; then
        INFO+=("ALTER TABLE ADD CONSTRAINT found - ensure existing data satisfies new constraints")
    fi

    if grep -iE "alter\s+table.*alter\s+column.*set\s+not\s+null" "$SQL_FILE" > /dev/null; then
        INFO+=("ALTER COLUMN SET NOT NULL found - ensure no existing NULL values")
    fi
}

generate_report() {
    echo "=================================="
    echo "Constraint Validation Report"
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
        echo -e "${GREEN}✓ All constraint validations passed${NC}"
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

main() {
    validate_file_exists

    echo "Validating database constraints: $SQL_FILE"
    echo ""

    check_primary_keys
    check_foreign_keys
    check_unique_constraints
    check_check_constraints
    check_not_null_constraints
    check_default_values
    check_constraint_validation_on_data

    generate_report
}

main "$@"
