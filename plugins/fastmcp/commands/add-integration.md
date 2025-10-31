---
description: Add integrations to FastMCP server (FastAPI, OpenAPI, LLM platforms, IDEs, authorization)
argument-hint: [integration-type] [--server-path=path]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Integrate existing FastMCP server with external platforms. Supports API frameworks (FastAPI, OpenAPI), LLM platforms (Anthropic, OpenAI, Gemini, ChatGPT), IDEs (Claude Desktop, Cursor, Claude Code), and authorization (Permit.io, Eunomia).

Phase 1: Discovery

Actions:
- Parse $ARGUMENTS for integration type and server path
- Use AskUserQuestion to gather integration categories (can select multiple):
  - API Frameworks: FastAPI (app path, mount path), OpenAPI (spec path, route mapping)
  - LLM Platforms: Anthropic/OpenAI/Gemini/ChatGPT (API key source, features)
  - IDEs: Claude Desktop/Cursor/Claude Code (installation method, config)
  - Authorization: Permit.io/Eunomia (policy config, resources to protect)
- Load FastMCP integrations docs: @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md

Phase 2: Analysis

Actions:
- Find server file and determine language (Python/TypeScript)
- Read existing integrations
- For FastAPI: find and read FastAPI app file
- For OpenAPI: read OpenAPI specification
- Check for conflicts

Phase 3: Implementation

Actions:

Implement directly or use Task with general-purpose agent for complex cases for each integration.

Agent should WebFetch based on integration type:

API Frameworks:
- FastAPI: https://gofastmcp.com/integrations/fastapi
- OpenAPI: https://gofastmcp.com/integrations/openapi

LLM Platforms:
- Anthropic: https://gofastmcp.com/integrations/anthropic
- OpenAI: https://gofastmcp.com/integrations/openai
- Gemini: https://gofastmcp.com/integrations/gemini
- ChatGPT: https://gofastmcp.com/integrations/chatgpt

IDEs:
- Claude Desktop: https://gofastmcp.com/integrations/claude-desktop
- Claude Code: https://gofastmcp.com/integrations/claude-code
- Cursor: https://gofastmcp.com/integrations/cursor

Authorization:
- Permit.io: https://gofastmcp.com/integrations/permit
- Eunomia: https://gofastmcp.com/integrations/eunomia-authorization

FastAPI: Import MCP server, mount at path, configure CORS, add middleware
OpenAPI: Parse spec, generate MCP tools from endpoints, add validation, configure route mapping
LLM Platform: Add client library, configure API key, setup MCP connector, add sampling support
IDE: Generate config files, add installation scripts, configure server command
Authorization: Add middleware, configure policy engine, define resources/permissions, add checks, setup policy files

Phase 4: Configuration & Dependencies

Actions:
- Update .env.example with integration-specific variables (API keys, URLs)
- Add dependencies to requirements.txt/package.json (fastapi, uvicorn, openapi-parser, anthropic, openai, google-generativeai, permit-fastmcp, eunomia)
- Install new dependencies

Phase 5: Documentation & Verification

Actions:
- Add integration section to README (what integrated, how to configure, usage examples)
- For FastAPI: combined endpoint structure
- For OpenAPI: generated tools list
- For LLM: MCP connector usage
- For IDEs: installation steps
- For Authorization: policy configuration
- Run syntax check, verify imports
- Test integration (start combined app, test endpoints, verify tools, test API connection, verify config files, test policy enforcement)
- Check environment variables documented

Phase 6: Summary

Actions:
- Display integration summary (what integrated, configuration needed, testing instructions)
- Show specific results (FastAPI endpoints, OpenAPI tools, connector usage, config locations, policy examples)
- Suggest next steps (test thoroughly, add error handling, add monitoring, update documentation)
