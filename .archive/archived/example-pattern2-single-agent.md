---
allowed-tools: Task(*), Read(*), Bash(*)
description: Refactor code for better maintainability
argument-hint: <file-or-directory>
---

**Arguments**: $ARGUMENTS

## Step 1: Validate Target

Verify target exists:

!{bash test -e "$ARGUMENTS" && echo "Target found" || echo "Target not found"}

## Step 2: Analyze Code Quality

Load target files for analysis:

@$ARGUMENTS

## Step 3: Delegate to Refactoring Agent

Task(
  description="Refactor code",
  subagent_type="code-refactorer",
  prompt="Refactor the code in $ARGUMENTS.

**Analysis Requirements:**
- Identify duplicate code patterns
- Find complex functions that need simplification
- Detect performance bottlenecks
- Suggest architectural improvements

**Refactoring Tasks:**
- Extract repeated logic into shared utilities
- Simplify complex conditional logic
- Optimize database queries
- Improve naming and structure

**Deliverables:**
- Refactored code with improvements
- Summary of changes made
- Performance impact analysis
- Testing recommendations"
)

## Step 4: Review Results

Display refactoring summary and next steps for testing.
