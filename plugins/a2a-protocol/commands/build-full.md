---
name: build-full
description: Complete A2A Protocol setup - initializes project, adds all features (agents, clients, discovery, streaming, production), and validates everything
allowed-tools: SlashCommand, Read, Write, Bash, Grep, Glob, TodoWrite, AskUserQuestion
---

# Build Complete A2A Protocol Stack

This command orchestrates the entire A2A Protocol setup by running all individual commands in the correct order.

**What this command does:**
1. Initializes A2A Protocol in your project
2. Adds agent implementation
3. Adds client implementation
4. Sets up agent discovery
5. Adds streaming support
6. Adds production features
7. Runs comprehensive tests
8. Validates the complete setup

**Usage:**
```bash
/a2a-protocol:build-full
```

## Execution Steps

### Phase 1: Create Todo List

Create a comprehensive todo list to track the full build:

```
TodoWrite([
  { content: "Initialize A2A Protocol project", status: "pending", activeForm: "Initializing A2A Protocol project" },
  { content: "Add agent implementation", status: "pending", activeForm: "Adding agent implementation" },
  { content: "Add client implementation", status: "pending", activeForm: "Adding client implementation" },
  { content: "Setup agent discovery", status: "pending", activeForm: "Setting up agent discovery" },
  { content: "Add streaming support", status: "pending", activeForm: "Adding streaming support" },
  { content: "Add production features", status: "pending", activeForm: "Adding production features" },
  { content: "Run comprehensive tests", status: "pending", activeForm: "Running comprehensive tests" },
  { content: "Display summary", status: "pending", activeForm: "Displaying summary" }
])
```

### Phase 2: Ask User Preferences

Use AskUserQuestion to understand what features they want:

```
AskUserQuestion({
  questions: [
    {
      question: "Which programming language will you use for A2A implementation?",
      header: "Language",
      multiSelect: false,
      options: [
        { label: "Python", description: "Python with async/await support" },
        { label: "TypeScript", description: "TypeScript with Node.js" },
        { label: "JavaScript", description: "JavaScript with Node.js" },
        { label: "Java", description: "Java with Spring Boot or standalone" },
        { label: "Go", description: "Go with standard library" }
      ]
    },
    {
      question: "Which features do you want to include?",
      header: "Features",
      multiSelect: true,
      options: [
        { label: "Agents (Recommended)", description: "Build A2A-compatible agents" },
        { label: "Clients (Recommended)", description: "Create clients to communicate with agents" },
        { label: "Discovery", description: "Enable agent discovery mechanisms" },
        { label: "Streaming", description: "Add streaming response support" }
      ]
    },
    {
      question: "What type of deployment?",
      header: "Deployment",
      multiSelect: false,
      options: [
        { label: "Development", description: "Local development setup" },
        { label: "Production", description: "Production-ready with monitoring, security, scaling" }
      ]
    }
  ]
})
```

### Phase 3: Initialize Project

Mark first todo as in_progress and run init:

```
TodoWrite(update first todo to in_progress)
SlashCommand(/a2a-protocol:init)
TodoWrite(mark first todo completed)
```

Wait for initialization to complete before proceeding.

### Phase 4: Add Agent Implementation (if selected)

If user selected "Agents" feature:

```
TodoWrite(update second todo to in_progress)
SlashCommand(/a2a-protocol:add-agent)
TodoWrite(mark second todo completed)
```

**CRITICAL:** Wait for this command to complete before moving to next step.

### Phase 5: Add Client Implementation (if selected)

If user selected "Clients" feature:

```
TodoWrite(update third todo to in_progress)
SlashCommand(/a2a-protocol:add-client)
TodoWrite(mark third todo completed)
```

**CRITICAL:** Wait for this command to complete before moving to next step.

### Phase 6: Setup Discovery (if selected)

If user selected "Discovery" feature:

```
TodoWrite(update fourth todo to in_progress)
SlashCommand(/a2a-protocol:add-discovery)
TodoWrite(mark fourth todo completed)
```

**CRITICAL:** Wait for this command to complete before moving to next step.

### Phase 7: Add Streaming (if selected)

If user selected "Streaming" feature:

```
TodoWrite(update fifth todo to in_progress)
SlashCommand(/a2a-protocol:add-streaming)
TodoWrite(mark fifth todo completed)
```

**CRITICAL:** Wait for this command to complete before moving to next step.

### Phase 8: Add Production Features (if production deployment)

If user selected "Production" deployment:

```
TodoWrite(update sixth todo to in_progress)
SlashCommand(/a2a-protocol:add-production)
TodoWrite(mark sixth todo completed)
```

**CRITICAL:** Wait for this command to complete before moving to next step.

### Phase 9: Run Tests

Run comprehensive test suite:

```
TodoWrite(update seventh todo to in_progress)
SlashCommand(/a2a-protocol:test)
TodoWrite(mark seventh todo completed)
```

### Phase 10: Display Summary

Mark final todo as in_progress and display completion summary:

```
TodoWrite(update eighth todo to in_progress)
```

Display summary showing:

```markdown
# A2A Protocol - Build Complete ✅

## Configuration
- **Language:** [selected language]
- **Features Installed:**
  - ✅ A2A Protocol initialized
  - [✅/❌] Agent implementation
  - [✅/❌] Client implementation
  - [✅/❌] Agent discovery
  - [✅/❌] Streaming support
  - [✅/❌] Production features
- **Deployment Type:** [Development/Production]

## What Was Created
- Configuration files
- [If agents] Agent implementation with A2A protocol support
- [If clients] Client library for communicating with A2A agents
- [If discovery] Discovery service for finding agents
- [If streaming] Streaming response handlers
- [If production] Monitoring, security, and scaling configuration
- Test suite and validation scripts

## Next Steps
1. Review generated code in your project
2. Configure environment variables in .env
3. Start your A2A agent/client:
   - Python: `python main.py`
   - TypeScript: `npm start`
   - Java: `mvn spring-boot:run`
   - Go: `go run main.go`
4. Test the implementation:
   ```bash
   /a2a-protocol:test
   ```
5. Explore the documentation in docs/a2a/

## Available Commands
- `/a2a-protocol:add-agent` - Add more agents
- `/a2a-protocol:add-client` - Add more clients
- `/a2a-protocol:add-discovery` - Update discovery config
- `/a2a-protocol:add-streaming` - Modify streaming setup
- `/a2a-protocol:test` - Run tests again

Your A2A Protocol stack is ready! 🚀
```

Mark final todo as completed.

## Important Notes

**Sequential Execution:**
- This command runs other slash commands ONE AT A TIME
- Each command must complete before the next one starts
- DO NOT run commands in parallel - they will queue and fail

**Error Handling:**
- If any command fails, stop execution
- Display error message and which step failed
- Provide guidance on how to fix the issue
- Allow user to retry or continue manually

**Customization:**
- User chooses which features to install
- Only selected features are added
- Minimal setup if user wants basic features
- Full stack if user wants everything

This orchestrator command provides a streamlined way to get a complete A2A Protocol setup without running each command individually.
