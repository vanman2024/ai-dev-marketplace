---
description: Create and setup a new FastMCP server project with Python or TypeScript. Use add-* commands to add features.
argument-hint: <server-name> [--language=python|typescript] [--purpose="description"] [--skip-questions]
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*)
---

**Arguments**: $ARGUMENTS

Goal: Create a production-ready FastMCP server project foundation with proper structure, FastMCP dependencies, and minimal starter code. Supports both Python and TypeScript. Additional features (tools, auth, deployment) can be added with add-* commands.

Core Principles:
- Accept parameters from parent commands (like build-full-server)
- Ask questions only if parameters not provided
- Route to correct setup agent based on language
- Follow FastMCP SDK documentation patterns
- Create functional starter code, not placeholders

**Parameter Detection:**
- Check if $ARGUMENTS contains `--language=python` or `--language=typescript`
- Check if $ARGUMENTS contains `--purpose="..."`
- Check if $ARGUMENTS contains `--skip-questions`
- If ALL parameters provided OR `--skip-questions` flag present: Skip Phase 1, go directly to Phase 2
- If parameters missing: Run Phase 1 to gather them

Phase 1: Discovery & Education (SKIP if --skip-questions or all params provided)
Goal: Understand what the user wants to build through interactive conversation

Actions:
- Parse $ARGUMENTS for project name and optional parameters
- Load FastMCP documentation for reference:
  @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md
- **ONLY if language not provided**: Ask language preference

  **Language Selection:**
  - Ask: "Which language do you prefer: Python or TypeScript?"
  - Explain differences: Python for simplicity, TypeScript for type safety
  - Store choice for Phase 4

- **ONLY if purpose not provided**: Ask about server purpose

  **Start with Purpose:**
  - Ask: "What will this MCP server do? (e.g., 'access my database', 'process documents', 'integrate with APIs')"
  - Based on their answer, suggest relevant MCP components:
    - If they mention data/database → Suggest Resources with URI templates
    - If they mention actions/operations → Suggest Tools with functions
    - If they mention LLM interactions → Suggest Prompts with templates

- Store all choices for Phase 4
- If called from build-full-server: Skip all questions, use provided requirements

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
- Confirm project location is appropriate

Phase 3: Planning & Documentation Guidance
Goal: Design project structure and educate on FastMCP patterns

Actions:
- Based on their requirements, explain the FastMCP server structure they'll get
- Show them relevant documentation sections:
  - If using Tools: Point to https://gofastmcp.com/servers/tools and explain @mcp.tool() decorator
  - If using Resources: Point to https://gofastmcp.com/servers/resources and explain URI templates
  - If using Prompts: Point to https://gofastmcp.com/servers/prompts and explain template strings
  - If auth chosen: Point to specific auth docs (OAuth, JWT, Bearer)
  - If HTTP/Cloud: Point to deployment docs
- Outline directory structure based on requirements
- Explain what starter code will be generated and why
- Present complete plan with documentation references
- Confirm they understand the architecture before proceeding

Phase 4: Implementation
Goal: Create project with language-specific agent

Actions:

**If Python was chosen in Phase 1:**

Invoke the fastmcp-setup agent to create the FastMCP server application.

The agent should:
- Create Python project structure with proper package layout
- Set up pyproject.toml with FastMCP dependencies
- Generate starter server code with FastMCP decorators
- Include examples for requested features (tools, resources, prompts)
- Set up authentication if requested
- Create README with setup and usage instructions
- Add .gitignore for Python projects
- Create .env.example for environment variables

Provide the agent with:
- Context: Project requirements and features from Phase 1
- Target: $ARGUMENTS (project name)
- Expected output: Complete working FastMCP server application

**If TypeScript was chosen in Phase 1:**

Invoke the fastmcp-setup-ts agent to create the FastMCP server application.

The agent should:
- Create Node.js/TypeScript project structure with proper layout
- Set up package.json with FastMCP TypeScript dependencies
- Create tsconfig.json with ES modules support
- Generate starter server code with TypeScript types
- Include examples for requested features (tools, resources, prompts)
- Set up authentication if requested
- Create README with setup and TypeScript build instructions
- Add .gitignore for Node.js/TypeScript projects
- Create .env.example for environment variables

Provide the agent with:
- Context: Project requirements and features from Phase 1
- Target: $ARGUMENTS (project name)
- Expected output: Complete working FastMCP server application with TypeScript

Phase 5: Post-Setup
Goal: Initialize Python environment and verify setup

Actions:
- Create virtual environment if needed
- Install dependencies
- Run basic validation that server starts
- Display setup summary with next steps

Phase 6: Summary
Goal: Guide user on next steps

Actions:
- Show project location and structure
- Display commands to run the server
- Explain how to add tools, resources, and prompts
- Provide FastMCP documentation links
- Suggest deployment options
