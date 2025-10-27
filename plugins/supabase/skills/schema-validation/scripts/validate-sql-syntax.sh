#!/usr/bin/env bash
#
# validate-sql-syntax.sh - Validate PostgreSQL SQL syntax
#
# Usage: validate-sql-syntax.sh <sql-file>
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SQL_FILE="${1:?ERROR: SQL file path required}"

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m' # No Color

# Validation results
declare -a ERRORS=()
declare -a WARNINGS=()
declare -a INFO=()

validate_file_exists() {
    if [[ ! -f "$SQL_FILE" ]]; then
        echo -e "${RED}ERROR: File not found: $SQL_FILE${NC}"
        exit 1
    fi
}

validate_syntax_with_psql() {
    # Try to validate with psql if available
    if command -v psql &> /dev/null; then
        local temp_db="validation_temp_$$"

        # Create temporary validation using dry-run mode
        if psql --version &> /dev/null; then
            # Use --dry-run if available (PostgreSQL 12+)
            if psql -c '\q' --dry-run &> /dev/null 2>&1; then
                if ! psql --dry-run -f "$SQL_FILE" 2>&1 | grep -i "error"; then
                    INFO+=("PostgreSQL syntax validation passed")
                else
                    ERRORS+=("PostgreSQL syntax errors detected")
                fi
            else
                INFO+=("Using basic syntax validation (psql --dry-run not available)")
            fi
        fi
    else
        INFO+=("psql not available, skipping PostgreSQL syntax validation")
    fi
}

check_reserved_keywords() {
    # PostgreSQL reserved keywords that should be quoted
    local reserved_keywords=(
        "user" "group" "order" "table" "select" "insert" "update" "delete"
        "create" "drop" "alter" "grant" "revoke" "index" "view" "trigger"
        "function" "procedure" "schema" "database" "role" "constraint"
        "primary" "foreign" "unique" "check" "default" "references"
    )

    for keyword in "${reserved_keywords[@]}"; do
        # Check for unquoted usage as identifiers
        if grep -iE "\b$keyword\s+\(" "$SQL_FILE" > /dev/null 2>&1; then
            continue # Function call, likely OK
        fi

        if grep -iE "create\s+table\s+$keyword\b" "$SQL_FILE" > /dev/null 2>&1; then
            WARNINGS+=("Reserved keyword '$keyword' used as table name without quotes")
        fi

        if grep -iE "\b$keyword\s+[a-zA-Z_]" "$SQL_FILE" | grep -v "create\|alter\|drop" > /dev/null 2>&1; then
            WARNINGS+=("Potential use of reserved keyword '$keyword' as identifier")
        fi
    done
}

check_statement_termination() {
    # Check for missing semicolons
    local line_num=0
    local in_statement=false

    while IFS= read -r line; do
        ((line_num++))

        # Skip comments
        if [[ "$line" =~ ^[[:space:]]*-- ]]; then
            continue
        fi

        # Skip empty lines
        if [[ -z "${line// /}" ]]; then
            continue
        fi

        # Check for statement keywords
        if [[ "$line" =~ ^[[:space:]]*(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|SELECT) ]]; then
            in_statement=true
        fi

        # Check for semicolon termination
        if [[ "$in_statement" == true ]] && [[ "$line" =~ \;[[:space:]]*$ ]]; then
            in_statement=false
        fi

    done < "$SQL_FILE"

    if [[ "$in_statement" == true ]]; then
        WARNINGS+=("Possible missing semicolon at end of file")
    fi
}

check_data_types() {
    # Check for deprecated or problematic data types
    if grep -iE "\bmoney\b" "$SQL_FILE" > /dev/null 2>&1; then
        WARNINGS+=("MONEY type found - consider using NUMERIC for better precision")
    fi

    if grep -iE "\bserial\b" "$SQL_FILE" > /dev/null 2>&1; then
        INFO+=("SERIAL type found - consider using IDENTITY columns (PostgreSQL 10+)")
    fi

    # Check for TEXT when VARCHAR might be better
    if grep -iE "create\s+table.*\btext\b" "$SQL_FILE" > /dev/null 2>&1; then
        INFO+=("TEXT type found - ensure this is intentional (consider VARCHAR with limit)")
    fi

    # Check for proper UUID usage
    if grep -iE "\buuid\b" "$SQL_FILE" > /dev/null 2>&1; then
        if ! grep -iE "gen_random_uuid\(\)|uuid_generate_v4\(\)" "$SQL_FILE" > /dev/null 2>&1; then
            INFO+=("UUID type found - ensure proper default value (gen_random_uuid())")
        fi
    fi
}

check_common_syntax_errors() {
    # Check for common typos
    if grep -iE "creat table|crate table" "$SQL_FILE" > /dev/null 2>&1; then
        ERRORS+=("Typo detected: 'creat table' or 'crate table' (should be 'CREATE TABLE')")
    fi

    if grep -iE "primay key|primar key" "$SQL_FILE" > /dev/null 2>&1; then
        ERRORS+=("Typo detected: incorrect spelling of PRIMARY KEY")
    fi

    # Check for single quotes in identifiers (should use double quotes)
    if grep -E "create\s+table\s+'[a-zA-Z_]" "$SQL_FILE" > /dev/null 2>&1; then
        ERRORS+=("Single quotes used for identifier (table name) - use double quotes or no quotes")
    fi

    # Check for missing commas between columns
    local prev_line=""
    while IFS= read -r line; do
        if [[ "$prev_line" =~ [a-zA-Z_][[:space:]]+[a-zA-Z_]+[[:space:]]*$ ]] &&
           [[ "$line" =~ ^[[:space:]]*[a-zA-Z_]+ ]]; then
            WARNINGS+=("Possible missing comma between column definitions")
        fi
        prev_line="$line"
    done < "$SQL_FILE"
}

generate_report() {
    echo "=================================="
    echo "SQL Syntax Validation Report"
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
        echo -e "${GREEN}✓ No syntax errors or warnings found${NC}"
    fi

    # Return exit code based on errors
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

main() {
    validate_file_exists

    echo "Validating SQL syntax: $SQL_FILE"
    echo ""

    validate_syntax_with_psql
    check_reserved_keywords
    check_statement_termination
    check_data_types
    check_common_syntax_errors

    generate_report
}

main "$@"
