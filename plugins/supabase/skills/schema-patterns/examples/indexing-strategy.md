# Indexing Strategy for AI Applications

Comprehensive guide to database indexing for optimal performance in AI applications with chat, RAG, and analytics.

## Index Types Overview

### 1. B-Tree Indexes (Default)

**Best for**: Equality and range queries, sorting

```sql
-- Single column
create index idx_users_email on public.users(email);

-- Multi-column (order matters!)
create index idx_messages_conv_created
on public.messages(conversation_id, created_at desc);

-- Partial index (filtered)
create index idx_documents_active
on public.documents(created_at desc)
where deleted_at is null;

-- Expression index
create index idx_users_email_lower
on public.users(lower(email));
```

### 2. HNSW Indexes (Vector Similarity)

**Best for**: Semantic search, embedding similarity

```sql
-- For vector similarity search
create index idx_chunks_embedding_hnsw
on public.document_chunks
using hnsw (embedding vector_cosine_ops)
with (m = 16, ef_construction = 64);

-- Parameters:
-- m = max connections per node (16-48, higher = more accurate but slower)
-- ef_construction = candidates during build (64-256, higher = better quality)
```

### 3. IVFFlat Indexes (Vector Similarity, Alternative)

**Best for**: Large datasets where build time matters

```sql
-- Faster to build, slower to query than HNSW
create index idx_chunks_embedding_ivfflat
on public.document_chunks
using ivfflat (embedding vector_cosine_ops)
with (lists = 100);

-- Lists = number of clusters (sqrt of row count is good starting point)
-- For 10,000 rows: lists = 100
-- For 100,000 rows: lists = 316
-- For 1,000,000 rows: lists = 1000
```

### 4. GIN Indexes (Full-Text Search)

**Best for**: Text search, JSONB queries

```sql
-- Full-text search
create index idx_documents_content_gin
on public.documents
using gin(to_tsvector('english', title || ' ' || content));

-- JSONB search
create index idx_metadata_gin
on public.documents
using gin(metadata);

-- JSONB specific keys
create index idx_metadata_settings_gin
on public.documents
using gin((metadata->'settings'));
```

### 5. GiST Indexes (Geometric/Range)

**Best for**: Range types, geometric data

```sql
-- Time range queries
create index idx_events_time_range
on public.events
using gist(tstzrange(start_time, end_time));

-- Geometric data
create index idx_locations_point
on public.locations
using gist(coordinates);
```

## AI Application Indexing Patterns

### Chat System Indexes

```sql
-- Conversation list (sorted by latest activity)
create index idx_conversations_updated
on public.conversations(updated_at desc)
where deleted_at is null;

-- Message pagination (most important!)
create index idx_messages_conversation_pagination
on public.messages(conversation_id, created_at desc)
where deleted_at is null;

-- Unread message count
create index idx_messages_unread
on public.messages(conversation_id, user_id, created_at)
where deleted_at is null;

-- Participant lookups
create index idx_participants_user_conversations
on public.conversation_participants(user_id, conversation_id);

create index idx_participants_conversation_users
on public.conversation_participants(conversation_id, user_id);

-- Message search
create index idx_messages_search
on public.messages
using gin(to_tsvector('english', content))
where deleted_at is null;

-- Reactions
create index idx_reactions_message
on public.message_reactions(message_id);

create index idx_reactions_user_message
on public.message_reactions(user_id, message_id);
```

### RAG System Indexes

```sql
-- Document lookups
create index idx_documents_collection
on public.documents(collection_id, created_at desc)
where deleted_at is null;

create index idx_documents_user
on public.documents(created_by, created_at desc)
where deleted_at is null;

-- Vector similarity search (most critical!)
create index idx_chunks_embedding_hnsw
on public.document_chunks
using hnsw (embedding vector_cosine_ops)
with (m = 16, ef_construction = 64);

-- Chunk retrieval
create index idx_chunks_document
on public.document_chunks(document_id, chunk_index);

-- Hybrid search: full-text + vector
create index idx_chunks_content_gin
on public.document_chunks
using gin(to_tsvector('english', content));

-- Document metadata search
create index idx_documents_metadata
on public.documents
using gin(metadata);

-- Processing status
create index idx_processing_status
on public.document_processing_status(document_id, status);
```

