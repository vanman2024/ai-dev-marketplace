---
name: mcp-integration
description: MCP server configuration, Zapier MCP setup, agent tool integration, and security controls. Use when building ElevenLabs agents with MCP tools, configuring external integrations, setting up Zapier MCP, implementing tool approval controls, or when user mentions MCP integration, Model Context Protocol, Zapier MCP, tool security, or agent integrations.
allowed-tools: Bash, Read, Write, Edit
---

# MCP Integration

Complete MCP (Model Context Protocol) integration skill for ElevenLabs Agents Platform. Provides configuration management, security controls, and integration patterns for connecting agents to external tools and data sources.

## Instructions

### Phase 1: MCP Server Configuration

1. **Configure MCP Server Connection**
   - Run: `bash scripts/configure-mcp.sh` to set up MCP server
   - Provide server URL, name, and optional authentication
   - Configure HTTP headers and transport method (SSE or HTTP)

2. **Test MCP Connection**
   - Run: `bash scripts/test-mcp-connection.sh <server-url>` to verify connectivity
   - Validates server availability and tool discovery
   - Reports available tools and their capabilities

3. **Setup Zapier MCP Integration**
   - Run: `bash scripts/setup-zapier-mcp.sh` for Zapier integration
   - Configures access to hundreds of external services
   - Sets up recommended security defaults

### Phase 2: Agent Tool Integration

4. **Configure Agent with MCP Tools**
   - Use template: `templates/agent-mcp-config.json.template`
   - Attach MCP servers to agent configuration
   - Define tool availability and usage patterns

5. **Implement Security Controls**
   - Use template: `templates/tool-approval-config.json.template`
   - Configure tool approval modes (Always Ask, Fine-Grained, No Approval)
   - Define auto-approved, requires-approval, and disabled tools

6. **Validate Tool Permissions**
   - Run: `bash scripts/validate-tool-permissions.sh` to audit security
   - Check for overly permissive configurations
   - Ensure sensitive operations require approval

### Phase 3: Advanced Patterns

7. **Setup Multi-Agent MCP Coordination**
   - Use example: `examples/multi-agent-mcp/`
   - Configure shared MCP resources across agents
   - Implement coordinated tool usage patterns

8. **Implement Dynamic Tool Management**
   - Use example: `examples/dynamic-tools/`
   - Monitor MCP servers for tool updates
   - Handle real-time tool availability changes

9. **Configure MCP Response Caching**
   - Run: `bash scripts/setup-mcp-caching.sh`
   - Optimize performance with intelligent caching
   - Configure TTL per tool type

## Examples

### Basic Zapier MCP Integration

See: `examples/zapier-mcp-agent/` - Complete example of agent with Zapier MCP access

### Custom MCP Server Integration

See: `examples/custom-mcp-server/` - Build and connect custom MCP server

### Security Controls Implementation

See: `examples/security-controls/` - Fine-grained approval and monitoring patterns

### Multi-Service Integration

See: `examples/multi-service/` - Coordinating multiple MCP servers (Calendar, Email, CRM)

### E-commerce Assistant

See: `examples/ecommerce-assistant/` - Inventory and order management with MCP tools

## Requirements

### Prerequisites
- ElevenLabs API key with Agents Platform access
- MCP server URL (Zapier or custom)
- Node.js 18+ or Python 3.9+ for agent implementation
- HTTPS-enabled endpoints for production

### Security Requirements
- **Default to "Always Ask" approval mode** for new integrations
- Store credentials in environment variables, never hardcode
- Use HTTPS for all MCP server connections
- Implement logging for all tool invocations
- Regular security audits of integrated servers

### MCP Server Limitations
- Not available with Zero Retention Mode
- Not available with HIPAA compliance requirements
- User responsibility for vetting external servers

## Scripts Overview

