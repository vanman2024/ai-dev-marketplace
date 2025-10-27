# Supabase RLS Templates Skill

Production-ready Row Level Security policy templates for Supabase applications, with a focus on AI application patterns.

## Quick Start

```bash
# Apply user isolation to tables
bash scripts/apply-rls-policies.sh user-isolation profiles settings

# Apply multi-tenant policies
bash scripts/apply-rls-policies.sh multi-tenant organizations projects

# Apply AI chat policies
bash scripts/apply-rls-policies.sh ai-chat conversations messages

# Test policies
bash scripts/test-rls-policies.sh conversations

# Audit all tables
bash scripts/audit-rls.sh
```

## Structure

```
rls-templates/
├── SKILL.md                          # Main skill manifest
├── README.md                         # This file
├── scripts/                          # Functional automation scripts
│   ├── apply-rls-policies.sh        # Apply templates to tables
│   ├── test-rls-policies.sh         # Test RLS enforcement
│   ├── generate-policy.sh           # Generate custom policies
│   └── audit-rls.sh                 # Security audit tool
├── templates/                        # SQL policy templates
│   ├── user-isolation.sql           # User owns row pattern
│   ├── multi-tenant.sql             # Organization isolation
│   ├── role-based-access.sql        # Permission levels
│   ├── ai-chat-policies.sql         # Chat/conversation security
│   └── embeddings-policies.sql      # Vector/RAG security
└── examples/                         # Comprehensive guides
    ├── common-patterns.md           # Most common use cases
    ├── testing-guide.md             # Testing methodologies
    └── migration-guide.md           # Production migration
```

## Templates

### 1. User Isolation (`user-isolation.sql`)
**Pattern:** User owns row directly via `user_id` column
**Use for:** User profiles, settings, personal documents

```sql
\i templates/user-isolation.sql
```

### 2. Multi-Tenant (`multi-tenant.sql`)
**Pattern:** Organization/team-based isolation via `organization_id`
**Use for:** SaaS apps, team workspaces, shared resources

```sql
\i templates/multi-tenant.sql
```

### 3. Role-Based Access (`role-based-access.sql`)
**Pattern:** Different permissions per role (admin, editor, user, viewer)
**Use for:** Admin panels, hierarchical access, permission levels

```sql
\i templates/role-based-access.sql
```

### 4. AI Chat (`ai-chat-policies.sql`)
**Pattern:** Conversation ownership with message hierarchy
**Use for:** AI chat apps, messaging systems, conversation history

```sql
\i templates/ai-chat-policies.sql
```

### 5. Vector Embeddings (`embeddings-policies.sql`)
**Pattern:** Secure vector/embedding data for RAG systems
**Use for:** RAG applications, semantic search, vector databases

```sql
\i templates/embeddings-policies.sql
```

## Scripts

### apply-rls-policies.sh
Apply template policies to tables with validation and indexing.

```bash
# Apply user isolation
bash scripts/apply-rls-policies.sh user-isolation profiles settings

# Apply multi-tenant
bash scripts/apply-rls-policies.sh multi-tenant organizations documents

# Apply to AI tables
bash scripts/apply-rls-policies.sh ai-chat conversations messages
```

**Features:**
- ✓ Enables RLS on tables
- ✓ Creates performance indexes
- ✓ Applies template policies
- ✓ Validates policy creation
- ✓ Detailed logging

### test-rls-policies.sh
Test RLS enforcement with different user contexts.

```bash
# Test all policies
bash scripts/test-rls-policies.sh conversations

# Test with specific user
bash scripts/test-rls-policies.sh messages --user-id "user-uuid"

# Test organization isolation
bash scripts/test-rls-policies.sh documents --org-id "org-uuid"
```

**Tests:**
- ✓ RLS enabled
- ✓ Policies exist
- ✓ Anonymous access denied
- ✓ User isolation working
- ✓ Performance indexes present
- ✓ CRUD operations validated

### generate-policy.sh
Generate custom RLS policy from template.

```bash
# Generate user isolation policy
bash scripts/generate-policy.sh user-isolation my_table user_id

# Generate multi-tenant policy
bash scripts/generate-policy.sh multi-tenant projects organization_id

# Save to file
bash scripts/generate-policy.sh user-isolation profiles > profiles-rls.sql
```

### audit-rls.sh
Audit tables for missing or incomplete RLS policies.

```bash
# Audit all tables in public schema
bash scripts/audit-rls.sh

# Audit specific tables
bash scripts/audit-rls.sh conversations messages embeddings

# Generate markdown report
bash scripts/audit-rls.sh --report security-audit.md
```

