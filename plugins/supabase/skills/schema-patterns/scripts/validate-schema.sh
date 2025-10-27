#!/bin/bash
# Validate database schema against best practices
# Usage: ./validate-schema.sh <schema-file>

set -e

SCHEMA_FILE="${1}"

if [ -z "$SCHEMA_FILE" ]; then
    echo "Usage: $0 <schema-file>"
    exit 1
fi

if [ ! -f "$SCHEMA_FILE" ]; then
    echo "Error: Schema file not found: $SCHEMA_FILE"
    exit 1
fi

echo "Validating schema: $SCHEMA_FILE"
echo "================================================"

ERRORS=0
WARNINGS=0

# Check 1: Proper naming conventions (lowercase, underscores)
echo -n "✓ Checking naming conventions... "
UPPERCASE_TABLES=$(grep -iE "create table [A-Z]" "$SCHEMA_FILE" | grep -v "if not exists" || true)
if [ -n "$UPPERCASE_TABLES" ]; then
    echo "FAIL"
    echo "  Error: Table names should be lowercase with underscores"
    echo "$UPPERCASE_TABLES" | sed 's/^/    /'
    ERRORS=$((ERRORS + 1))
else
    echo "OK"
fi

# Check 2: All tables have primary keys
echo -n "✓ Checking primary keys... "
TABLES_WITHOUT_PK=$(grep -i "create table" "$SCHEMA_FILE" | grep -v "if not exists" | while read -r line; do
    TABLE_NAME=$(echo "$line" | grep -oP '(?<=create table )(\w+)' || echo "")
    if [ -n "$TABLE_NAME" ]; then
        if ! grep -q "primary key" "$SCHEMA_FILE" 2>/dev/null || ! grep -A 20 "create table $TABLE_NAME" "$SCHEMA_FILE" | grep -q "primary key"; then
            echo "$TABLE_NAME"
        fi
    fi
done)

if [ -n "$TABLES_WITHOUT_PK" ]; then
    echo "FAIL"
    echo "  Error: Tables without primary keys:"
    echo "$TABLES_WITHOUT_PK" | sed 's/^/    /'
    ERRORS=$((ERRORS + 1))
else
    echo "OK"
fi

# Check 3: Foreign key relationships use proper syntax
echo -n "✓ Checking foreign key syntax... "
FK_ERRORS=$(grep -i "foreign key\|references" "$SCHEMA_FILE" | grep -v "on delete\|on update" || true)
if [ -n "$FK_ERRORS" ]; then
    echo "WARNING"
    echo "  Warning: Foreign keys should specify ON DELETE/ON UPDATE behavior"
    WARNINGS=$((WARNINGS + 1))
else
    echo "OK"
fi

# Check 4: Vector columns use proper syntax (if pgvector is used)
if grep -q "vector(" "$SCHEMA_FILE"; then
    echo -n "✓ Checking pgvector usage... "

    # Check if extension is enabled
    if ! grep -q "create extension.*vector" "$SCHEMA_FILE"; then
        echo "FAIL"
        echo "  Error: pgvector extension not enabled (missing: create extension if not exists vector;)"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK"
    fi

    # Check for proper indexing
    echo -n "✓ Checking vector indexes... "
    if ! grep -q "using hnsw\|using ivfflat" "$SCHEMA_FILE"; then
        echo "WARNING"
        echo "  Warning: No vector indexes found. Consider adding HNSW or IVFFlat indexes for similarity search"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "OK"
    fi
fi

# Check 5: Timestamps use proper defaults
echo -n "✓ Checking timestamp defaults... "
TIMESTAMP_FIELDS=$(grep -i "timestamp" "$SCHEMA_FILE" | grep -v "default\|generated" || true)
if [ -n "$TIMESTAMP_FIELDS" ]; then
    echo "WARNING"
    echo "  Warning: Timestamp fields should have defaults (e.g., default now())"
    WARNINGS=$((WARNINGS + 1))
else
    echo "OK"
fi

# Check 6: UUIDs use proper defaults
echo -n "✓ Checking UUID defaults... "
UUID_FIELDS=$(grep -i "uuid" "$SCHEMA_FILE" | grep "primary key" | grep -v "default\|generated" || true)
if [ -n "$UUID_FIELDS" ]; then
    echo "WARNING"
    echo "  Warning: UUID primary keys should have defaults (e.g., default uuid_generate_v4())"
    WARNINGS=$((WARNINGS + 1))
else
    echo "OK"
fi

# Check 7: Indexes on foreign keys
echo -n "✓ Checking foreign key indexes... "
# This is a heuristic check - proper validation requires parsing SQL
FK_COLUMNS=$(grep -i "references" "$SCHEMA_FILE" | grep -oP '\w+(?=\s+\w+\s+references)' || true)
MISSING_FK_INDEXES=""
for col in $FK_COLUMNS; do
    if ! grep -q "create index.*$col" "$SCHEMA_FILE"; then
        MISSING_FK_INDEXES="$MISSING_FK_INDEXES $col"
    fi
done

if [ -n "$MISSING_FK_INDEXES" ]; then
    echo "WARNING"
    echo "  Warning: Consider adding indexes on foreign key columns:$MISSING_FK_INDEXES"
    WARNINGS=$((WARNINGS + 1))
else
    echo "OK"
fi

# Check 8: RLS policies (if tables are created)
if grep -q "create table" "$SCHEMA_FILE"; then
    echo -n "✓ Checking RLS policies... "
    if ! grep -q "alter table.*enable row level security\|create policy" "$SCHEMA_FILE"; then
        echo "WARNING"
        echo "  Warning: No RLS policies found. Consider adding row level security for production"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "OK"
    fi
fi

# Summary
echo "================================================"
echo "Validation complete:"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ Schema validation failed with $ERRORS error(s)"
    echo "Please fix errors before applying migration"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo ""
    echo "⚠️  Schema validation passed with $WARNINGS warning(s)"
    echo "Review warnings before applying to production"
    exit 0
else
    echo ""
    echo "✅ Schema validation passed"
    exit 0
fi
