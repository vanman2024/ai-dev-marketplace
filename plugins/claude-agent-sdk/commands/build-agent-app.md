---
description: Build a complete Claude Agent SDK application with all features enabled. One command to create production-ready AI agent systems with MCP, subagents, sessions, and deployment.
argument-hint: <project-name>
---

## Build Complete Claude Agent SDK Application

**Project Name**: $ARGUMENTS

This command orchestrates multiple specialized agents to build a complete Claude Agent SDK application.

---

## Phase 1: Gather Requirements

First, understand what the user needs:

```
Task(agent-sdk-setup-agent) Ask the user:
1. Programming language preference (TypeScript recommended, or Python)
2. What type of agent system they want to build
3. Key features needed (MCP servers, subagents, persistence, etc.)
```

---

## Phase 2: Project Setup (Parallel)

Run these tasks in parallel to set up the foundation:

```
Task(agent-sdk-setup-agent) Create the base project structure for "$ARGUMENTS":
- Initialize project with correct dependencies
- Set up TypeScript/Python configuration
- Create basic entry point with query() pattern
- Add environment configuration files
- Create README with setup instructions
```

---

## Phase 3: Core Features (Parallel)

Based on user requirements, run these specialized agents in parallel:

### MCP Integration
```
Task(agent-sdk-mcp-agent) Add MCP integration to "$ARGUMENTS":
- Configure MCP servers (STDIO, HTTP, or SDK)
- Set up tool allowlists
- Create .mcp.json if needed
- Implement custom tools with createSdkMcpServer() if requested
```

### Subagent Architecture
```
Task(agent-sdk-subagents-agent) Implement subagent system for "$ARGUMENTS":
- Design agent architecture (orchestrator, pipeline, or hierarchical)
- Define specialized subagents with descriptions and prompts
- Configure Task tool for agent invocation
- Set up inter-agent communication patterns
```

### Custom Tools & Skills
```
Task(agent-sdk-tools-agent) Add tools and extensibility to "$ARGUMENTS":
- Implement custom tools with Zod schemas
- Create Agent Skills in .claude/skills/
- Set up slash commands in .claude/commands/
- Configure plugin structure if needed
```

---

## Phase 4: Persistence & State

```
Task(agent-sdk-persistence-agent) Implement persistence for "$ARGUMENTS":
- Add session management with resume capability
- Configure file checkpointing if needed
- Set up memory tool integration
- Implement todo tracking for task management
```

---

## Phase 5: Production Readiness

```
Task(agent-sdk-production-agent) Prepare "$ARGUMENTS" for production:
- Configure permission modes
- Implement security hooks (block dangerous commands)
- Set up cost tracking and limits
- Create Dockerfile for deployment
- Add monitoring and logging hooks
```

---

## Phase 6: Verification

Run verifiers based on the language:

### TypeScript
```
Task(agent-sdk-verifier-ts) Verify the TypeScript SDK application "$ARGUMENTS":
- Check SDK installation and version
- Validate TypeScript configuration
- Verify correct API patterns
- Run type checking
- Report any issues
```

### Python
```
Task(agent-sdk-verifier-py) Verify the Python SDK application "$ARGUMENTS":
- Check SDK installation
- Validate async patterns
- Verify correct parameter names (snake_case)
- Report any issues
```

---

## Final Output

After all phases complete, provide the user with:

1. **Summary of Created Files**
   - List all files created with descriptions

2. **Setup Instructions**
   ```bash
   cd $ARGUMENTS
   
   # TypeScript
   npm install
   cp .env.example .env
   # Add your ANTHROPIC_API_KEY to .env
   npm start
   
   # Python
   pip install -r requirements.txt
   cp .env.example .env
   # Add your ANTHROPIC_API_KEY to .env
   python main.py
   ```

3. **Architecture Overview**
   - Describe the agent system architecture
   - Explain subagent roles if applicable
   - Document MCP servers configured

4. **Next Steps**
   - How to customize the agents
   - How to add more tools
   - Deployment recommendations

---

## Example Project Structures

### Full-Featured TypeScript
```
project-name/
├── src/
│   └── index.ts          # Main entry with orchestrator
├── .claude/
│   ├── skills/           # Agent Skills
│   │   └── analysis/
│   │       └── SKILL.md
│   └── commands/         # Slash commands
│       └── analyze.md
├── .mcp.json             # MCP server configuration
├── package.json
├── tsconfig.json
├── .env.example
├── .gitignore
├── Dockerfile            # Production deployment
└── README.md
```

### Full-Featured Python
```
project-name/
├── main.py               # Main entry with orchestrator
├── .claude/
│   ├── skills/
│   │   └── analysis/
│   │       └── SKILL.md
│   └── commands/
│       └── analyze.md
├── .mcp.json
├── requirements.txt
├── .env.example
├── .gitignore
├── Dockerfile
└── README.md
```
