# Schema Validation Workflow

This guide demonstrates how to integrate schema validation into your development workflow.

## Table of Contents
1. [Pre-Migration Validation](#pre-migration-validation)
2. [CI/CD Integration](#cicd-integration)
3. [Local Development Workflow](#local-development-workflow)
4. [Team Collaboration](#team-collaboration)

---

## Pre-Migration Validation

### Workflow

```bash
# Step 1: Create your migration file
supabase migration new add_users_table

# Step 2: Write your SQL
cat > supabase/migrations/20250126_add_users_table.sql << 'EOF'
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
  email TEXT UNIQUE NOT NULL
  username TEXT UNIQUE NOT NULL
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can read their own data
CREATE POLICY users_select_own ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Indexes
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_username ON users (username);
EOF

# Step 3: Validate the schema
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/20250126_add_users_table.sql

# Step 4: Review the report
cat validation-report.md

# Step 5: Fix any errors
# ... make corrections based on validation report ...

# Step 6: Re-validate until clean
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/20250126_add_users_table.sql

# Step 7: Apply the migration
supabase db push
```

---

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/validate-schema.yml`:

```yaml
name: Validate Database Schema

on:
  pull_request:
    paths:
      - 'supabase/migrations/**'
      - 'supabase/schema.sql'

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install PostgreSQL tools
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Run schema validation
        run: |
          bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
            supabase/migrations/

      - name: Check for errors
        run: |
          if grep -q "ERROR" validation-report.md; then
            echo "Schema validation failed with errors"
            cat validation-report.md
            exit 1
          fi

      - name: Upload validation report
        uses: actions/upload-artifact@v3
        with:
          name: validation-report
          path: validation-report.md

      - name: Comment on PR
        if: always()
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('validation-report.md', 'utf8');

            github.rest.issues.createComment({
              issue_number: context.issue.number
              owner: context.repo.owner
              repo: context.repo.repo
              body: '## Schema Validation Report\n\n' + report
            });
```

### GitLab CI Example

Create `.gitlab-ci.yml`:

```yaml
validate-schema:
  stage: test
  image: postgres:15
  script:
    - apt-get update && apt-get install -y bash
    - bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh supabase/migrations/
    - |
      if grep -q "ERROR" validation-report.md; then
        echo "Schema validation failed"
        cat validation-report.md
        exit 1
      fi
  artifacts:
    paths:
      - validation-report.md
    when: always
  only:
    changes:
      - supabase/migrations/**
      - supabase/schema.sql
```

---

## Local Development Workflow

### Pre-Commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Check if any SQL files are being committed
SQL_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sql$')

if [ -z "$SQL_FILES" ]; then
  # No SQL files changed, skip validation
  exit 0
fi

echo "Validating SQL schema changes..."

# Run validation on staged SQL files
for file in $SQL_FILES; do
  echo "Validating $file..."

  bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh "$file"

  if [ $? -ne 0 ]; then
    echo "❌ Schema validation failed for $file"
    echo "Review validation-report.md for details"
    exit 1
  fi
done

echo "✅ All SQL files validated successfully"
exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

### Pre-Push Hook

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash

echo "Running full schema validation before push..."

# Validate all migrations
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/

if [ $? -ne 0 ]; then
  echo "❌ Schema validation failed"
  echo ""
  echo "Fix errors in validation-report.md before pushing"
  echo ""
  echo "To skip this check (not recommended):"
  echo "  git push --no-verify"
  exit 1
fi

echo "✅ Schema validation passed"
exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-push
```

---

## Team Collaboration

### PR Template

Create `.github/pull_request_template.md`:

```markdown
## Description
<!-- Describe your changes -->

## Database Changes
<!-- List any schema changes -->

- [ ] New tables
- [ ] New columns
- [ ] New indexes
- [ ] New RLS policies
- [ ] Modified constraints

## Schema Validation

- [ ] Ran `full-validation.sh` on all changed SQL files
- [ ] Fixed all ERRORs
- [ ] Reviewed all WARNINGs
- [ ] Validation report attached

### Validation Results

<details>
<summary>Click to expand validation report</summary>

```
<!-- Paste validation report here -->
```

</details>

## Testing

- [ ] Tested migration in local environment
- [ ] Tested RLS policies with different user roles
- [ ] Verified indexes are used in query plans
- [ ] Tested rollback migration

## Deployment

- [ ] Migration tested in staging
- [ ] Rollback plan documented
- [ ] Team notified of schema changes
```

### Code Review Checklist

Reviewers should verify:

1. **Validation Report Included**
   - PR includes validation-report.md
   - All ERRORs are fixed
   - WARNINGs are addressed or explained

2. **Naming Conventions**
   - Tables use snake_case and plural names
   - Columns use snake_case and singular names
   - Constraints follow naming patterns (pk_, fk_, uq_, ck_)
   - Indexes follow naming patterns (idx_, uidx_)

3. **Schema Design**
   - All tables have primary keys
   - Foreign keys are indexed
   - RLS is enabled on public tables
   - RLS policies exist for necessary operations

4. **Performance**
   - Indexes exist for frequently queried columns
   - Columns in RLS policies are indexed
   - No unnecessary indexes

5. **Security**
   - RLS policies properly restrict access
   - Sensitive data is protected
   - No hardcoded credentials

---

## Example: Complete Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/add-blog-posts
```

### 2. Create Migration

```bash
supabase migration new add_blog_posts
```

### 3. Write SQL

```sql
-- Create blog_posts table
CREATE TABLE blog_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
  title TEXT NOT NULL
  slug TEXT UNIQUE NOT NULL
  content TEXT NOT NULL
  published_at TIMESTAMPTZ
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  CONSTRAINT ck_blog_posts_title_length CHECK (length(title) > 0)
  CONSTRAINT ck_blog_posts_slug_format CHECK (slug ~ '^[a-z0-9-]+$')
);

-- Enable RLS
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY blog_posts_select_published ON blog_posts
  FOR SELECT
  TO authenticated
  USING (published_at IS NOT NULL OR user_id = auth.uid());

CREATE POLICY blog_posts_insert_own ON blog_posts
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY blog_posts_update_own ON blog_posts
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_blog_posts_user_id ON blog_posts (user_id);
CREATE INDEX idx_blog_posts_published_at ON blog_posts (published_at) WHERE published_at IS NOT NULL;
CREATE UNIQUE INDEX uidx_blog_posts_slug ON blog_posts (slug);
```

### 4. Validate Schema

```bash
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/20250126_add_blog_posts.sql
```

### 5. Review Report

```bash
cat validation-report.md
```

### 6. Fix Issues

Make corrections based on validation report.

### 7. Re-validate

```bash
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/20250126_add_blog_posts.sql
```

### 8. Test Locally

```bash
supabase db reset
supabase db push
```

### 9. Commit Changes

```bash
git add .
git commit -m "feat: Add blog_posts table with RLS policies"
```

### 10. Create PR

```bash
gh pr create --title "Add blog posts feature" \
  --body-file .github/pull_request_template.md
```

### 11. Attach Validation Report

Add `validation-report.md` to PR description.

---

## Tips & Best Practices

1. **Validate Early and Often**
   - Run validation before committing
   - Fix errors immediately
   - Don't accumulate validation debt

2. **Automate Everything**
   - Use pre-commit hooks
   - Integrate into CI/CD
   - Require validation in PR process

3. **Team Standards**
   - Document naming conventions
   - Share validation rules
   - Review reports together

4. **Keep Reports**
   - Archive validation reports
   - Track common issues
   - Learn from patterns

5. **Continuous Improvement**
   - Update validation rules as needed
   - Add new checks for new patterns
   - Share learnings with team

---

**Next Steps:**
- Set up pre-commit hooks
- Add CI/CD integration
- Create team documentation
- Train team on validation workflow
