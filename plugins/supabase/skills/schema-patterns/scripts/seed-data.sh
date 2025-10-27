#!/bin/bash
# Generate and insert seed data for testing
# Usage: ./seed-data.sh <pattern-type>

set -e

PATTERN_TYPE="${1}"

if [ -z "$PATTERN_TYPE" ]; then
    echo "Usage: $0 <pattern-type>"
    echo ""
    echo "Pattern types:"
    echo "  chat              - Generate sample conversations and messages"
    echo "  rag               - Generate sample documents with embeddings"
    echo "  multi-tenant      - Generate sample organizations and members"
    echo "  user-management   - Generate sample user profiles"
    echo "  ai-usage          - Generate sample usage records"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_FILE="/tmp/seed_${PATTERN_TYPE}_$(date +%s).sql"

echo "Generating seed data for: $PATTERN_TYPE"
echo "================================================"

# Generate seed SQL based on pattern type
case "$PATTERN_TYPE" in
    chat)
        cat > "$SEED_FILE" << 'EOF'
-- Seed data for chat schema
-- Users
insert into users (id, email, username, full_name)
values
    ('00000000-0000-0000-0000-000000000001'::uuid, 'alice@example.com', 'alice', 'Alice Johnson'),
    ('00000000-0000-0000-0000-000000000002'::uuid, 'bob@example.com', 'bob', 'Bob Smith'),
    ('00000000-0000-0000-0000-000000000003'::uuid, 'carol@example.com', 'carol', 'Carol Williams')
on conflict (id) do nothing;

-- Conversations
insert into conversations (id, title, created_by)
values
    ('10000000-0000-0000-0000-000000000001'::uuid, 'Project Discussion', '00000000-0000-0000-0000-000000000001'::uuid),
    ('10000000-0000-0000-0000-000000000002'::uuid, 'Team Standup', '00000000-0000-0000-0000-000000000002'::uuid)
on conflict (id) do nothing;

