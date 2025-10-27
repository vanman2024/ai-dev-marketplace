#!/bin/bash
# Audit Supabase tables for missing or incomplete RLS policies
# Usage: audit-rls.sh [table1] [table2] [--report output.md]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [tables...] [--report output.md]

Options:
  --report FILE      Generate markdown report
  --schema SCHEMA    Check specific schema (default: public)

Environment Variables (required):
  SUPABASE_DB_URL    - PostgreSQL connection string

Examples:
  $0                           # Audit all tables in public schema
  $0 conversations messages    # Audit specific tables
  $0 --report audit.md         # Generate markdown report
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

log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
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

get_all_tables() {
    local schema="${1:-public}"

    psql "$SUPABASE_DB_URL" -t -c "
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = '$schema'
        ORDER BY tablename;
    " 2>/dev/null | tr -d ' '
}

check_rls_enabled() {
    local table="$1"

    local enabled=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT relrowsecurity
        FROM pg_class
        WHERE relname = '$table';
    " 2>/dev/null | tr -d ' ')

    [[ "$enabled" == "t" ]]
}

get_policy_count() {
    local table="$1"

    psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*)
        FROM pg_policies
        WHERE tablename = '$table';
    " 2>/dev/null | tr -d ' '
}

get_policies() {
    local table="$1"

    psql "$SUPABASE_DB_URL" -t -c "
        SELECT policyname, cmd, roles::text
        FROM pg_policies
        WHERE tablename = '$table'
        ORDER BY cmd;
    " 2>/dev/null
}

check_performance_indexes() {
    local table="$1"

    local indexes=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*)
        FROM pg_indexes
        WHERE tablename = '$table'
        AND (indexname LIKE '%user_id%' OR indexname LIKE '%organization_id%');
    " 2>/dev/null | tr -d ' ')

    [[ "$indexes" -gt 0 ]]
}

has_user_id_column() {
    local table="$1"

    local has_column=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_name = '$table'
        AND column_name = 'user_id';
    " 2>/dev/null | tr -d ' ')

    [[ "$has_column" -gt 0 ]]
}

audit_table() {
    local table="$1"
    local issues=0
    local warnings=0

    echo "Table: $table"
    echo "----------------------------------------"

    # Check RLS enabled
    if check_rls_enabled "$table"; then
        log_info "✓ RLS enabled"
    else
        log_critical "✗ RLS NOT enabled!"
        ((issues++))
    fi

    # Check policy count
    local policy_count=$(get_policy_count "$table")
    if [[ "$policy_count" -eq 0 ]]; then
        log_critical "✗ No policies defined!"
        ((issues++))
    else
        log_info "✓ $policy_count policies defined"

        # List policies
        echo "  Policies:"
        get_policies "$table" | while read -r line; do
            if [[ -n "$line" ]]; then
                echo "    - $line"
            fi
        done
    fi

    # Check for performance indexes
    if has_user_id_column "$table"; then
        if check_performance_indexes "$table"; then
            log_info "✓ Performance indexes found"
        else
            log_warn "⚠ No performance indexes on user_id/organization_id"
            ((warnings++))
        fi
    fi

    # Check for common policy patterns
    local has_select=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*) FROM pg_policies
        WHERE tablename = '$table' AND cmd = 'SELECT';
    " 2>/dev/null | tr -d ' ')

    local has_insert=$(psql "$SUPABASE_DB_URL" -t -c "
        SELECT COUNT(*) FROM pg_policies
        WHERE tablename = '$table' AND cmd = 'INSERT';
    " 2>/dev/null | tr -d ' ')

    if [[ "$has_select" -eq 0 ]] && [[ "$policy_count" -gt 0 ]]; then
        log_warn "⚠ No SELECT policy (data may be invisible)"
        ((warnings++))
    fi

    if [[ "$has_insert" -eq 0 ]] && [[ "$policy_count" -gt 0 ]]; then
        log_warn "⚠ No INSERT policy (users cannot create records)"
        ((warnings++))
    fi

    echo

    # Return issue count
    echo "$issues:$warnings"
}

