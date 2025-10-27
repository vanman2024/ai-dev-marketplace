#!/bin/bash
# Audit RLS coverage across all public tables

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

REPORT_FILE=""; FORMAT="text"; SCHEMA="public"; ISSUES=0

[ -f .env ] && source .env

while [[ $# -gt 0 ]]; do
    case $1 in
        --report) REPORT_FILE="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --schema) SCHEMA="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --report FILE    Generate report to FILE"
            echo "  --format FMT     Output format: text, markdown, json (default: text)"
            echo "  --schema SCHEMA  Schema to audit (default: public)"
            exit 0
            ;;
        *) shift ;;
    esac
done

[ -z "${SUPABASE_DB_URL:-}" ] && echo -e "${RED}Error: SUPABASE_DB_URL not set${NC}" && exit 1

execute_sql() { psql "$SUPABASE_DB_URL" -t -A -c "$1" 2>&1; }

init_report() {
    if [ -n "$REPORT_FILE" ]; then
        if [ "$FORMAT" = "markdown" ]; then
            echo "# RLS Coverage Audit Report" > "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "**Schema:** $SCHEMA" >> "$REPORT_FILE"
            echo "**Generated:** $(date)" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        elif [ "$FORMAT" = "json" ]; then
            echo "{\"schema\":\"$SCHEMA\",\"generated\":\"$(date -Iseconds)\",\"tables\":[" > "$REPORT_FILE"
        else
            echo "RLS Coverage Audit Report" > "$REPORT_FILE"
            echo "Schema: $SCHEMA" >> "$REPORT_FILE"
            echo "Generated: $(date)" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    fi
}

check_table_rls() {
    local table=$1

    # Check if RLS is enabled
    local rls_enabled=$(execute_sql "
        SELECT relrowsecurity::int
        FROM pg_class
        WHERE oid = '$SCHEMA.$table'::regclass;
    ")

    # Count policies by type
    local select_policies=$(execute_sql "SELECT COUNT(*) FROM pg_policies WHERE schemaname='$SCHEMA' AND tablename='$table' AND cmd='SELECT';")
    local insert_policies=$(execute_sql "SELECT COUNT(*) FROM pg_policies WHERE schemaname='$SCHEMA' AND tablename='$table' AND cmd='INSERT';")
    local update_policies=$(execute_sql "SELECT COUNT(*) FROM pg_policies WHERE schemaname='$SCHEMA' AND tablename='$table' AND cmd='UPDATE';")
    local delete_policies=$(execute_sql "SELECT COUNT(*) FROM pg_policies WHERE schemaname='$SCHEMA' AND tablename='$table' AND cmd='DELETE';")

    local status="OK"
    local warnings=()

    if [ "$rls_enabled" != "1" ]; then
        status="CRITICAL"
        warnings+=("RLS not enabled")
        ((ISSUES++))
    fi

    if [ "$select_policies" = "0" ]; then
        status="WARNING"
        warnings+=("No SELECT policy")
        ((ISSUES++))
    fi

    if [ "$insert_policies" = "0" ]; then
        status="WARNING"
        warnings+=("No INSERT policy")
        ((ISSUES++))
    fi

    if [ "$update_policies" = "0" ]; then
        status="WARNING"
        warnings+=("No UPDATE policy")
        ((ISSUES++))
    fi

    if [ "$delete_policies" = "0" ]; then
        status="WARNING"
        warnings+=("No DELETE policy")
        ((ISSUES++))
    fi

    # Output results
    if [ "$FORMAT" = "markdown" ] && [ -n "$REPORT_FILE" ]; then
        echo "### $table" >> "$REPORT_FILE"
        echo "- **Status:** $status" >> "$REPORT_FILE"
        echo "- **RLS Enabled:** $([ "$rls_enabled" = "1" ] && echo "✓" || echo "✗")" >> "$REPORT_FILE"
        echo "- **Policies:** SELECT($select_policies) INSERT($insert_policies) UPDATE($update_policies) DELETE($delete_policies)" >> "$REPORT_FILE"
        [ ${#warnings[@]} -gt 0 ] && echo "- **Issues:** ${warnings[*]}" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    elif [ "$FORMAT" = "json" ] && [ -n "$REPORT_FILE" ]; then
        cat >> "$REPORT_FILE" <<EOF
{"table":"$table","status":"$status","rls_enabled":$rls_enabled,"policies":{"select":$select_policies,"insert":$insert_policies,"update":$update_policies,"delete":$delete_policies},"warnings":[$(printf '"%s",' "${warnings[@]}" | sed 's/,$//')]}$([ "$table" != "$last_table" ] && echo "," || echo "")
EOF
    else
        if [ "$status" = "CRITICAL" ]; then
            echo -e "${RED}✗ $table: ${warnings[*]}${NC}"
        elif [ "$status" = "WARNING" ]; then
            echo -e "${YELLOW}⚠ $table: ${warnings[*]}${NC}"
        else
            echo -e "${GREEN}✓ $table: All policies present${NC}"
        fi
    fi
}

# Main execution
echo -e "${BLUE}🔍 RLS Coverage Audit${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

init_report

# Get all tables in schema
tables=($(execute_sql "SELECT tablename FROM pg_tables WHERE schemaname='$SCHEMA' ORDER BY tablename;" | tr '\n' ' '))
last_table="${tables[-1]}"

echo -e "${BLUE}Auditing ${#tables[@]} tables in schema '$SCHEMA'...${NC}"
echo ""

for table in "${tables[@]}"; do
    check_table_rls "$table"
done

# Close JSON if needed
[ "$FORMAT" = "json" ] && [ -n "$REPORT_FILE" ] && echo "],\"issues\":$ISSUES}" >> "$REPORT_FILE"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Audit Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Tables audited: ${#tables[@]}"
echo -e "  Issues found: $ISSUES"
echo ""

if [ $ISSUES -gt 0 ]; then
    echo -e "${RED}❌ RLS coverage issues detected${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All tables have proper RLS coverage${NC}"
    exit 0
fi
