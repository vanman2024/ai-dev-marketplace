---
description: Add authentication to FastMCP server (OAuth 2.1, JWT, Bearer Token, all providers)
argument-hint: [auth-type] [--server-path=path]
allowed-tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

Goal: Add authentication and authorization to an existing FastMCP server. Supports OAuth 2.1 (all providers), JWT token verification, Bearer tokens, and authorization middleware.

Core Principles:
- Ask which authentication method to use
- Support all OAuth providers (Google, GitHub, Azure, WorkOS, Auth0, AWS Cognito, Descope, Scalekit, Supabase)
- Handle both server-side and remote OAuth
- Secure credential management
- Follow FastMCP auth patterns

Phase 1: Discovery
Goal: Understand authentication requirements

Actions:
- Parse $ARGUMENTS for auth type and server path
- Use AskUserQuestion to gather:
  - Authentication method:
    - OAuth 2.1 Providers (select which):
      - Google
      - GitHub
      - Azure (Microsoft Entra)
      - WorkOS / AuthKit
      - Auth0
      - AWS Cognito
      - Descope
      - Scalekit
      - Supabase
    - JWT Token Verification
    - Bearer Token
    - Remote OAuth (proxy)
  - OAuth configuration (if OAuth selected):
    - Client ID source (env variable name)
    - Client secret source (env variable name)
    - Scopes needed
    - Redirect URI
    - Token storage strategy
  - JWT configuration (if JWT selected):
    - JWT secret source
    - Token location (header, cookie)
    - Claims to validate
    - Issuer/audience validation
  - Bearer token configuration (if Bearer selected):
    - Token storage method (env, file, database)
    - Token format
  - Server file location
- Load FastMCP auth documentation:
  @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md

Phase 2: Analysis
Goal: Understand existing server and language

Actions:
- Find server file
- Read existing code to determine:
  - Language (Python or TypeScript)
  - Existing authentication (if any)
  - Import patterns
  - Middleware configuration
- Check for conflicts with existing auth

Phase 3: Implementation
Goal: Add authentication

Actions:

Invoke the fastmcp-features agent to add authentication.

The agent should:
- WebFetch relevant authentication documentation:
  - OAuth Proxy: https://gofastmcp.com/servers/auth/oauth-proxy
  - Remote OAuth: https://gofastmcp.com/servers/auth/remote-oauth
  - Token Verification: https://gofastmcp.com/servers/auth/token-verification
  - Provider-specific docs:
    - Google: https://gofastmcp.com/integrations/google
    - GitHub: https://gofastmcp.com/integrations/github
    - Azure: https://gofastmcp.com/integrations/azure
    - WorkOS: https://gofastmcp.com/integrations/workos + https://gofastmcp.com/integrations/authkit
    - Auth0: https://gofastmcp.com/integrations/auth0
    - AWS Cognito: https://gofastmcp.com/integrations/aws-cognito
    - Descope: https://gofastmcp.com/integrations/descope
    - Scalekit: https://gofastmcp.com/integrations/scalekit
- Add provider-specific imports
- Configure provider with credentials from environment
- Add authentication middleware to server
- Update .env.example with required variables
- Add redirect URI configuration (for OAuth)
- Include error handling for auth failures
- Add authorization middleware if requested:
  - Permit.io: https://gofastmcp.com/integrations/permit
  - Eunomia: https://gofastmcp.com/integrations/eunomia-authorization

Provide the agent with:
- Context: Auth method and configuration from Phase 1
- Target: Server file path
- Language: Python or TypeScript
- Expected output: Authentication configured and working

Phase 4: Configuration Files
Goal: Update environment and documentation

Actions:
- Ensure .env.example has all required variables:
  - OAuth: CLIENT_ID, CLIENT_SECRET, REDIRECT_URI
  - JWT: JWT_SECRET, JWT_ISSUER, JWT_AUDIENCE
  - Bearer: BEARER_TOKEN or token file path
- Add .gitignore entry for .env if missing
- Update README with:
  - How to get OAuth credentials
  - Environment variables needed
  - Authentication flow explanation
  - Testing instructions

Phase 5: Verification
Goal: Verify authentication works

Actions:
- Run syntax check
- Verify imports are correct
- Check .env.example is complete
- Verify .env is in .gitignore
- Scan for hardcoded credentials (should be none)

Phase 6: Summary
Goal: Show configuration and next steps

Actions:
- Display authentication setup
- Show .env variables needed
- Explain how to obtain credentials:
  - Google: https://console.cloud.google.com
  - GitHub: https://github.com/settings/developers
  - Azure: https://portal.azure.com
  - WorkOS: https://workos.com
  - Auth0: https://auth0.com
  - AWS Cognito: https://aws.amazon.com/cognito
  - Descope: https://app.descope.com
  - Scalekit: https://app.scalekit.com
- Provide testing examples
- Suggest adding authorization if needed (Permit.io, Eunomia)