generate_markdown_report() {
    local output_file="$1"
    local total_tables="$2"
    local total_issues="$3"
    local total_warnings="$4"
    local schema="${5:-public}"

    cat > "$output_file" <<EOF
# Supabase RLS Audit Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Schema:** $schema
**Total Tables:** $total_tables
**Critical Issues:** $total_issues
**Warnings:** $total_warnings

## Summary

EOF

    if [[ $total_issues -eq 0 ]]; then
        echo "✅ **All tables have RLS enabled with policies configured**" >> "$output_file"
    else
        echo "❌ **$total_issues critical security issue(s) found**" >> "$output_file"
    fi

    if [[ $total_warnings -gt 0 ]]; then
        echo "" >> "$output_file"
        echo "⚠️ **$total_warnings warning(s) - review recommended**" >> "$output_file"
    fi

    cat >> "$output_file" <<EOF

## Recommendations

### Critical Issues
- **RLS Not Enabled**: Tables without RLS are exposed via API
- **No Policies**: Tables with RLS but no policies deny all access

### Performance Optimizations
- Add indexes on columns used in policies (user_id, organization_id)
- Wrap auth functions in SELECT: \`(SELECT auth.uid())\`
- Filter queries explicitly in client code

### Testing
\`\`\`bash
# Test all policies
bash scripts/test-rls-policies.sh <table_name>
\`\`\`

## Detailed Findings

EOF

    log_info "Markdown report generated: $output_file"
}

main() {
    local schema="public"
    local report_file=""
    local specific_tables=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --report)
                report_file="$2"
                shift 2
                ;;
            --schema)
                schema="$2"
                shift 2
                ;;
            --help|-h)
                usage
                ;;
            *)
                specific_tables+=("$1")
                shift
                ;;
        esac
    done

    check_prerequisites

    log_info "Starting RLS audit for schema: $schema"
    echo

    # Get tables to audit
    local tables=()
    if [[ ${#specific_tables[@]} -gt 0 ]]; then
        tables=("${specific_tables[@]}")
    else
        mapfile -t tables < <(get_all_tables "$schema")
    fi

    if [[ ${#tables[@]} -eq 0 ]]; then
        log_error "No tables found to audit"
        exit 1
    fi

    log_info "Auditing ${#tables[@]} table(s)"
    echo

    local total_issues=0
    local total_warnings=0
    local results=()

    # Audit each table
    for table in "${tables[@]}"; do
        if [[ -n "$table" ]]; then
            result=$(audit_table "$table")
            results+=("$table:$result")

            IFS=':' read -r issues warnings <<< "$result"
            total_issues=$((total_issues + issues))
            total_warnings=$((total_warnings + warnings))
        fi
    done

    # Generate report if requested
    if [[ -n "$report_file" ]]; then
        generate_markdown_report "$report_file" "${#tables[@]}" "$total_issues" "$total_warnings" "$schema"
        echo >> "$report_file"

        for result in "${results[@]}"; do
            IFS=':' read -r tbl issues warnings <<< "$result"
            if [[ "$issues" -gt 0 ]] || [[ "$warnings" -gt 0 ]]; then
                echo "### $tbl" >> "$report_file"
                if [[ "$issues" -gt 0 ]]; then
                    echo "- ❌ $issues critical issue(s)" >> "$report_file"
                fi
                if [[ "$warnings" -gt 0 ]]; then
                    echo "- ⚠️ $warnings warning(s)" >> "$report_file"
                fi
                echo >> "$report_file"
            fi
        done
    fi

    # Summary
    echo "========================================"
    echo "AUDIT SUMMARY"
    echo "========================================"
    log_info "Tables audited: ${#tables[@]}"

    if [[ $total_issues -gt 0 ]]; then
        log_critical "Critical issues: $total_issues"
    else
        log_info "Critical issues: 0"
    fi

    if [[ $total_warnings -gt 0 ]]; then
        log_warn "Warnings: $total_warnings"
    else
        log_info "Warnings: 0"
    fi

    echo

    if [[ $total_issues -eq 0 ]]; then
        log_info "Audit passed! All tables properly secured."
        exit 0
    else
        log_error "Audit failed! Fix critical issues before deploying."
        exit 1
    fi
}

main "$@"
