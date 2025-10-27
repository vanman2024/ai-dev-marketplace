---
description: Add MCP components to existing FastMCP server (tools, resources, prompts, middleware, context, dependencies)
argument-hint: [component-type] [--server-path=path]
allowed-tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

Goal: Add MCP protocol components to an existing FastMCP server. Supports tools, resources, prompts, middleware, context management, dependencies, and elicitation.

Core Principles:
- Ask which component type to add
- Support multiple components in one invocation
- Follow FastMCP SDK patterns from documentation
- Use proper decorators and type hints

Phase 1: Discovery
Goal: Understand which components to add

Actions:
- Parse $ARGUMENTS for component type and server path
- Use AskUserQuestion to gather:
  - Which components to add (can select multiple):
    - Tools (@mcp.tool() - executable functions)
    - Resources (@mcp.resource() - data access with URI templates)
    - Prompts (@mcp.prompt() - LLM interaction templates)
    - Middleware (logging, caching, error handling, timing)
    - Context (server context management)
    - Dependencies (dependency injection)
    - Elicitation (user input from server)
  - Server file location (if not provided)
  - For each selected component, ask specific details:
    - Tools: Function name, parameters, return type, description
    - Resources: URI template, data source, caching strategy
    - Prompts: Template name, variables, use case
    - Middleware: Type (logging, caching, error, timing, custom)
    - Context: State management needs
    - Dependencies: Services to inject
- Load FastMCP documentation:
  @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md

Phase 2: Analysis
Goal: Understand existing server structure

Actions:
- Find server file (server.py, main.py, src/server.ts, src/index.ts)
- Read existing code to understand:
  - Current language (Python or TypeScript)
  - Existing components
  - Import patterns
  - Code style
- Identify where to add new components
- Check for conflicts with existing names

Phase 3: Implementation
Goal: Add selected components

Actions:

Determine complexity:
- Count total components to add
- If adding 10 or fewer components: Implement directly (no agent needed)
- If adding 11-50 components: Optionally use Task with general-purpose agent
- If adding 50+ components OR wrapping API endpoints: Use Task with general-purpose agent

For simple cases (<=10 components), implement directly:
- WebFetch relevant documentation based on component type:
  - Tools: https://gofastmcp.com/servers/tools
  - Resources: https://gofastmcp.com/servers/resources
  - Prompts: https://gofastmcp.com/servers/prompts
  - Middleware: https://gofastmcp.com/servers/middleware
  - Context: https://gofastmcp.com/servers/context
  - Dependencies: https://gofastmcp.com/servers/dependencies
  - Elicitation: https://gofastmcp.com/servers/elicitation
- Read existing server code
- Add component following fetched documentation patterns
- Use Edit tool to add imports and component code
- Add proper type hints/annotations (Python) or TypeScript types
- Include comprehensive docstrings/comments
- Add error handling
- Follow existing code style

For complex cases (>50 components), use Task agent:
- Launch general-purpose agent with context about:
- Context: Component specifications from Phase 1
- Target: Server file path
- Language: Python or TypeScript
- Expected output: Component(s) added to server

Phase 4: Verification
Goal: Verify components work

Actions:
- Run syntax check based on language:
  - Python: `python -m py_compile <file>`
  - TypeScript: `npx tsc --noEmit`
- Verify imports are correct
- Check that server can start
- Display added components summary

Phase 5: Summary
Goal: Show what was added and next steps

Actions:
- List all components added with their signatures
- Show how to test each component:
  - Tools: How to call from client
  - Resources: URI pattern to access
  - Prompts: How to use in LLM interactions
  - Middleware: Execution order and effects
- Suggest next steps:
  - Add authentication if handling sensitive data
  - Configure deployment for production
  - Add testing for new components
  - Consider adding related components
