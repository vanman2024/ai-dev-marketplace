# FastMCP Plugin

FastMCP SDK plugin for Claude Code. Build Model Context Protocol (MCP) servers and clients with Python or TypeScript using FastMCP's high-level interface.

## Overview

This plugin provides comprehensive support for FastMCP development including:

- Server and client development with tools, resources, and prompts
- Authentication (OAuth 2.1 with all providers, JWT, Bearer Token)
- Deployment options (HTTP, STDIO for IDEs, FastMCP Cloud)
- Platform integrations (FastAPI, OpenAPI, LLM platforms, IDEs, Authorization)
- Testing and verification tools

## Installation

This plugin is part of the ai-dev-marketplace. To use it:

```bash
# Clone the marketplace
git clone https://github.com/ai-dev-marketplace/ai-dev-marketplace

# The plugin will be auto-loaded from plugins/fastmcp/
```

## Commands

### Core Commands

#### `/fastmcp:new-server`
Create a new FastMCP server project with Python or TypeScript structure and minimal starter code.

**Usage:** `/fastmcp:new-server my-server`

**What it does:**
- Asks which language (Python/TypeScript)
- Creates project structure with proper dependencies
- Generates starter code with MCP server initialization
- Sets up .env configuration
- Provides README with usage instructions

#### `/fastmcp:new-client`
Create a new FastMCP client project for connecting to MCP servers.

**Usage:** `/fastmcp:new-client my-client`

**What it does:**
- Asks which language (Python/TypeScript)
- Creates client project structure
- Generates starter code with transport configuration
- Sets up example tool calls and resource fetching
- Provides connection management patterns

### Feature Addition Commands

#### `/fastmcp:add-api-wrapper`
**Generate MCP tools from Postman collections - Automatically wrap REST APIs.**

**Usage:** `/fastmcp:add-api-wrapper <collection-name-or-id> [--server-path=path]`

**What it does:**
- Uses **Postman MCP server** to access your Postman collections
- Uses **Newman** to analyze API structure and validate endpoints
- Generates MCP tools that wrap REST API endpoints:
  - Proper function signatures from request parameters
  - Type hints from response schemas
  - Error handling for HTTP status codes
  - Authentication header injection
  - Comprehensive documentation from Postman descriptions
- Creates helper functions for API base URL and auth token management
- Updates .env.example with required API credentials
- Adds HTTP client dependencies (requests/httpx for Python, fetch/axios for TypeScript)

**Example Use Cases:**
- Wrap GitHub API: `/fastmcp:add-api-wrapper "GitHub API"`
- Wrap your internal API: `/fastmcp:add-api-wrapper "Company Internal API"`
- Wrap any public API with Postman collection

**Result:** FastMCP server with production-ready tools that bridge external APIs to MCP

#### `/fastmcp:add-components`
**Add MCP components to existing server - ONE command handles ALL component types.**

**Usage:** `/fastmcp:add-components [component-type] [--server-path=path]`

**What it does:**
- Asks which components to add (can select multiple):
  - **Tools** - Executable functions with @mcp.tool()
  - **Resources** - Data access with URI templates
  - **Prompts** - LLM interaction templates
  - **Middleware** - Logging, caching, error handling, timing
  - **Context** - Server context management
  - **Dependencies** - Dependency injection
  - **Elicitation** - User input from server
- Adds requested components with proper decorators
- Includes comprehensive documentation
- Verifies syntax and imports

**Example:** Add tools AND resources AND prompts in one invocation

#### `/fastmcp:add-auth`
**Add authentication to server - ONE command handles ALL authentication methods.**

**Usage:** `/fastmcp:add-auth [auth-type] [--server-path=path]`

**What it does:**
- Asks which authentication method to use:
  - **OAuth 2.1 Providers** (select which):
    - Google, GitHub, Azure (Microsoft Entra)
    - WorkOS / AuthKit, Auth0, AWS Cognito
    - Descope, Scalekit, Supabase
  - **JWT Token Verification** - Token validation with claims
  - **Bearer Token** - API key-based access
  - **Remote OAuth** - Proxy-based OAuth flow
- Configures authentication middleware
- Updates .env.example with required variables
- Provides credential setup instructions
- Optional: Add authorization (Permit.io, Eunomia)

**Example:** Add Google OAuth AND JWT verification in one invocation

#### `/fastmcp:add-deployment`
**Configure deployment for server - ONE command handles ALL deployment types.**

**Usage:** `/fastmcp:add-deployment [deployment-type] [--server-path=path]`

