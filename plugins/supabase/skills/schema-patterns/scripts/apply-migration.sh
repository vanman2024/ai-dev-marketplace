#!/bin/bash
# Apply database migration with validation
# Usage: ./apply-migration.sh <schema-file> <migration-name>

set -e

SCHEMA_FILE="${1}"
MIGRATION_NAME="${2}"

if [ -z "$SCHEMA_FILE" ] || [ -z "$MIGRATION_NAME" ]; then
    echo "Usage: $0 <schema-file> <migration-name>"
    echo ""
    echo "Example: $0 schema.sql 'add-chat-schema'"
    exit 1
fi

if [ ! -f "$SCHEMA_FILE" ]; then
    echo "Error: Schema file not found: $SCHEMA_FILE"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate schema first
echo "Step 1: Validating schema..."
if ! "$SCRIPT_DIR/validate-schema.sh" "$SCHEMA_FILE"; then
    echo ""
    echo "❌ Schema validation failed. Please fix errors before applying."
    exit 1
fi

echo ""
echo "Step 2: Creating migration file..."

# Create migrations directory if it doesn't exist
MIGRATIONS_DIR="./supabase/migrations"
if [ ! -d "$MIGRATIONS_DIR" ]; then
    mkdir -p "$MIGRATIONS_DIR"
    echo "Created migrations directory: $MIGRATIONS_DIR"
fi

# Generate timestamp for migration
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
MIGRATION_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_${MIGRATION_NAME}.sql"

# Copy schema to migration file
cp "$SCHEMA_FILE" "$MIGRATION_FILE"

echo "✓ Created migration: $MIGRATION_FILE"
echo ""

# Check if Supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo "⚠️  Supabase CLI not found"
    echo ""
    echo "To apply this migration:"
    echo "  1. Install Supabase CLI: npm install -g supabase"
    echo "  2. Link project: supabase link --project-ref <your-project-ref>"
    echo "  3. Apply migration: supabase db push"
    echo ""
    echo "Or copy the SQL from: $MIGRATION_FILE"
    echo "And run it in Supabase SQL Editor"
    exit 0
fi

# Check if project is linked
if [ ! -f "./.supabase/config.toml" ]; then
    echo "⚠️  Supabase project not linked"
    echo ""
    echo "To apply this migration:"
    echo "  1. Link project: supabase link --project-ref <your-project-ref>"
    echo "  2. Apply migration: supabase db push"
    exit 0
fi

# Ask for confirmation
echo "Step 3: Ready to apply migration"
echo ""
echo "Migration file: $MIGRATION_FILE"
echo "Project: $(grep 'project_id' ./.supabase/config.toml | cut -d'"' -f2)"
echo ""
read -p "Apply this migration? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Migration not applied. File saved at: $MIGRATION_FILE"
    exit 0
fi

# Apply migration
echo ""
echo "Step 4: Applying migration..."
if supabase db push; then
    echo ""
    echo "✅ Migration applied successfully!"
    echo ""
    echo "Next steps:"
    echo "  - Verify in Supabase Dashboard: Table Editor"
    echo "  - Test queries in SQL Editor"
    echo "  - (Optional) Seed data: ./scripts/seed-data.sh <pattern-type>"
else
    echo ""
    echo "❌ Migration failed. Check error messages above."
    echo "The migration file is saved at: $MIGRATION_FILE"
    exit 1
fi
