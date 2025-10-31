# Schema Validation Quick Start

Get started with database schema validation in 5 minutes.

## 1. Validate Your First Migration

```bash
# Navigate to your project
cd /path/to/your/project

# Validate a single migration
bash /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/20250126_your_migration.sql

# View the report
cat validation-report.md
```

## 2. Understand the Output

### ✅ Green = Success
```
✓ All validations passed!
```
Your schema is good to go!

### ❌ Red = Errors (Must Fix)
```
ERRORS (3):
  - Table 'users' has no primary key defined
  - Table 'posts' in public schema must have RLS enabled
  - Column 'userId' contains uppercase letters
```
These **must** be fixed before deployment.

### ⚠️ Yellow = Warnings (Should Review)
```
WARNINGS (2):
  - Foreign key column 'user_id' has no index
  - Unique constraint has no explicit name
```
These **should** be fixed but won't block deployment.

### 💡 Blue = Info (Suggestions)
```
INFO (1):
  - Table 'user' is singular - consider using plural form
```
These are suggestions for improvement.

## 3. Fix Common Issues

### Missing Primary Key
```sql
-- ❌ Before
CREATE TABLE users (
  email TEXT
);

-- ✅ After
CREATE TABLE users (
  id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
  email TEXT NOT NULL
);
```

### Missing RLS
```sql
-- ❌ Before
CREATE TABLE users (
  id UUID PRIMARY KEY
);

-- ✅ After
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_select_own ON users
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());
```

### Wrong Naming Convention
```sql
-- ❌ Before
CREATE TABLE UserProfile (
  userId UUID
  firstName TEXT
);

-- ✅ After
CREATE TABLE user_profiles (
  id UUID CONSTRAINT pk_user_profiles PRIMARY KEY DEFAULT gen_random_uuid()
  user_id UUID NOT NULL
  first_name TEXT NOT NULL
  CONSTRAINT fk_user_profiles_users
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles (user_id);
```

## 4. Set Up Pre-Commit Hook

Prevent bad schemas from being committed:

```bash
# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
SQL_FILES=$(git diff --cached --name-only | grep '\.sql$')

if [ -n "$SQL_FILES" ]; then
  echo "Validating SQL files..."

  bash /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
    supabase/migrations/

  if [ $? -ne 0 ]; then
    echo "❌ Schema validation failed!"
    echo "Review validation-report.md for details"
    exit 1
  fi

  echo "✅ Schema validation passed"
fi
EOF

# Make executable
chmod +x .git/hooks/pre-commit
```

## 5. Add to CI/CD

### GitHub Actions

Create `.github/workflows/validate-schema.yml`:

```yaml
name: Validate Schema

on:
  pull_request:
    paths:
      - 'supabase/migrations/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate Schema
        run: |
          bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
            supabase/migrations/

          if grep -q "ERROR" validation-report.md; then
            cat validation-report.md
            exit 1
          fi

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: validation-report
          path: validation-report.md
```

## 6. Example Workflow

### Daily Development

```bash
# 1. Create migration
supabase migration new add_feature

# 2. Write SQL
vim supabase/migrations/20250126_add_feature.sql

# 3. Validate (runs automatically on commit if hook is set up)
git add .
git commit -m "feat: Add feature"

# 4. If validation passes, push
git push
```

### When Validation Fails

```bash
# 1. Review the report
cat validation-report.md

# 2. Fix the issues
vim supabase/migrations/20250126_add_feature.sql

# 3. Re-validate
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/20250126_add_feature.sql

# 4. Commit when clean
git add .
git commit -m "fix: Address validation issues"
```

## Next Steps

1. **Read the full docs**: `cat README.md`
2. **Learn common issues**: `cat examples/common-issues.md`
3. **Set up workflow**: `cat examples/validation-workflow.md`
4. **Customize rules**: Edit `templates/validation-rules.json`
5. **CI/CD integration**: `cat examples/ci-integration.md`

## Help

### Run Individual Validators

```bash
# Just SQL syntax
bash scripts/validate-sql-syntax.sh <file>

# Just naming conventions
bash scripts/validate-naming.sh <file>

# Just constraints
bash scripts/validate-constraints.sh <file>

# Just indexes
bash scripts/validate-indexes.sh <file>

# Just RLS
bash scripts/validate-rls.sh <file>
```

### Validate Directory

```bash
# All migrations
bash scripts/full-validation.sh supabase/migrations/

# Specific subset
bash scripts/full-validation.sh supabase/migrations/2025*
```

### Custom Report Location

```bash
bash scripts/full-validation.sh <file> custom-report.md
```

## Cheat Sheet

| Task | Command |
|------|---------|
| Validate file | `bash scripts/full-validation.sh <file>` |
| Validate directory | `bash scripts/full-validation.sh <dir>` |
| View report | `cat validation-report.md` |
| Check errors only | `grep ERROR validation-report.md` |
| Check warnings only | `grep WARNING validation-report.md` |
| Make scripts executable | `chmod +x scripts/*.sh` |

---

**You're ready to go!** Start validating your schemas and catch issues before they reach production.
