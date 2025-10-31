# Complete AI Application Schema Example

This document demonstrates a complete database schema for a production AI application combining all patterns: user management, multi-tenancy, chat, RAG, and usage tracking.

## Architecture Overview

```
AI Application Database
├── User Management (auth.users + profiles)
├── Multi-Tenancy (organizations + teams)
├── Chat System (conversations + messages)
├── RAG System (documents + embeddings)
└── Usage Tracking (API calls + costs)
```

## Schema Generation

Generate the complete schema:

```bash
cd /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/schema-patterns
./scripts/generate-schema.sh complete complete-schema.sql
./scripts/validate-schema.sh complete-schema.sql
./scripts/apply-migration.sh complete-schema.sql "complete-ai-platform"
```

## Entity Relationships

### User Flow
1. User signs up → `auth.users`
2. Profile created → `user_profiles`, `user_preferences`
3. Joins/creates organization → `organizations`, `organization_members`
4. Creates conversations → `conversations`, `conversation_participants`
5. Uploads documents → `documents`, `document_chunks` (with embeddings)
6. Makes API calls → `api_usage`, `token_usage_summary`

### Data Flow Example

```sql
-- 1. User signup (handled by Supabase Auth)
-- Automatically triggers user_profiles and user_preferences creation

-- 2. Create organization
insert into organizations (name, slug, created_by)
values ('Acme AI Corp', 'acme-ai', auth.uid())
returning id;

-- 3. Add team member
insert into organization_members (organization_id, user_id, role)
values ('<org-id>', '<user-id>', 'member');

-- 4. Create conversation
insert into conversations (title, created_by, type)
values ('Project Discussion', auth.uid(), 'group')
returning id;

-- 5. Add participants
insert into conversation_participants (conversation_id, user_id)
values
    ('<conv-id>', auth.uid())
    ('<conv-id>', '<other-user-id>');

-- 6. Send message
insert into messages (conversation_id, user_id, content)
values ('<conv-id>', auth.uid(), 'Hello team!');

-- 7. Upload document for RAG
insert into documents (title, content, created_by, collection_id)
values (
    'Product Requirements'
    'Our AI product needs...'
    auth.uid()
    '<collection-id>'
)
returning id;

-- 8. Create document chunks with embeddings
insert into document_chunks (document_id, content, chunk_index, embedding)
values (
    '<doc-id>'
    'Our AI product needs real-time chat'
    0
    '<embedding-vector>'
);

-- 9. Perform semantic search
select * from search_documents(
    '<query-embedding>'::vector(384)
    0.7,  -- similarity threshold
    10,   -- max results
    '<collection-id>'
);

-- 10. Track API usage
insert into api_usage (
    user_id
    organization_id
    endpoint
    model_name
    tokens_input
    tokens_output
    cost_usd
)
values (
    auth.uid()
    '<org-id>'
    '/chat/completions'
    'gpt-4'
    1500
    500
    0.06
);
```

## Common Queries

### User Dashboard Stats

```sql
-- Get user's complete dashboard data
select
    -- User info
    u.email
    up.full_name
    up.avatar_url
    -- Organization membership
    (
        select jsonb_agg(jsonb_build_object(
            'id', o.id
            'name', o.name
            'role', om.role
        ))
        from organizations o
        join organization_members om on om.organization_id = o.id
        where om.user_id = u.id
    ) as organizations
    -- Conversation count
    (
        select count(distinct c.id)
        from conversations c
        join conversation_participants cp on cp.conversation_id = c.id
        where cp.user_id = u.id
    ) as conversation_count
    -- Unread messages
    (
        select count(*)
        from messages m
        join conversation_participants cp on cp.conversation_id = m.conversation_id
        where cp.user_id = u.id
          and m.created_at > coalesce(cp.last_read_at, '1970-01-01'::timestamp)
          and m.user_id != u.id
    ) as unread_count
    -- Document count
    (
        select count(*)
        from documents d
        where d.created_by = u.id
          and d.deleted_at is null
    ) as document_count
    -- Usage this month
    (
        select jsonb_build_object(
            'tokens', sum(tokens_used)
            'cost_usd', sum(cost_usd)
            'requests', count(*)
        )
        from api_usage
        where user_id = u.id
          and created_at >= date_trunc('month', now())
    ) as usage_this_month

from auth.users u
left join user_profiles up on up.user_id = u.id
where u.id = auth.uid();
```

### Organization Analytics

```sql
-- Get organization-wide analytics
select
    o.name
    o.plan_type
    -- Member count
    (select count(*) from organization_members where organization_id = o.id) as member_count
    -- Team count
    (select count(*) from teams where organization_id = o.id) as team_count
    -- Total conversations
    (
        select count(*)
        from conversations c
        join conversation_participants cp on cp.conversation_id = c.id
        join organization_members om on om.user_id = cp.user_id
        where om.organization_id = o.id
    ) as total_conversations
    -- Total documents
    (
        select count(*)
        from documents d
        join organization_members om on om.user_id = d.created_by
        where om.organization_id = o.id
          and d.deleted_at is null
    ) as total_documents
    -- Usage this month
    (
        select jsonb_build_object(
            'tokens', sum(tokens_used)
            'cost_usd', sum(cost_usd)
            'requests', count(*)
            'by_user', jsonb_object_agg(u.email, user_usage)
        )
        from (
            select
                user_id
                jsonb_build_object(
                    'tokens', sum(tokens_used)
                    'cost', sum(cost_usd)
                ) as user_usage
            from api_usage
            where organization_id = o.id
              and created_at >= date_trunc('month', now())
            group by user_id
        ) usage
        join auth.users u on u.id = usage.user_id
    ) as usage_this_month

from organizations o
where o.id = '<org-id>';
```

