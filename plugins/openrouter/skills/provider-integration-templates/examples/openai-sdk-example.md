# OpenAI SDK with OpenRouter Example

Complete guide to using OpenRouter as a drop-in replacement for OpenAI SDK.

## Why This Works

OpenRouter is OpenAI API compatible. By changing just 3 things, your existing OpenAI code works with OpenRouter:

1. Change `baseURL` to OpenRouter endpoint
2. Change API key to OpenRouter key
3. Add HTTP headers (optional, for rankings)

## Setup

### Python

```bash
pip install openai python-dotenv
```

### TypeScript/Node.js

```bash
npm install openai dotenv
```

## Environment Variables

Create `.env`:

```bash
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_SITE_URL=https://yourapp.com
OPENROUTER_SITE_NAME=YourApp
```

## Basic Usage

### Python

```python
import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# Create OpenAI client configured for OpenRouter
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
)

# Use exactly like OpenAI SDK
response = client.chat.completions.create(
    model="anthropic/claude-4.5-sonnet",
    messages=[
        {"role": "user", "content": "Say hello!"}
    ]
)

print(response.choices[0].message.content)
```

### TypeScript

```typescript
import OpenAI from 'openai';
import 'dotenv/config';

// Create OpenAI client configured for OpenRouter
const client = new OpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
});

// Use exactly like OpenAI SDK
const response = await client.chat.completions.create({
  model: 'anthropic/claude-4.5-sonnet',
  messages: [
    { role: 'user', content: 'Say hello!' }
  ],
});

console.log(response.choices[0].message.content);
```

## Streaming Responses

### Python

```python
stream = client.chat.completions.create(
    model="anthropic/claude-4.5-sonnet",
    messages=[{"role": "user", "content": "Count from 1 to 10"}],
    stream=True,
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
print()
```

### TypeScript

```typescript
const stream = await client.chat.completions.create({
  model: 'anthropic/claude-4.5-sonnet',
  messages: [{ role: 'user', content: 'Count from 1 to 10' }],
  stream: true,
});

for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content || '');
}
console.log();
```

## Function Calling

### Python

```python
import json

# Define function schema
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get current weather for a location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "City name, e.g. San Francisco",
                    },
                    "unit": {
                        "type": "string",
                        "enum": ["celsius", "fahrenheit"],
                    },
                },
                "required": ["location"],
            },
        },
    }
]

# First request with tools
response = client.chat.completions.create(
    model="anthropic/claude-4.5-sonnet",
    messages=[
        {"role": "user", "content": "What's the weather in San Francisco?"}
    ],
    tools=tools,
    tool_choice="auto",
)

# Check if model wants to call a function
message = response.choices[0].message
if message.tool_calls:
    tool_call = message.tool_calls[0]
    function_name = tool_call.function.name
    function_args = json.loads(tool_call.function.arguments)

    print(f"Function called: {function_name}")
    print(f"Arguments: {function_args}")

    # Call your function here
    weather_data = {"temperature": "72", "condition": "sunny"}

    # Send function result back
    second_response = client.chat.completions.create(
        model="anthropic/claude-4.5-sonnet",
        messages=[
            {"role": "user", "content": "What's the weather in San Francisco?"},
            message,
            {
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": json.dumps(weather_data),
            },
        ],
        tools=tools,
    )

    print(second_response.choices[0].message.content)
```

## Conversation with History

### Python

```python
messages = [
    {"role": "system", "content": "You are a helpful assistant."},
]

def chat(user_message: str):
    # Add user message
    messages.append({"role": "user", "content": user_message})

    # Get response
    response = client.chat.completions.create(
        model="anthropic/claude-4.5-sonnet",
        messages=messages,
    )

    # Add assistant response to history
    assistant_message = response.choices[0].message.content
    messages.append({"role": "assistant", "content": assistant_message})

    return assistant_message

# Multi-turn conversation
print(chat("My name is Alice"))
print(chat("What's my name?"))  # Should remember "Alice"
```

## Using Different Models

OpenRouter gives you access to many models through one API:

### Python

```python
# Claude 3.5 Sonnet - Best reasoning
response = client.chat.completions.create(
    model="anthropic/claude-4.5-sonnet",
    messages=[{"role": "user", "content": "Explain quantum computing"}],
)

# GPT-4 Turbo - Strong general purpose
response = client.chat.completions.create(
    model="openai/gpt-4-turbo",
    messages=[{"role": "user", "content": "Explain quantum computing"}],
)

# Llama 3.1 70B - Fast and cost-effective
response = client.chat.completions.create(
    model="meta-llama/llama-3.1-70b-instruct",
    messages=[{"role": "user", "content": "Explain quantum computing"}],
)

# Gemini Pro - Long context, multimodal
response = client.chat.completions.create(
    model="google/gemini-pro-1.5",
    messages=[{"role": "user", "content": "Explain quantum computing"}],
)
```

## Advanced Configuration

### With Custom Headers

```python
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
    default_headers={
        "HTTP-Referer": os.getenv("OPENROUTER_SITE_URL"),
        "X-Title": os.getenv("OPENROUTER_SITE_NAME"),
    },
)
```

### With Timeout

```python
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
    timeout=60.0,  # 60 seconds
)
```

### With Retries

```python
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
    max_retries=3,
)
```

## Error Handling

### Python

```python
from openai import OpenAI, APIError, RateLimitError, APIConnectionError

try:
    response = client.chat.completions.create(
        model="anthropic/claude-4.5-sonnet",
        messages=[{"role": "user", "content": "Hello"}],
    )
    print(response.choices[0].message.content)

except RateLimitError as e:
    print("Rate limit exceeded. Please try again later.")

except APIConnectionError as e:
    print("Network error. Please check your connection.")

except APIError as e:
    print(f"API error: {e}")

except Exception as e:
    print(f"Unexpected error: {e}")
```

## Migration from OpenAI

If you have existing OpenAI code:

### Before (OpenAI)

```python
from openai import OpenAI

client = OpenAI(api_key="sk-...")

response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello"}],
)
```

### After (OpenRouter)

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-or-v1-...",  # Change key
    base_url="https://openrouter.ai/api/v1",  # Add base_url
)

response = client.chat.completions.create(
    model="openai/gpt-4-turbo",  # Add provider prefix
    messages=[{"role": "user", "content": "Hello"}],
)
```

That's it! Everything else stays the same.

## Cost Optimization

OpenRouter shows costs in the response:

```python
response = client.chat.completions.create(
    model="anthropic/claude-4.5-sonnet",
    messages=[{"role": "user", "content": "Hello"}],
)

# Check usage
usage = response.usage
print(f"Prompt tokens: {usage.prompt_tokens}")
print(f"Completion tokens: {usage.completion_tokens}")
print(f"Total tokens: {usage.total_tokens}")
```

## Best Practices

1. **Use Environment Variables**: Never hardcode API keys
2. **Add Error Handling**: Handle rate limits and network errors
3. **Enable Streaming**: Better UX for long responses
4. **Set Reasonable Timeouts**: Prevent hanging requests
5. **Monitor Token Usage**: Track costs
6. **Use Appropriate Models**: Balance cost vs quality
7. **Add HTTP Headers**: Help OpenRouter improve rankings

## Resources

- OpenRouter Dashboard: https://openrouter.ai/
- Model Pricing: https://openrouter.ai/models
- API Documentation: https://openrouter.ai/docs
- Model Comparison: https://openrouter.ai/models