**Checks:**
- ✓ RLS enabled on all tables
- ✓ Policies configured
- ✓ Performance indexes present
- ✓ Policy coverage (SELECT, INSERT, UPDATE, DELETE)
- ✓ Security gaps identified

## Examples

### Example 1: Secure Chat Application

```sql
-- Apply chat policies
\i templates/ai-chat-policies.sql

-- Tables: conversations, messages
-- Result: Users only see their conversations
```

### Example 2: Multi-Tenant RAG System

```bash
# Apply organization isolation
bash scripts/apply-rls-policies.sh multi-tenant organizations documents

# Apply embedding security
bash scripts/apply-rls-policies.sh embeddings document_embeddings

# Test
bash scripts/test-rls-policies.sh documents --org-id "org-uuid"
```

### Example 3: Role-Based Admin Panel

```sql
-- Apply role-based policies
\i templates/role-based-access.sql

-- Roles: admin, editor, user, viewer
-- Result: Different permissions per role
```

## Prerequisites

### Environment Variables

```bash
export SUPABASE_DB_URL="postgresql://postgres:password@db.project.supabase.co:5432/postgres"
export SUPABASE_ANON_KEY="your-anon-key"
export SUPABASE_SERVICE_KEY="your-service-role-key"
```

### Tools

- PostgreSQL client (`psql`)
- Bash 4.0+
- Supabase project

## Best Practices

1. **Enable RLS from day 1** on new tables
2. **Add indexes** on columns used in policies (user_id, organization_id)
3. **Wrap auth functions** in SELECT for caching: `(SELECT auth.uid())`
4. **Filter queries explicitly** in client code for performance
5. **Use security definer functions** for complex authorization
6. **Test thoroughly** before deploying to production
7. **Audit regularly** with `audit-rls.sh`
8. **Monitor performance** after adding policies
9. **Document decisions** in migration files
10. **Never use user_metadata** for authorization (use app_metadata)

## Testing Workflow

```bash
# 1. Apply policies
bash scripts/apply-rls-policies.sh user-isolation conversations

# 2. Test enforcement
bash scripts/test-rls-policies.sh conversations

# 3. Audit security
bash scripts/audit-rls.sh conversations

# 4. Performance check
psql "$SUPABASE_DB_URL" -c "EXPLAIN ANALYZE SELECT * FROM conversations WHERE user_id = 'uuid';"
```

## CI/CD Integration

```yaml
# .github/workflows/security-audit.yml
name: RLS Security Audit
on: [push, pull_request]
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run RLS Audit
        env:
          SUPABASE_DB_URL: ${{ secrets.SUPABASE_DB_URL }}
        run: |
          bash scripts/audit-rls.sh
```

## Documentation

- **Common Patterns:** `examples/common-patterns.md` - Most frequently used patterns
- **Testing Guide:** `examples/testing-guide.md` - Comprehensive testing methodologies
- **Migration Guide:** `examples/migration-guide.md` - Adding RLS to existing tables

## Security Checklist

Before deploying to production:

- [ ] RLS enabled on all public schema tables
- [ ] Policies test both authenticated and anonymous access
- [ ] Indexes created on policy columns
- [ ] Service key never exposed to client
- [ ] Policies use `(SELECT auth.uid())` for performance
- [ ] WITH CHECK clause included on INSERT/UPDATE policies
- [ ] Testing validates isolation between users/tenants
- [ ] Audit script passes with 0 critical issues
- [ ] Performance benchmarks acceptable (< 100ms queries)

## Troubleshooting

### Issue: Users can't see any data after enabling RLS

**Cause:** Missing policies or wrong user_id

**Solution:**
```bash
# Check policies exist
bash scripts/audit-rls.sh your_table

# Test with specific user
bash scripts/test-rls-policies.sh your_table --user-id "uuid"
```

### Issue: Slow queries after enabling RLS

**Cause:** Missing indexes on policy columns

**Solution:**
```sql
CREATE INDEX idx_table_user_id ON your_table(user_id);
```

### Issue: Service role queries return no data

**Cause:** Using anon key instead of service role key

**Solution:**
```typescript
// Use service role key (bypasses RLS)
const supabaseAdmin = createClient(url, SUPABASE_SERVICE_ROLE_KEY);
```

## Resources

- **Supabase RLS Docs:** https://supabase.com/docs/guides/auth/row-level-security
- **PostgreSQL RLS:** https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- **Performance Guide:** https://supabase.com/docs/guides/database/postgres/row-level-security#performance

## License

Part of the Supabase plugin for Claude Code AI Development Marketplace.
