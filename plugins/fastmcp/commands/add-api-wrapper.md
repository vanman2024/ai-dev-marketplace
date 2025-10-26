---
description: Generate MCP tools from Postman collections to wrap existing APIs. Falls back to WebFetch/Playwright if Postman unavailable. Uses Postman MCP server and Newman to analyze API structure and create FastMCP tool wrappers.
argument-hint: <collection-name-or-id> [--server-path=path]
allowed-tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), WebFetch(*), WebSearch(*), mcp__postman(*)
mcp-servers: postman
---

**Arguments**: $ARGUMENTS

Goal: Automatically generate FastMCP tools that wrap existing REST APIs. Uses Postman collections as primary source, but falls back to WebFetch/Playwright if Postman MCP is unavailable or collection doesn't exist.

Phase 1: Discovery & API Source Determination
Goal: Find API structure from best available source

**Primary Strategy: Postman/Newman**

Actions:
- Parse $ARGUMENTS for collection name/ID and server path
- Check if Postman MCP server is available
- If available:
  - Use mcp__postman tools to list collections and get collection details
  - Interactive conversation:
    - "Which Postman collection contains the API you want to wrap?"
    - "Do you want to wrap ALL endpoints or select specific ones?"
    - Show collection structure (folders, requests)
    - Explain what MCP tools will be generated

**Fallback Strategy: WebFetch/Playwright**

If Postman MCP not available OR collection doesn't exist:
- Use WebSearch to find "{API_NAME} API documentation"
- Use WebFetch to retrieve:
  - Official API documentation pages
  - OpenAPI/Swagger specifications
  - API reference guides
  - Developer portal endpoints
- Check common documentation paths:
  - `/api/docs`
  - `/swagger`
  - `/api-docs`
  - `/docs/api`
- If interactive discovery needed, document that Playwright could be used
- If NO documentation found, use generic REST patterns with clear warnings

Phase 2: API Structure Analysis
Goal: Extract endpoint information from chosen source

**If using Postman/Newman:**
- Export collection to temporary JSON file
- Run Newman to validate collection and extract:
  - Endpoint paths and HTTP methods
  - Request parameters (path, query, body)
  - Response schemas
  - Authentication requirements
  - Error responses
- Analyze API patterns: RESTful conventions, pagination, error handling, authentication flow

**If using WebFetch/Playwright:**
- Parse documentation to extract:
  - Endpoint paths and HTTP methods
  - Required and optional parameters
  - Authentication methods (Bearer token, API key, OAuth, etc.)
  - Response formats and schemas
  - Rate limiting information
  - Error response codes
- Look for OpenAPI/Swagger specs that contain structured endpoint data
- Document any assumptions made due to incomplete documentation

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
