# MCP Security Controls Example

Comprehensive guide to implementing security controls for MCP integrations with ElevenLabs agents.

## Overview

This example demonstrates:
- Fine-grained tool approval configuration
- Security monitoring and auditing
- Token rotation and credential management
- Risk assessment for tools
- Incident response procedures

## Security Architecture

```
┌──────────────────────────────────────────────┐
│         Security Layers                      │
├──────────────────────────────────────────────┤
│ 1. Authentication (Bearer Tokens)            │
│ 2. Tool Approval (Always Ask/Fine-Grained)   │
│ 3. Input Validation (Schema Validation)      │
│ 4. Rate Limiting (Per-User/Per-Tool)         │
│ 5. Audit Logging (All Tool Invocations)      │
│ 6. Monitoring (Anomaly Detection)            │
└──────────────────────────────────────────────┘
```

## Setup

### 1. Configure Security Settings

```bash
# Copy security configuration template
cp security-config.json.template security-config.json

# Edit with your settings
nano security-config.json

# Apply configuration
bash apply-security-config.sh
```

### 2. Enable Audit Logging

```bash
# Create audit log directory
mkdir -p .elevenlabs/audit

# Configure logging
cat > .elevenlabs/audit/config.json <<EOF
{
  "enabled": true,
  "logLevel": "info",
  "destinations": ["file", "webhook"],
  "retention": {
    "days": 90,
    "compress": true
  }
}
EOF
```

### 3. Setup Monitoring

```bash
# Start continuous monitoring
bash ../../scripts/monitor-mcp-health.sh --continuous --interval 60 &

# Monitor PID stored in .elevenlabs/monitor.pid
```

## Tool Approval Modes

### Mode 1: Always Ask (Maximum Security)

**Use when:**
- Initial integration testing
- High-risk operations
- Sensitive data access
- Compliance requirements

**Configuration:**
```json
{
  "approvalMode": "always_ask",
  "approvalTimeout": 30,
  "fallbackOnTimeout": "deny"
}
```

**Example flow:**
```
User: "Send an email to John"
Agent: "I need approval to send email"
System: [Approval Request UI appears]
User: [Approves or Denies]
Agent: [Executes or cancels based on response]
```

### Mode 2: Fine-Grained (Balanced)

**Use when:**
- Known safe read-only tools
- Established trust with MCP server
- Performance optimization needed

**Configuration:**
```json
{
  "approvalMode": "fine_grained",
  "rules": {
    "autoApproved": {
      "patterns": ["*_read", "*_get", "*_search"],
      "tools": ["weather_get", "calendar_read"]
    },
    "requiresApproval": {
      "patterns": ["*_send", "*_create", "*_update"],
      "tools": ["email_send", "order_process"]
    },
    "disabled": {
      "patterns": ["*_delete", "admin_*"],
      "tools": ["user_delete", "system_admin"]
    }
  }
}
```

### Mode 3: No Approval (Use with Caution)

**Only use when:**
- MCP server is fully trusted and vetted
- All tools are read-only
- Testing in isolated environment

**Configuration:**
```json
{
  "approvalMode": "no_approval",
  "warning": "All tools execute without approval",
  "auditLogging": "required"
}
```

⚠️ **Warning:** Never use "No Approval" in production unless absolutely necessary and fully vetted.

## Risk Assessment Framework

### Tool Risk Levels

#### Low Risk (Auto-Approve Candidate)
- **Characteristics:**
  - Read-only operations
  - No side effects
  - Public data only
  - No PII exposure

- **Examples:**
  - Weather lookup
  - Public web search
  - Knowledge base queries
  - Product information

- **Configuration:**
  ```json
  {
    "approval": "auto_approved",
    "riskLevel": "low",
    "auditLevel": "minimal"
  }
  ```

#### Medium Risk (Requires Approval)
- **Characteristics:**
  - Data modification
  - External communication
  - Non-critical operations
  - Reversible actions

- **Examples:**
  - Email sending
  - Calendar creation
  - Spreadsheet updates
  - Task creation

- **Configuration:**
  ```json
  {
    "approval": "requires_approval",
    "riskLevel": "medium",
    "auditLevel": "standard",
    "approvalTimeout": 30
  }
  ```

#### High Risk (Extra Scrutiny)
- **Characteristics:**
  - Financial operations
  - Sensitive data access
  - External integrations
  - Difficult to reverse

- **Examples:**
  - Payment processing
  - Account modifications
  - Access control changes
  - Data exports

- **Configuration:**
  ```json
  {
    "approval": "requires_approval",
    "riskLevel": "high",
    "auditLevel": "detailed",
    "requiresMultipleApprovals": true,
    "approvalTimeout": 60
  }
  ```

#### Critical Risk (Disabled)
- **Characteristics:**
  - Destructive operations
  - Irreversible actions
  - System administration
  - Security implications

- **Examples:**
  - User deletion
  - System administration
  - Database drops
  - Access revocation

- **Configuration:**
  ```json
  {
    "approval": "disabled",
    "riskLevel": "critical",
    "permanentlyDisabled": true,
    "reason": "Destructive operation"
  }
  ```

## Security Monitoring

### Real-time Monitoring

```bash
# Monitor tool usage
tail -f .elevenlabs/audit/tool-usage.log

# Monitor approvals
tail -f .elevenlabs/audit/approvals.log

# Monitor errors
tail -f .elevenlabs/audit/errors.log
```

