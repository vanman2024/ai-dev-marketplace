#!/bin/bash
# Generate RLS policy from template
# Usage: generate-policy.sh <template> <table> [column]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 <template> <table> [column]

Templates:
  user-isolation      - User owns row (default column: user_id)
  multi-tenant        - Organization isolation (default column: organization_id)
  role-based-access   - Role-based permissions
  ai-chat            - Chat/conversation policies
  embeddings         - Vector/embedding policies

Examples:
  $0 user-isolation profiles
  $0 multi-tenant documents organization_id
  $0 ai-chat conversations
EOF
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

generate_user_isolation() {
    local table="$1"
    local column="${2:-user_id}"

    cat <<SQL
-- User Isolation RLS Policies for $table
-- Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

-- Enable RLS
ALTER TABLE $table ENABLE ROW LEVEL SECURITY;

-- Performance index
CREATE INDEX IF NOT EXISTS idx_${table}_${column} ON $table($column);

-- SELECT: Users can view their own records
CREATE POLICY "${table}_select_own" ON $table
    FOR SELECT
    TO authenticated
    USING ((SELECT auth.uid()) = $column);

-- INSERT: Users can create records for themselves
CREATE POLICY "${table}_insert_own" ON $table
    FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = $column);

-- UPDATE: Users can update their own records
CREATE POLICY "${table}_update_own" ON $table
    FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = $column)
    WITH CHECK ((SELECT auth.uid()) = $column);

-- DELETE: Users can delete their own records
CREATE POLICY "${table}_delete_own" ON $table
    FOR DELETE
    TO authenticated
    USING ((SELECT auth.uid()) = $column);
SQL
}

generate_multi_tenant() {
    local table="$1"
    local column="${2:-organization_id}"

    cat <<SQL
-- Multi-Tenant RLS Policies for $table
-- Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

-- Enable RLS
ALTER TABLE $table ENABLE ROW LEVEL SECURITY;

-- Performance index
CREATE INDEX IF NOT EXISTS idx_${table}_${column} ON $table($column);

-- Helper function to check organization membership
CREATE OR REPLACE FUNCTION auth.user_has_org_access(org_uuid UUID)
RETURNS BOOLEAN AS \$\$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM org_members
        WHERE user_id = auth.uid()
        AND organization_id = org_uuid
    );
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- SELECT: Users can view records in their organizations
CREATE POLICY "${table}_select_org" ON $table
    FOR SELECT
    TO authenticated
    USING (auth.user_has_org_access($column));

-- INSERT: Users can create records in their organizations
CREATE POLICY "${table}_insert_org" ON $table
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.user_has_org_access($column));

-- UPDATE: Users can update records in their organizations
CREATE POLICY "${table}_update_org" ON $table
    FOR UPDATE
    TO authenticated
    USING (auth.user_has_org_access($column))
    WITH CHECK (auth.user_has_org_access($column));

-- DELETE: Users can delete records in their organizations
CREATE POLICY "${table}_delete_org" ON $table
    FOR DELETE
    TO authenticated
    USING (auth.user_has_org_access($column));
SQL
}

generate_role_based() {
    local table="$1"

    cat <<SQL
-- Role-Based Access RLS Policies for $table
-- Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

-- Enable RLS
ALTER TABLE $table ENABLE ROW LEVEL SECURITY;

-- Helper function to get user role from JWT
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT AS \$\$
BEGIN
    RETURN COALESCE(
        auth.jwt() ->> 'user_role',
        auth.jwt() -> 'app_metadata' ->> 'role',
        'user'
    );
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- SELECT: All authenticated users can read
CREATE POLICY "${table}_select_authenticated" ON $table
    FOR SELECT
    TO authenticated
    USING (true);

-- INSERT: Users and above can create
CREATE POLICY "${table}_insert_users" ON $table
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.user_role() IN ('user', 'editor', 'admin'));

-- UPDATE: Editors and admins can update
CREATE POLICY "${table}_update_editors" ON $table
    FOR UPDATE
    TO authenticated
    USING (auth.user_role() IN ('editor', 'admin'))
    WITH CHECK (auth.user_role() IN ('editor', 'admin'));

-- DELETE: Only admins can delete
CREATE POLICY "${table}_delete_admins" ON $table
    FOR DELETE
    TO authenticated
    USING (auth.user_role() = 'admin');
SQL
}

generate_ai_chat() {
    local table="$1"

    if [[ "$table" == "conversations" ]]; then
        cat <<SQL
-- AI Chat RLS Policies for conversations
-- Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);

-- SELECT: Users can view their own conversations
CREATE POLICY "conversations_select_own" ON conversations
    FOR SELECT
    TO authenticated
    USING ((SELECT auth.uid()) = user_id);

-- INSERT: Users can create their own conversations
CREATE POLICY "conversations_insert_own" ON conversations
    FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- UPDATE: Users can update their own conversations
CREATE POLICY "conversations_update_own" ON conversations
    FOR UPDATE
    TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

-- DELETE: Users can delete their own conversations
CREATE POLICY "conversations_delete_own" ON conversations
    FOR DELETE
    TO authenticated
    USING ((SELECT auth.uid()) = user_id);
SQL
    elif [[ "$table" == "messages" ]]; then
        cat <<SQL
-- AI Chat RLS Policies for messages
-- Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);

-- SELECT: Users can view messages from their conversations
CREATE POLICY "messages_select_own_conversations" ON messages
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- INSERT: Users can create messages in their conversations
CREATE POLICY "messages_insert_own_conversations" ON messages
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- UPDATE: Users can update messages in their conversations
CREATE POLICY "messages_update_own_conversations" ON messages
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- DELETE: Users can delete messages from their conversations
CREATE POLICY "messages_delete_own_conversations" ON messages
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );
SQL
    fi
}

main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local template="$1"
    local table="$2"
    local column="${3:-}"

    log_info "Generating $template policy for table: $table"
    echo

    case "$template" in
        user-isolation)
            generate_user_isolation "$table" "$column"
            ;;
        multi-tenant)
            generate_multi_tenant "$table" "$column"
            ;;
        role-based-access)
            generate_role_based "$table"
            ;;
        ai-chat)
            generate_ai_chat "$table"
            ;;
        *)
            log_warn "Unknown template: $template"
            usage
            ;;
    esac

    echo
    log_info "Policy generated successfully!"
    log_info "Review the output and apply with: psql \$SUPABASE_DB_URL < generated.sql"
}

main "$@"
