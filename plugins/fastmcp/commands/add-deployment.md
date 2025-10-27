---
description: Configure deployment for FastMCP server (HTTP, STDIO, FastMCP Cloud, production config)
argument-hint: [deployment-type] [--server-path=path]
allowed-tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

Goal: Configure deployment and transport for an existing FastMCP server. Supports HTTP, STDIO (Claude Desktop/Cursor), FastMCP Cloud, and production configuration.

Phase 1: Discovery

Actions:
- Parse $ARGUMENTS for deployment type and server path
- Use AskUserQuestion to gather deployment targets (can select multiple):
  - HTTP/HTTPS: port, host, CORS, SSL/TLS
  - STDIO: Target IDE (Claude Desktop, Cursor, Claude Code), logging
  - FastMCP Cloud: server name, auth, environment vars
  - Production: environment, monitoring, error reporting, rate limiting
- Load FastMCP deployment docs: @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md

Phase 2: Analysis

Actions:
- Find server file and determine language (Python/TypeScript)
- Read existing transport configuration
- Check for conflicts

Phase 3: Implementation

Actions:

Implement directly or use Task with general-purpose agent for complex cases for each deployment target.

Agent should WebFetch:
- Running Servers: https://gofastmcp.com/deployment/running-server
- HTTP: https://gofastmcp.com/deployment/http
- Cloud: https://gofastmcp.com/deployment/fastmcp-cloud
- Config: https://gofastmcp.com/deployment/server-configuration

HTTP Transport: Configure HTTP, CORS, SSL/TLS, reverse proxy, startup script
STDIO Transport: Configure stdin/stdout, stderr logging, generate IDE configs (claude_desktop_config.json, .cursor/mcp_config.json, .claude/mcp.json)
FastMCP Cloud: Configure fastmcp.json, auth, environment mapping, deployment scripts

Phase 4: IDE Integration & Production Config

Actions:
- Generate IDE config files for selected targets
- Create environment-specific configs (.env.development, .env.production)
- Add production middleware (error handling, timing, rate limiting, health checks)
- Configure logging (structured format, levels, rotation)
- Add monitoring hooks (metrics, error reporting, uptime)

Phase 5: Documentation & Verification

Actions:
- Add deployment section to README (how to run, endpoints, IDE setup, cloud deployment)
- Document environment variables
- Add troubleshooting guide
- Run syntax check for language
- Test HTTP server starts, STDIO mode works, IDE config files valid
- Verify environment variables documented

Phase 6: Summary

Actions:
- Display deployment configurations (port/host for HTTP, IDE files for STDIO, command for Cloud)
- Show run commands for each transport
- Provide testing instructions
- Suggest production checklist (env vars set, auth configured, CORS configured, error handling, logging, health checks)