### Multi-Tenant Indexes

```sql
-- Organization lookups
create index idx_orgs_slug on public.organizations(slug);

-- Member lookups (bidirectional)
create index idx_members_org
on public.organization_members(organization_id, role);

create index idx_members_user
on public.organization_members(user_id);

-- Team membership
create index idx_team_members_team
on public.team_members(team_id);

create index idx_team_members_user
on public.team_members(user_id);

-- Organization-scoped data (composite index)
create index idx_documents_org_created
on public.documents(organization_id, created_at desc)
where deleted_at is null;

-- Invitations
create index idx_invitations_email_pending
on public.organization_invitations(email)
where accepted_at is null and expires_at > now();
```

### Usage Tracking Indexes

```sql
-- Usage queries (time-series)
create index idx_usage_user_time
on public.api_usage(user_id, created_at desc);

create index idx_usage_org_time
on public.api_usage(organization_id, created_at desc)
where organization_id is not null;

-- Model analytics
create index idx_usage_model_time
on public.api_usage(model_name, created_at desc);

-- Cost queries
create index idx_usage_cost
on public.api_usage(created_at desc)
include (cost_usd, tokens_used);

-- Quota checks (partial index)
create index idx_quotas_active
on public.usage_quotas(user_id, quota_type)
where reset_at > now();

-- Rate limiting (time window)
create index idx_rate_limits_window
on public.rate_limits(user_id, endpoint, window_start desc);
```

## Index Optimization Techniques

### 1. Covering Indexes

Include frequently accessed columns in index to avoid table lookups:

```sql
-- Instead of:
create index idx_documents_org on public.documents(organization_id);

-- Use covering index:
create index idx_documents_org_covering
on public.documents(organization_id)
include (title, created_at, created_by);

-- Now this query uses index-only scan:
select title, created_at, created_by
from public.documents
where organization_id = '<org-id>';
```

### 2. Partial Indexes

Index only relevant rows to save space:

```sql
-- Active records only
create index idx_documents_active
on public.documents(created_at desc)
where deleted_at is null;

-- Recent records only
create index idx_messages_recent
on public.messages(conversation_id, created_at desc)
where created_at > now() - interval '90 days';

-- Pending invitations
create index idx_invitations_pending
on public.organization_invitations(email, organization_id)
where accepted_at is null and expires_at > now();
```

### 3. Expression Indexes

Index computed values:

```sql
-- Case-insensitive email lookup
create index idx_users_email_lower
on public.users(lower(email));

-- JSONB field
create index idx_metadata_status
on public.documents((metadata->>'status'));

-- Date truncation
create index idx_usage_date
on public.api_usage(date_trunc('day', created_at));
```

### 4. Multi-Column Index Ordering

**Order matters!** Most selective columns first:

```sql
-- ✅ Good: Filter first, then sort
create index idx_messages_user_conv_time
on public.messages(user_id, conversation_id, created_at desc);

-- Query: WHERE user_id = X AND conversation_id = Y ORDER BY created_at
-- Uses index efficiently

-- ❌ Bad: Sort first, then filter
create index idx_messages_time_user_conv
on public.messages(created_at desc, user_id, conversation_id);

-- Same query won't use this index efficiently
```

## Index Monitoring

### Check Index Usage

```sql
-- Find unused indexes
select
    schemaname
    tablename
    indexname
    idx_scan as scans
    idx_tup_read as tuples_read
    idx_tup_fetch as tuples_fetched
    pg_size_pretty(pg_relation_size(indexrelid)) as size
from pg_stat_user_indexes
where schemaname = 'public'
  and idx_scan = 0
order by pg_relation_size(indexrelid) desc;

-- Find most used indexes
select
    schemaname
    tablename
    indexname
    idx_scan
    pg_size_pretty(pg_relation_size(indexrelid)) as size
from pg_stat_user_indexes
where schemaname = 'public'
order by idx_scan desc
limit 20;
```

### Check Index Size

```sql
-- Total index size per table
select
    tablename
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) as total_size
    pg_size_pretty(pg_relation_size(tablename::regclass)) as table_size
    pg_size_pretty(
        pg_total_relation_size(tablename::regclass) -
        pg_relation_size(tablename::regclass)
    ) as index_size
from pg_tables
where schemaname = 'public'
order by pg_total_relation_size(tablename::regclass) desc;
```

