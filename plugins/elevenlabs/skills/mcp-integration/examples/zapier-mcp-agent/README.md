# Zapier MCP Agent Example

Complete example of an ElevenLabs voice agent with Zapier MCP integration for accessing hundreds of external tools.

## Overview

This example demonstrates:
- Setting up Zapier MCP server connection
- Configuring agent with fine-grained tool approvals
- Implementing common use cases (email, calendar, search)
- Handling tool approval workflows
- Error handling and fallbacks

## Setup

### 1. Get Zapier MCP Credentials

```bash
# Visit https://zapier.com/mcp
# Create or access your MCP server
# Copy server URL and authentication token
```

### 2. Configure Zapier MCP Server

```bash
# Run setup script
bash ../../scripts/setup-zapier-mcp.sh

# Or manually configure
export ZAPIER_MCP_URL="https://your-zapier-mcp-server.com"
export ZAPIER_MCP_TOKEN="your_token_here"
```

### 3. Create Agent Configuration

Use the provided `agent-config.json` to create your agent in the ElevenLabs dashboard.

## Files

- `agent-config.json` - Complete agent configuration with Zapier MCP
- `tool-approvals.json` - Fine-grained approval settings
- `agent.ts` - TypeScript implementation
- `agent.py` - Python implementation
- `test-agent.sh` - Testing script

## Common Use Cases

### 1. Personal Assistant

The agent can help with:
- Checking calendar availability
- Sending emails (with approval)
- Creating calendar events
- Getting weather information
- Web search

Example conversation:
```
User: "Check my calendar for tomorrow"
Agent: *searches calendar* "You have 3 meetings tomorrow..."

User: "Send an email to John about the project update"
Agent: *requests approval* "I'd like to send an email to john@example.com with subject 'Project Update'. Approve?"
User: "Yes"
Agent: *sends email* "Email sent successfully!"
```

### 2. Meeting Scheduler

```
User: "Schedule a meeting with Sarah for next Tuesday at 2pm"
Agent: *checks calendar for conflicts*
Agent: *requests approval* "Create event 'Meeting with Sarah' on Tuesday 2-3pm?"
User: "Yes"
Agent: *creates calendar event*
Agent: *requests approval* "Send calendar invite to sarah@example.com?"
```

### 3. Research Assistant

```
User: "What's the weather like in New York?"
Agent: *auto-approved search* "Currently 72°F and sunny in New York..."

User: "Search for recent AI news"
Agent: *auto-approved search* "Here are the latest AI developments..."
```

## Tool Approval Configuration

### Auto-Approved Tools (Read-only, Low Risk)

- `zapier_weather_get` - Weather information
- `zapier_calendar_read` - Read calendar events
- `zapier_search_web` - Web search
- `zapier_knowledge_base` - Knowledge base queries

### Requires Approval (Modification, External Actions)

- `zapier_email_send` - Send emails
- `zapier_calendar_create` - Create calendar events
- `zapier_message_send` - Send messages (Slack, Discord)
- `zapier_spreadsheet_update` - Update spreadsheets

### Disabled (High Risk)

- `zapier_file_delete` - Delete files
- `zapier_admin_action` - Administrative actions
- `zapier_user_delete` - Delete users

## Implementation

### TypeScript/Next.js

See `agent.ts` for full implementation:

```typescript
import { ElevenLabsAgent } from '@elevenlabs/agents';

const agent = new ElevenLabsAgent({
  apiKey: process.env.ELEVENLABS_API_KEY!
  agentId: 'your-agent-id'
  mcpServers: [
    {
      name: 'zapier-mcp'
      url: process.env.ZAPIER_MCP_URL!
      approvalMode: 'fine_grained'
    }
  ]
});

// Handle tool approval requests
agent.onToolApprovalRequest(async (tool, params) => {
  console.log(`Approval requested: ${tool.name}`, params);
  // Implement your approval logic
  return true; // or false
});
```

### Python

See `agent.py` for full implementation:

```python
from elevenlabs import ElevenLabs

client = ElevenLabs(api_key=os.getenv("ELEVENLABS_API_KEY"))

agent_config = {
    "name": "Zapier Assistant"
    "mcp_servers": ["zapier-mcp"]
    "approval_mode": "fine_grained"
}

# Agent automatically handles approved tools
# and requests approval for others
```

## Testing

### Test Connection

```bash
bash ../../scripts/test-mcp-connection.sh "$ZAPIER_MCP_URL" --token "$ZAPIER_MCP_TOKEN"
```

### Test Agent

```bash
bash test-agent.sh
```

### Manual Testing

1. Start conversation with agent
2. Try read-only command: "What's the weather?"
3. Try approval-required: "Send an email to test@example.com"
4. Verify approval request appears
5. Approve/deny and verify behavior

## Security Best Practices

1. **Start with "Always Ask" mode**
   - Test thoroughly before switching to fine-grained
   - Understand all available tools

2. **Review auto-approved tools regularly**
   - Audit which tools don't require approval
   - Ensure they're truly read-only and safe

3. **Monitor tool usage**
   - Log all tool invocations
   - Alert on suspicious patterns
   - Review logs weekly

4. **Rotate tokens regularly**
   ```bash
   bash ../../scripts/rotate-mcp-tokens.sh zapier-mcp
   ```

5. **Validate approvals**
   - Implement proper approval workflows
   - Don't auto-approve in production
   - Require user confirmation

## Troubleshooting

### Agent not using tools

- Check MCP server is configured in agent
- Verify server is reachable: `test-mcp-connection.sh`
- Review agent logs for errors

### Tool approvals timing out

- Increase approval timeout in config
- Implement fallback behavior
- Check approval webhook is responding

### Authentication errors

- Verify token is current: `test-mcp-connection.sh`
- Check token in environment variables
- Rotate token if expired: `rotate-mcp-tokens.sh`

## Next Steps

1. Customize tool approval rules for your use case
2. Implement custom approval workflow UI
3. Add monitoring and alerting
4. Scale to multiple agents
5. Integrate with your existing systems

## Resources

- [ElevenLabs MCP Documentation](https://elevenlabs.io/docs/agents-platform/customization/tools/mcp)
- [Zapier MCP](https://zapier.com/mcp)
- [MCP Protocol Spec](https://modelcontextprotocol.io/)

## Support

For issues with this example:
1. Check troubleshooting section above
2. Review security audit: `bash ../../scripts/validate-tool-permissions.sh`
3. Monitor health: `bash ../../scripts/monitor-mcp-health.sh --continuous`
