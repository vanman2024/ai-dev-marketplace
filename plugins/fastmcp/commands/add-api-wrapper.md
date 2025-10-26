---
description: Generate MCP tools from Postman collections to wrap existing APIs. Uses Postman MCP server and Newman to analyze API structure and create FastMCP tool wrappers.
argument-hint: <collection-name-or-id> [--server-path=path]
allowed-tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), mcp__postman(*)
mcp-servers: postman
---

**Arguments**: $ARGUMENTS

Goal: Automatically generate FastMCP tools that wrap existing REST APIs from Postman collections. This command uses the Postman MCP server to access collections and Newman to understand API structure, then generates proper MCP tool decorators with type hints, documentation, and error handling.

Phase 1: Discovery & Collection Analysis
Goal: Find and analyze the Postman collection

Actions:
- Parse $ARGUMENTS for collection name/ID and server path
- Verify Postman MCP server available and Newman installed
- Use mcp__postman tools to list collections and get collection details
- Interactive conversation:
  - "Which Postman collection contains the API you want to wrap?"
  - "Do you want to wrap ALL endpoints or select specific ones?"
  - Show collection structure (folders, requests)
  - Explain what MCP tools will be generated

Phase 2: API Structure Analysis
Goal: Use Newman to understand the API endpoints

Actions:
- Export collection to temporary JSON file
- Run Newman to validate collection and extract:
  - Endpoint paths and HTTP methods
  - Request parameters (path, query, body)
  - Response schemas
  - Authentication requirements
  - Error responses
- Analyze API patterns: RESTful conventions, pagination, error handling, authentication flow

Phase 3: Planning & User Confirmation
Goal: Design the MCP tool wrappers and confirm approach

Actions:
- For each API endpoint, design an MCP tool (convert endpoint to function name, extract parameters, define return types)
- Present plan: number of tools, example signatures, authentication strategy, error handling approach
- Reference FastMCP docs: https://gofastmcp.com/servers/tools, /servers/auth/token-verification
- Confirm before generating code

Phase 4: Implementation
Goal: Generate FastMCP server with API wrapper tools

Invoke the fastmcp-api-wrapper agent to create the API wrapper tools.

The agent should:
- Read existing FastMCP server file or create new one
- For EACH API endpoint, generate MCP tool with @mcp.tool() decorator, proper function naming, type hints, HTTP client code, auth headers, error handling, comprehensive docstring
- Add helper functions for base URL config, auth token management, common error handling, response validation
- Update .env.example with API_BASE_URL, API_KEY/AUTH_TOKEN
- Add dependencies: requests/httpx (Python), axios/fetch (TypeScript)

Provide the agent with:
- Context: Collection structure and API analysis from Phase 2
- Endpoints: List of endpoints to wrap with full specifications
- Server path: Where to add/create the server
- Expected output: Complete working FastMCP server application

Phase 5: Verification
Goal: Validate the generated code works

Actions:
- Run syntax check on generated code
- Verify all dependencies are listed
- Test that server can start
- Optionally run test request with Newman

Phase 6: Documentation & Next Steps
Goal: Guide user on using the API wrapper

Actions:
- Show generated tool list with signatures
- Explain how to configure API credentials
- Show example of calling tools from Claude Desktop
- Provide FastMCP testing guidance
- Suggest enhancements: rate limiting, caching, batch operations, webhooks

Success Criteria:
- ✅ Postman collection successfully analyzed
- ✅ Newman validation passed
- ✅ MCP tools generated for all selected endpoints
- ✅ Type hints and documentation complete
- ✅ Authentication handling implemented (if needed)
- ✅ Error handling covers common API errors
- ✅ Server can start without errors
- ✅ Environment variables documented in .env.example