### Analyze Query Plans

```sql
-- Check if query uses index
explain (analyze, buffers)
select *
from public.messages
where conversation_id = '<conv-id>'
  and deleted_at is null
order by created_at desc
limit 50;

-- Look for:
-- - "Index Scan" or "Index Only Scan" (good)
-- - "Seq Scan" on large tables (bad)
-- - "Bitmap Index Scan" (okay for multiple conditions)
```

## Performance Best Practices

### 1. Don't Over-Index

**Problem**: Too many indexes slow down writes

```sql
-- ❌ Redundant indexes
create index idx_documents_org on public.documents(organization_id);
create index idx_documents_org_created on public.documents(organization_id, created_at);

-- The second index can handle queries on organization_id alone
-- Drop the first index
```

### 2. Regular Maintenance

```sql
-- Reindex periodically (during maintenance window)
reindex table concurrently public.document_chunks;

-- Update statistics
analyze public.documents;

-- Vacuum to reclaim space
vacuum analyze public.messages;
```

### 3. Index Build Strategies

```sql
-- For production: create concurrently (doesn't lock table)
create index concurrently idx_documents_search
on public.documents using gin(to_tsvector('english', content));

-- For large tables: increase maintenance_work_mem
set maintenance_work_mem = '1GB';
create index concurrently idx_chunks_embedding
on public.document_chunks using hnsw (embedding vector_cosine_ops);
```

### 4. Monitor Bloat

```sql
-- Check for index bloat
select
    schemaname
    tablename
    indexname
    pg_size_pretty(pg_relation_size(indexrelid)) as size
    idx_scan
from pg_stat_user_indexes
where schemaname = 'public'
  and idx_scan < 100 -- Rarely used
  and pg_relation_size(indexrelid) > 10485760 -- > 10MB
order by pg_relation_size(indexrelid) desc;
```

## Vector Index Tuning

### HNSW Parameters

```sql
-- Default (balanced)
create index idx_embedding_default
using hnsw (embedding vector_cosine_ops)
with (m = 16, ef_construction = 64);

-- High accuracy (slower build, faster search)
create index idx_embedding_accurate
using hnsw (embedding vector_cosine_ops)
with (m = 32, ef_construction = 128);

-- Fast build (faster build, slower search)
create index idx_embedding_fast
using hnsw (embedding vector_cosine_ops)
with (m = 8, ef_construction = 32);
```

### Query-Time Tuning

```sql
-- Adjust search accuracy at query time
set hnsw.ef_search = 100; -- Higher = more accurate but slower

-- Run similarity search
select *
from public.document_chunks
order by embedding <=> '<query-embedding>'
limit 10;

-- Reset to default
reset hnsw.ef_search;
```

## Troubleshooting

### Query Not Using Index

**Problem**: Sequential scan instead of index scan

```sql
-- Check if statistics are outdated
analyze public.documents;

-- Increase statistics target for problematic columns
alter table public.documents
alter column organization_id set statistics 1000;

analyze public.documents;
```

### Slow Index Creation

**Problem**: Index build taking too long

```sql
-- Increase memory for index build
set maintenance_work_mem = '2GB';

-- Use fillfactor for tables with frequent updates
create index idx_messages_conv
on public.messages(conversation_id, created_at desc)
with (fillfactor = 70);
```

### Index Not Being Used

**Problem**: Planner chooses seq scan over index

```sql
-- Check if index is valid
select indexname, indisvalid
from pg_index
join pg_class on pg_class.oid = indexrelid
join pg_indexes on indexname = relname
where schemaname = 'public';

-- Force index usage (testing only!)
set enable_seqscan = off;
-- Run query
-- Reset
set enable_seqscan = on;
```

## Recommended Index Sets

### Minimal (Development)

```sql
-- Just the essentials
create index idx_messages_conv on public.messages(conversation_id, created_at desc);
create index idx_chunks_embedding on public.document_chunks using hnsw (embedding vector_cosine_ops);
create index idx_users_email on public.users(email);
```

### Standard (Production)

All indexes from the pattern sections above.

### Enterprise (High-Scale)

Standard + additional optimization:
- Partitioned tables with local indexes
- Covering indexes for hot queries
- Partial indexes for active data
- Regular reindexing schedule