### RAG Search with Context

```sql
-- Hybrid search across user's documents
select
    dc.id as chunk_id
    d.id as document_id
    d.title
    dc.content
    dc.chunk_index
    -- Semantic similarity
    1 - (dc.embedding <=> '<query-embedding>'::vector(384)) as semantic_score
    -- Keyword relevance
    ts_rank_cd(
        to_tsvector('english', dc.content)
        plainto_tsquery('english', '<search-query>')
    ) as keyword_score
    -- Combined score
    (
        (1 - (dc.embedding <=> '<query-embedding>'::vector(384))) * 0.7 +
        ts_rank_cd(
            to_tsvector('english', dc.content)
            plainto_tsquery('english', '<search-query>')
        ) * 0.3
    ) as combined_score

from document_chunks dc
join documents d on d.id = dc.document_id
join organization_members om on om.user_id = d.created_by
where om.organization_id = '<org-id>'
  and d.deleted_at is null
  and (
      1 - (dc.embedding <=> '<query-embedding>'::vector(384)) > 0.7
      or to_tsvector('english', dc.content) @@ plainto_tsquery('english', '<search-query>')
  )
order by combined_score desc
limit 10;
```

## Performance Optimization

### Critical Indexes

```sql
-- Most frequently accessed patterns

-- User lookups
create index idx_users_email on auth.users(email);

-- Organization member queries
create index idx_org_members_user_org on organization_members(user_id, organization_id);

-- Conversation participant queries
create index idx_conv_participants_user_conv on conversation_participants(user_id, conversation_id);

-- Message pagination
create index idx_messages_conv_created on messages(conversation_id, created_at desc);

-- Document search
create index idx_documents_org_created on documents(
    (select organization_id from organization_members where user_id = documents.created_by limit 1)
    created_at desc
);

-- Usage analytics
create index idx_api_usage_org_created on api_usage(organization_id, created_at desc) where organization_id is not null;
```

### Query Performance Tips

1. **Use proper JOINs**: Prefer EXISTS over IN for subqueries
2. **Limit result sets**: Always use LIMIT for pagination
3. **Filter early**: Apply WHERE clauses before JOINs when possible
4. **Use covering indexes**: Include frequently queried columns in indexes
5. **Partition large tables**: Consider partitioning `api_usage` by date
6. **Use materialized views**: For complex analytics queries

## Security Considerations

### RLS Policy Hierarchy

```
Organization Level
├── Owner: Full access to all org data
├── Admin: Manage members, teams, settings
├── Member: Access assigned resources
└── Viewer: Read-only access

Team Level
├── Lead: Manage team members and resources
└── Member: Access team resources

Resource Level
├── Created by user
└── Shared within organization/team
```

### Sensitive Data Handling

```sql
-- Never expose in queries:
-- - auth.users.encrypted_password
-- - user_connections.access_token_encrypted
-- - organization_api_keys.key_hash

-- Always use:
-- - Row Level Security (RLS)
-- - Encrypted columns for tokens
-- - Soft deletes (deleted_at) for audit trails
```

## Migration Strategy

### Initial Setup

```bash
# 1. Generate schema
./scripts/generate-schema.sh complete schema.sql

# 2. Validate
./scripts/validate-schema.sh schema.sql

# 3. Apply
./scripts/apply-migration.sh schema.sql "initial-setup"

# 4. Seed development data
./scripts/seed-data.sh complete
```

### Adding New Features

```bash
# 1. Create new migration
./scripts/generate-schema.sh <pattern> new-feature.sql

# 2. Validate
./scripts/validate-schema.sh new-feature.sql

# 3. Apply
./scripts/apply-migration.sh new-feature.sql "add-new-feature"
```

## Monitoring & Maintenance

### Regular Tasks

```sql
-- Cleanup expired sessions (daily)
select cleanup_expired_sessions();

-- Cleanup old typing indicators (every 5 minutes)
select cleanup_typing_indicators();

-- Aggregate usage summaries (hourly)
select aggregate_usage_summary('hour');

-- Generate daily/monthly summaries
select aggregate_usage_summary('day');
select aggregate_usage_summary('month');
```

### Health Checks

```sql
-- Check for missing indexes
select
    schemaname
    tablename
    indexname
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;

-- Check table sizes
select
    schemaname
    tablename
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
from pg_tables
where schemaname = 'public'
order by pg_total_relation_size(schemaname||'.'||tablename) desc;

-- Check RLS policies
select
    schemaname
    tablename
    policyname
    cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
```

## Next Steps

1. **Configure Realtime**: Enable realtime subscriptions for chat
2. **Setup Storage**: Add file storage for document uploads
3. **Add Edge Functions**: Implement business logic
4. **Configure Backups**: Setup automated backups
5. **Monitor Performance**: Use Supabase Dashboard analytics
