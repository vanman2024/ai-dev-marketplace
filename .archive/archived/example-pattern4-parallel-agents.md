---
allowed-tools: Task(*), Read(*), Bash(*)
description: Comprehensive code audit - runs security, quality, and performance checks in parallel
argument-hint: <directory>
---

**Arguments**: $ARGUMENTS

## Step 1: Validate Target Directory

!{bash test -d "$ARGUMENTS" && echo "Directory exists" || echo "Directory not found"}

## Step 2: Load Context

Read target directory structure:

!{bash find "$ARGUMENTS" -type f -name "*.js" -o -name "*.ts" -o -name "*.py" | head -20}

## Step 3: Run Parallel Audits

Run the following agents IN PARALLEL (all at once):

Task(
  description="Security audit",
  subagent_type="security-checker",
  prompt="Audit $ARGUMENTS for security vulnerabilities.

Check for:
- Exposed secrets or API keys
- SQL injection vulnerabilities
- XSS vulnerabilities
- Insecure dependencies
- Authentication/authorization issues

Report findings with severity levels and remediation steps."
)

Task(
  description="Code quality analysis",
  subagent_type="code-scanner",
  prompt="Analyze code quality in $ARGUMENTS.

Evaluate:
- Code complexity metrics
- Duplicate code detection
- Code smell identification
- Maintainability index
- Test coverage gaps

Provide actionable improvement recommendations."
)

Task(
  description="Performance analysis",
  subagent_type="performance-analyzer",
  prompt="Analyze performance of $ARGUMENTS.

Check for:
- Inefficient algorithms
- Memory leaks
- Database query optimization
- Resource-intensive operations
- Caching opportunities

Suggest optimizations with expected impact."
)

Wait for ALL agents to complete before proceeding.

## Step 4: Consolidate Results

Combine results from all three audits:
- Security findings (critical, high, medium, low)
- Quality issues (refactoring opportunities)
- Performance bottlenecks (optimization targets)

Generate comprehensive audit report with prioritized action items.
