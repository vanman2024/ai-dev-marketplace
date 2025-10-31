# Master Command Pattern Template

This template shows how to structure slash commands using the Goal → Actions → Phase pattern. Choose the appropriate pattern based on your command's complexity.

---

## Pattern Selection Guide

**Pattern 1: Simple (No Agents)**
- Use for: Mechanical tasks, script execution, file operations
- Examples: version bumping, config updates, git operations
- No AI decision-making needed

**Pattern 2: Single Agent**
- Use for: One specialized capability needed
- Examples: project analysis, code generation, architecture design
- One focused AI task

**Pattern 3: Sequential (Multiple Phases)**
- Use for: Multi-phase workflows with dependencies
- Examples: build → test → deploy, setup → configure → verify
- Steps must run in order

**Pattern 4: Parallel (Multiple Agents)**
- Use for: Independent tasks that can run simultaneously
- Examples: lint + test + security audit
- No dependencies between tasks, faster execution

---

## Pattern 1: Simple Command Template

```markdown
---
description: [What this command does]
argument-hint: [argument-placeholder]
allowed-tools: Read, Write, Bash(*), Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: [What this command accomplishes]

Core Principles:
- [Principle 1: e.g., "Detect don't assume"]
- [Principle 2: e.g., "Validate before executing"]
- [Principle 3: e.g., "Provide clear feedback"]

Phase 1: Discovery
Goal: [Understand what needs to be done]

Actions:
- Parse $ARGUMENTS for required inputs
- Detect project type/framework
- Load relevant configuration files
- Example: !{bash ls package.json pyproject.toml 2>/dev/null}

Phase 2: Validation
Goal: [Verify inputs and environment]

Actions:
- Check if required files exist
- Validate input parameters
- Confirm prerequisites met
- Example: @package.json

Phase 3: Execution
Goal: [Perform the main task]

Actions:
- Execute scripts or commands
- Example: !{bash npm run build}
- Handle errors gracefully
- Provide progress feedback

Phase 4: Summary
Goal: [Report results]

Actions:
- Display what was accomplished
- Show next steps if applicable
- Report any warnings or issues
```

---

## Pattern 2: Single Agent Template

```markdown
---
description: [What this command does]
argument-hint: [argument-placeholder]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: [What this command accomplishes]

Core Principles:
- [Principle 1: e.g., "Understand before acting"]
- [Principle 2: e.g., "Ask when uncertain"]
- [Principle 3: e.g., "Follow existing patterns"]

Phase 1: Discovery
Goal: [Gather context and requirements]

Actions:
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - What is the goal?
  - What are the constraints?
  - Any specific requirements?
- Load relevant files for context
- Example: @src/config.ts

Phase 2: Analysis
Goal: [Understand existing codebase and patterns]

Actions:
- Read relevant files identified
- Understand current architecture
- Identify where changes need to be made
- Example: !{bash find src -name "*.ts" | head -10}

Phase 3: Planning
Goal: [Design the approach]

Actions:
- Outline the implementation steps
- Identify potential issues
- Confirm approach with user if significant
- Present clear plan

Phase 4: Implementation
Goal: [Execute with agent]

Actions:

Task(description="[Accomplish task]", subagent_type="[agent-name]", prompt="You are the [agent-name] agent. [Accomplish task] for $ARGUMENTS.

Context: [What context is needed]

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Expected output: [What should be delivered]")

Phase 5: Review
Goal: [Verify results]

Actions:
- Check agent's output
- Verify functionality
- Run validation if applicable
- Example: !{bash npm run typecheck}

Phase 6: Summary
Goal: [Document what was accomplished]

Actions:
- Summarize changes made
- Highlight key decisions
- Suggest next steps
```

---

## Pattern 3: Sequential Multi-Phase Template

```markdown
---
description: [What this command does]
argument-hint: [argument-placeholder]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: [What this command accomplishes - typically a complete workflow]

Core Principles:
- Ask clarifying questions early
- Understand before acting
- Track progress with TodoWrite
- Get user approval before major changes

Phase 1: Discovery
Goal: [Understand what needs to be built]

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for initial context
- If unclear, use AskUserQuestion to gather:
  - What problem are they solving?
  - What should the outcome be?
  - Any constraints or requirements?
- Summarize understanding and confirm with user

Phase 2: Exploration
Goal: [Understand relevant existing code and patterns]

Actions:
- Launch 2-3 explorer agents in parallel to understand different aspects:
  - Agent 1: Find similar features and trace their implementation
  - Agent 2: Map the architecture and key abstractions
  - Agent 3: Analyze current state of related areas
- Each agent should return list of 5-10 key files to read
- Wait for all agents to complete
- Read all files identified by agents to build deep understanding
- Present comprehensive summary of findings
- Update todos as each exploration completes

Phase 3: Clarifying Questions
Goal: [Fill in gaps and resolve ambiguities]

CRITICAL: Do not skip this phase

Actions:
- Review findings and original request
- Identify underspecified aspects:
  - Edge cases
  - Error handling
  - Integration points
  - Design preferences
- Present all questions to user in organized list
- Wait for answers before proceeding
- Update todos

Phase 4: Design
Goal: [Plan the implementation approach]

Actions:
- Based on exploration and answers, design approach
- For complex tasks, consider launching architect agents with different focuses
- Present design to user with:
  - What will be changed
  - Why this approach
  - Any trade-offs
- Get user approval before implementing
- Update todos

Phase 5: Implementation
Goal: [Build the solution]

DO NOT START WITHOUT USER APPROVAL

Actions:
- Read all relevant files identified
- Implement following planned approach
- Follow codebase conventions
- Write clean, documented code
- Update todos as each piece completes

Phase 6: Verification
Goal: [Ensure quality and correctness]

Actions:
- Run tests if applicable
- Run type checking if applicable
- Example: !{bash npm run test && npm run typecheck}
- Verify functionality works as expected
- Update todos

Phase 7: Summary
Goal: [Document what was accomplished]

Actions:
- Mark all todos complete
- Summarize:
  - What was built
  - Key decisions made
  - Files modified
  - Suggested next steps
```

