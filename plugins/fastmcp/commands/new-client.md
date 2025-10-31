---
description: Create and setup a new FastMCP client project with Python or TypeScript for connecting to MCP servers
argument-hint: <client-name>
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Create a FastMCP client project for connecting to and interacting with MCP servers. Supports both Python and TypeScript.

Core Principles:
- Ask language preference first (Python or TypeScript)
- Route to correct setup agent based on language
- Follow FastMCP Client SDK patterns
- Create functional client code with proper transport configuration

Phase 1: Discovery & Education
Goal: Understand what the user wants to build through interactive conversation

Actions:
- Parse $ARGUMENTS for project name
- Load FastMCP documentation:
  @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md
- Have an interactive conversation to understand the client:

  **Start with Purpose:**
  - "What MCP server(s) will this client connect to?"
  - "What will this client do? (e.g., 'call tools', 'fetch resources', 'automated workflows')"

  **Explain Transport Types:**
  - **STDIO**: For local MCP servers (like Claude Desktop uses)
    - Reference: https://gofastmcp.com/clients/client-transports
  - **HTTP**: For remote MCP servers over HTTP/HTTPS
  - **In-Memory**: For testing or embedded servers
  - Ask which transport they need and explain the differences

  **Explain Client Capabilities:**
  - Show them how clients call tools: `client.call_tool("tool_name", {...})`
  - Show them how to fetch resources: `client.read_resource("uri://resource")`
  - Explain callback handlers for server notifications
  - Reference: https://gofastmcp.com/clients/client-usage

  **Language Selection:**
  - Use AskUserQuestion for language (Python or TypeScript)
  - Explain: Python for scripts/automation, TypeScript for applications

  **Connection Strategy:**
  - Will they connect to multiple servers? Explain connection management
  - Do they need authentication? Explain client-side auth

- Store all choices for Phase 3

Phase 2: Validation
Goal: Verify project doesn't exist and environment is ready

Actions:
- Check if directory already exists
- If Python chosen:
  - Verify Python is installed (Python 3.10+)
  - Check if uv or pip is available
- If TypeScript chosen:
  - Verify Node.js is installed (Node 18+)
  - Check if npm/yarn/pnpm is available
- Confirm project location

Phase 3: Implementation
Goal: Create client project with language-specific agent

Actions:

**If Python was chosen in Phase 1:**

Invoke the fastmcp-client-setup agent to create the FastMCP client application.

The agent should:
- Create Python project structure
- Set up pyproject.toml with FastMCP client dependencies
- Generate starter client code with transport configuration
- Include examples for tool calls, resource fetching
- Create README with setup instructions
- Add .gitignore for Python projects
- Create .env.example if needed

Provide the agent with:
- Context: Client requirements and transport type
- Target: $ARGUMENTS (project name)
- Expected output: Working FastMCP client application

**If TypeScript was chosen in Phase 1:**

Invoke the fastmcp-client-setup-ts agent to create the FastMCP client application.

The agent should:
- Create Node.js/TypeScript project structure
- Set up package.json with FastMCP client TypeScript dependencies
- Create tsconfig.json with ES modules support
- Generate starter client code with TypeScript types and transport configuration
- Include examples for tool calls, resource fetching
- Create README with setup and TypeScript build instructions
- Add .gitignore for Node.js/TypeScript projects
- Create .env.example if needed

Provide the agent with:
- Context: Client requirements and transport type
- Target: $ARGUMENTS (project name)
- Expected output: Working FastMCP client application with TypeScript

Phase 4: Summary
Goal: Guide user on next steps

Actions:
- Show project location and structure
- Display how to connect to MCP servers
- Explain transport configuration
- Provide FastMCP Client documentation links
