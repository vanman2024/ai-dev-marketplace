-- Migration: <MIGRATION_NAME>
-- Created: <TIMESTAMP>
-- Author: <AUTHOR>
-- Description: <DESCRIPTION>

-- Enable required extensions
-- create extension if not exists "uuid-ossp";
-- create extension if not exists "vector";

-- ============================================================================
-- UP MIGRATION
-- ============================================================================

-- Drop existing objects if needed (use carefully!)
-- drop table if exists <table_name> cascade;

-- Create tables
create table if not exists public.<table_name> (
    id uuid primary key default uuid_generate_v4(),

    -- Your columns here
    name text not null,
    description text,
    metadata jsonb default '{}'::jsonb,

    -- Audit fields
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);

-- Add comments
comment on table public.<table_name> is '<TABLE_DESCRIPTION>';
comment on column public.<table_name>.id is 'Primary key';

-- Create indexes
create index if not exists idx_<table>_<column>
    on public.<table_name>(<column>);

-- Create full-text search index (if needed)
create index if not exists idx_<table>_search
    on public.<table_name>
    using gin(to_tsvector('english', name || ' ' || coalesce(description, '')));

-- Create vector index (if needed)
-- create index if not exists idx_<table>_embedding
--     on public.<table_name>
--     using hnsw (embedding vector_cosine_ops)
--     with (m = 16, ef_construction = 64);

-- Create helper functions
create or replace function public.<function_name>(
    p_param1 text,
    p_param2 integer default 10
)
returns table (
    id uuid,
    name text
) as $$
begin
    return query
    select
        t.id,
        t.name
    from public.<table_name> t
    where t.name = p_param1
    limit p_param2;
end;
$$ language plpgsql stable;

-- Create triggers
create or replace function public.handle_<table>_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger set_<table>_updated_at
    before update on public.<table_name>
    for each row
    execute function public.handle_<table>_updated_at();

-- Enable Row Level Security
alter table public.<table_name> enable row level security;

-- Create RLS policies
create policy "<table>_select_policy"
    on public.<table_name>
    for select
    using (
        deleted_at is null and
        (
            created_by = auth.uid() or
            -- Add additional conditions
            true
        )
    );

create policy "<table>_insert_policy"
    on public.<table_name>
    for insert
    with check (created_by = auth.uid());

create policy "<table>_update_policy"
    on public.<table_name>
    for update
    using (created_by = auth.uid());

create policy "<table>_delete_policy"
    on public.<table_name>
    for delete
    using (created_by = auth.uid());

-- Grant permissions (if needed for service role)
-- grant usage on schema public to service_role;
-- grant all on public.<table_name> to service_role;

-- ============================================================================
-- DOWN MIGRATION (for rollback)
-- ============================================================================

-- To rollback this migration, uncomment and run:

-- drop policy if exists "<table>_delete_policy" on public.<table_name>;
-- drop policy if exists "<table>_update_policy" on public.<table_name>;
-- drop policy if exists "<table>_insert_policy" on public.<table_name>;
-- drop policy if exists "<table>_select_policy" on public.<table_name>;
-- drop trigger if exists set_<table>_updated_at on public.<table_name>;
-- drop function if exists public.handle_<table>_updated_at();
-- drop function if exists public.<function_name>(text, integer);
-- drop index if exists idx_<table>_<column>;
-- drop table if exists public.<table_name> cascade;
