#!/usr/bin/env bash
#
# full-validation.sh - Run all schema validations and generate report
#
# Usage: full-validation.sh <sql-file-or-directory>
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INPUT="${1:?ERROR: SQL file or directory path required}"
readonly REPORT_FILE="${2:-validation-report.md}"

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Validation results
declare -a SQL_FILES=()
declare -i TOTAL_ERRORS=0
declare -i TOTAL_WARNINGS=0
declare -i TOTAL_INFO=0

find_sql_files() {
    if [[ -f "$INPUT" ]]; then
        SQL_FILES=("$INPUT")
    elif [[ -d "$INPUT" ]]; then
        while IFS= read -r -d '' file; do
            SQL_FILES+=("$file")
        done < <(find "$INPUT" -type f -name "*.sql" -print0 | sort -z)

        if [[ ${#SQL_FILES[@]} -eq 0 ]]; then
            echo -e "${RED}ERROR: No SQL files found in directory: $INPUT${NC}"
            exit 1
        fi
    else
        echo -e "${RED}ERROR: Invalid path: $INPUT${NC}"
        exit 1
    fi

    echo -e "${BLUE}Found ${#SQL_FILES[@]} SQL file(s) to validate${NC}"
    echo ""
}

initialize_report() {
    cat > "$REPORT_FILE" << 'EOF'
# Database Schema Validation Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## Summary

EOF

    echo "## Summary" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

run_validation() {
    local sql_file="$1"
    local validator="$2"
    local validator_name="$3"

    echo -e "${BLUE}Running $validator_name validation on: $(basename "$sql_file")${NC}"

    local output
    local exit_code

    # Run validator and capture output and exit code
    set +e
    output=$(bash "$SCRIPT_DIR/$validator" "$sql_file" 2>&1)
    exit_code=$?
    set -e

    # Count errors, warnings, and info
    local errors=$(echo "$output" | grep -c "^  - .*" | grep -A 100 "ERRORS" || echo "0")
    local warnings=$(echo "$output" | grep -c "^  - .*" | grep -A 100 "WARNINGS" || echo "0")
    local info=$(echo "$output" | grep -c "^  - .*" | grep -A 100 "INFO" || echo "0")

    # Add to totals
    TOTAL_ERRORS=$((TOTAL_ERRORS + errors))
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + warnings))
    TOTAL_INFO=$((TOTAL_INFO + info))

    # Append to report
    echo "### $validator_name - $(basename "$sql_file")" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "$output" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ Passed${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    echo ""

    return $exit_code
}

generate_summary() {
    # Update summary section at the beginning of report
    local temp_file=$(mktemp)

    cat > "$temp_file" << EOF
# Database Schema Validation Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Files Validated:** ${#SQL_FILES[@]}

## Summary

| Validation Type | Errors | Warnings | Info |
|----------------|---------|----------|------|
| **TOTAL** | **$TOTAL_ERRORS** | **$TOTAL_WARNINGS** | **$TOTAL_INFO** |

EOF

    if [[ $TOTAL_ERRORS -gt 0 ]]; then
        echo "❌ **Status:** FAILED - $TOTAL_ERRORS error(s) must be fixed before deployment" >> "$temp_file"
    elif [[ $TOTAL_WARNINGS -gt 0 ]]; then
        echo "⚠️  **Status:** PASSED with warnings - $TOTAL_WARNINGS warning(s) should be reviewed" >> "$temp_file"
    else
        echo "✅ **Status:** PASSED - All validations successful" >> "$temp_file"
    fi

    echo "" >> "$temp_file"
    echo "## Validation Details" >> "$temp_file"
    echo "" >> "$temp_file"

    # Append the rest of the original report
    tail -n +7 "$REPORT_FILE" >> "$temp_file"

    mv "$temp_file" "$REPORT_FILE"
}

main() {
    echo "========================================"
    echo "Database Schema Full Validation"
    echo "========================================"
    echo ""

    find_sql_files
    initialize_report

    local overall_status=0

    # Run all validations for each SQL file
    for sql_file in "${SQL_FILES[@]}"; do
        echo -e "${BLUE}═══ Validating: $(basename "$sql_file") ═══${NC}"
        echo ""

        # SQL Syntax Validation
        if ! run_validation "$sql_file" "validate-sql-syntax.sh" "SQL Syntax"; then
            overall_status=1
        fi

        # Naming Convention Validation
        if ! run_validation "$sql_file" "validate-naming.sh" "Naming Conventions"; then
            overall_status=1
        fi

        # Constraint Validation
        if ! run_validation "$sql_file" "validate-constraints.sh" "Constraints"; then
            overall_status=1
        fi

        # Index Validation
        if ! run_validation "$sql_file" "validate-indexes.sh" "Indexes"; then
            overall_status=1
        fi

        # RLS Validation
        if ! run_validation "$sql_file" "validate-rls.sh" "Row Level Security"; then
            overall_status=1
        fi

        echo ""
    done

    # Generate final summary
    generate_summary

    # Print summary to console
    echo "========================================"
    echo "Validation Complete"
    echo "========================================"
    echo ""
    echo "Files validated: ${#SQL_FILES[@]}"
    echo -e "${RED}Errors:   $TOTAL_ERRORS${NC}"
    echo -e "${YELLOW}Warnings: $TOTAL_WARNINGS${NC}"
    echo "Info:     $TOTAL_INFO"
    echo ""
    echo "Report saved to: $REPORT_FILE"
    echo ""

    if [[ $overall_status -eq 0 ]] && [[ $TOTAL_ERRORS -eq 0 ]]; then
        echo -e "${GREEN}✓ All validations passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Validation failed - review $REPORT_FILE for details${NC}"
        exit 1
    fi
}

main "$@"