**What it does:**
- Asks which deployment targets (can select multiple):
  - **HTTP/HTTPS** - Web-based access with CORS, SSL/TLS
  - **STDIO** - For Claude Desktop, Cursor, Claude Code
  - **FastMCP Cloud** - Hosted deployment
  - **Production** - Monitoring, error reporting, rate limiting
- Configures transport for each target
- Generates IDE config files (claude_desktop_config.json, etc.)
- Sets up environment-specific configs
- Adds production middleware

**Example:** Add HTTP AND STDIO AND Cloud in one invocation

#### `/fastmcp:add-integration`
**Add integrations to server - ONE command handles ALL integration types.**

**Usage:** `/fastmcp:add-integration [integration-type] [--server-path=path]`

**What it does:**
- Asks which integrations to add (can select multiple):
  - **API Frameworks**:
    - FastAPI - Mount MCP server on existing FastAPI app
    - OpenAPI - Generate MCP tools from OpenAPI spec
  - **LLM Platforms**:
    - Anthropic, OpenAI, Gemini, ChatGPT
  - **IDEs**:
    - Claude Desktop, Cursor, Claude Code
  - **Authorization**:
    - Permit.io - Policy-based authorization
    - Eunomia - Advanced authorization framework
- Configures integration-specific settings
- Updates dependencies
- Generates config files
- Provides usage examples

**Example:** Add FastAPI AND Claude Desktop AND Permit.io in one invocation

### Orchestrator Command

#### `/fastmcp:build-full-server`
Build a complete production-ready server by chaining all feature commands based on requirements.

**Usage:** `/fastmcp:build-full-server my-production-server`

**What it does:**
1. Asks comprehensive questions upfront (components, auth, deployment, integrations)
2. Creates base server with `/fastmcp:new-server`
3. Adds MCP components with `/fastmcp:add-components`
4. Configures authentication with `/fastmcp:add-auth`
5. Sets up deployment with `/fastmcp:add-deployment`
6. Adds integrations with `/fastmcp:add-integration`
7. Verifies everything works
8. Provides complete production-ready server

**Result:** Fully configured server ready for production use

## Architecture: Layered and Composable

The FastMCP plugin follows a layered architecture where each command builds on the previous:

```
1. new-server          → Create base server
2. add-api-wrapper     → Generate tools from Postman collections (NEW!)
3. add-components      → Layer on MCP features
4. add-auth           → Layer on authentication
5. add-deployment     → Layer on deployment config
6. add-integration    → Layer on external integrations
7. build-full-server  → Orchestrates all of the above
```

**Key principle:** ONE command per CATEGORY, not one command per feature. Each command asks which specific options to implement within that category.

**Special Feature:** The `add-api-wrapper` command uses the **Postman MCP server** and **Newman** to automatically generate MCP tools from existing API collections, making it incredibly easy to wrap any REST API as MCP tools.

## Agents

### `fastmcp-setup` (Python)
Creates and initializes new FastMCP server applications using Python with proper project structure, dependencies, and starter code following SDK best practices.

**Used by:** `/fastmcp:new-server` command (when Python is selected)

**Capabilities:**
- Python 3.10+ server project initialization
- FastMCP SDK installation and configuration
- Server starter code generation with decorators
- .env configuration setup
- README generation

### `fastmcp-setup-ts` (TypeScript)
Creates and initializes new FastMCP server applications using TypeScript with proper project structure, dependencies, and starter code following SDK best practices.

**Used by:** `/fastmcp:new-server` command (when TypeScript is selected)

**Capabilities:**
- Node.js 18+ / TypeScript server project initialization
- FastMCP TypeScript SDK installation with type definitions
- Type-safe server starter code generation
- tsconfig.json with ES modules support
- TypeScript build scripts

### `fastmcp-client-setup` (Python)
Creates and initializes new FastMCP client applications using Python for connecting to and interacting with MCP servers.

**Used by:** `/fastmcp:new-client` command (when Python is selected)

**Capabilities:**
- Python 3.10+ client project initialization
- FastMCP Client SDK installation
- Client starter code with transport configuration (HTTP, STDIO, in-memory)
- Example tool calls and resource fetching
- Connection management patterns

### `fastmcp-client-setup-ts` (TypeScript)
Creates and initializes new FastMCP client applications using TypeScript for connecting to and interacting with MCP servers.

**Used by:** `/fastmcp:new-client` command (when TypeScript is selected)

**Capabilities:**
- Node.js 18+ / TypeScript client project initialization
- FastMCP Client TypeScript SDK installation with type definitions
- Type-safe client starter code with transport configuration
- Example tool calls and resource fetching with proper types
- TypeScript build scripts

### `fastmcp-api-wrapper`
Generates MCP tools that wrap REST APIs from Postman collections. Analyzes API structure using Newman and creates production-ready FastMCP tools with proper types, error handling, and documentation.

