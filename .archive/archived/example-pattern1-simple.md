---
allowed-tools: Read(*), Write(*), Bash(*), Glob(*)
description: Validate project configuration files
argument-hint: [--fix]
---

**Arguments**: $ARGUMENTS

## Step 1: Detect Project Type

Check for configuration files:

!{bash ls package.json pyproject.toml Cargo.toml pom.xml 2>/dev/null || echo "No config files found"}

## Step 2: Load Configuration

Read project configuration:

@package.json
@pyproject.toml
@Cargo.toml

## Step 3: Validate Configuration

Run validation checks:

!{bash npx validate-package-json package.json 2>/dev/null || echo "package.json valid"}

## Step 4: Report Results

Display validation summary:
- Configuration files found
- Validation status
- Recommended fixes (if $ARGUMENTS contains --fix)

## Step 5: Apply Fixes (Optional)

If $ARGUMENTS contains --fix flag:
- Fix common issues
- Update outdated dependencies
- Standardize formatting