### Anomaly Detection

```typescript
// Monitor for suspicious patterns
class SecurityMonitor {
  private suspiciousPatterns = [
    { pattern: 'rapid_tool_changes', threshold: 10, window: 60 },
    { pattern: 'unusual_hours', hours: [0, 1, 2, 3, 4, 5] },
    { pattern: 'high_denial_rate', threshold: 0.5 },
    { pattern: 'new_tool_usage', alert: true }
  ];

  detectAnomalies(events: ToolEvent[]): Alert[] {
    const alerts: Alert[] = [];

    // Check rapid tool usage
    const recentTools = this.getRecentToolUsage(60);
    if (recentTools.length > 10) {
      alerts.push({
        type: 'rapid_tool_usage',
        severity: 'medium',
        count: recentTools.length
      });
    }

    // Check unusual hours
    const hour = new Date().getHours();
    if ([0, 1, 2, 3, 4, 5].includes(hour)) {
      alerts.push({
        type: 'unusual_hours',
        severity: 'low',
        hour
      });
    }

    return alerts;
  }
}
```

### Audit Reports

```bash
# Generate daily audit report
bash generate-audit-report.sh --period daily

# Generate compliance report
bash generate-audit-report.sh --period monthly --format compliance

# Export for external analysis
bash generate-audit-report.sh --export --format csv
```

## Incident Response

### Suspicious Activity Detected

1. **Immediate Actions:**
   ```bash
   # Disable affected MCP server
   bash disable-mcp-server.sh <server-name>

   # Rotate tokens immediately
   bash ../../scripts/rotate-mcp-tokens.sh <server-name>

   # Review recent activity
   bash audit-recent-activity.sh --hours 24
   ```

2. **Investigation:**
   ```bash
   # Get detailed logs
   grep "suspicious" .elevenlabs/audit/*.log

   # Analyze tool usage patterns
   bash analyze-tool-patterns.sh --server <server-name>

   # Check for data exfiltration
   bash check-data-access.sh --timerange "last 24 hours"
   ```

3. **Recovery:**
   ```bash
   # Re-enable with stricter controls
   bash enable-mcp-server.sh <server-name> --mode always_ask

   # Implement additional monitoring
   bash add-monitoring-rules.sh <server-name>

   # Document incident
   bash create-incident-report.sh
   ```

### Token Compromise

```bash
# Immediately revoke all tokens for server
bash revoke-all-tokens.sh <server-name>

# Generate new tokens
bash generate-new-tokens.sh <server-name>

# Update all agents
bash update-agent-tokens.sh <server-name>

# Audit all activity with compromised token
bash audit-token-activity.sh <old-token>
```

## Best Practices Checklist

### Initial Setup
- [ ] Start with "Always Ask" approval mode
- [ ] Configure comprehensive audit logging
- [ ] Set up monitoring and alerting
- [ ] Document all MCP servers and their purposes
- [ ] Create incident response plan

### Ongoing Operations
- [ ] Review audit logs weekly
- [ ] Rotate tokens monthly (minimum)
- [ ] Update approval rules as needed
- [ ] Monitor for anomalies daily
- [ ] Test backup/recovery procedures monthly

### Security Hardening
- [ ] Use HTTPS for all MCP connections
- [ ] Store tokens in environment variables
- [ ] Implement rate limiting
- [ ] Enable request signing
- [ ] Set up intrusion detection

### Compliance
- [ ] Document all tool usage
- [ ] Maintain audit trails (90+ days)
- [ ] Implement data retention policies
- [ ] Regular security assessments
- [ ] Compliance reporting automated

## Security Configuration Files

### security-config.json

Complete security configuration:

```json
{
  "authentication": {
    "method": "bearer_token",
    "tokenRotation": {
      "enabled": true,
      "intervalDays": 30,
      "notifyBeforeDays": 7
    }
  },
  "approvalMode": "fine_grained",
  "auditLogging": {
    "enabled": true,
    "destinations": ["file", "webhook"],
    "logLevel": "info",
    "retention": {
      "days": 90,
      "compress": true
    }
  },
  "monitoring": {
    "enabled": true,
    "healthCheckInterval": 60,
    "anomalyDetection": true,
    "alertChannels": ["email", "webhook"]
  },
  "rateLimiting": {
    "enabled": true,
    "requestsPerMinute": 60,
    "burstLimit": 10
  },
  "incidentResponse": {
    "autoDisableOnSuspicious": true,
    "notificationEmails": ["security@example.com"],
    "escalationWebhook": "https://your-alerting-system.com/webhook"
  }
}
```

## Testing Security

```bash
# Run security audit
bash ../../scripts/validate-tool-permissions.sh

# Test approval workflow
bash test-approval-flow.sh

# Simulate attack scenarios
bash security-penetration-test.sh

# Verify audit logging
bash verify-audit-logs.sh
```

## Resources

- [ElevenLabs MCP Security Guide](https://elevenlabs.io/docs/agents-platform/customization/tools/mcp/security)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [MCP Security Best Practices](https://modelcontextprotocol.io/security)

## Support

For security concerns:
1. Review this guide thoroughly
2. Run security audit: `validate-tool-permissions.sh`
3. Check monitoring: `monitor-mcp-health.sh`
4. Contact: security@elevenlabs.io (for platform issues)
