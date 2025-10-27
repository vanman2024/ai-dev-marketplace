---
description: Build a complete production-ready FastMCP server by orchestrating all feature commands based on requirements
argument-hint: <server-name>
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), SlashCommand(*), TodoWrite(*)
---

**Arguments**: $ARGUMENTS

Goal: Build a complete, production-ready FastMCP server from scratch by chaining all relevant feature commands based on user requirements.

Core Principles:
- Ask comprehensive questions upfront
- Chain slash commands sequentially
- Track progress with TodoWrite
- Build incrementally, validate at each step

Phase 1: Discovery & Documentation Ingestion
Goal: Understand complete server requirements and ingest all relevant documentation

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for server name
- **FIRST: Ask user if they have specification or documentation files to provide**
  - Use AskUserQuestion: "Do you have a specification file, API documentation, or requirements document for this server?"
  - If yes, ask for file path(s) and Read each file completely
  - Store specification details for use in all subsequent phases
- Load FastMCP documentation:
  @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md
- **Based on specification OR via questions**, gather requirements:
  - Server name and purpose (from spec if provided)
  - MCP components needed (tools count, resources, prompts - extract from spec)
  - Authentication method (OAuth/JWT/Bearer/none)
  - Deployment target (STDIO/HTTP/Cloud)
  - Integrations needed (FastAPI/Claude Desktop/Supabase MCP/etc.)
  - Special architecture patterns (if mentioned in spec)
- Present complete build plan to user for confirmation
- **Store all requirements in memory for autonomous execution of phases 2-10**

Phase 2: Create Base Server
Goal: Initialize server project

Actions:
- Use SlashCommand tool to invoke: /fastmcp:new-server $ARGUMENTS
- The /fastmcp:new-server command will:
  - Load FastMCP documentation
  - Ask language preference (Python or TypeScript)
  - Invoke fastmcp-setup or fastmcp-setup-ts agent
  - Create complete project structure
- **CRITICAL: Wait for server creation to complete**
- **Immediately after completion, Read the created server file to understand its structure:**
  - Use Bash to find server path: `find . -name "server.py" -o -name "server.ts" -o -name "main.py"`
  - Use Read tool to read the complete server file
  - Note: Server location, existing tools, import patterns, mcp object name
- Verify server directory exists using Bash
- Update todos with TodoWrite
- **Proceed immediately to Phase 3 without asking more questions**

Phase 3: Add MCP Components
Goal: Add tools, resources, prompts, and/or middleware

Actions:
- **Use requirements from Phase 1 (no new questions)**
- **If user provided specification file, use it to determine what tools to build**
- Determine component complexity:
  - Count total components to add (from Phase 1 requirements or spec)
  - If 50 or fewer: Use SlashCommand: /fastmcp:add-components [component-types]
  - If 51-180 components: Use Task with general-purpose agent for batch implementation
  - If 180+ components OR API wrapper: Use SlashCommand: /fastmcp:add-api-wrapper
- For standard components:
  - **If specification provided: Pass spec details to the command/agent**
  - Use SlashCommand tool to invoke: /fastmcp:add-components [component-types] --server-path=[path]
  - The command will handle directly (≤10) or spawn agent (>50)
  - **Agent receives: Spec file contents, tool descriptions, expected behavior**
- For API wrappers (large tool sets from Postman):
  - Use SlashCommand tool to invoke: /fastmcp:add-api-wrapper [collection-name]
  - Generates tools from REST API endpoints
- **Wait for completion, then Read updated server file to verify tools were added**
- Update todos with TodoWrite
- **Proceed immediately to Phase 4**

Phase 4: Add Authentication
Goal: Configure authentication if requested

Actions:
- **Use requirements from Phase 1 (no new questions)**
- If authentication requested in Phase 1:
  - Use SlashCommand tool to invoke: /fastmcp:add-auth [auth-type] --server-path=[path]
  - The /fastmcp:add-auth command will:
    - Load FastMCP authentication documentation
    - Read the existing server code
    - Add authentication provider (OAuth, JWT, Bearer)
    - Update environment configuration
    - Add security best practices
  - **Wait for completion, then Read updated server file**
- Else: Skip this phase
- Update todos with TodoWrite
- **Proceed immediately to Phase 5**

Phase 5: Configure Deployment
Goal: Set up deployment transport

