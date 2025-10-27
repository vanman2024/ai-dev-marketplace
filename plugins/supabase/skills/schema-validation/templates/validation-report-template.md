# Database Schema Validation Report

**Project:** {PROJECT_NAME}
**Generated:** {TIMESTAMP}
**Validated By:** {VALIDATOR_VERSION}

## Executive Summary

- **Total Files Validated:** {FILE_COUNT}
- **Total Errors:** {ERROR_COUNT}
- **Total Warnings:** {WARNING_COUNT}
- **Total Info:** {INFO_COUNT}
- **Overall Status:** {STATUS}

---

## Validation Results

### 1. SQL Syntax Validation

**Purpose:** Ensure SQL syntax is valid and follows PostgreSQL standards

**Results:**
- ✅ Passed: {SYNTAX_PASSED}
- ❌ Failed: {SYNTAX_FAILED}

**Issues Found:**

#### Errors
{SYNTAX_ERRORS}

#### Warnings
{SYNTAX_WARNINGS}

---

### 2. Naming Convention Validation

**Purpose:** Ensure consistent snake_case naming and proper constraint naming

**Results:**
- ✅ Passed: {NAMING_PASSED}
- ❌ Failed: {NAMING_FAILED}

**Issues Found:**

#### Errors
{NAMING_ERRORS}

#### Warnings
{NAMING_WARNINGS}

---

### 3. Constraint Validation

**Purpose:** Ensure proper primary keys, foreign keys, and constraints

**Results:**
- ✅ Passed: {CONSTRAINT_PASSED}
- ❌ Failed: {CONSTRAINT_FAILED}

**Issues Found:**

#### Errors
{CONSTRAINT_ERRORS}

#### Warnings
{CONSTRAINT_WARNINGS}

---

### 4. Index Validation

**Purpose:** Ensure proper indexing strategy for performance

**Results:**
- ✅ Passed: {INDEX_PASSED}
- ❌ Failed: {INDEX_FAILED}

**Issues Found:**

#### Errors
{INDEX_ERRORS}

#### Warnings
{INDEX_WARNINGS}

---

### 5. RLS Policy Validation

**Purpose:** Ensure Row Level Security is properly configured

**Results:**
- ✅ Passed: {RLS_PASSED}
- ❌ Failed: {RLS_FAILED}

**Issues Found:**

#### Errors
{RLS_ERRORS}

#### Warnings
{RLS_WARNINGS}

---

## Recommendations

### Critical (Fix Before Deployment)
{CRITICAL_RECOMMENDATIONS}

### Important (Fix Soon)
{IMPORTANT_RECOMMENDATIONS}

### Suggested Improvements
{SUGGESTED_IMPROVEMENTS}

---

## Next Steps

1. **Fix all ERRORS** - These will prevent deployment or cause runtime issues
2. **Review WARNINGS** - These indicate potential problems or best practice violations
3. **Consider INFO items** - These are suggestions for improvement
4. **Re-run validation** after making changes
5. **Integrate into CI/CD** to prevent future issues

---

## Validation Details by File

{FILE_DETAILS}

---

## Appendix

### Validation Tools Used
- SQL Syntax Validator v{VERSION}
- Naming Convention Checker v{VERSION}
- Constraint Validator v{VERSION}
- Index Analyzer v{VERSION}
- RLS Policy Checker v{VERSION}

### References
- [PostgreSQL Naming Conventions](https://www.postgresql.org/docs/current/sql-syntax-lexical.html)
- [Supabase RLS Best Practices](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [PostgreSQL Index Types](https://www.postgresql.org/docs/current/indexes-types.html)

---

**Report End**
