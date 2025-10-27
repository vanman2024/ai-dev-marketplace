# PostgreSQL/Supabase SQL Best Practices Checklist

## Table Design

### ✅ Primary Keys
- [ ] Every table has a primary key
- [ ] Use UUID type for distributed systems
- [ ] Use `gen_random_uuid()` as default for UUID columns
- [ ] Use IDENTITY columns instead of SERIAL (PostgreSQL 10+)
- [ ] Primary key constraints are explicitly named (pk_table_name)

### ✅ Foreign Keys
- [ ] All foreign key constraints are explicitly named (fk_table_ref)
- [ ] Foreign keys have ON DELETE action specified
- [ ] Foreign keys reference existing tables
- [ ] Foreign key columns match referenced column types

### ✅ Constraints
- [ ] All constraints have explicit names
- [ ] Unique constraints use uq_ prefix
- [ ] Check constraints use ck_ prefix
- [ ] NOT NULL is used where appropriate
- [ ] Check constraints validate business rules

### ✅ Data Types
- [ ] Use appropriate types (avoid TEXT for everything)
- [ ] Use TIMESTAMPTZ instead of TIMESTAMP
- [ ] Avoid MONEY type (use NUMERIC instead)
- [ ] Use JSONB instead of JSON
- [ ] Use proper array types when needed

## Naming Conventions

### ✅ Tables
- [ ] Use lowercase with underscores (snake_case)
- [ ] Use plural names (users, not user)
- [ ] Avoid reserved keywords
- [ ] No tbl_ or table_ prefixes
- [ ] Maximum 63 characters

### ✅ Columns
- [ ] Use lowercase with underscores (snake_case)
- [ ] Use singular names (user_id, not users_id)
- [ ] Use _id suffix for foreign keys
- [ ] Use _at suffix for timestamps
- [ ] Use is_ or has_ prefix for booleans

### ✅ Constraints & Indexes
- [ ] Primary keys: pk_table_name
- [ ] Foreign keys: fk_table_referenced_table
- [ ] Unique constraints: uq_table_column
- [ ] Check constraints: ck_table_description
- [ ] Indexes: idx_table_column
- [ ] Unique indexes: uidx_table_column

## Indexing Strategy

### ✅ Required Indexes
- [ ] All foreign key columns are indexed
- [ ] Columns used in RLS policies are indexed
- [ ] Columns frequently used in WHERE clauses are indexed
- [ ] Columns used in ORDER BY are indexed

### ✅ Index Types
- [ ] Use GIN for JSONB columns
- [ ] Use GIN for array columns
- [ ] Use GIN for full-text search (tsvector)
- [ ] Use partial indexes for filtered queries
- [ ] Consider covering indexes for SELECT queries

### ✅ Index Best Practices
- [ ] No duplicate indexes
- [ ] Multi-column indexes have proper column order
- [ ] Partial indexes for soft-delete patterns
- [ ] Indexes are explicitly named

## Row Level Security (RLS)

### ✅ RLS Configuration
- [ ] RLS enabled on all public tables
- [ ] Every table with RLS has at least one policy
- [ ] Policies specify roles (TO authenticated, TO anon)
- [ ] SELECT policies exist for read access
- [ ] INSERT/UPDATE/DELETE policies exist if needed

### ✅ RLS Performance
- [ ] Columns used in policies are indexed
- [ ] auth.uid() wrapped in SELECT for performance
- [ ] Avoid complex JOINs in policies
- [ ] Use materialized views for complex policy logic

### ✅ RLS Security
- [ ] WITH CHECK clause on INSERT/UPDATE policies
- [ ] No blanket TO public policies
- [ ] Service role properly secured
- [ ] Policies tested for data leakage

## Schema Organization

### ✅ Schema Structure
- [ ] Use public schema for API-exposed tables
- [ ] Use private schemas for internal tables
- [ ] Extensions in extensions schema
- [ ] Auth tables in auth schema (Supabase)

### ✅ Migrations
- [ ] One migration per logical change
- [ ] Migrations are idempotent (IF NOT EXISTS)
- [ ] Down migrations provided
- [ ] Data migrations separate from schema migrations

## Performance

### ✅ Query Optimization
- [ ] Avoid N+1 queries
- [ ] Use pagination for large result sets
- [ ] Use EXPLAIN ANALYZE to check query plans
- [ ] Minimize joins in queries

### ✅ Data Integrity
- [ ] Use transactions for multi-step operations
- [ ] Set appropriate isolation levels
- [ ] Handle concurrent updates properly
- [ ] Use optimistic locking where needed

## Audit & Metadata

### ✅ Standard Columns
- [ ] id (primary key)
- [ ] created_at (timestamp with default now())
- [ ] updated_at (timestamp with trigger)
- [ ] deleted_at (for soft deletes, optional)

### ✅ Audit Trails
- [ ] created_by (if needed)
- [ ] updated_by (if needed)
- [ ] Use trigger for updated_at automation

## Security

### ✅ SQL Injection Prevention
- [ ] Use parameterized queries
- [ ] Never concatenate user input into SQL
- [ ] Validate all inputs
- [ ] Use prepared statements

### ✅ Access Control
- [ ] RLS policies enforce access control
- [ ] Service role properly restricted
- [ ] API keys stored securely (not in schema)
- [ ] Sensitive data encrypted at rest

## Documentation

### ✅ Schema Documentation
- [ ] Table purposes documented
- [ ] Complex constraints explained
- [ ] Business rules documented
- [ ] RLS policies explained

### ✅ Comments
- [ ] Tables have COMMENT ON TABLE
- [ ] Columns have COMMENT ON COLUMN
- [ ] Functions documented
- [ ] Triggers documented

## Maintenance

### ✅ Regular Tasks
- [ ] Vacuum tables regularly
- [ ] Analyze tables for query planning
- [ ] Monitor index usage
- [ ] Remove unused indexes

### ✅ Monitoring
- [ ] Track slow queries
- [ ] Monitor table bloat
- [ ] Check for missing indexes
- [ ] Review execution plans

## Supabase-Specific

### ✅ Supabase Features
- [ ] Use Supabase auth.uid() for user identification
- [ ] Use Supabase storage for files
- [ ] Use Supabase realtime for live updates
- [ ] Use Supabase edge functions for serverless

### ✅ Supabase Best Practices
- [ ] Enable RLS on all public tables
- [ ] Use service role sparingly
- [ ] Test policies with different user roles
- [ ] Use Supabase client libraries properly

## Pre-Deployment Checklist

- [ ] All validation scripts pass
- [ ] No syntax errors
- [ ] No naming convention violations
- [ ] All tables have primary keys
- [ ] All foreign keys indexed
- [ ] RLS enabled on public tables
- [ ] Policies tested
- [ ] Migrations tested in staging
- [ ] Rollback plan prepared
- [ ] Documentation updated

---

**Reference Documentation:**
- [PostgreSQL Documentation](https://www.postgresql.org/docs/current/)
- [Supabase Database Guide](https://supabase.com/docs/guides/database)
- [PostgreSQL Naming Conventions](https://www.postgresql.org/docs/current/sql-syntax-lexical.html)
- [Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)