---

## Pattern 4: Parallel Multi-Agent Template

```markdown
---
description: [What this command does - typically comprehensive analysis or audit]
argument-hint: [argument-placeholder]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: [What this command accomplishes - typically running independent checks]

Core Principles:
- Launch independent tasks in parallel for speed
- Consolidate results at the end
- Track progress with TodoWrite
- Provide comprehensive summary

Phase 1: Discovery
Goal: [Understand the target and scope]

Actions:
- Create todo list using TodoWrite
- Parse $ARGUMENTS for target (file, directory, etc.)
- Validate target exists
- Example: !{bash test -e "$ARGUMENTS" && echo "Found" || echo "Not found"}
- Load context about target
- Update todos

Phase 2: Parallel Execution
Goal: [Run multiple independent agents simultaneously]

Actions:

Run the following agents IN PARALLEL (all at once):

Task(description="[First Check Name]", subagent_type="[agent-type-1]", prompt="You are the [agent-type-1] agent. [Accomplish first task] for $ARGUMENTS. Focus on: [Focus area 1], [Focus area 2]. Deliverable: [Expected output]")

Task(description="[Second Check Name]", subagent_type="[agent-type-2]", prompt="You are the [agent-type-2] agent. [Accomplish second task] for $ARGUMENTS. Focus on: [Focus area 1], [Focus area 2]. Deliverable: [Expected output]")

Task(description="[Third Check Name]", subagent_type="[agent-type-3]", prompt="You are the [agent-type-3] agent. [Accomplish third task] for $ARGUMENTS. Focus on: [Focus area 1], [Focus area 2]. Deliverable: [Expected output]")

Wait for ALL agents to complete before proceeding.

Update todos as each agent completes.

Phase 3: Consolidation
Goal: [Combine and analyze results from all agents]

Actions:
- Review all agent outputs
- Identify common themes or critical issues
- Prioritize findings by severity/importance
- Cross-reference findings for validation
- Update todos

Phase 4: Summary
Goal: [Present comprehensive results]

Actions:
- Mark all todos complete
- Present consolidated report:
  - Results from each agent
  - Critical issues (high priority)
  - Warnings and recommendations
  - Suggested next steps
- Organize by priority or category
```

---

## Key Patterns and Syntax

### Arguments
Always use `$ARGUMENTS` never `$1`, `$2`, etc.
```
If user provided --fix flag:
  Parse from $ARGUMENTS
```

### File Loading
Use `@` prefix to load files:
```
@package.json
@src/config.ts
```

### Bash Execution
Use `!{bash command}` for inline execution:
```
!{bash npm run build}
!{bash ls -la | grep package}
```

### Script Execution
Reference shared scripts:
```
!{bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh}
```

### Agent Invocation
Use Task() tool calls with proper parameters:

**Single agent:**
```
Task(description="Validate setup", subagent_type="verifier-agent", prompt="You are the verifier agent. Validate the setup for $ARGUMENTS. Focus on: configuration files, dependencies, environment variables. Return validation report with pass/fail status.")
```

**Parallel agents (run all at once in SAME message):**
```
Task(description="Security check", subagent_type="security-checker", prompt="Audit security for $ARGUMENTS")
Task(description="Code scan", subagent_type="code-scanner", prompt="Scan code quality for $ARGUMENTS")
Task(description="Performance analysis", subagent_type="performance-analyzer", prompt="Analyze performance for $ARGUMENTS")

Wait for ALL agents to complete before proceeding.
```

Claude Code will convert this natural language to actual Task() tool calls during execution.

**Examples:**
- Single agent: "Invoke the refactorer agent to improve code quality"
- Sequential: "First launch the detector agent, then based on findings, invoke the fixer agent"
- Parallel: "Launch 3 reviewer agents in parallel focusing on: security, performance, and maintainability"

### TodoWrite Integration
Track progress throughout:
```
Phase 1: Create initial todo list
Phase N: Update todos as work progresses
Phase Final: Mark all todos complete
```

---

## Best Practices

1. **Ask Before Acting**: Use AskUserQuestion for clarification
2. **Detect Don't Assume**: Check what exists rather than assuming structure
3. **Progressive Disclosure**: Load context as needed, not all upfront
4. **Clear Communication**: Explain what's happening at each phase
5. **Error Handling**: Check for issues and provide helpful messages
6. **User Approval**: Get confirmation before major changes
7. **Track Progress**: Use TodoWrite for complex workflows
8. **Validation**: Verify results before completing

---

## When to Use Each Pattern

**Use Pattern 1 (Simple)** when:
- No AI decision-making needed
- Clear, deterministic steps
- Configuration updates, version bumps
- Running predefined scripts

**Use Pattern 2 (Single Agent)** when:
- One specialized capability needed
- Analysis, generation, or transformation task
- Agent can handle the full scope
- Example: code refactoring, project setup

**Use Pattern 3 (Sequential)** when:
- Multiple phases with dependencies
- User input needed at checkpoints
- Complex workflows: understand → design → implement → verify
- Example: feature development, major refactoring

**Use Pattern 4 (Parallel)** when:
- Multiple independent checks or analyses
- Tasks have no dependencies
- Speed matters (parallel execution faster)
- Example: comprehensive audits, multi-aspect validation