Actions:
- **Use requirements from Phase 1 (no new questions)**
- Use SlashCommand tool to invoke: /fastmcp:add-deployment [deployment-type] --server-path=[path]
- The /fastmcp:add-deployment command will:
  - Load FastMCP deployment documentation
  - Configure transport (HTTP, STDIO, Cloud) from Phase 1 requirements
  - Set up server startup code
  - Add deployment configuration files
  - Update README with deployment instructions
- **Wait for completion, then Read updated server file and config files**
- Update todos with TodoWrite
- **Proceed immediately to Phase 6**

Phase 6: Add Integrations
Goal: Configure integrations if requested

Actions:
- **Use requirements from Phase 1 (no new questions)**
- If integrations requested in Phase 1:
  - Use SlashCommand tool to invoke: /fastmcp:add-integration [integration-type] --server-path=[path]
  - The /fastmcp:add-integration command will:
    - Load integration-specific documentation
    - Configure FastAPI/OpenAPI/LLM platform integration
    - Add necessary middleware or routes
    - Update configuration files
  - **Wait for completion, then Read updated files**
- Else: Skip this phase
- Update todos with TodoWrite
- **Proceed immediately to Phase 7**

Phase 7: Static Verification
Goal: Verify server structure and syntax

Actions:
- **Use language detected in Phase 2 (no new questions)**
- Invoke the appropriate verifier agent:
  - Python: Task tool with fastmcp:fastmcp-verifier-py subagent_type
  - TypeScript: Task tool with fastmcp:fastmcp-verifier-ts subagent_type
- Provide verifier with server path from Phase 2
- The verifier agent will:
  - Check Python/TypeScript syntax
  - Verify all dependencies are installed
  - Validate server structure follows FastMCP patterns
  - Check all imports and decorators are correct
  - Verify tools from specification were implemented correctly
- If validation fails: Fix issues before proceeding
- Update todos based on verification results
- **Proceed immediately to Phase 8**

Phase 8: Generate Test Suite
Goal: Create comprehensive tests for the server

Actions:
- **Use server path from Phase 2 (no new questions)**
- Use SlashCommand tool to invoke: /fastmcp:test --server-path=[detected-path] --run --coverage
- The /fastmcp:test command will:
  - Analyze server structure (tools, resources, prompts)
  - Invoke fastmcp-tester agent to generate pytest-based tests
  - Generate tests/conftest.py with mcp_client fixture
  - Generate test files for each toolset/module
  - Include parametrized tests for edge cases
  - Add error handling tests
  - Create pytest.ini configuration
  - Run tests if --run flag provided
  - Generate coverage report if --coverage flag provided
- **Wait for test generation and execution**
- Review test results for any failures
- If tests fail: Analyze and fix issues
- Update todos with TodoWrite
- **Proceed immediately to Phase 9**

Phase 9: Environment Configuration & Live Testing
Goal: Configure API keys and test server with live integrations

Actions:
- Create fastmcp.json with environment configuration:
  - Check which API keys are needed (based on tools added)
  - Create deployment.env section with placeholder syntax
  - **CRITICAL - Use ${VAR_NAME} placeholder format:**
    ```json
    {
      "deployment": {
        "env": {
          "CATS_API_KEY": "${CATS_API_KEY}",
          "CATS_MCP_API_KEY": "${CATS_MCP_API_KEY}"
        }
      }
    }
    ```
  - **NEVER hardcode actual key values in fastmcp.json**
  - Keys will be loaded from system environment (bashrc) at runtime
- Verify server code uses os.getenv() for all API keys
- Ensure .gitignore includes fastmcp.json if it contains sensitive config
- Run live integration tests:
  - Start server (FastMCP will interpolate ${VAR} from environment)
  - Test authentication flows with real credentials from bashrc
  - Test API tool calls to external services
  - Test resource fetching from live data sources
  - Verify rate limiting and error handling
  - Monitor for errors or failures
  - Stop server after testing
- Document test results (passed/failed/errors)
- Update todos with TodoWrite

Phase 10: Summary
Goal: Present complete build results

Actions:
- Mark all todos complete
- Display comprehensive summary:
  - Server location and structure
  - Components added (count of tools, resources, prompts)
  - Authentication configured (type and provider)
  - Deployment method (STDIO, HTTP, Cloud)
  - Integrations enabled
  - Test results (passed/failed/coverage %)
  - Live integration test results (if applicable)
  - Commands to run server:
    - Development: `python server.py` or `npm run dev`
    - Production: Deployment-specific instructions
  - Next steps:
    - Add more tools/resources as needed
    - Configure additional integrations
    - Deploy to production environment
    - Monitor and iterate based on usage
