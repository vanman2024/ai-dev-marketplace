# Custom MCP Server Integration Example

Learn how to build and integrate a custom MCP server with ElevenLabs voice agents.

## Overview

This example demonstrates:
- Building a custom MCP server from scratch
- Implementing MCP protocol endpoints
- Defining custom tools and capabilities
- Integrating with ElevenLabs agents
- Security and authentication

## What You'll Build

A custom MCP server that provides:
- **Customer Data Tools** - CRM-like functionality
- **Inventory Management** - Product and stock operations
- **Order Processing** - Order creation and tracking
- **Analytics** - Business metrics and reporting

## Architecture

```
┌─────────────────┐
│ ElevenLabs Agent│
│  (Voice UI)     │
└────────┬────────┘
         │ HTTP/SSE
         │
┌────────▼────────┐
│   Custom MCP    │
│     Server      │
│  (Your Backend) │
└────────┬────────┘
         │
    ┌────▼────┐
    │Database │
    │   API   │
    └─────────┘
```

## Setup

### 1. Server Implementation

Choose your language:

**TypeScript/Node.js**
```bash
cd server-typescript
npm install
npm run dev
```

**Python/FastAPI**
```bash
cd server-python
pip install -r requirements.txt
python server.py
```

### 2. Deploy Server

```bash
# Local development
npm start  # or python server.py

# Production (example with Fly.io)
flyctl launch
flyctl deploy
```

### 3. Configure ElevenLabs Integration

```bash
# Add your server to MCP configuration
bash ../../scripts/configure-mcp.sh \
  --server-name custom-crm-mcp \
  --server-url https://your-server.fly.dev/mcp
```

## MCP Server Implementation

### Required Endpoints

Your MCP server must implement:

1. **Tool Listing** - `tools/list`
2. **Tool Execution** - `tools/call`
3. **Health Check** - `/health`

### TypeScript Implementation

See `server-typescript/src/mcp-server.ts`:

```typescript
import express from 'express';
import { MCPServer } from './mcp';

const app = express();
const mcpServer = new MCPServer();

// MCP protocol endpoint
app.post('/mcp', async (req, res) => {
  const { method, params } = req.body;

  switch (method) {
    case 'tools/list':
      res.json(mcpServer.listTools());
      break;

    case 'tools/call':
      const result = await mcpServer.callTool(
        params.name
        params.arguments
      );
      res.json({ result });
      break;

    default:
      res.status(400).json({ error: 'Unknown method' });
  }
});

app.listen(3000, () => {
  console.log('MCP Server running on port 3000');
});
```

### Python Implementation

See `server-python/server.py`:

```python
from fastapi import FastAPI
from mcp_server import MCPServer

app = FastAPI()
mcp = MCPServer()

@app.post("/mcp")
async def mcp_endpoint(request: dict):
    method = request.get("method")
    params = request.get("params", {})

    if method == "tools/list":
        return mcp.list_tools()

    elif method == "tools/call":
        result = await mcp.call_tool(
            params["name"]
            params.get("arguments", {})
        )
        return {"result": result}

    return {"error": "Unknown method"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## Defining Custom Tools

### Tool Schema

```typescript
{
  name: "customer_lookup"
  description: "Look up customer information by ID or email"
  inputSchema: {
    type: "object"
    properties: {
      customerId: {
        type: "string"
        description: "Customer ID"
      }
      email: {
        type: "string"
        description: "Customer email address"
      }
    }
    required: []
  }
  outputSchema: {
    type: "object"
    properties: {
      id: { type: "string" }
      name: { type: "string" }
      email: { type: "string" }
      orders: { type: "array" }
    }
  }
}
```

### Tool Implementation

```typescript
async function customerLookup(args: {
  customerId?: string;
  email?: string;
}): Promise<Customer> {
  // Your business logic here
  const customer = await db.customers.findOne({
    $or: [
      { id: args.customerId }
      { email: args.email }
    ]
  });

  return {
    id: customer.id
    name: customer.name
    email: customer.email
    orders: customer.orders
  };
}
```

## Example Tools

### 1. Customer Lookup (Read-only, Auto-approved)

```json
{
  "name": "customer_lookup"
  "description": "Look up customer by ID or email"
  "inputSchema": {
    "customerId": "string (optional)"
    "email": "string (optional)"
  }
  "riskLevel": "low"
  "approval": "auto_approved"
}
```

### 2. Order Create (Modification, Requires Approval)

```json
{
  "name": "order_create"
  "description": "Create a new order for customer"
  "inputSchema": {
    "customerId": "string (required)"
    "items": "array (required)"
    "total": "number (required)"
  }
  "riskLevel": "medium"
  "approval": "requires_approval"
}
```

### 3. Customer Delete (High Risk, Disabled)

```json
{
  "name": "customer_delete"
  "description": "Delete customer account (DISABLED)"
  "riskLevel": "critical"
  "approval": "disabled"
}
```

## Security Implementation

### Authentication

```typescript
import { verifyToken } from './auth';

