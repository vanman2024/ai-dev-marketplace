# Common Schema Issues and Fixes

This document catalogs common database schema problems detected by the validation tools and how to fix them.

---

## Table of Contents

1. [Naming Violations](#naming-violations)
2. [Missing Constraints](#missing-constraints)
3. [Indexing Issues](#indexing-issues)
4. [RLS Problems](#rls-problems)
5. [SQL Syntax Errors](#sql-syntax-errors)
6. [Performance Anti-Patterns](#performance-anti-patterns)

---

## Naming Violations

### ❌ Problem: Uppercase in Table Names

```sql
CREATE TABLE Users (
  id UUID PRIMARY KEY
);
```

**Error:** Table 'Users' contains uppercase letters - use lowercase with underscores

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);
```

---

### ❌ Problem: CamelCase Column Names

```sql
CREATE TABLE users (
  userId UUID
  firstName TEXT
  lastName TEXT
);
```

**Error:** Column names use camelCase - use snake_case

**✅ Fix:**
```sql
CREATE TABLE users (
  user_id UUID
  first_name TEXT
  last_name TEXT
);
```

---

### ❌ Problem: Unnamed Constraints

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY
  email TEXT UNIQUE
);
```

**Warning:** Unique constraint has no explicit name

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
  email TEXT CONSTRAINT uq_users_email UNIQUE NOT NULL
);
```

---

### ❌ Problem: Reserved Keyword Usage

```sql
CREATE TABLE user (
  id UUID PRIMARY KEY
);
```

**Warning:** Table 'user' is a PostgreSQL reserved keyword

**✅ Fix:**
```sql
-- Option 1: Use plural form
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

-- Option 2: Quote the identifier (not recommended)
CREATE TABLE "user" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);
```

---

## Missing Constraints

### ❌ Problem: No Primary Key

```sql
CREATE TABLE users (
  email TEXT UNIQUE
  username TEXT
);
```

**Error:** Table 'users' has no primary key defined

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
  email TEXT CONSTRAINT uq_users_email UNIQUE NOT NULL
  username TEXT CONSTRAINT uq_users_username UNIQUE NOT NULL
);
```

---

### ❌ Problem: Foreign Key Without ON DELETE

```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY
  user_id UUID REFERENCES users(id)
);
```

**Info:** Foreign key missing ON DELETE action

**✅ Fix:**
```sql
CREATE TABLE posts (
  id UUID CONSTRAINT pk_posts PRIMARY KEY DEFAULT gen_random_uuid()
  user_id UUID NOT NULL
  CONSTRAINT fk_posts_users
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
);
```

---

### ❌ Problem: Missing NOT NULL on Important Columns

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY
  email TEXT UNIQUE
  created_at TIMESTAMPTZ
);
```

**Warning:** Column 'email' should probably be NOT NULL
**Warning:** Column 'created_at' should probably be NOT NULL

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
  email TEXT CONSTRAINT uq_users_email UNIQUE NOT NULL
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

### ❌ Problem: Missing Check Constraints for Business Rules

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY
  price NUMERIC
);
```

**Info:** Numeric field 'price' might benefit from CHECK constraint

**✅ Fix:**
```sql
CREATE TABLE products (
  id UUID CONSTRAINT pk_products PRIMARY KEY DEFAULT gen_random_uuid()
  price NUMERIC NOT NULL
  CONSTRAINT ck_products_positive_price
    CHECK (price > 0)
);
```

---

## Indexing Issues

### ❌ Problem: Foreign Key Without Index

```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY
  user_id UUID REFERENCES users(id)
);
```

**Warning:** Foreign key column 'user_id' has no index

**✅ Fix:**
```sql
CREATE TABLE posts (
  id UUID CONSTRAINT pk_posts PRIMARY KEY DEFAULT gen_random_uuid()
  user_id UUID NOT NULL
  CONSTRAINT fk_posts_users
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
);

CREATE INDEX idx_posts_user_id ON posts (user_id);
```

---

### ❌ Problem: RLS Policy Column Without Index

```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY
  user_id UUID REFERENCES users(id)
);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY posts_select_own ON posts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());
```

**Warning:** Column 'user_id' used in RLS policy has no index

**✅ Fix:**
```sql
-- Create index for RLS performance
CREATE INDEX idx_posts_user_id ON posts (user_id);
```

---

### ❌ Problem: JSONB Column Without GIN Index

```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY
  metadata JSONB
);

CREATE INDEX idx_documents_metadata ON documents (metadata);
```

**Warning:** JSONB column in index - consider using GIN index

**✅ Fix:**
```sql
CREATE TABLE documents (
  id UUID CONSTRAINT pk_documents PRIMARY KEY DEFAULT gen_random_uuid()
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX idx_documents_metadata ON documents USING GIN (metadata);
```

---

### ❌ Problem: Duplicate Indexes

```sql
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_email_2 ON users (email);
```

**Warning:** Duplicate index on table 'users' columns (email)

**✅ Fix:**
```sql
-- Remove duplicate
DROP INDEX idx_users_email_2;

-- Keep only one index
CREATE INDEX idx_users_email ON users (email);
```

---

## RLS Problems

### ❌ Problem: RLS Not Enabled on Public Table

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY
  email TEXT
);
```

**Error:** Table 'users' in public schema must have RLS enabled

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
  email TEXT NOT NULL
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_select_own ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());
```

---

### ❌ Problem: RLS Enabled Without Policies

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

**Error:** Table 'users' has RLS enabled but no policies defined

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
  email TEXT NOT NULL
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Add at least a SELECT policy
CREATE POLICY users_select_own ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());
```

---

### ❌ Problem: Policy Without Role Specification

```sql
CREATE POLICY users_select ON users
  FOR SELECT
  USING (id = auth.uid());
