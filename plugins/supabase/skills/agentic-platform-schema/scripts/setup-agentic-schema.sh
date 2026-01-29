#!/bin/bash
# Setup agentic platform schema in Supabase
# Usage: ./setup-agentic-schema.sh

echo "🗄️ Setting up agentic platform schema..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run migration
supabase db push --file "$SCRIPT_DIR/../templates/agentic-schema.sql"

echo "✅ Agentic platform tables created:"
echo "   - agent_runs"
echo "   - agent_events"
echo "   - agent_artifacts"
echo "   - agent_tool_calls"
