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

Phase 1: Discovery
Goal: Understand complete server requirements

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for server name
- Use AskUserQuestion to gather comprehensive requirements:
  - Server name and purpose
  - MCP components needed (tools, resources, prompts)
  - Authentication method (OAuth/JWT/Bearer/none)
  - Deployment target (STDIO/HTTP/Cloud)
  - Integrations needed (FastAPI/Claude Desktop)
- Load FastMCP documentation:
  @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md
- Present complete build plan to user for confirmation

Phase 2: Create Base Server
Goal: Initialize server project

Actions:
- Use SlashCommand tool to invoke: /fastmcp:new-server $ARGUMENTS
- The /fastmcp:new-server command will:
  - Load FastMCP documentation
  - Ask language preference (Python or TypeScript)
  - Invoke fastmcp-setup or fastmcp-setup-ts agent
  - Create complete project structure
- Wait for server creation to complete
- Verify server directory exists using Bash
- Update todos with TodoWrite

Phase 3: Add MCP Components
Goal: Add tools, resources, prompts, and/or middleware

Actions:
- Determine component complexity:
  - Count total components to add (tools + resources + prompts)
  - If 50 or fewer: Use SlashCommand: /fastmcp:add-components [component-types]
  - If 51-180 components: Use Task with general-purpose agent for batch implementation
  - If 180+ components OR API wrapper: Use SlashCommand: /fastmcp:add-api-wrapper
- For standard components:
  - Use SlashCommand tool to invoke: /fastmcp:add-components [component-types]
  - The command will handle directly (≤10) or spawn agent (>50)
- For API wrappers (large tool sets from Postman):
  - Use SlashCommand tool to invoke: /fastmcp:add-api-wrapper [collection-name]
  - Generates tools from REST API endpoints
- Wait for completion
- Update todos with TodoWrite

Phase 4: Add Authentication
Goal: Configure authentication if requested

Actions:
- If authentication requested:
  - Use SlashCommand tool to invoke: /fastmcp:add-auth [auth-type]
  - The /fastmcp:add-auth command will:
    - Load FastMCP authentication documentation
    - Read the existing server code
    - Add authentication provider (OAuth, JWT, Bearer)
    - Update environment configuration
    - Add security best practices
  - Wait for completion
- Update todos with TodoWrite

Phase 5: Configure Deployment
Goal: Set up deployment transport

Actions:
- Use SlashCommand tool to invoke: /fastmcp:add-deployment [deployment-type]
- The /fastmcp:add-deployment command will:
  - Load FastMCP deployment documentation
  - Configure transport (HTTP, STDIO, Cloud)
  - Set up server startup code
  - Add deployment configuration files
  - Update README with deployment instructions
- Wait for completion
- Update todos with TodoWrite

Phase 6: Add Integrations
Goal: Configure integrations if requested

Actions:
- If integrations requested:
  - Use SlashCommand tool to invoke: /fastmcp:add-integration [integration-type]
  - The /fastmcp:add-integration command will:
    - Load integration-specific documentation
    - Configure FastAPI/OpenAPI/LLM platform integration
    - Add necessary middleware or routes
    - Update configuration files
  - Wait for completion
- Update todos with TodoWrite

Phase 7: Static Verification
Goal: Verify server structure and syntax

Actions:
- Invoke the appropriate verifier agent:
  - Python: Task tool with fastmcp:fastmcp-verifier-py
  - TypeScript: Task tool with fastmcp:fastmcp-verifier-ts
- The verifier agent will:
  - Check Python/TypeScript syntax
  - Verify all dependencies are installed
  - Validate server structure follows FastMCP patterns
  - Check all imports and decorators are correct
- If validation fails: Fix issues before proceeding
- Update todos based on verification results

Phase 8: Generate Test Suite
Goal: Create comprehensive tests for the server

Actions:
- Use SlashCommand tool to invoke: /fastmcp:test --server-path=. --run --coverage
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
- Wait for test generation and execution
- Review test results for any failures
- Update todos with TodoWrite

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
