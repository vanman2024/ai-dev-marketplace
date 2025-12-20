# Calculator Agent Example

This example demonstrates a simple calculator agent that performs basic arithmetic operations.

## Agent Card

```json
{
  "id": "urn:example:agent:calculator",
  "name": "Calculator Agent",
  "description": "A simple calculator agent that performs basic arithmetic operations (add, subtract, multiply, divide).",
  "version": "1.0.0",
  "protocolVersion": "0.3",
  "serviceEndpoint": "https://api.mathservices.example.com/calculator",
  "provider": {
    "name": "Math Services Inc.",
    "contactEmail": "support@mathservices.example.com",
    "url": "https://mathservices.example.com"
  },
  "capabilities": {
    "streaming": false,
    "pushNotifications": false
  },
  "securitySchemes": {
    "api_key": {
      "type": "apiKey",
      "name": "X-API-Key",
      "in": "header"
    }
  },
  "security": [
    {
      "api_key": []
    }
  ],
  "skills": [
    {
      "name": "basic-arithmetic",
      "description": "Perform basic arithmetic operations",
      "inputSchema": {
        "type": "object",
        "properties": {
          "operation": {
            "type": "string",
            "enum": ["add", "subtract", "multiply", "divide"],
            "description": "Arithmetic operation to perform"
          },
          "operands": {
            "type": "array",
            "items": {
              "type": "number"
            },
            "minItems": 2,
            "description": "Numbers to operate on"
          }
        },
        "required": ["operation", "operands"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "result": {
            "type": "number",
            "description": "Result of the calculation"
          },
          "operation": {
            "type": "string",
            "description": "Operation that was performed"
          }
        }
      },
      "tags": ["math", "calculator", "arithmetic"],
      "examples": [
        {
          "input": {
            "operation": "add",
            "operands": [5, 3]
          },
          "output": {
            "result": 8,
            "operation": "add"
          }
        },
        {
          "input": {
            "operation": "multiply",
            "operands": [4, 7]
          },
          "output": {
            "result": 28,
            "operation": "multiply"
          }
        }
      ]
    },
    {
      "name": "scientific-functions",
      "description": "Advanced mathematical functions (square root, power, logarithm)",
      "inputSchema": {
        "type": "object",
        "properties": {
          "function": {
            "type": "string",
            "enum": ["sqrt", "power", "log", "exp"],
            "description": "Mathematical function to apply"
          },
          "value": {
            "type": "number",
            "description": "Input value"
          },
          "parameter": {
            "type": "number",
            "description": "Additional parameter (e.g., exponent for power, base for log)"
          }
        },
        "required": ["function", "value"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "result": {
            "type": "number"
          },
          "function": {
            "type": "string"
          }
        }
      },
      "tags": ["math", "scientific", "advanced"]
    }
  ],
  "metadata": {
    "precision": "64-bit floating point",
    "rateLimit": "1000 calculations/minute"
  }
}
```

## Authentication Setup

The calculator agent uses API key authentication. To obtain an API key:

1. Visit https://mathservices.example.com/signup
2. Create an account
3. Navigate to API Keys section
4. Generate a new API key
5. Use the key in the `X-API-Key` header

Example request:
```bash
curl -X POST https://api.mathservices.example.com/calculator/task \
  -H "X-API-Key: your_api_key_here" \
  -H "Content-Type: application/json" \
  -d '{
    "skillName": "basic-arithmetic",
    "input": {
      "operation": "add",
      "operands": [10, 25]
    }
  }'
```

## Usage Scenarios

### Scenario 1: Basic Addition
Calculate the sum of multiple numbers.

**Input:**
```json
{
  "operation": "add",
  "operands": [15, 27, 8, 42]
}
```

**Output:**
```json
{
  "result": 92,
  "operation": "add"
}
```

### Scenario 2: Division with Error Handling
Attempt to divide numbers, handling division by zero.

**Input:**
```json
{
  "operation": "divide",
  "operands": [100, 0]
}
```

**Output:**
```json
{
  "error": "Division by zero",
  "code": "INVALID_OPERAND"
}
```

### Scenario 3: Scientific Function
Calculate square root.

**Input:**
```json
{
  "function": "sqrt",
  "value": 144
}
```

**Output:**
```json
{
  "result": 12,
  "function": "sqrt"
}
```

## Deployment Instructions

1. **Generate Agent Card:**
   ```bash
   ./scripts/generate-agent-card.sh --template basic --output calculator-agent-card.json
   ```

2. **Validate Agent Card:**
   ```bash
   ./scripts/validate-agent-card.sh calculator-agent-card.json
   ```

3. **Deploy to Well-Known URI:**
   ```bash
   # Copy to web server's well-known directory
   cp calculator-agent-card.json /var/www/html/.well-known/agent.json

   # Verify accessibility
   curl https://api.mathservices.example.com/.well-known/agent.json
   ```

4. **Test Discovery:**
   ```bash
   # A2A clients should be able to discover the agent
   curl https://api.mathservices.example.com/.well-known/agent.json
   ```

## Error Handling

The calculator agent returns standard error responses:

- `INVALID_OPERATION`: Unsupported operation type
- `INVALID_OPERAND`: Invalid number format or division by zero
- `MISSING_PARAMETER`: Required parameter not provided
- `RATE_LIMIT_EXCEEDED`: Too many requests

Example error response:
```json
{
  "error": "Invalid operation type",
  "code": "INVALID_OPERATION",
  "details": "Operation must be one of: add, subtract, multiply, divide"
}
```

## Rate Limits

- 1000 calculations per minute per API key
- Burst allowance: 100 requests
- Rate limit headers included in responses

## Security Notes

- API keys must be kept secure (use placeholders in examples)
- Never commit API keys to version control
- Use environment variables for API key storage
- Rotate keys regularly (recommended: every 90 days)
