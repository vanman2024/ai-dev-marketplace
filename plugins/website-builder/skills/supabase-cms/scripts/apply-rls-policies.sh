#!/bin/bash
# Apply Row Level Security policies to Supabase tables

set -e

# Check for required arguments
if [ -z "$1" ]; then
  echo "Usage: ./apply-rls-policies.sh <policy-file.sql>"
  echo "Example: ./apply-rls-policies.sh templates/rls/draft-publish-policies.sql"
  exit 1
fi

POLICY_FILE=$1

# Check if policy file exists
if [ ! -f "$POLICY_FILE" ]; then
  echo "❌ Error: Policy file not found: $POLICY_FILE"
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

echo "🔒 Applying RLS policies: $POLICY_FILE"

# Extract project ID from URL
PROJECT_ID=$(echo $PUBLIC_SUPABASE_URL | sed -E 's/https:\/\/([^.]+).*/\1/')

# Apply policies using Supabase CLI
supabase db push --db-url "postgresql://postgres:$DB_PASSWORD@db.$PROJECT_ID.supabase.co:5432/postgres" < "$POLICY_FILE"

echo "✅ RLS policies applied successfully!"
echo ""
echo "⚠️  Important: Test your RLS policies before going to production"
echo "Run: ./scripts/test-rls-policies.sh"
