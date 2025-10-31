# RLS Security Verification Checklist

Use this checklist to verify comprehensive RLS security before deploying to production.

## 1. RLS Enablement

- [ ] RLS enabled on all tables in `public` schema
- [ ] RLS enabled on custom schemas that are exposed
- [ ] Verified with: `SELECT tablename FROM pg_tables WHERE schemaname='public' AND NOT EXISTS (SELECT 1 FROM pg_class WHERE oid=('public.'||tablename)::regclass AND relrowsecurity)`
- [ ] No tables accidentally bypass RLS

## 2. Policy Coverage

### SELECT Policies
- [ ] All tables have SELECT policies
- [ ] Policies use `USING` clause correctly
- [ ] Anonymous access properly restricted
- [ ] Authenticated users see only authorized data

### INSERT Policies
- [ ] All tables have INSERT policies
- [ ] Policies use `WITH CHECK` clause (not just `USING`)
- [ ] Users cannot insert with other users' IDs
- [ ] Foreign key relationships respect ownership

### UPDATE Policies
- [ ] All tables have UPDATE policies
- [ ] Policies use both `USING` and `WITH CHECK`
- [ ] Users cannot transfer ownership to other users
- [ ] Partial updates don't bypass checks

### DELETE Policies
- [ ] All tables have DELETE policies
- [ ] Soft delete tables have UPDATE instead of DELETE
- [ ] Cascade deletes respect RLS
- [ ] Users cannot delete others' data

## 3. User Isolation

- [ ] Users can only read their own data
- [ ] Users can only insert data with their own user_id
- [ ] Users cannot update other users' data
- [ ] Users cannot delete other users' data
- [ ] Test with: `bash scripts/test-user-isolation.sh --all`

## 4. Multi-Tenant Isolation

- [ ] Organization members can only access org data
- [ ] Users not in org cannot access org data
- [ ] Removed members lose access immediately
- [ ] Cross-org data access is blocked
- [ ] Test with: `bash scripts/test-multi-tenant-isolation.sh --test-members`

## 5. Anonymous Access

- [ ] Anonymous users cannot read protected tables
- [ ] Anonymous users cannot insert/update/delete
- [ ] Public data correctly designated
- [ ] `auth.uid()` null handling is safe
- [ ] Test with: `bash scripts/test-anonymous-access.sh --test-null-uid`

## 6. Role-Based Access

- [ ] Admin role has appropriate full access
- [ ] Editor role limited to read/write (no delete)
- [ ] Viewer role is read-only
- [ ] Roles use `app_metadata` not `user_metadata`
- [ ] Users cannot escalate their own privileges
- [ ] Test with: `bash scripts/test-role-permissions.sh --test-escalation`

## 7. Policy Implementation

### Correct Patterns
- [ ] Use `(SELECT auth.uid())` for performance
- [ ] Use `IS NOT NULL` checks for auth.uid()
- [ ] Specify roles with `TO authenticated` or `TO anon`
- [ ] Complex logic in security definer functions
- [ ] Policies are named descriptively

### Anti-Patterns Avoided
- [ ] No direct `auth.uid()` comparisons (wrap in SELECT)
- [ ] No policies with only `true` for protected data
- [ ] No `user_metadata` used for authorization
- [ ] No missing `WITH CHECK` on INSERT/UPDATE
- [ ] No service key exposed to clients

## 8. Performance Optimization

- [ ] Indexes on columns used in policies
  - [ ] `CREATE INDEX idx_table_user_id ON table(user_id)`
  - [ ] `CREATE INDEX idx_table_org_id ON table(organization_id)`
- [ ] Auth functions wrapped: `(SELECT auth.uid())`
- [ ] Client queries include explicit filters
- [ ] Complex joins avoided in policies
- [ ] Role specified in policies: `TO authenticated`

## 9. Testing Coverage

- [ ] All RLS tests pass: `bash scripts/run-all-rls-tests.sh`
- [ ] User isolation verified
- [ ] Multi-tenant isolation verified
- [ ] Anonymous access verified
- [ ] Role permissions verified
- [ ] Edge cases tested (null values, removed users, etc.)

## 10. Documentation

- [ ] RLS policies documented in migration files
- [ ] Policy decisions explained in comments
- [ ] Security model documented for team
- [ ] Common patterns documented
- [ ] Breaking changes to policies documented

## 11. CI/CD Integration

- [ ] RLS tests run in CI pipeline
- [ ] Coverage audit runs on every PR
- [ ] Tests block deployment on failure
- [ ] Security regression tests in place
- [ ] Performance benchmarks tracked

## 12. Monitoring & Auditing

- [ ] Slow policy queries identified
- [ ] Policy changes logged
- [ ] Failed access attempts logged
- [ ] Regular security audits scheduled
- [ ] Metrics on policy performance

## 13. Common Vulnerabilities

### Critical Issues
- [ ] No tables without RLS in public schema
- [ ] No service keys in client code
- [ ] No cross-tenant data leaks
- [ ] No privilege escalation possible

### High Priority
- [ ] No missing WITH CHECK clauses
- [ ] No improper NULL handling
- [ ] No unindexed policy columns
- [ ] No role checks using user_metadata

### Medium Priority
- [ ] No overly permissive anonymous access
- [ ] No missing indexes on policy columns
- [ ] No complex joins slowing policies
- [ ] No undocumented policy changes

## 14. Production Deployment

- [ ] All tests passing
- [ ] No security issues found
- [ ] Performance acceptable
- [ ] Team reviewed RLS changes
- [ ] Rollback plan in place
- [ ] Monitoring configured
- [ ] Documentation updated

## 15. Post-Deployment

- [ ] Monitor for slow queries
- [ ] Check for failed access attempts
- [ ] Verify expected behavior
- [ ] User feedback collected
- [ ] Performance metrics reviewed
- [ ] Schedule next security audit

---

## Quick Audit Commands

```bash
# Run complete test suite
bash scripts/run-all-rls-tests.sh --ci --report audit-report.json

# Check RLS coverage
bash scripts/audit-rls-coverage.sh --report coverage.md --format markdown

# Test specific concerns
bash scripts/test-user-isolation.sh --all --report isolation.md
bash scripts/test-multi-tenant-isolation.sh --test-members
bash scripts/test-anonymous-access.sh --test-null-uid
bash scripts/test-role-permissions.sh --test-escalation
```

## Critical Checks Before Deploy

```sql
-- 1. All public tables have RLS
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
AND NOT EXISTS (
  SELECT 1 FROM pg_class
  WHERE oid = ('public.' || tablename)::regclass
  AND relrowsecurity
);
-- Should return NO rows

-- 2. All tables have complete policy coverage
SELECT tablename
  COUNT(*) FILTER (WHERE cmd = 'SELECT') as select_policies
  COUNT(*) FILTER (WHERE cmd = 'INSERT') as insert_policies
  COUNT(*) FILTER (WHERE cmd = 'UPDATE') as update_policies
  COUNT(*) FILTER (WHERE cmd = 'DELETE') as delete_policies
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename;
-- All counts should be > 0

-- 3. No policies using user_metadata for auth
SELECT tablename, policyname, qual
FROM pg_policies
WHERE schemaname = 'public'
AND qual::text LIKE '%user_metadata%';
-- Should return NO rows (use app_metadata instead)
```

## Sign-Off

- [ ] Development Lead: _______________
- [ ] Security Review: _______________
- [ ] QA Testing: _______________
- [ ] Product Owner: _______________

**Date:** _______________
