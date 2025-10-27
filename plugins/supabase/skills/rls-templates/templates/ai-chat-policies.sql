-- AI Chat Application RLS Policies
-- Pattern: Conversation ownership with message hierarchy
-- Use for: AI chat apps, messaging systems, conversation history, chatbots

-- ============================================
-- Table: conversations
-- ============================================
-- Users own conversations directly

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);

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

-- UPDATE: Users can update their own conversations (title, metadata)
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

-- ============================================
-- Table: messages
-- ============================================
-- Messages belong to conversations, inherit ownership

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- SELECT: Users can view messages from their conversations
CREATE POLICY "messages_select_own_conversations" ON messages
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = (SELECT auth.uid())
        )
    );

-- INSERT: Users can create messages in their conversations
CREATE POLICY "messages_insert_own_conversations" ON messages
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = (SELECT auth.uid())
        )
    );

-- UPDATE: Users can update messages in their conversations
-- (e.g., editing, adding feedback, updating status)
CREATE POLICY "messages_update_own_conversations" ON messages
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = (SELECT auth.uid())
        )
    );

-- DELETE: Users can delete messages from their conversations
CREATE POLICY "messages_delete_own_conversations" ON messages
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = (SELECT auth.uid())
        )
    );

-- ============================================
-- Optional Table: conversation_participants
-- ============================================
-- For shared conversations (multiple users)

-- CREATE TABLE IF NOT EXISTS conversation_participants (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
--     user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--     role TEXT DEFAULT 'participant',
--     created_at TIMESTAMPTZ DEFAULT NOW(),
--     UNIQUE(conversation_id, user_id)
-- );

-- ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

-- CREATE INDEX IF NOT EXISTS idx_participants_conversation_id
--     ON conversation_participants(conversation_id);
-- CREATE INDEX IF NOT EXISTS idx_participants_user_id
--     ON conversation_participants(user_id);

-- -- SELECT: Users can view participants in their conversations
-- CREATE POLICY "participants_select_member_conversations" ON conversation_participants
--     FOR SELECT
--     TO authenticated
--     USING (
--         EXISTS (
--             SELECT 1
--             FROM conversation_participants cp
--             WHERE cp.conversation_id = conversation_participants.conversation_id
--             AND cp.user_id = (SELECT auth.uid())
--         )
--     );

-- ============================================
-- Shared Conversations Alternative Policy
-- ============================================
-- If using conversation_participants for shared access

-- DROP POLICY IF EXISTS "conversations_select_own" ON conversations;
-- CREATE POLICY "conversations_select_participant" ON conversations
--     FOR SELECT
--     TO authenticated
--     USING (
--         user_id = (SELECT auth.uid())  -- Owner
--         OR EXISTS (                      -- Or participant
--             SELECT 1
--             FROM conversation_participants
--             WHERE conversation_id = conversations.id
--             AND user_id = (SELECT auth.uid())
--         )
--     );

-- ============================================
-- Performance Optimization Function
-- ============================================
-- Cache conversation ownership check for complex queries

CREATE OR REPLACE FUNCTION auth.owns_conversation(conv_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM conversations
        WHERE id = conv_id
        AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Usage in policies:
-- USING (auth.owns_conversation(conversation_id))

-- ============================================
-- Notes:
-- ============================================
-- 1. Messages inherit security from conversations table
-- 2. Add indexes on created_at for efficient pagination
-- 3. Consider partitioning messages table by created_at for large datasets
-- 4. Use conversation_participants for shared/collaborative chat
-- 5. Always filter in queries: .eq('conversation_id', convId)
-- 6. Consider soft deletes (deleted_at) instead of hard deletes
-- 7. Add message.user_id if you need to track message authorship separately
