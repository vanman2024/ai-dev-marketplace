#!/usr/bin/env bash
#
# validate-rls.sh - Validate Row Level Security policies
#
# Usage: validate-rls.sh <sql-file>
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
declare -a PUBLIC_TABLES=()
declare -A TABLE_POLICIES=()
declare -A TABLE_RLS_ENABLED=()

validate_file_exists() {
    if [[ ! -f "$SQL_FILE" ]]; then
        echo -e "${RED}ERROR: File not found: $SQL_FILE${NC}"
        exit 1
    fi
}

extract_public_tables() {
    # Extract tables in public schema (or no schema specified = public)
    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+table[[:space:]]+(if[[:space:]]+not[[:space:]]+exists[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            local table="${BASH_REMATCH[2]}"

            # Check if schema is specified
            if [[ "$line" =~ create[[:space:]]+table.*public\. ]] || [[ ! "$line" =~ \. ]]; then
                PUBLIC_TABLES+=("$table")
                TABLE_RLS_ENABLED[$table]=false
            fi
        fi

        # Check for explicit schema specification
        if [[ "$line" =~ create[[:space:]]+table.*([a-zA-Z_][a-zA-Z0-9_]*)\.([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            local schema="${BASH_REMATCH[1]}"
            local table="${BASH_REMATCH[2]}"

            if [[ "$schema" == "public" ]]; then
                PUBLIC_TABLES+=("$table")
                TABLE_RLS_ENABLED[$table]=false
            fi
        fi
    done < "$SQL_FILE"

    # Remove duplicates
    PUBLIC_TABLES=($(printf '%s\n' "${PUBLIC_TABLES[@]}" | sort -u))
}

check_rls_enabled() {
    # Check for ALTER TABLE ... ENABLE ROW LEVEL SECURITY
    for table in "${PUBLIC_TABLES[@]}"; do
        if grep -iE "alter[[:space:]]+table[[:space:]]+${table}[[:space:]]+enable[[:space:]]+row[[:space:]]+level[[:space:]]+security" "$SQL_FILE" > /dev/null; then
            TABLE_RLS_ENABLED[$table]=true
        else
            ERRORS+=("Table '$table' in public schema must have RLS enabled: ALTER TABLE $table ENABLE ROW LEVEL SECURITY;")
        fi
    done
}

extract_policies() {
    # Extract all policies for each table
    local current_table=""

    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+policy[[:space:]]+[\"']?([a-zA-Z_][a-zA-Z0-9_]*)[\"']?[[:space:]]+on[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            local policy="${BASH_REMATCH[1]}"
            current_table="${BASH_REMATCH[2]}"

            if [[ -z "${TABLE_POLICIES[$current_table]:-}" ]]; then
                TABLE_POLICIES[$current_table]="$policy"
            else
                TABLE_POLICIES[$current_table]="${TABLE_POLICIES[$current_table]},$policy"
            fi
        fi
    done < "$SQL_FILE"
}

check_policy_coverage() {
    # Check if each table with RLS has policies for CRUD operations
    for table in "${PUBLIC_TABLES[@]}"; do
        if [[ "${TABLE_RLS_ENABLED[$table]}" == true ]]; then
            local policies="${TABLE_POLICIES[$table]:-}"

            if [[ -z "$policies" ]]; then
                ERRORS+=("Table '$table' has RLS enabled but no policies defined - table will be inaccessible")
                continue
            fi

            # Check for SELECT policy
            if ! grep -iE "create[[:space:]]+policy.*on[[:space:]]+${table}.*for[[:space:]]+select" "$SQL_FILE" > /dev/null; then
                WARNINGS+=("Table '$table' missing SELECT policy - users cannot read data")
            fi

            # Check for INSERT policy
            if ! grep -iE "create[[:space:]]+policy.*on[[:space:]]+${table}.*for[[:space:]]+insert" "$SQL_FILE" > /dev/null; then
                INFO+=("Table '$table' has no INSERT policy - consider if users need to create records")
            fi

            # Check for UPDATE policy
            if ! grep -iE "create[[:space:]]+policy.*on[[:space:]]+${table}.*for[[:space:]]+update" "$SQL_FILE" > /dev/null; then
                INFO+=("Table '$table' has no UPDATE policy - consider if users need to modify records")
            fi

            # Check for DELETE policy
            if ! grep -iE "create[[:space:]]+policy.*on[[:space:]]+${table}.*for[[:space:]]+delete" "$SQL_FILE" > /dev/null; then
                INFO+=("Table '$table' has no DELETE policy - consider if users need to remove records")
            fi
        fi
    done
}

check_policy_roles() {
    # Check if policies specify roles (TO clause)
    local policy_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+policy ]]; then
            ((policy_count++))

            # Check for TO clause specifying role
            if [[ ! "$line" =~ to[[:space:]]+(authenticated|anon|public|[a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                WARNINGS+=("Policy missing TO clause - specify role (TO authenticated, TO anon, etc.)")
            fi

            # Check for proper role usage
            if [[ "$line" =~ to[[:space:]]+public ]]; then
                WARNINGS+=("Policy uses TO public - consider using TO authenticated or TO anon for better security")
            fi
        fi
    done < "$SQL_FILE"

    if [[ $policy_count -eq 0 ]] && [[ ${#PUBLIC_TABLES[@]} -gt 0 ]]; then
        WARNINGS+=("No RLS policies found but ${#PUBLIC_TABLES[@]} public table(s) detected")
    fi
}

check_auth_functions() {
    # Check for proper use of auth helper functions
    local uses_auth_uid=false
    local uses_auth_jwt=false

    if grep -iE "auth\.uid\(\)" "$SQL_FILE" > /dev/null; then
        uses_auth_uid=true
        INFO+=("Using auth.uid() in policies - ensure it's wrapped in SELECT for performance: (SELECT auth.uid())")
    fi

    if grep -iE "auth\.jwt\(\)" "$SQL_FILE" > /dev/null; then
        uses_auth_jwt=true
        INFO+=("Using auth.jwt() in policies - ensure proper JWT claim extraction")
    fi

    # Check for common mistakes
    if grep -iE "current_user" "$SQL_FILE" > /dev/null; then
        WARNINGS+=("Using current_user in policy - use auth.uid() for Supabase authentication instead")
    fi
}

check_with_check_expressions() {
    # Check for WITH CHECK expressions on INSERT/UPDATE policies
    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+policy ]] && [[ "$line" =~ for[[:space:]]+(insert|update) ]]; then
            local next_lines=""
            local line_num=0

            # Read next few lines to check for WITH CHECK
            while IFS= read -r next_line && [[ $line_num -lt 5 ]]; do
                next_lines="$next_lines $next_line"
                ((line_num++))

                if [[ "$next_line" =~ \; ]]; then
                    break
                fi
            done < <(grep -A 5 "$line" "$SQL_FILE")

            if [[ ! "$next_lines" =~ with[[:space:]]+check ]]; then
                WARNINGS+=("INSERT/UPDATE policy missing WITH CHECK clause - data validation not enforced")
            fi
        fi
    done < "$SQL_FILE"
}

check_performance_indexes() {
    # Check if columns used in policies have indexes
    local policy_columns=()

    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+policy ]]; then
            # Extract common patterns
            if [[ "$line" =~ user_id[[:space:]]*= ]]; then
                policy_columns+=("user_id")
            fi
            if [[ "$line" =~ role[[:space:]]*= ]]; then
                policy_columns+=("role")
            fi
            if [[ "$line" =~ organization_id[[:space:]]*= ]]; then
                policy_columns+=("organization_id")
            fi
        fi
    done < "$SQL_FILE"

    # Remove duplicates
    policy_columns=($(printf '%s\n' "${policy_columns[@]}" | sort -u))

    for col in "${policy_columns[@]}"; do
        if ! grep -iE "create[[:space:]]+index.*\($col\)" "$SQL_FILE" > /dev/null; then
            WARNINGS+=("Column '$col' used in RLS policy but no index found - add index for performance")
        fi
    done
}

check_policy_complexity() {
    # Warn about overly complex policies
    while IFS= read -r line; do
        if [[ "$line" =~ create[[:space:]]+policy ]]; then
            # Count JOINs in policy
            local join_count=$(grep -A 10 "$line" "$SQL_FILE" | grep -ic "join")

            if [[ $join_count -gt 1 ]]; then
                WARNINGS+=("Policy contains multiple JOINs - consider simplifying with materialized views or denormalization")
            fi

            # Check for subqueries
            if grep -A 10 "$line" "$SQL_FILE" | grep -iE "select.*from.*where" > /dev/null; then
                INFO+=("Policy contains subquery - ensure it's wrapped in SELECT for performance")
            fi
        fi
    done < "$SQL_FILE"
}

check_bypass_rls() {
    # Check for service role bypass (security consideration)
    if grep -iE "bypassrls|bypass_rls" "$SQL_FILE" > /dev/null; then
        WARNINGS+=("BYPASSRLS found - ensure this is only for service role and properly documented")
    fi
}

generate_report() {
    echo "=================================="
    echo "RLS Policy Validation Report"
    echo "=================================="
    echo "File: $SQL_FILE"
    echo ""
    echo "Public tables found: ${#PUBLIC_TABLES[@]}"
    if [[ ${#PUBLIC_TABLES[@]} -gt 0 ]]; then
        echo "Tables: ${PUBLIC_TABLES[*]}"
    fi
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
        echo -e "${GREEN}✓ All RLS validations passed${NC}"
    fi

    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

main() {
    validate_file_exists

    echo "Validating RLS policies: $SQL_FILE"
    echo ""

    extract_public_tables
    check_rls_enabled
    extract_policies
    check_policy_coverage
    check_policy_roles
    check_auth_functions
    check_with_check_expressions
    check_performance_indexes
    check_policy_complexity
    check_bypass_rls

    generate_report
}

main "$@"