**Used by:** `/fastmcp:add-api-wrapper`

**Capabilities:**
- Analyze Postman collections via Postman MCP server
- Use Newman to validate and understand API structure
- Generate MCP tools for each API endpoint with:
  - Proper function signatures from request parameters
  - Type hints from response schemas
  - HTTP client code (requests/httpx/fetch/axios)
  - Authentication header injection
  - Error handling for common HTTP status codes
  - Comprehensive docstrings with examples
- Create helper functions for base URL and auth token management
- Add HTTP client dependencies
- Document environment variables in .env.example
- Support both Python and TypeScript

### `fastmcp-features`
Implements FastMCP features for existing server applications. This is the workhorse agent used by ALL feature addition commands.

**Used by:** `/fastmcp:add-components`, `/fastmcp:add-auth`, `/fastmcp:add-deployment`, `/fastmcp:add-integration`

**Capabilities:**
- Add tools, resources, prompts, middleware, context, dependencies
- Configure ALL authentication methods (OAuth providers, JWT, Bearer)
- Set up ALL deployment types (HTTP, STDIO, Cloud)
- Integrate with ALL supported platforms (FastAPI, LLM platforms, IDEs, Authorization)
- WebFetch documentation URLs based on feature type
- Adapt to Python or TypeScript
- Follow SDK best practices

### `fastmcp-verifier-py` (Python)
Validates Python FastMCP applications for correct SDK usage, MCP protocol compliance, and production readiness.

**When to use:** After creating or modifying a Python FastMCP application to verify it follows best practices.

**Validation focuses on:**
- FastMCP SDK installation and configuration
- Python 3.10+ requirements
- MCP protocol compliance (tools, resources, prompts)
- Security (no hardcoded credentials, proper .env setup)
- Deployment readiness
- Documentation completeness

### `fastmcp-verifier-ts` (TypeScript)
Validates TypeScript FastMCP applications for correct SDK usage, type safety, MCP protocol compliance, and production readiness.

**When to use:** After creating or modifying a TypeScript FastMCP application to verify it follows best practices.

**Validation focuses on:**
- FastMCP TypeScript SDK installation and configuration
- Node.js 18+ and TypeScript compilation
- Type safety (proper type annotations, no `any` types)
- tsconfig.json configuration (ES modules, strict mode)
- MCP protocol compliance (tools, resources, prompts)
- Security (no hardcoded credentials, proper .env setup)
- Deployment readiness
- Documentation completeness

## Skills

The FastMCP plugin includes 4 production-ready skills with functional scripts:

### `newman-runner`
Run and analyze Newman (Postman CLI) tests for API validation.

**Scripts:**
- `run-newman.sh` - Execute Newman tests with reporting
- `analyze-newman-results.py` - Parse and display test results
- `validate-collection.sh` - Validate Postman collection structure

**Use when:** Running API tests, validating Postman collections, testing HTTP endpoints

### `api-schema-analyzer`
Analyze OpenAPI and Postman schemas to extract endpoint information for MCP tool generation.

**Scripts:**
- `analyze-openapi.py` - Parse OpenAPI v2/v3 specifications
- `generate-tool-signatures.py` - Generate function signatures from schemas
- `map-to-mcp-tools.py` - Map API endpoints to MCP tool definitions

**Use when:** Analyzing API specifications, extracting endpoint information, generating tool signatures

### `mcp-server-config`
Manage `.mcp.json` MCP server configurations.

**Scripts:**
- `add-mcp-server.sh` - Add new MCP server to configuration
- `remove-mcp-server.sh` - Remove server from configuration
- `list-mcp-servers.sh` - List all configured servers
- `set-server-env.sh` - Configure environment variables for servers
- `validate-mcp-config.sh` - Validate configuration structure

**Use when:** Configuring MCP servers, managing .mcp.json files, setting up server environments

### `postman-collection-manager`
Import, export, and manage Postman collections.

**Scripts:**
- `openapi-to-postman.sh` - Convert OpenAPI specs to Postman collections
- `import-from-url.sh` - Download collections from URLs
- `export-collection.sh` - Export in various formats
- `extract-endpoints.sh` - List all endpoints in collection
- `merge-collections.sh` - Combine multiple collections
- `filter-collection.sh` - Filter collection requests

**Use when:** Working with Postman collections, importing OpenAPI specs, managing API collections

## Documentation

- [FastMCP Official Docs](https://gofastmcp.com/)
- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)
- [FastMCP GitHub](https://github.com/jlowin/fastmcp)

## License

MIT License - see LICENSE file for details
