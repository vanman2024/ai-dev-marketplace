# Security Best Practices for A2A + MCP Integration

This document outlines security best practices when integrating A2A Protocol and Model Context Protocol in hybrid agent systems.

## Table of Contents

1. [Authentication and Authorization](#authentication-and-authorization)
2. [Network Security](#network-security)
3. [Data Protection](#data-protection)
4. [Secret Management](#secret-management)
5. [Agent Trust](#agent-trust)
6. [MCP Tool Security](#mcp-tool-security)
7. [Monitoring and Auditing](#monitoring-and-auditing)

---

## Authentication and Authorization

### Separate Credentials Per Protocol

**DO:**
- Use separate API keys for A2A and MCP
- Implement independent authentication for each protocol
- Rotate credentials on different schedules

```python
# Separate authentication
a2a_client = A2AClient(api_key=os.getenv("A2A_API_KEY"))
mcp_client = MCPClient(api_key=os.getenv("MCP_API_KEY"))
```

**DON'T:**
- Share authentication tokens between protocols
- Reuse the same API key for both A2A and MCP
- Pass MCP credentials through A2A messages

### Principle of Least Privilege

**DO:**
- Grant minimum required permissions for each protocol
- Use role-based access control (RBAC)
- Implement scoped tokens with limited capabilities

```bash
# A2A with limited scope
A2A_API_KEY_SCOPE=agent:communicate,task:receive

# MCP with read-only access
MCP_API_KEY_SCOPE=tool:execute:read-only
```

**DON'T:**
- Use admin/root credentials for agent operations
- Grant broad permissions without justification
- Share credentials across multiple agents

### Token Management

**DO:**
- Implement token expiration and refresh
- Use short-lived tokens (< 1 hour) when possible
- Revoke tokens immediately when compromised

```python
# Token refresh pattern
if token_expires_in < 300:  # 5 minutes
    a2a_token = refresh_token(a2a_client)
```

**DON'T:**
- Use long-lived tokens in production
- Store tokens in plaintext files
- Embed tokens in source code or logs

---

## Network Security

### TLS/SSL Everywhere

**DO:**
- Use HTTPS for all A2A communications
- Use TLS for MCP connections
- Verify SSL certificates

```python
# Enforce TLS
a2a_client = A2AClient(
    api_key=api_key,
    base_url="https://a2a.example.com",  # HTTPS only
    verify_ssl=True
)
```

**DON'T:**
- Use HTTP in production
- Disable SSL verification (even for testing)
- Accept self-signed certificates without validation

### Network Segmentation

**DO:**
- Keep MCP servers on private networks
- Use VPN for inter-agent communication
- Implement firewall rules for protocol isolation

```yaml
# Example network policy
a2a:
  network: public
  allow: internet-facing

mcp:
  network: private
  allow: internal-only
```

**DON'T:**
- Expose MCP servers to the public internet
- Allow unrestricted agent-to-agent communication
- Mix production and development networks

### Rate Limiting and DDoS Protection

**DO:**
- Implement rate limiting on both protocols
- Use API gateways with DDoS protection
- Monitor for abnormal traffic patterns

```python
# Rate limiting configuration
A2A_RATE_LIMIT=100  # requests per minute
MCP_RATE_LIMIT=50   # tool executions per minute
```

---

## Data Protection

### Encryption at Rest and in Transit

**DO:**
- Encrypt sensitive data before transmission
- Use end-to-end encryption for agent messages
- Encrypt MCP tool results containing sensitive data

```python
# Encrypt sensitive task data
encrypted_params = encrypt(task_params, agent_public_key)
task = Task(type="analyze", params=encrypted_params)
```

**DON'T:**
- Send plaintext passwords or secrets via A2A
- Store sensitive MCP results without encryption
- Log sensitive data in plaintext

### Data Sanitization

**DO:**
- Sanitize inputs before passing to MCP tools
- Validate outputs before sending via A2A
- Remove sensitive data from logs and errors

```python
# Input sanitization
def sanitize_params(params):
    sanitized = params.copy()
    # Remove sensitive fields
    sanitized.pop('password', None)
    sanitized.pop('api_key', None)
    return sanitized

safe_params = sanitize_params(task.params)
```

**DON'T:**
- Trust user input without validation
- Include API keys or tokens in error messages
- Log full request/response bodies

---

## Secret Management

### Environment Variables

**DO:**
- Store all credentials in environment variables
- Use `.env` files for local development (gitignored)
- Create `.env.example` with placeholders only

```bash
# .env (NEVER commit this)
A2A_API_KEY=sk_actual_production_key_abc123
MCP_API_KEY=mcp_actual_production_key_xyz789

# .env.example (safe to commit)
A2A_API_KEY=your_a2a_key_here
MCP_API_KEY=your_mcp_key_here
```

**DON'T:**
- Hardcode credentials in source files
- Commit `.env` files to version control
- Use example values in production

### Production Secret Management

**DO:**
- Use dedicated secret management (Vault, AWS Secrets Manager, etc.)
- Rotate secrets regularly (30-90 days)
- Implement secret versioning

```python
# Using HashiCorp Vault
import hvac

client = hvac.Client(url='https://vault.example.com')
a2a_secret = client.secrets.kv.v2.read_secret_version(
    path='a2a/production/api_key'
)
a2a_api_key = a2a_secret['data']['data']['key']
```

**DON'T:**
- Store secrets in configuration files
- Use the same secrets across environments
- Share production secrets via chat/email

---

## Agent Trust

### Agent Verification

**DO:**
- Verify agent identity before task delegation
- Use cryptographic signatures for agent cards
- Implement agent allowlists for sensitive operations

```python
# Verify agent signature
def verify_agent(agent_card, signature):
    public_key = get_agent_public_key(agent_card.id)
    return verify_signature(agent_card, signature, public_key)
```

**DON'T:**
- Accept tasks from unverified agents
- Trust agent cards without signature validation
- Allow anonymous agent communication

### Trust Boundaries

**DO:**
- Define clear trust zones (internal vs. external agents)
- Limit data sharing based on agent trust level
- Implement agent reputation scoring

```python
# Trust-based delegation
if agent.trust_level >= TrustLevel.HIGH:
    delegate_sensitive_task(agent, task)
else:
    delegate_public_task(agent, task)
```

**DON'T:**
- Treat all agents as equally trusted
- Share sensitive data with external agents
- Allow low-trust agents to execute privileged tools

---

## MCP Tool Security

### Tool Access Control

**DO:**
- Restrict tool access based on agent role
- Implement tool execution sandboxing
- Validate tool parameters before execution

```python
# Role-based tool access
allowed_tools = {
    'search-agent': ['web_search', 'data_fetch'],
    'analyze-agent': ['data_analysis', 'ml_inference'],
    'storage-agent': ['database_read', 'database_write']
}

def can_execute_tool(agent_role, tool_name):
    return tool_name in allowed_tools.get(agent_role, [])
```

**DON'T:**
- Allow unrestricted tool access
- Execute tools without parameter validation
- Run tools with elevated privileges by default

### Tool Result Validation

**DO:**
- Validate MCP tool outputs before using them
- Sanitize tool results before sharing via A2A
- Implement output size limits

```python
# Validate tool result
def validate_result(result):
    if len(str(result)) > MAX_RESULT_SIZE:
        raise ValueError("Result too large")
    if contains_sensitive_data(result):
        result = redact_sensitive_data(result)
    return result
```

**DON'T:**
- Trust tool outputs blindly
- Forward raw MCP results without inspection
- Allow unbounded result sizes

---

## Monitoring and Auditing

### Comprehensive Logging

**DO:**
- Log all A2A agent interactions
- Log all MCP tool executions
- Include correlation IDs for request tracing

```python
# Structured logging
logger.info("A2A task received", extra={
    "task_id": task.id,
    "task_type": task.type,
    "sender": task.requester_id,
    "correlation_id": correlation_id
})

logger.info("MCP tool executed", extra={
    "tool_name": tool_name,
    "agent_id": agent_id,
    "correlation_id": correlation_id
})
```

**DON'T:**
- Log sensitive data (passwords, API keys)
- Disable logging in production
- Use unstructured log formats

### Security Monitoring

**DO:**
- Monitor for suspicious agent behavior
- Alert on failed authentication attempts
- Track unusual tool execution patterns

```python
# Security alerts
if failed_auth_count > THRESHOLD:
    alert("Multiple failed authentications", agent_id)

if tool_execution_rate > NORMAL_RATE * 10:
    alert("Abnormal tool usage detected", agent_id)
```

**DON'T:**
- Ignore security warnings
- Disable security monitoring for performance
- Delay incident response

### Audit Trails

**DO:**
- Maintain immutable audit logs
- Include timestamps, agent IDs, actions
- Retain audit logs per compliance requirements

```python
# Audit log entry
{
    "timestamp": "2025-12-20T10:30:45Z",
    "event": "task_delegation",
    "actor": "agent-001",
    "target": "agent-002",
    "action": "delegate_task",
    "task_type": "data_analysis",
    "result": "success",
    "correlation_id": "abc-123-xyz"
}
```

**DON'T:**
- Modify audit logs after creation
- Store audit logs without backup
- Delete audit logs prematurely

---

## Security Checklist

Before deploying A2A + MCP integration to production:

### Authentication
- [ ] Separate credentials for A2A and MCP
- [ ] Least privilege access configured
- [ ] Token expiration and refresh implemented
- [ ] No hardcoded credentials in code

### Network
- [ ] TLS/SSL enabled for both protocols
- [ ] MCP servers on private network
- [ ] Firewall rules configured
- [ ] Rate limiting enabled

### Data
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Input validation on all parameters
- [ ] Output sanitization implemented
- [ ] No secrets in logs

### Secrets
- [ ] All secrets in environment variables or vault
- [ ] `.env` in `.gitignore`
- [ ] `.env.example` with placeholders only
- [ ] Regular secret rotation schedule

### Agent Trust
- [ ] Agent identity verification
- [ ] Cryptographic signatures for agent cards
- [ ] Trust levels defined and enforced
- [ ] Agent allowlists for sensitive operations

### Tools
- [ ] Role-based tool access control
- [ ] Tool execution sandboxing
- [ ] Parameter validation
- [ ] Result validation and sanitization

### Monitoring
- [ ] Comprehensive logging (no sensitive data)
- [ ] Security monitoring and alerts
- [ ] Immutable audit trails
- [ ] Incident response plan

---

## Resources

- [A2A Security Best Practices](https://a2a-protocol.org/security)
- [MCP Security Guide](https://modelcontextprotocol.io/security)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Last Updated:** 2025-12-20
**Version:** 1.0.0
