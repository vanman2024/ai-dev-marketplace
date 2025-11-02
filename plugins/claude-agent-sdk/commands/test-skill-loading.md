---
description: Test if skills are properly loaded and used by agents
allowed-tools: Task, Skill, Read
---

**Purpose**: Test that the claude-agent-setup agent can properly invoke and use the fastmcp-integration skill

## Test Workflow

1. **Invoke the claude-agent-setup agent** with MCP requirements
2. **Verify** the agent invokes the fastmcp-integration skill
3. **Check** that skill content influences the agent's output

## Test Command

Run this test by asking:

```
Create a new Python Agent SDK project called "test-mcp-project"
that will connect to FastMCP Cloud servers.
```

## Expected Behavior

The agent should:
1. ✅ Detect "FastMCP Cloud servers" in the request
2. ✅ Invoke the fastmcp-integration skill: `!{skill fastmcp-integration}`
3. ✅ Use skill knowledge to:
   - Generate code with `"type": "http"` not `"sse"`
   - Include FASTMCP_CLOUD_API_KEY in .env.example
   - Reference correct examples
   - Warn about common mistakes

## Verification

After agent completes, check:
- Did the agent invoke the skill? (Look for skill invocation in output)
- Does generated code have `"type": "http"`?
- Does .env.example include FASTMCP_CLOUD_API_KEY?
- Did agent mention the skill's warnings?

## If Skill Not Invoked

The agent may not be detecting MCP requirements. Try being more explicit:

```
Create a Python Agent SDK project that uses FastMCP Cloud MCP servers.
I need help with the MCP configuration.
```

Or manually invoke the skill:

```
!{skill fastmcp-integration}
```

Then ask the agent to reference the loaded skill content.
