#!/bin/bash
# Generate TypeScript types from Supabase database schema

set -e

echo "🔄 Generating TypeScript types from Supabase..."

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

if [ -z "$PUBLIC_SUPABASE_URL" ]; then
  echo "❌ Error: PUBLIC_SUPABASE_URL not found in .env"
  exit 1
fi

# Extract project ID from URL
PROJECT_ID=$(echo $PUBLIC_SUPABASE_URL | sed -E 's/https:\/\/([^.]+).*/\1/')

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: Could not extract project ID from URL"
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p src/lib/supabase

# Generate types
echo "📝 Generating types for project: $PROJECT_ID"
supabase gen types typescript --project-id "$PROJECT_ID" > src/lib/supabase/database.types.ts

echo "✅ TypeScript types generated successfully!"
echo "📁 Location: src/lib/supabase/database.types.ts"
echo ""
echo "You can now import types in your code:"
echo "import type { Database } from '@/lib/supabase/database.types';"
