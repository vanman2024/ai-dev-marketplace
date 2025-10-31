# Supabase Schema Validation Skill

Comprehensive database schema validation tools for Supabase/PostgreSQL projects. Validates SQL syntax, naming conventions, constraints, indexes, and RLS policies before deployment.

## Overview

This skill provides automated validation for database schemas to catch issues before they reach production. It checks for:

- **SQL Syntax** - PostgreSQL compliance, reserved keywords, data types
- **Naming Conventions** - snake_case tables/columns, proper constraint naming
- **Constraints** - Primary keys, foreign keys, unique constraints, check constraints
- **Indexes** - Foreign key indexes, RLS policy indexes, performance optimization
- **Row Level Security** - RLS enabled, policies defined, proper roles specified

## Quick Start

### Validate a Single Migration

```bash
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/20250126_add_users_table.sql
```

### Validate All Migrations

```bash
bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
  supabase/migrations/
```

### Review the Report

```bash
cat validation-report.md
```

## Installation

No installation required! The validation scripts are self-contained bash scripts that use standard Unix tools.

**Optional dependencies:**
- PostgreSQL client tools (`psql`) for advanced syntax validation
- `trash-put` for safe file operations (recommended but not required)

## Directory Structure

```
schema-validation/
├── SKILL.md                    # Skill manifest
├── README.md                   # This file
├── scripts/                    # Validation scripts
│   ├── validate-sql-syntax.sh  # SQL syntax validation
│   ├── validate-naming.sh      # Naming convention checks
│   ├── validate-constraints.sh # Constraint validation
│   ├── validate-indexes.sh     # Index analysis
│   ├── validate-rls.sh         # RLS policy validation
│   └── full-validation.sh      # Run all validations
├── templates/                  # Configuration templates
│   ├── validation-rules.json   # Validation rule configuration
│   ├── naming-conventions.json # Naming convention patterns
│   ├── validation-report-template.md
│   └── sql-best-practices.md   # Best practices checklist
└── examples/                   # Usage examples
    ├── validation-workflow.md  # Development workflow guide
    ├── common-issues.md        # Common problems and fixes
    └── ci-integration.md       # CI/CD integration examples
```

## Validation Scripts

### validate-sql-syntax.sh

Validates PostgreSQL SQL syntax and checks for common errors.

**Checks:**
- PostgreSQL syntax compliance (with psql if available)
- Reserved keyword usage
- Statement termination (semicolons)
- Deprecated data types (MONEY, SERIAL)
- Proper UUID defaults
- Common typos and syntax errors

**Usage:**
```bash
bash scripts/validate-sql-syntax.sh <sql-file>
```

### validate-naming.sh

Enforces consistent naming conventions across your schema.

**Checks:**
- Table naming (lowercase, snake_case, plural)
- Column naming (lowercase, snake_case, singular)
- Constraint naming (pk_, fk_, uq_, ck_ prefixes)
- Index naming (idx_, uidx_ prefixes)
- Reserved keyword avoidance

**Usage:**
```bash
bash scripts/validate-naming.sh <sql-file>
```

### validate-constraints.sh

Validates database constraints and data integrity rules.

**Checks:**
- Primary key existence on all tables
- Foreign key definitions and actions
- Unique constraints on appropriate columns
- Check constraints for business rules
- NOT NULL constraints
- Default values
- Constraint naming conventions

**Usage:**
```bash
bash scripts/validate-constraints.sh <sql-file>
```

### validate-indexes.sh

Analyzes indexing strategy for performance and correctness.

**Checks:**
- Foreign key columns have indexes
- RLS policy columns are indexed
- Common search columns indexed
- Duplicate index detection
- Proper index types (GIN for JSONB, etc.)
- Multi-column index optimization
- Partial index opportunities

**Usage:**
```bash
bash scripts/validate-indexes.sh <sql-file>
```

### validate-rls.sh

Validates Row Level Security configuration.

**Checks:**
- RLS enabled on public tables
- Policy existence for tables with RLS
- Role specification (TO authenticated, TO anon)
- Policy coverage (SELECT, INSERT, UPDATE, DELETE)
- WITH CHECK clauses on INSERT/UPDATE
- Performance optimization (indexes, subqueries)
- Security best practices

**Usage:**
```bash
bash scripts/validate-rls.sh <sql-file>
```

### full-validation.sh

Runs all validation scripts and generates a comprehensive report.

**Features:**
- Validates multiple files or entire directories
- Aggregates results from all validators
- Generates markdown report with summary statistics
- Returns proper exit codes for CI/CD integration
- Highlights errors, warnings, and informational items

**Usage:**
```bash
bash scripts/full-validation.sh <file-or-directory> [report-output.md]
```

## Configuration

### Validation Rules

Customize validation behavior by editing `templates/validation-rules.json`:

```json
{
  "naming": {
    "tables": {
      "case": "snake_case"
      "plural": true
      "max_length": 63
    }
  }
  "constraints": {
    "primary_key": {
      "required_on_all_tables": true
    }
  }
  "rls": {
    "require_on_public_tables": true
  }
}
```

### Naming Conventions

Define naming patterns in `templates/naming-conventions.json`:

```json
{
  "constraints": {
    "primary_key": {
      "pattern": "^pk_[a-z][a-z0-9_]*$"
      "template": "pk_{table_name}"
    }
    "foreign_key": {
      "pattern": "^fk_[a-z][a-z0-9_]*_[a-z][a-z0-9_]*$"
      "template": "fk_{table}_{referenced_table}"
    }
  }
}
```

## Integration

### Pre-Commit Hook

```bash
#!/bin/bash
SQL_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.sql$')

if [ -n "$SQL_FILES" ]; then
  bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
    supabase/migrations/

  if [ $? -ne 0 ]; then
    echo "Schema validation failed - check validation-report.md"
    exit 1
  fi
fi
```

### GitHub Actions

```yaml
- name: Validate Database Schema
  run: |
    bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh \
      supabase/migrations/

    if grep -q "ERROR" validation-report.md; then
      exit 1
    fi
```

See `examples/ci-integration.md` for more CI/CD examples.

## Exit Codes

All validation scripts follow standard Unix exit code conventions:

- `0` - Validation passed (no errors)
- `1` - Validation failed (errors found)

**Note:** Warnings do not cause scripts to exit with error code 1.

## Severity Levels

### ERROR (Red)
**Must be fixed before deployment**
- Missing primary keys
- Invalid SQL syntax
- RLS not enabled on public tables
- Uppercase identifiers

### WARNING (Yellow)
**Should be reviewed and fixed**
- Unnamed constraints
- Missing indexes on foreign keys
- Reserved keyword usage
- Complex RLS policies

### INFO (Blue)
**Suggestions for improvement**
- Potential index opportunities
- Best practice recommendations
- Performance optimization hints

## Common Issues

See `examples/common-issues.md` for a comprehensive list of common schema problems and their solutions.

### Most Common Fixes

1. **Add primary key:**
   ```sql
   id UUID CONSTRAINT pk_users PRIMARY KEY DEFAULT gen_random_uuid()
   ```

2. **Enable RLS:**
   ```sql
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   ```

3. **Add RLS policy:**
   ```sql
   CREATE POLICY users_select_own ON users
     FOR SELECT TO authenticated
     USING (id = auth.uid());
   ```

4. **Index foreign key:**
   ```sql
   CREATE INDEX idx_posts_user_id ON posts (user_id);
   ```

## Validation Workflow

Complete development workflow with validation:

1. **Create migration**
   ```bash
   supabase migration new add_feature
   ```

2. **Write SQL**
   ```sql
   -- Write your schema changes
   ```

3. **Validate**
   ```bash
   bash scripts/full-validation.sh supabase/migrations/latest.sql
   ```

4. **Fix issues**
   ```bash
   # Review validation-report.md and fix errors
   ```

5. **Re-validate**
   ```bash
   bash scripts/full-validation.sh supabase/migrations/latest.sql
   ```

6. **Apply migration**
   ```bash
   supabase db push
   ```

See `examples/validation-workflow.md` for detailed workflow examples.

## Best Practices

1. **Validate before every commit** - Use pre-commit hooks
2. **Fix errors immediately** - Don't accumulate validation debt
3. **Review warnings** - They often indicate potential issues
4. **Integrate into CI/CD** - Block merges on validation failures
5. **Keep reports** - Archive validation reports for reference
6. **Update rules** - Customize validation rules for your project
7. **Team training** - Ensure team understands validation output

## Troubleshooting

### Script Permission Denied

```bash
chmod +x plugins/supabase/skills/schema-validation/scripts/*.sh
```

### psql Not Found

The scripts work without `psql`, but syntax validation is limited. Install PostgreSQL client tools for full syntax checking:

```bash
# Ubuntu/Debian
sudo apt-get install postgresql-client

# macOS
brew install postgresql

# Windows (WSL)
sudo apt-get install postgresql-client
```

### Validation Hangs

If validation seems stuck, check for:
- Very large SQL files (>10MB)
- Complex regex patterns in scripts
- Network issues (if using psql validation)

## Performance

Validation performance benchmarks:

- **Single file (small):** < 1 second
- **Single file (large):** 2-5 seconds
- **10 migration files:** 5-10 seconds
- **100+ migration files:** 30-60 seconds

**Optimization tips:**
- Run individual validators in parallel
- Cache validation results for unchanged files
- Use partial validation for incremental changes

## Contributing

To add new validation checks:

1. Create new check function in appropriate script
2. Add to validation rules in `templates/validation-rules.json`
3. Document in `templates/sql-best-practices.md`
4. Add examples in `examples/common-issues.md`
5. Test with various SQL patterns

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/current/)
- [Supabase Database Guide](https://supabase.com/docs/guides/database)
- [PostgreSQL Naming Conventions](https://www.postgresql.org/docs/current/sql-syntax-lexical.html)
- [Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)

## Support

For issues, questions, or suggestions:
- Review `examples/common-issues.md` for known problems
- Check `examples/validation-workflow.md` for usage guidance
- Consult `templates/sql-best-practices.md` for best practices

## License

Part of the ai-dev-marketplace Supabase plugin.

---

**Version:** 1.0.0
**Last Updated:** 2025-01-26
**Plugin:** supabase
**Skill Type:** validation