```

**Warning:** Policy missing TO clause - specify role

**✅ Fix:**
```sql
CREATE POLICY users_select_own ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());
```

---

### ❌ Problem: INSERT/UPDATE Policy Without WITH CHECK

```sql
CREATE POLICY posts_insert ON posts
  FOR INSERT
  TO authenticated
  USING (user_id = auth.uid());
```

**Warning:** INSERT policy missing WITH CHECK clause

**✅ Fix:**
```sql
CREATE POLICY posts_insert_own ON posts
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());
```

---

### ❌ Problem: auth.uid() Not Wrapped in SELECT

```sql
CREATE POLICY posts_select_own ON posts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());
```

**Info:** Using auth.uid() - wrap in SELECT for performance

**✅ Fix:**
```sql
CREATE POLICY posts_select_own ON posts
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));
```

---

## SQL Syntax Errors

### ❌ Problem: Missing Semicolon

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY
)
-- Missing semicolon
CREATE TABLE posts (
  id UUID PRIMARY KEY
);
```

**Warning:** Possible missing semicolon

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);
```

---

### ❌ Problem: Using SERIAL Instead of IDENTITY

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY
);
```

**Info:** SERIAL type found - consider using IDENTITY columns

**✅ Fix:**
```sql
CREATE TABLE users (
  id BIGINT GENERATED ALWAYS AS IDENTITY
  CONSTRAINT pk_users PRIMARY KEY (id)
);

-- Or with UUID (preferred for distributed systems)
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
);
```

---

### ❌ Problem: UUID Without Default

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY
);
```

**Info:** UUID type found - ensure proper default value

**✅ Fix:**
```sql
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
);
```

---

## Performance Anti-Patterns

### ❌ Problem: No Index on Timestamp Sort Column

```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Common query: SELECT * FROM posts ORDER BY created_at DESC
```

**Info:** Timestamp column 'created_at' often used for sorting - consider adding index

**✅ Fix:**
```sql
CREATE TABLE posts (
  id UUID CONSTRAINT pk_posts PRIMARY KEY DEFAULT gen_random_uuid()
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_posts_created_at ON posts (created_at DESC);
```

---

### ❌ Problem: No Partial Index for Soft Deletes

```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY
  deleted_at TIMESTAMPTZ
);

-- Common query: SELECT * FROM posts WHERE deleted_at IS NULL
```

**Info:** Soft-delete pattern detected - consider partial index WHERE deleted_at IS NULL

**✅ Fix:**
```sql
CREATE TABLE posts (
  id UUID CONSTRAINT pk_posts PRIMARY KEY DEFAULT gen_random_uuid()
  deleted_at TIMESTAMPTZ
);

-- Partial index for active records only
CREATE INDEX idx_posts_active ON posts (created_at)
  WHERE deleted_at IS NULL;
```

---

### ❌ Problem: Complex JOIN in RLS Policy

```sql
CREATE POLICY posts_select ON posts
  FOR SELECT
  TO authenticated
  USING (
    user_id IN (
      SELECT user_id
      FROM team_members
      JOIN teams ON teams.id = team_members.team_id
      WHERE teams.owner_id = auth.uid()
    )
  );
```

**Warning:** Policy contains multiple JOINs - consider simplifying

**✅ Fix:**
```sql
-- Option 1: Use materialized view
CREATE MATERIALIZED VIEW user_accessible_posts AS
SELECT posts.id, posts.user_id
FROM posts
JOIN team_members ON team_members.user_id = posts.user_id
JOIN teams ON teams.id = team_members.team_id;

CREATE POLICY posts_select ON posts
  FOR SELECT
  TO authenticated
  USING (id IN (SELECT id FROM user_accessible_posts WHERE user_id = auth.uid()));

-- Option 2: Denormalize with array
ALTER TABLE posts ADD COLUMN authorized_user_ids UUID[];

CREATE POLICY posts_select ON posts
  FOR SELECT
  TO authenticated
  USING (auth.uid() = ANY(authorized_user_ids));

-- Don't forget the index!
CREATE INDEX idx_posts_authorized_users ON posts USING GIN (authorized_user_ids);
```

---

## Quick Reference

### Most Common Fixes

1. **Add PRIMARY KEY:**
   ```sql
   id UUID CONSTRAINT pk_tablename PRIMARY KEY DEFAULT gen_random_uuid()
   ```

2. **Name FOREIGN KEY:**
   ```sql
   CONSTRAINT fk_table_reftable FOREIGN KEY (col) REFERENCES reftable(id) ON DELETE CASCADE
   ```

3. **Enable RLS:**
   ```sql
   ALTER TABLE tablename ENABLE ROW LEVEL SECURITY;
   ```

4. **Add RLS Policy:**
   ```sql
   CREATE POLICY name ON table FOR SELECT TO authenticated USING (condition);
   ```

5. **Index Foreign Key:**
   ```sql
   CREATE INDEX idx_table_column ON table (column);
   ```

6. **Use snake_case:**
   ```sql
   -- Wrong: UserProfile, user_Profile
   -- Right: user_profile
   ```

---

**Pro Tip:** Run `full-validation.sh` after each fix to verify the issue is resolved and no new issues were introduced.
