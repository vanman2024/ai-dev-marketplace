---
allowed-tools: Task(*), Read(*), Bash(*), SlashCommand(*)
description: Setup new feature with validation, testing, and documentation
argument-hint: <feature-name>
---

**Arguments**: $ARGUMENTS

## Step 1: Validate Feature Name

!{bash test -n "$ARGUMENTS" && echo "Feature: $ARGUMENTS" || echo "No feature name provided"}

## Step 2: Create Feature Spec

Task(
  description="Create feature spec",
  subagent_type="spec-creator",
  prompt="Create a complete feature spec for $ARGUMENTS.

Generate spec.md with:
- Feature overview and requirements
- Technical approach
- Success criteria
- Testing requirements
"
)

## Step 3: Generate Tests (SlashCommand)

**CRITICAL - SlashCommand Invocation:**

When invoking slash commands:
- Use SlashCommand tool ONLY - do not type the command in your response
- Never mention the command before invoking it
- Invoke silently, then report results after completion

Invoke test generation:

SlashCommand: /testing:test-generate spec/$ARGUMENTS

Wait for test generation to complete before proceeding.

## Step 4: Setup Documentation (SlashCommand)

Invoke documentation initialization:

SlashCommand: /docs:init spec/$ARGUMENTS

Wait for documentation setup to complete.

## Step 5: Generate Task Breakdown (SlashCommand)

Organize tasks for parallel execution:

SlashCommand: /iterate:tasks spec/$ARGUMENTS

## Step 6: Report Setup Complete

Display summary:
- Feature spec created at spec/$ARGUMENTS/spec.md
- Tests scaffolded in tests/
- Documentation initialized in docs/
- Tasks organized in spec/$ARGUMENTS/layered-tasks.md

Next steps:
- Review generated tests
- Begin implementation
- Update documentation as you build
