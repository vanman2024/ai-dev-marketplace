#!/bin/bash
# Setup eval tracking in Supabase
# Usage: ./setup-tracking.sh

echo "🗄️ Setting up eval tracking..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run migration
supabase db push --file "$SCRIPT_DIR/../templates/schema.sql"

echo "✅ Eval tracking tables created"
