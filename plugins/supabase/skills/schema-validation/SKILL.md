---
name: schema-validation
description: Database schema validation tools - SQL syntax checking, constraint validation, naming convention enforcement, and schema integrity verification. Use when validating database schemas, checking migrations, enforcing naming conventions, verifying constraints, or when user mentions schema validation, migration checks, database best practices, or PostgreSQL validation.
allowed-tools: Bash, Read, Write, Grep, Glob
---

# Schema Validation

Comprehensive database schema validation for Supabase/PostgreSQL projects. Validates SQL syntax, naming conventions, constraints, indexes, and RLS policies before deployment.

## Instructions

### 1. Run Full Validation
```bash
cd /path/to/project
bash /home/vanman2025/Projects/ai-dev-marketplace/plugins/supabase/skills/schema-validation/scripts/full-validation.sh <schema-file-or-directory>
```

### 2. Run Individual Validations

**SQL Syntax Validation:**
```bash
bash scripts/validate-sql-syntax.sh <sql-file>
```

**Naming Convention Validation:**
```bash
bash scripts/validate-naming.sh <sql-file>
```

**Constraint Validation:**
```bash
bash scripts/validate-constraints.sh <sql-file>
```

**Index Validation:**
```bash
bash scripts/validate-indexes.sh <sql-file>
```

**RLS Policy Validation:**
```bash
bash scripts/validate-rls.sh <sql-file>
```

### 3. Generate Validation Report
The full validation script generates a detailed markdown report showing:
- Validation results for each check
- Issues found with severity levels (ERROR, WARNING, INFO)
- Recommendations for fixes
- Summary statistics

### 4. Configure Validation Rules
Customize validation rules by editing:
```bash
templates/validation-rules.json
templates/naming-conventions.json
```

## Examples

### Example 1: Validate Migration Before Deployment
```bash
# Validate a new migration file
bash scripts/full-validation.sh supabase/migrations/20250126_add_users_table.sql

# Review the generated report
cat validation-report.md
```

### Example 2: Validate Entire Schema Directory
```bash
# Validate all migration files
bash scripts/full-validation.sh supabase/migrations/

# Check for common issues
grep "ERROR" validation-report.md
```

### Example 3: CI/CD Integration
```bash
# Add to .github/workflows/validate-schema.yml
- name: Validate Database Schema
  run: |
    bash plugins/supabase/skills/schema-validation/scripts/full-validation.sh supabase/migrations/
    if grep -q "ERROR" validation-report.md; then
      exit 1
    fi
```

## Validation Checks

### SQL Syntax (validate-sql-syntax.sh)
- PostgreSQL syntax compliance
- Reserved keyword usage
- Statement termination
- Data type validity

### Naming Conventions (validate-naming.sh)
- Lowercase with underscores (snake_case)
- Plural table names
- Singular column names
- Constraint naming patterns (fk_, uq_, ck_, pk_)
- Index naming patterns (idx_, uidx_)

### Constraints (validate-constraints.sh)
- Primary key existence
- Foreign key references
- Unique constraint usage
- Check constraint validity
- NOT NULL enforcement

### Indexes (validate-indexes.sh)
- Index coverage for foreign keys
- Index coverage for RLS policy columns
- Duplicate index detection
- Index naming conventions

### RLS Policies (validate-rls.sh)
- RLS enabled on public tables
- Policy existence for CRUD operations
- Role specification (authenticated, anon)
- Performance optimization (proper indexing)

## Requirements

- PostgreSQL client tools (psql) for syntax validation
- Bash 4.0+ for script execution
- Read access to schema files
- Write access for generating reports

## Best Practices

1. **Run validation before every migration**
2. **Fix ERRORs immediately** - these will cause deployment failures
3. **Address WARNINGs** - these indicate potential issues
4. **Review INFO items** - these are suggestions for improvement
5. **Keep validation rules updated** as your schema evolves
6. **Integrate into CI/CD** to prevent invalid schemas from being deployed

---

**Plugin**: supabase
**Version**: 1.0.0
**Last Updated**: 2025-01-26