- **configure-mcp.sh** - Interactive MCP server configuration with validation
- **test-mcp-connection.sh** - Connection testing and tool discovery
- **setup-zapier-mcp.sh** - Zapier MCP quick-start configuration
- **validate-tool-permissions.sh** - Security audit for tool approval settings
- **setup-mcp-caching.sh** - Performance optimization with response caching
- **monitor-mcp-health.sh** - Continuous health monitoring for MCP servers
- **rotate-mcp-tokens.sh** - Secure token rotation for MCP authentication

## Templates Overview

- **mcp-server-config.json.template** - Base MCP server configuration
- **agent-mcp-config.json.template** - Agent with MCP tools integration
- **tool-approval-config.json.template** - Security and approval settings
- **zapier-mcp-config.json.template** - Pre-configured Zapier integration
- **multi-mcp-config.json.template** - Multiple MCP servers coordination

## Security Best Practices

### 1. Tool Approval Configuration

**Recommended Approach:**
- Start with "Always Ask" mode for all new servers
- Transition to "Fine-Grained" after thorough testing
- **Never use "No Approval" in production** unless server is fully trusted

**Tool Classification:**
- **Auto-Approved**: Read-only, low-risk (weather, search, knowledge base)
- **Requires Approval**: Data modification, external actions (email, calendar create, order processing)
- **Disabled**: High-risk, unnecessary (admin tools, delete operations, financial transfers)

### 2. Authentication & Credentials

- Use platform secret management features
- Store tokens in environment variables
- Rotate credentials regularly with `scripts/rotate-mcp-tokens.sh`
- Never commit credentials to version control

### 3. Data Privacy

- Minimize data sent to external MCP servers
- Avoid sending PII unless necessary
- Review conversation data handling policies
- Implement data retention policies

### 4. Monitoring & Auditing

- Log all tool invocations with timestamps
- Monitor approval patterns for anomalies
- Set up alerts for unusual activity
- Regular security reviews of integrated servers

### 5. Server Vetting Process

Before integrating any MCP server:
1. Verify provider reputation and security practices
2. Review tool capabilities and data access requirements
3. Test in development environment first
4. Document integration rationale and risk assessment
5. Establish monitoring and review schedule

## Performance Optimization

### Caching Strategy
- Cache read-only tool responses (weather, knowledge base)
- Configure TTL based on data freshness requirements
- Implement cache invalidation for dynamic data

### Parallel Operations
- Execute independent MCP operations concurrently
- Batch similar requests when possible
- Use connection pooling for HTTP transport

### Error Handling
- Implement exponential backoff for connection retries
- Handle timeout gracefully with fallback responses
- Log errors for debugging and monitoring

## Troubleshooting

### Connection Issues
- Verify server URL is accessible and HTTPS-enabled
- Check authentication headers and token validity
- Test with `scripts/test-mcp-connection.sh`
- Review firewall/network ACL settings

### Tool Discovery Failures
- Confirm MCP server implements protocol correctly
- Verify server responds to tool listing requests
- Check server logs for errors

### Approval Timeouts
- Increase timeout values in agent configuration
- Implement fallback behavior for denied/timed-out approvals
- Consider switching to auto-approval for low-risk tools

### Performance Degradation
- Enable MCP response caching
- Review tool execution patterns
- Implement request rate limiting
- Monitor server health with `scripts/monitor-mcp-health.sh`

## Resources

- **ElevenLabs MCP Documentation**: https://elevenlabs.io/docs/agents-platform/customization/tools/mcp
- **MCP Security Guide**: https://elevenlabs.io/docs/agents-platform/customization/tools/mcp/security
- **Model Context Protocol Spec**: https://modelcontextprotocol.io/
- **Zapier MCP**: https://zapier.com/mcp
- **MCP Integration Dashboard**: https://elevenlabs.io/app/agents/integrations

---

**Skill Location**: plugins/elevenlabs/skills/mcp-integration/
**Version**: 1.0.0
**Last Updated**: 2025-10-29
