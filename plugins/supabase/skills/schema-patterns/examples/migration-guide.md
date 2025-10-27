# Schema Migration Guide

Best practices for evolving your database schema over time without breaking existing applications.

## Migration Principles

### 1. Never Break Existing Code

- **Additive changes only**: Add new tables/columns, don't remove existing ones immediately
- **Backwards compatibility**: Ensure old code continues to work during transition period
- **Gradual deprecation**: Mark features as deprecated before removing them

### 2. Use Versioned Migrations

- **Timestamp-based naming**: `20250126120000_add_user_profiles.sql`
- **Descriptive names**: Clearly indicate what the migration does
- **One purpose per migration**: Don't mix unrelated changes

### 3. Test Before Applying

- **Validate schema**: Use `validate-schema.sh` script
- **Test on staging**: Never test migrations on production first
- **Backup first**: Always backup before applying migrations

## Common Migration Patterns

### Adding a New Column

**Safe approach** (backwards compatible):

```sql
-- Migration: 20250126120000_add_user_avatar.sql

-- Add column with default value
alter table public.user_profiles
add column if not exists avatar_url text;

-- Add index if needed
create index if not exists idx_profiles_avatar
on public.user_profiles(avatar_url)
where avatar_url is not null;

-- Update RLS policies if needed (avatar_url should be publicly readable)
-- No policy changes needed - existing policies already cover new columns
```

**Unsafe approach** (can break existing code):

```sql
-- ❌ DON'T DO THIS
alter table public.user_profiles
add column avatar_url text not null; -- Fails if table has existing rows!
```

### Renaming a Column

**Safe approach** (3-step process):

```sql
-- Step 1: Add new column
-- Migration: 20250126120000_add_full_name_column.sql
alter table public.user_profiles
add column if not exists full_name text;

-- Copy data from old column
update public.user_profiles
set full_name = name
where full_name is null and name is not null;

-- Update application code to use full_name
-- Deploy application update

-- Step 2: Deprecate old column (wait for all old code to be replaced)
-- Migration: 20250127120000_deprecate_name_column.sql
comment on column public.user_profiles.name is 'DEPRECATED: Use full_name instead';

-- Step 3: Remove old column (after sufficient time)
-- Migration: 20250201120000_remove_name_column.sql
alter table public.user_profiles
drop column if exists name;
```

### Changing Column Type

**Safe approach**:

```sql
-- Migration: 20250126120000_change_user_status_type.sql

-- Add new column with new type
alter table public.users
add column if not exists status_new text
check (status_new in ('online', 'offline', 'away', 'busy'));

-- Migrate data
update public.users
set status_new = status::text
where status_new is null;

-- Update application to use status_new
-- Deploy application update

-- Drop old column
alter table public.users
drop column if exists status;

-- Rename new column to original name
alter table public.users
rename column status_new to status;
```

### Adding Foreign Key Constraint

**Safe approach**:

```sql
-- Migration: 20250126120000_add_organization_fk.sql

-- First, ensure data integrity
-- Remove orphaned records
delete from public.documents
where organization_id is not null
  and not exists (
      select 1 from public.organizations
      where id = documents.organization_id
  );

-- Add foreign key with validation
alter table public.documents
add constraint fk_documents_organization
foreign key (organization_id)
references public.organizations(id)
on delete cascade;

-- Add index for performance
create index if not exists idx_documents_organization
on public.documents(organization_id);
```

### Adding NOT NULL Constraint

**Safe approach**:

```sql
-- Migration: 20250126120000_make_email_required.sql

-- Step 1: Fill in missing values
update public.user_profiles
set email = 'unknown@example.com'
where email is null;

-- Step 2: Add constraint
alter table public.user_profiles
alter column email set not null;

-- Step 3: Add validation check (optional)
alter table public.user_profiles
add constraint check_email_format
check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
```

### Splitting a Table

**Safe approach**:

```sql
-- Migration: 20250126120000_split_user_table.sql

-- Create new table for extracted data
create table if not exists public.user_settings (
    user_id uuid primary key references auth.users(id) on delete cascade,
    theme text,
    language text,
    timezone text,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Migrate data
insert into public.user_settings (user_id, theme, language, timezone)
select id, theme, language, timezone
from public.user_profiles
on conflict (user_id) do nothing;

-- Keep old columns temporarily for backwards compatibility
comment on column public.user_profiles.theme is 'DEPRECATED: Use user_settings table';
comment on column public.user_profiles.language is 'DEPRECATED: Use user_settings table';
comment on column public.user_profiles.timezone is 'DEPRECATED: Use user_settings table';

-- Update application to use new table
-- Deploy application update

-- Later migration: Remove old columns
-- alter table public.user_profiles
-- drop column theme,
-- drop column language,
-- drop column timezone;
```

### Changing Primary Key

**Safe approach** (complex, requires downtime):

```sql
-- Migration: 20250126120000_change_pk_to_uuid.sql

-- This requires careful planning and typically downtime

-- Step 1: Add new UUID column
alter table public.documents
add column if not exists uuid uuid default uuid_generate_v4();

-- Step 2: Update all foreign key references to include both IDs
-- (This is complex and depends on your schema)

-- Step 3: Switch constraints
alter table public.documents
drop constraint documents_pkey;

alter table public.documents
add primary key (uuid);

-- Step 4: Remove old ID column
-- alter table public.documents
-- drop column id;

-- Step 5: Rename uuid to id
alter table public.documents
rename column uuid to id;
```

