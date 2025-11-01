# openai-sdk-config.py
# OpenAI SDK configuration for OpenRouter (Python)

import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# Create OpenAI client configured for OpenRouter
# This is a drop-in replacement for the standard OpenAI client
client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1",
    default_headers={
        # Optional: For OpenRouter rankings and analytics
        "HTTP-Referer": os.getenv("OPENROUTER_SITE_URL", "http://localhost:3000"),
        "X-Title": os.getenv("OPENROUTER_SITE_NAME", "My App"),
    },
)


def create_chat_completion(
    messages: list,
    model: str = None,
    **kwargs,
):
    """
    Create a chat completion using OpenRouter

    Args:
        messages: List of message dictionaries with 'role' and 'content'
        model: Model ID (defaults to OPENROUTER_MODEL env var)
        **kwargs: Additional arguments to pass to the API

    Returns:
        Chat completion response

    Common models:
        - anthropic/claude-3.5-sonnet
        - anthropic/claude-3-opus
        - meta-llama/llama-3.1-70b-instruct
        - openai/gpt-4-turbo
        - google/gemini-pro-1.5
    """
    model = model or os.getenv("OPENROUTER_MODEL", "anthropic/claude-3.5-sonnet")

    return client.chat.completions.create(
        model=model,
        messages=messages,
        **kwargs,
    )


def create_streaming_chat_completion(
    messages: list,
    model: str = None,
    **kwargs,
):
    """
    Create a streaming chat completion using OpenRouter

    Args:
        messages: List of message dictionaries with 'role' and 'content'
        model: Model ID (defaults to OPENROUTER_MODEL env var)
        **kwargs: Additional arguments to pass to the API

    Returns:
        Streaming chat completion response

    Usage:
        stream = create_streaming_chat_completion([...])
        for chunk in stream:
            if chunk.choices[0].delta.content:
                print(chunk.choices[0].delta.content, end="")
    """
    model = model or os.getenv("OPENROUTER_MODEL", "anthropic/claude-3.5-sonnet")

    return client.chat.completions.create(
        model=model,
        messages=messages,
        stream=True,
        **kwargs,
    )


# Example usage
if __name__ == "__main__":
    # Simple chat completion
    print("=== Simple Chat Completion ===")
    response = create_chat_completion(
        messages=[
            {"role": "user", "content": "Say 'Hello from OpenRouter!'"}
        ]
    )
    print(response.choices[0].message.content)
    print()

    # Streaming chat completion
    print("=== Streaming Chat Completion ===")
    stream = create_streaming_chat_completion(
        messages=[
            {"role": "user", "content": "Count from 1 to 5"}
        ]
    )

    for chunk in stream:
        if chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)
    print("\n")

    # Chat with system message
    print("=== Chat with System Message ===")
    response = create_chat_completion(
        messages=[
            {"role": "system", "content": "You are a helpful assistant that speaks like a pirate."},
            {"role": "user", "content": "Hello, how are you?"}
        ]
    )
    print(response.choices[0].message.content)
    print()

    # Chat with different model
    print("=== Chat with Different Model ===")
    response = create_chat_completion(
        messages=[
            {"role": "user", "content": "What is 2+2?"}
        ],
        model="meta-llama/llama-3.1-70b-instruct"
    )
    print(f"Model: meta-llama/llama-3.1-70b-instruct")
    print(f"Response: {response.choices[0].message.content}")
    print()

    # Chat with temperature control
    print("=== Chat with Temperature Control ===")
    response = create_chat_completion(
        messages=[
            {"role": "user", "content": "Write a creative story opening (one sentence)."}
        ],
        temperature=1.0,  # More creative
        max_tokens=50,
    )
    print(response.choices[0].message.content)