-- Conversation Participants
insert into conversation_participants (conversation_id, user_id)
values
    ('10000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid),
    ('10000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000002'::uuid),
    ('10000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000002'::uuid),
    ('10000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000003'::uuid)
on conflict (conversation_id, user_id) do nothing;

-- Messages
insert into messages (conversation_id, user_id, content)
values
    ('10000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'Hey team, lets discuss the new feature'),
    ('10000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'Sounds good! What are the requirements?'),
    ('10000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'We need to add chat functionality with real-time updates'),
    ('10000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'Good morning everyone!'),
    ('10000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'Morning! Ready for todays sprint.');
EOF
        ;;

    rag)
        cat > "$SEED_FILE" << 'EOF'
-- Seed data for RAG schema
-- Documents
insert into documents (id, title, content, source_url)
values
    ('20000000-0000-0000-0000-000000000001'::uuid, 'Introduction to AI', 'Artificial intelligence (AI) is intelligence demonstrated by machines...', 'https://example.com/ai-intro'),
    ('20000000-0000-0000-0000-000000000002'::uuid, 'Machine Learning Basics', 'Machine learning is a subset of AI that enables systems to learn from data...', 'https://example.com/ml-basics'),
    ('20000000-0000-0000-0000-000000000003'::uuid, 'Neural Networks Explained', 'Neural networks are computing systems inspired by biological neural networks...', 'https://example.com/neural-nets')
on conflict (id) do nothing;

-- Document Chunks (with placeholder embeddings - replace with real embeddings in production)
insert into document_chunks (id, document_id, content, chunk_index, embedding)
values
    ('21000000-0000-0000-0000-000000000001'::uuid, '20000000-0000-0000-0000-000000000001'::uuid,
     'Artificial intelligence (AI) is intelligence demonstrated by machines, in contrast to natural intelligence.',
     0,
     array_fill(0, ARRAY[384])::vector(384)),
    ('21000000-0000-0000-0000-000000000002'::uuid, '20000000-0000-0000-0000-000000000002'::uuid,
     'Machine learning is a subset of AI that enables systems to learn and improve from experience.',
     0,
     array_fill(0, ARRAY[384])::vector(384)),
    ('21000000-0000-0000-0000-000000000003'::uuid, '20000000-0000-0000-0000-000000000003'::uuid,
     'Neural networks are computing systems inspired by biological neural networks in animal brains.',
     0,
     array_fill(0, ARRAY[384])::vector(384))
on conflict (id) do nothing;

-- Note: In production, generate real embeddings using an embedding model
-- Example with OpenAI: embedding = openai.Embedding.create(input=content)['data'][0]['embedding']
EOF
        ;;

    multi-tenant)
        cat > "$SEED_FILE" << 'EOF'
-- Seed data for multi-tenant schema
-- Organizations
insert into organizations (id, name, slug, plan_type)
values
    ('30000000-0000-0000-0000-000000000001'::uuid, 'Acme Corporation', 'acme-corp', 'enterprise'),
    ('30000000-0000-0000-0000-000000000002'::uuid, 'Tech Startup Inc', 'tech-startup', 'pro'),
    ('30000000-0000-0000-0000-000000000003'::uuid, 'Freelance Agency', 'freelance-agency', 'free')
on conflict (id) do nothing;

-- Teams
insert into teams (id, organization_id, name, description)
values
    ('31000000-0000-0000-0000-000000000001'::uuid, '30000000-0000-0000-0000-000000000001'::uuid, 'Engineering', 'Product development team'),
    ('31000000-0000-0000-0000-000000000002'::uuid, '30000000-0000-0000-0000-000000000001'::uuid, 'Marketing', 'Marketing and growth team'),
    ('31000000-0000-0000-0000-000000000003'::uuid, '30000000-0000-0000-0000-000000000002'::uuid, 'Development', 'Core dev team')
on conflict (id) do nothing;

-- Organization Members
insert into organization_members (organization_id, user_id, role)
values
    ('30000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'owner'),
    ('30000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'admin'),
    ('30000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'member'),
    ('30000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'owner')
on conflict (organization_id, user_id) do nothing;

-- Team Members
insert into team_members (team_id, user_id, role)
values
    ('31000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000001'::uuid, 'lead'),
    ('31000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'member'),
    ('31000000-0000-0000-0000-000000000002'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'member')
on conflict (team_id, user_id) do nothing;
EOF
        ;;

    user-management)
        cat > "$SEED_FILE" << 'EOF'
-- Seed data for user management schema
-- User Profiles
insert into user_profiles (user_id, bio, avatar_url, timezone, language)
values
    ('00000000-0000-0000-0000-000000000001'::uuid, 'Software engineer passionate about AI', 'https://i.pravatar.cc/150?u=alice', 'America/New_York', 'en'),
    ('00000000-0000-0000-0000-000000000002'::uuid, 'Product manager and tech enthusiast', 'https://i.pravatar.cc/150?u=bob', 'America/Los_Angeles', 'en'),
    ('00000000-0000-0000-0000-000000000003'::uuid, 'Designer focused on user experience', 'https://i.pravatar.cc/150?u=carol', 'Europe/London', 'en')
on conflict (user_id) do nothing;

-- User Preferences
insert into user_preferences (user_id, preferences)
values
    ('00000000-0000-0000-0000-000000000001'::uuid, '{"theme": "dark", "notifications": {"email": true, "push": true}, "privacy": {"profile_visible": true}}'::jsonb),
    ('00000000-0000-0000-0000-000000000002'::uuid, '{"theme": "light", "notifications": {"email": true, "push": false}, "privacy": {"profile_visible": true}}'::jsonb),
    ('00000000-0000-0000-0000-000000000003'::uuid, '{"theme": "auto", "notifications": {"email": false, "push": true}, "privacy": {"profile_visible": false}}'::jsonb)
on conflict (user_id) do nothing;
EOF
        ;;

    ai-usage)
        cat > "$SEED_FILE" << 'EOF'
-- Seed data for AI usage tracking schema
-- API Usage Records
insert into api_usage (user_id, endpoint, model_name, tokens_used, cost_usd)
values
    ('00000000-0000-0000-0000-000000000001'::uuid, '/chat/completions', 'gpt-4', 1500, 0.045),
    ('00000000-0000-0000-0000-000000000001'::uuid, '/chat/completions', 'gpt-4', 2300, 0.069),
    ('00000000-0000-0000-0000-000000000002'::uuid, '/embeddings', 'text-embedding-ada-002', 8000, 0.0008),
    ('00000000-0000-0000-0000-000000000002'::uuid, '/chat/completions', 'gpt-3.5-turbo', 1200, 0.0018),
    ('00000000-0000-0000-0000-000000000003'::uuid, '/chat/completions', 'claude-3-opus', 3000, 0.045);

-- Token Usage Summary
insert into token_usage_summary (user_id, period_start, period_end, total_tokens, total_cost_usd, request_count)
values
    ('00000000-0000-0000-0000-000000000001'::uuid,
     date_trunc('month', now()),
     date_trunc('month', now()) + interval '1 month',
     3800, 0.114, 2),
    ('00000000-0000-0000-0000-000000000002'::uuid,
     date_trunc('month', now()),
     date_trunc('month', now()) + interval '1 month',
     9200, 0.0026, 2),
    ('00000000-0000-0000-0000-000000000003'::uuid,
     date_trunc('month', now()),
     date_trunc('month', now()) + interval '1 month',
     3000, 0.045, 1)
on conflict (user_id, period_start) do update
    set total_tokens = excluded.total_tokens,
        total_cost_usd = excluded.total_cost_usd,
        request_count = excluded.request_count;
EOF
        ;;

    *)
        echo "Error: Invalid pattern type '$PATTERN_TYPE'"
        exit 1
        ;;
esac

echo "✓ Generated seed SQL: $SEED_FILE"
echo ""

# Check if Supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo "⚠️  Supabase CLI not found"
    echo ""
    echo "To apply seed data:"
    echo "  1. Copy SQL from: $SEED_FILE"
    echo "  2. Run in Supabase SQL Editor"
    echo ""
    echo "Or install Supabase CLI: npm install -g supabase"
    exit 0
fi

# Check if project is linked
if [ ! -f "./.supabase/config.toml" ]; then
    echo "⚠️  Supabase project not linked"
    echo ""
    echo "To apply seed data:"
    echo "  1. Link project: supabase link --project-ref <your-project-ref>"
    echo "  2. Run: supabase db execute --file $SEED_FILE"
    exit 0
fi

# Ask for confirmation
echo "Ready to insert seed data"
read -p "Apply seed data? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Seed data not applied. File saved at: $SEED_FILE"
    exit 0
fi

# Apply seed data
echo ""
echo "Applying seed data..."
if supabase db execute --file "$SEED_FILE"; then
    echo ""
    echo "✅ Seed data inserted successfully!"
    echo ""
    echo "Verify in Supabase Dashboard: Table Editor"
    rm "$SEED_FILE"
else
    echo ""
    echo "❌ Seed data insertion failed. Check error messages above."
    echo "The seed file is saved at: $SEED_FILE"
    exit 1
fi
