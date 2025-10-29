#!/bin/bash
# Apply database migration to Supabase

set -e

# Check for required arguments
if [ -z "$1" ]; then
  echo "Usage: ./apply-migration.sh <migration-file.sql>"
  echo "Example: ./apply-migration.sh templates/schemas/blog-schema.sql"
  exit 1
fi

MIGRATION_FILE=$1

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
  echo "❌ Error: Migration file not found: $MIGRATION_FILE"
  exit 1
fi

# Check for Supabase CLI
if ! command -v supabase &> /dev/null; then
  echo "❌ Error: Supabase CLI not found. Install it with: npm install -g supabase"
  exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
  echo "❌ Error: .env file not found. Run setup-supabase-cms.sh first"
  exit 1
fi

# Load environment variables
source .env

if [ -z "$PUBLIC_SUPABASE_URL" ] || [ -z "$PUBLIC_SUPABASE_ANON_KEY" ]; then
  echo "❌ Error: Supabase credentials not found in .env"
  exit 1
fi

echo "🚀 Applying migration: $MIGRATION_FILE"

# Extract project ID from URL
PROJECT_ID=$(echo $PUBLIC_SUPABASE_URL | sed -E 's/https:\/\/([^.]+).*/\1/')

# Apply migration using Supabase CLI
supabase db push --db-url "postgresql://postgres:$DB_PASSWORD@db.$PROJECT_ID.supabase.co:5432/postgres" < "$MIGRATION_FILE"

echo "✅ Migration applied successfully!"
echo ""
echo "Next steps:"
echo "1. Verify the migration in Supabase dashboard"
echo "2. Generate updated TypeScript types: npm run generate:types"
echo "3. Apply RLS policies if needed: ./scripts/apply-rls-policies.sh"
