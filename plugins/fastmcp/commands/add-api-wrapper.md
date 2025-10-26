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

Phase 2: API Structure Analysis & Architecture Decision
Goal: Extract endpoint information and determine server architecture

**If using Postman/Newman:**
- Export collection to temporary JSON file
- Run Newman to validate collection and extract:
  - **Total endpoint count** (CRITICAL for architecture decision)
  - Endpoint paths and HTTP methods
  - Request parameters (path, query, body)
  - Response schemas
  - Authentication requirements
  - Error responses
  - Folder structure (for natural toolset groupings)
- Analyze API patterns: RESTful conventions, pagination, error handling, authentication flow
- **Count endpoints by resource/folder** to identify toolset groupings

**If using WebFetch/Playwright:**
- Parse documentation to extract:
  - **Total endpoint count**
  - Endpoint paths and HTTP methods
  - Required and optional parameters
  - Authentication methods (Bearer token, API key, OAuth, etc.)
  - Response formats and schemas
  - Rate limiting information
  - Error response codes
  - Resource groupings (from table of contents/sections)
- Look for OpenAPI/Swagger specs that contain structured endpoint data
- Document any assumptions made due to incomplete documentation

**Architecture Decision (NEW - Critical Step):**

Based on total endpoint count, determine server architecture:

1. **<30 endpoints:** Single server, all tools directly in main file
   - Simple, straightforward implementation
   - No toolsets needed
   - Estimated file size: 400-900 lines

2. **30-80 endpoints:** Ask user to choose:
   - **Option A (Recommended):** Toolsets pattern
     - 5-8 toolsets with default subset
     - CLI: `--toolsets <list>`
     - Estimated: 800-2,000 lines
   - **Option B:** Hybrid approach
     - 20 common tools + generic request tool
     - Simpler but less flexible
     - Estimated: 600-1,200 lines

3. **80-150 endpoints (e.g., GitHub 103, CATS 162):** Toolsets pattern (REQUIRED)
   - 10-20 toolsets organized by resource
   - Default: 5 core toolsets (~30-40% of API)
   - Optional: 10-15 additional toolsets
   - CLI flags: `--toolsets candidates,jobs,companies` or `--toolsets all`
   - Environment: `{API_NAME}_TOOLSETS="core,extended"`
   - **Key benefit:** Agents load only needed toolsets (token efficient)
   - Estimated: 3,000-6,000 lines (but organized into clear sections)

4. **150+ endpoints:** Multiple domain servers
   - Split into 3-5 specialized servers
   - Each server: 30-50 tools
   - Better permission isolation

**Toolset Organization (for Large APIs):**
- Analyze Postman folder structure or API documentation sections
- Identify natural resource groupings
- Calculate tool count per grouping
- Designate 5 most-used groupings as DEFAULT_TOOLSETS
- Remaining groupings become OPTIONAL_TOOLSETS
- Document use cases for each toolset combination

**Present Architecture Recommendation:**
- Show total endpoint count
- Show recommended architecture with reasoning
- If toolsets: show proposed DEFAULT and OPTIONAL toolsets with tool counts
- Explain token efficiency benefits (agents load ~30-40% of tools by default)
- Get user confirmation before proceeding

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

**Provide the agent with:**
- **Architecture:** Which pattern to use (simple, toolsets, or multi-server)
- **Endpoint count:** Total number of endpoints
- **Toolset breakdown** (if using toolsets):
  - DEFAULT_TOOLSETS list with tool counts
  - OPTIONAL_TOOLSETS list with tool counts
  - Toolset groupings (which endpoints belong to which toolset)
- **Context:** Collection structure and API analysis from Phase 2
- **Endpoints:** List of endpoints to wrap with full specifications
- **Server path:** Where to add/create the server
- **Expected output:** Complete working FastMCP server application

**The agent should generate:**

For **Small/Medium APIs (<80 endpoints):**
- Single server file with all tools directly registered
- Standard structure: imports, config, helper functions, tools, main block

For **Large APIs (80+ endpoints) - Toolsets Pattern:**
- Toolset registration functions (one per resource group)
- CLI argument parser with `--toolsets` flag
- Environment variable support (`{API_NAME}_TOOLSETS`)
- Toolset loading logic
- Default toolsets vs optional toolsets
- `--list-toolsets` command to show available toolsets
- Clear section headers separating toolsets

**All servers should include:**
- @mcp.tool() decorator for each endpoint
- Proper function naming (HTTP method + resource)
- Type hints for parameters and returns
- HTTP client code (httpx for Python, fetch for TypeScript)
- Authentication headers
- Error handling (map HTTP status → appropriate exceptions)
- Comprehensive docstrings with endpoint reference
- Helper functions: make_request(), auth headers, error handling
- .env.example with API_BASE_URL, API_KEY
- Dependencies: httpx (Python), node-fetch (TypeScript)

**Documentation to generate:**
- README section explaining toolset usage (if applicable)
- Example .mcp.json configuration
- Common toolset combinations by use case
- Token efficiency explanation

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
