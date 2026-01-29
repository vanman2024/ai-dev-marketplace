---
description: Add a specific feature to an existing Supabase project. Features include table, auth, rls, realtime, storage, migration, ai.
argument-hint: <feature> [options]
---

# Add Supabase Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2` `$3`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Database Features

**If `$0` = "table":**

```
Task(supabase-database-executor) Add DATABASE TABLE.

Requirements:
- Table name: $1 (required)
- Columns: $2 (column definitions or preset)
- Create table with columns
- Add indexes
- Generate types
- Create RLS policies
```

**If `$0` = "migration":**

```
Task(supabase-migration-applier) Add MIGRATION.

Requirements:
- Migration name: $1 (required)
- Type: $2 (schema, data, both - default: schema)
- Create migration file
- Add rollback
- Test migration
```

**If `$0` = "schema":**

```
Task(supabase-schema-validator) Add/validate SCHEMA.

Requirements:
- Action: $1 (validate, sync, generate - default: validate)
- Validate current schema
- Generate types
- Check relationships
```

### Auth Features

**If `$0` = "auth":**

```
Task(supabase-auth-pages-builder) Add AUTHENTICATION.

Requirements:
- Provider: $1 (email, google, github, magic-link - default: email)
- Features: $2 (mfa, social, passwordless - default: basic)
- Configure auth provider
- Create auth pages
- Add session handling
- Set up middleware
```

### Security Features

**If `$0` = "rls":**

```
Task(supabase-security-specialist) Add RLS POLICY.

Requirements:
- Table: $1 (required)
- Policy type: $2 (select, insert, update, delete, all - default: all)
- Create RLS policies
- Add helper functions
- Test enforcement
```

**If `$0` = "audit":**

```
Task(supabase-security-auditor) Run SECURITY AUDIT.

Requirements:
- Scope: $1 (rls, auth, all - default: all)
- Audit security settings
- Check for vulnerabilities
- Generate report
- Recommend fixes
```

### Realtime Features

**If `$0` = "realtime":**

```
Task(supabase-realtime-builder) Add REALTIME feature.

Requirements:
- Feature: $1 (subscribe, broadcast, presence - default: subscribe)
- Tables: $2 (table names or all)
- Set up realtime subscriptions
- Create hooks
- Add event handlers
```

### Storage Features

**If `$0` = "storage":**

```
Task(supabase-architect) Add STORAGE.

Requirements:
- Bucket name: $1 (required)
- Access: $2 (public, private, authenticated - default: authenticated)
- Create storage bucket
- Configure policies
- Add upload helpers
- Set up transformations
```

### AI Features

**If `$0` = "ai":**

```
Task(supabase-ai-specialist) Add AI features.

Requirements:
- Feature: $1 (embeddings, vector, search - default: embeddings)
- Model: $2 (openai, huggingface - default: openai)
- Enable pgvector extension
- Create embedding column
- Set up vector search
- Add similarity functions
```

### UI Features

**If `$0` = "ui":**

```
Task(supabase-ui-generator) Generate UI.

Requirements:
- Component: $1 (auth, crud, list - required)
- Table: $2 (table name for crud/list)
- Generate UI components
- Add data fetching
- Set up mutations
```

### Performance Features

**If `$0` = "performance":**

```
Task(supabase-performance-analyzer) Analyze PERFORMANCE.

Requirements:
- Focus: $1 (queries, indexes, rls - default: all)
- Analyze query performance
- Check index usage
- Review RLS impact
- Recommend optimizations
```

### Validation Features

**If `$0` = "validate":**

```
Task(supabase-validator) Run VALIDATION.

Requirements:
- Scope: $1 (schema, types, all - default: all)
- Validate schema
- Check type sync
- Verify connections
```

---

## Usage Examples

```bash
# Database
/supabase:add table users "id uuid, email text, created_at timestamp"
/supabase:add table posts
/supabase:add migration add_posts_table schema
/supabase:add schema generate

# Auth
/supabase:add auth email basic
/supabase:add auth google social
/supabase:add auth magic-link

# Security
/supabase:add rls users all
/supabase:add rls posts select
/supabase:add audit all

# Realtime
/supabase:add realtime subscribe messages
/supabase:add realtime presence
/supabase:add realtime broadcast

# Storage & AI
/supabase:add storage avatars public
/supabase:add ai embeddings openai
/supabase:add ai vector

# UI & Performance
/supabase:add ui auth
/supabase:add ui crud users
/supabase:add performance queries
```

---

## Feature Reference

| Feature       | Agent                | $1 Options                     | Description        |
| ------------- | -------------------- | ------------------------------ | ------------------ |
| `table`       | database-executor    | table-name (required)          | Database table     |
| `migration`   | migration-applier    | migration-name (required)      | Schema migration   |
| `schema`      | schema-validator     | validate/sync/generate         | Schema management  |
| `auth`        | auth-pages-builder   | email/google/github/magic-link | Authentication     |
| `rls`         | security-specialist  | table-name (required)          | RLS policies       |
| `audit`       | security-auditor     | rls/auth/all                   | Security audit     |
| `realtime`    | realtime-builder     | subscribe/broadcast/presence   | Realtime features  |
| `storage`     | architect            | bucket-name (required)         | File storage       |
| `ai`          | ai-specialist        | embeddings/vector/search       | AI/Vector features |
| `ui`          | ui-generator         | auth/crud/list                 | UI generation      |
| `performance` | performance-analyzer | queries/indexes/rls            | Performance        |
| `validate`    | validator            | schema/types/all               | Validation         |