app.use('/mcp', async (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const payload = await verifyToken(token);
    req.user = payload;
    next();
  } catch (error) {
    res.status(403).json({ error: 'Invalid token' });
  }
});
```

### Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60, // 60 requests per minute
  message: 'Too many requests'
});

app.use('/mcp', limiter);
```

### Input Validation

```typescript
import Joi from 'joi';

const toolSchemas = {
  customer_lookup: Joi.object({
    customerId: Joi.string().uuid()
    email: Joi.string().email()
  }).or('customerId', 'email')
};

function validateToolInput(toolName: string, args: any) {
  const schema = toolSchemas[toolName];
  if (!schema) throw new Error('Unknown tool');

  const { error } = schema.validate(args);
  if (error) throw new Error(`Invalid input: ${error.message}`);
}
```

## Testing

### Test Tool Listing

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0"
    "id": 1
    "method": "tools/list"
  }'
```

### Test Tool Execution

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "jsonrpc": "2.0"
    "id": 2
    "method": "tools/call"
    "params": {
      "name": "customer_lookup"
      "arguments": {
        "email": "customer@example.com"
      }
    }
  }'
```

### Integration Test with ElevenLabs

```bash
# Test server connection
bash ../../scripts/test-mcp-connection.sh http://localhost:3000/mcp --token YOUR_TOKEN

# Monitor health
bash ../../scripts/monitor-mcp-health.sh --continuous
```

## Deployment

### Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Fly.io

```toml
# fly.toml
app = "custom-mcp-server"

[build]
  builder = "heroku/buildpacks:20"

[[services]]
  http_checks = []
  internal_port = 3000
  protocol = "tcp"

  [[services.ports]]
    port = 80
    handlers = ["http"]
  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
```

## Best Practices

1. **Versioning** - Include API version in responses
2. **Logging** - Log all tool invocations with timestamps
3. **Error Handling** - Return meaningful error messages
4. **Timeouts** - Set reasonable timeout limits
5. **Caching** - Cache read-only operations
6. **Monitoring** - Track tool usage and performance
7. **Documentation** - Document all tools thoroughly

## Troubleshooting

### Server not reachable

- Check server is running: `curl http://localhost:3000/health`
- Verify firewall allows connections
- Check HTTPS certificate if using SSL

### Authentication failures

- Verify token format and expiry
- Check Authorization header
- Review token validation logic

### Tool execution errors

- Validate input parameters
- Check database connectivity
- Review error logs

## Next Steps

1. Add more custom tools for your domain
2. Implement proper authentication and RBAC
3. Add comprehensive logging and monitoring
4. Scale with load balancing
5. Deploy to production with CI/CD

## Resources

- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [ElevenLabs MCP Integration](https://elevenlabs.io/docs/agents-platform/customization/tools/mcp)
- [FastMCP SDK](https://github.com/jlowin/fastmcp) - Quick MCP server development