## Migration Checklist

Before applying a migration:

- [ ] **Backup database**: Create a backup of production data
- [ ] **Review changes**: Ensure migration follows safe patterns
- [ ] **Validate schema**: Run `./scripts/validate-schema.sh`
- [ ] **Test on staging**: Apply migration to staging environment
- [ ] **Test rollback**: Verify rollback procedure works
- [ ] **Check dependencies**: Ensure application code is compatible
- [ ] **Plan downtime**: Schedule maintenance window if needed
- [ ] **Monitor performance**: Check query performance after migration
- [ ] **Update documentation**: Document schema changes

## Rollback Strategies

### Immediate Rollback

For migrations that can be reversed immediately:

```sql
-- Migration: 20250126120000_add_user_bio.sql

-- UP
alter table public.user_profiles
add column if not exists bio text;

-- DOWN (in same file, commented)
-- alter table public.user_profiles
-- drop column if exists bio;
```

### Delayed Rollback

For migrations requiring gradual rollback:

```sql
-- Migration: 20250126120000_add_user_bio.sql
alter table public.user_profiles
add column if not exists bio text;

-- Rollback migration: 20250127120000_rollback_user_bio.sql
-- (Created separately if rollback is needed)
alter table public.user_profiles
drop column if exists bio;
```

## Version Control

### Naming Convention

```
YYYYMMDDHHMMSS_descriptive_name.sql

Examples:
20250126120000_initial_schema.sql
20250126130000_add_user_profiles.sql
20250126140000_add_organizations.sql
20250127100000_add_chat_system.sql
```

### Migration Template

```sql
-- Migration: <NAME>
-- Version: <VERSION>
-- Author: <AUTHOR>
-- Date: <DATE>
-- Description: <DESCRIPTION>

-- Dependencies:
-- - Requires: <PREVIOUS_MIGRATION>
-- - Conflicts: <CONFLICTING_MIGRATION>

-- ============================================================================
-- UP MIGRATION
-- ============================================================================

begin;

-- Your migration code here

commit;

-- ============================================================================
-- DOWN MIGRATION (for rollback)
-- ============================================================================

-- begin;
-- Your rollback code here
-- commit;
```

## Testing Migrations

### Local Testing

```bash
# 1. Create test database
createdb test_db

# 2. Apply migrations
supabase db push --db-url "postgresql://postgres:postgres@localhost:5432/test_db"

# 3. Test queries
psql test_db -f test_queries.sql

# 4. Cleanup
dropdb test_db
```

### Staging Testing

```bash
# 1. Link to staging project
supabase link --project-ref <staging-project-ref>

# 2. Apply migration
./scripts/apply-migration.sh new-migration.sql "migration-name"

# 3. Run integration tests
npm test

# 4. Monitor for errors
supabase logs --follow
```

## Performance Considerations

### Large Table Migrations

For tables with millions of rows:

```sql
-- ❌ Don't do this (locks table)
alter table public.documents
add column processed boolean default false;

-- ✅ Do this (incremental)
alter table public.documents
add column processed boolean;

-- Update in batches
do $$
declare
    batch_size int := 10000;
    offset_val int := 0;
begin
    loop
        update public.documents
        set processed = false
        where id in (
            select id
            from public.documents
            where processed is null
            limit batch_size
        );

        if not found then
            exit;
        end if;

        offset_val := offset_val + batch_size;

        -- Pause between batches
        perform pg_sleep(0.1);
    end loop;
end $$;
```

### Index Creation

```sql
-- Create index concurrently (doesn't lock table)
create index concurrently if not exists idx_documents_created
on public.documents(created_at desc);

-- For large tables, create in background
create index concurrently if not exists idx_documents_content
on public.documents using gin(to_tsvector('english', content));
```

## Common Pitfalls

### 1. Breaking RLS Policies

**Problem**: New columns not covered by existing RLS policies

```sql
-- ❌ New column bypasses RLS
alter table public.documents
add column secret_data text;

-- ✅ Update RLS policies
alter table public.documents
add column secret_data text;

-- Update policy to exclude secret_data from public queries
create or replace policy "documents_select_policy"
on public.documents for select
using (
    deleted_at is null and
    created_by = auth.uid()
);
```

### 2. Orphaned Records

**Problem**: Deleting parent records without cascade

```sql
-- ❌ Leaves orphaned records
delete from public.organizations where id = '<org-id>';

-- ✅ Use cascading deletes
alter table public.documents
add constraint fk_documents_organization
foreign key (organization_id)
references public.organizations(id)
on delete cascade;
```

### 3. Missing Indexes

**Problem**: Slow queries after migration

```sql
-- Always add indexes for:
-- - Foreign keys
-- - Frequently queried columns
-- - Order by columns
-- - Where clause columns

create index idx_documents_org on public.documents(organization_id);
create index idx_documents_created on public.documents(created_at desc);
create index idx_documents_deleted on public.documents(deleted_at) where deleted_at is null;
```

## Resources

- [PostgreSQL ALTER TABLE docs](https://www.postgresql.org/docs/current/sql-altertable.html)
- [Supabase Migration guide](https://supabase.com/docs/guides/database/migrations)
- [Database Refactoring by Martin Fowler](https://martinfowler.com/books/refactoringDatabases.html)
