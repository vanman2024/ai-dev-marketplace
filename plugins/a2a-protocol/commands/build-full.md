---
name: build-full
description: Intelligent A2A Protocol setup - analyzes your project (project.json, features.json, specs/) and builds complete A2A integration tailored to your stack
allowed-tools: Task, Read, Write, Bash, Grep, Glob, TodoWrite
---

# Build Complete A2A Protocol Stack (Intelligent)

This command intelligently analyzes your entire project and builds the appropriate A2A Protocol integration.

**Execution Flow:**
1. **Analyze Project** - Read all project files to understand what you're building
2. **Plan Integration** - Determine which A2A features your project needs
3. **Build Stack** - Delegate to appropriate commands to implement everything

## Phase 1: Project Analysis

### Step 1: Create Analysis Todo List

```
TodoWrite([
  { content: "Analyze project structure and configuration", status: "in_progress", activeForm: "Analyzing project structure and configuration" },
  { content: "Plan A2A integration strategy", status: "pending", activeForm: "Planning A2A integration strategy" },
  { content: "Execute A2A Protocol setup", status: "pending", activeForm: "Executing A2A Protocol setup" },
  { content: "Validate and summarize", status: "pending", activeForm: "Validating and summarizing" }
])
```

### Step 2: Read All Project Configuration Files

Read the following files to understand the project:

**Core Configuration:**
```
Read(.claude/project.json)
Read(features.json)  # If exists
Read(.claude/features.json)  # Alternative location
Read(package.json)  # If exists
Read(requirements.txt)  # If exists
Read(pyproject.toml)  # If exists
Read(pom.xml)  # If exists
Read(go.mod)  # If exists
```

**Architecture Documentation:**
```
Glob(pattern="docs/architecture/**/*.md")
Read all architecture docs found

Glob(pattern="docs/specs/**/*.md")
Read all spec files found

Glob(pattern="specs/**/*.md")
Read all spec files (alternative location)
```

**Feature Specifications:**
```
Glob(pattern="specs/features/*/spec.md")
Read all feature specs

Glob(pattern="specs/features/*/tasks.md")
Read all feature task lists
```

**Application Design:**
```
Read(.claude/application-design.json)  # If exists
Read(docs/application-design.json)  # If exists
```

### Step 3: Analyze Project with Agent

**CRITICAL:** Use the Task tool to delegate analysis to an exploration agent:

```
Task(
  description="Analyze project for A2A integration",
  subagent_type="Explore",
  prompt="Analyze this entire project to determine A2A Protocol integration needs.

**Read and analyze ALL of the following:**

1. **Project Configuration:**
   - .claude/project.json
   - features.json or .claude/features.json
   - package.json / requirements.txt / pyproject.toml / pom.xml / go.mod

2. **Architecture Documentation:**
   - All files in docs/architecture/
   - All files in docs/specs/
   - All files in specs/

3. **Feature Specifications:**
   - All spec.md files in specs/features/
   - All tasks.md files in specs/features/

4. **Application Design:**
   - .claude/application-design.json
   - docs/application-design.json

**Provide comprehensive analysis including:**

- **Project Type:** (web app, API, microservices, CLI tool, etc.)
- **Tech Stack:**
  - Primary language(s)
  - Frameworks (FastAPI, Next.js, Spring Boot, etc.)
  - Database(s)
  - Frontend framework (if applicable)
  - Backend framework (if applicable)

- **Existing Features:**
  - List all features from features.json
  - Summarize what the project does

- **A2A Integration Opportunities:**
  - Would this project benefit from A2A agents? (yes/no and why)
  - Would this project benefit from A2A clients? (yes/no and why)
  - Does this project need agent discovery? (yes/no and why)
  - Does this project need streaming? (yes/no and why)
  - Does this project need production features? (yes/no and why)

- **Recommended A2A Features:**
  - Prioritized list of A2A features to add
  - Justification for each recommendation

- **Implementation Strategy:**
  - Which files would be modified
  - Where A2A code should be added
  - Integration points with existing code

Return this analysis in structured format."
)
```

Wait for analysis agent to complete and return results.

### Step 4: Mark Analysis Complete

```
TodoWrite(mark first todo completed, second todo in_progress)
```

## Phase 2: Planning Integration

Based on the analysis from the agent, create an integration plan.

### Step 1: Extract Key Findings

From the agent's analysis, extract:
- Primary language
- Recommended A2A features
- Integration strategy

### Step 2: Create Implementation Plan

Determine which commands to run in sequence:

**Example decision logic:**
```
If analysis recommends "agents":
  → Queue /a2a-protocol:add-agent

If analysis recommends "clients":
  → Queue /a2a-protocol:add-client

If analysis recommends "discovery":
  → Queue /a2a-protocol:add-discovery

If analysis recommends "streaming":
  → Queue /a2a-protocol:add-streaming

If analysis recommends "production":
  → Queue /a2a-protocol:add-production

Always queue: /a2a-protocol:test (at the end)
```

### Step 3: Display Plan to User

Before executing, show the user what will be done:

```markdown
# A2A Protocol Integration Plan

Based on analysis of your project, here's what will be added:

## Project Summary
- **Type:** [detected project type]
- **Language:** [primary language]
- **Stack:** [key technologies]

## Recommended A2A Features
✅ [Feature 1] - [Reason why]
✅ [Feature 2] - [Reason why]
✅ [Feature 3] - [Reason why]

## Commands That Will Run
1. /a2a-protocol:init
2. /a2a-protocol:add-agent (because: [reason])
3. /a2a-protocol:add-client (because: [reason])
4. /a2a-protocol:add-streaming (because: [reason])
5. /a2a-protocol:test

## Integration Points
- [Where A2A code will be added]
- [Which files will be modified]
- [New files that will be created]

Proceeding with implementation...
```

### Step 4: Mark Planning Complete

```
TodoWrite(mark second todo completed, third todo in_progress)
```

## Phase 3: Execute Integration

### Step 1: Initialize A2A Protocol

**ALWAYS run init first:**

```
SlashCommand(/a2a-protocol:init)
```

**CRITICAL:** Wait for init to complete before proceeding.

### Step 2: Run Recommended Commands Sequentially

Based on the plan, run each command **ONE AT A TIME**:

```
If plan includes "add-agent":
  SlashCommand(/a2a-protocol:add-agent)
  Wait for completion

If plan includes "add-client":
  SlashCommand(/a2a-protocol:add-client)
  Wait for completion

If plan includes "add-discovery":
  SlashCommand(/a2a-protocol:add-discovery)
  Wait for completion

If plan includes "add-streaming":
  SlashCommand(/a2a-protocol:add-streaming)
  Wait for completion

If plan includes "add-production":
  SlashCommand(/a2a-protocol:add-production)
  Wait for completion
```

**CRITICAL RULES:**
- Run commands ONE AT A TIME
- WAIT for each to complete before starting next
- DO NOT run in parallel
- DO NOT skip waiting

### Step 3: Run Tests

After all features are added:

```
SlashCommand(/a2a-protocol:test)
```

Wait for tests to complete.

### Step 4: Mark Execution Complete

```
TodoWrite(mark third todo completed, fourth todo in_progress)
```

## Phase 4: Validation & Summary

### Step 1: Validate Integration

Check that everything was created correctly:

```
Read integration files to verify they exist
Check for common issues
Validate configuration
```

### Step 2: Display Comprehensive Summary

```markdown
# A2A Protocol Integration - Complete ✅

## Project Analysis Results
- **Project Type:** [type]
- **Primary Language:** [language]
- **Tech Stack:** [stack]
- **Features Analyzed:** [count] features from features.json

## What Was Added

### A2A Features Installed
✅ A2A Protocol initialized
[✅] Agent implementation (added because: [reason])
[✅] Client implementation (added because: [reason])
[✅] Agent discovery (added because: [reason])
[✅] Streaming support (added because: [reason])
[✅] Production features (added because: [reason])

### Files Created
- [List of new files]
- [Configuration files]
- [Implementation files]

### Files Modified
- [List of modified files]
- [Integration points]

## Integration Points
Your A2A Protocol integration is connected to:
- [Integration point 1]
- [Integration point 2]
- [Integration point 3]

## Next Steps

1. **Review generated code:**
   - Check files in [directories]
   - Review integration points

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your actual API keys
   ```

3. **Start your application:**
   - [Language-specific start command]

4. **Test A2A features:**
   ```bash
   /a2a-protocol:test
   ```

5. **Explore documentation:**
   - See docs/a2a/ for detailed usage
   - Review generated examples

## Available Commands
Run these to modify your A2A setup:
- `/a2a-protocol:add-agent` - Add more agents
- `/a2a-protocol:add-client` - Add more clients
- `/a2a-protocol:add-discovery` - Update discovery
- `/a2a-protocol:add-streaming` - Modify streaming
- `/a2a-protocol:test` - Run tests again

Your intelligent A2A Protocol integration is complete! 🚀
```

### Step 3: Mark Final Todo Complete

```
TodoWrite(mark fourth todo completed)
```

## Error Handling

If any step fails:

1. **Stop execution immediately**
2. **Display error details:**
   ```
   ❌ A2A Protocol Integration Failed

   Failed at: [which command/step]
   Error: [error message]

   What to do:
   - [Specific guidance for this error]
   - [How to fix]
   - [How to retry]
   ```
3. **Provide recovery options:**
   - Manual command to retry
   - How to continue from where it failed
   - How to rollback if needed

## Key Principles

**Intelligence First:**
- Analyze before acting
- Understand the project before building
- Tailor integration to actual needs

**Project-Driven:**
- Read project.json to understand stack
- Read features.json to understand features
- Read specs/ to understand requirements
- Read architecture docs to understand design

**Context-Aware:**
- Different integration for FastAPI vs Next.js
- Different features for API vs full-stack app
- Different approach for microservices vs monolith

**Sequential Execution:**
- One command at a time
- Wait for completion
- Handle errors gracefully
- Track progress clearly

This intelligent orchestrator adapts to YOUR project and builds exactly what YOU need.
