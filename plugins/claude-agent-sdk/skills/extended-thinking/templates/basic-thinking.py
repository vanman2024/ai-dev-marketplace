"""
Extended Thinking - Python Implementation
Enable Claude to reason deeply before responding
"""
import anthropic
from typing import Any


def basic_extended_thinking(prompt: str) -> dict[str, Any]:
    """Basic extended thinking request"""
    client = anthropic.Anthropic()

    response = client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=16000,
        thinking={
            "type": "enabled",
            "budget_tokens": 10000,  # How much "thinking" to allow
        },
        messages=[{"role": "user", "content": prompt}],
    )

    # Parse response - includes thinking blocks
    thinking_blocks = []
    final_response = ""

    for block in response.content:
        if block.type == "thinking":
            thinking_blocks.append(block.thinking)
        elif block.type == "text":
            final_response = block.text

    return {
        "thinking": thinking_blocks,
        "response": final_response,
        "usage": response.usage,
    }


def extended_thinking_with_tools(prompt: str, tools: list[dict]) -> Any:
    """Extended thinking with tools (interleaved)"""
    client = anthropic.Anthropic()

    response = client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=16000,
        thinking={
            "type": "enabled",
            "budget_tokens": 10000,
        },
        tools=tools,
        messages=[{"role": "user", "content": prompt}],
        extra_headers={
            "anthropic-beta": "interleaved-thinking-2025-05-14",
        },
    )

    return response


def stream_extended_thinking(prompt: str):
    """Streaming extended thinking for real-time visibility"""
    client = anthropic.Anthropic()

    with client.messages.stream(
        model="claude-sonnet-4-5-20250929",
        max_tokens=16000,
        thinking={
            "type": "enabled",
            "budget_tokens": 10000,
        },
        messages=[{"role": "user", "content": prompt}],
    ) as stream:
        for event in stream:
            if hasattr(event, "type"):
                if event.type == "content_block_start":
                    if hasattr(event, "content_block"):
                        if event.content_block.type == "thinking":
                            print("🧠 Thinking started...")
                elif event.type == "content_block_delta":
                    if hasattr(event, "delta"):
                        if event.delta.type == "thinking_delta":
                            print(event.delta.thinking, end="", flush=True)
                        elif event.delta.type == "text_delta":
                            print(event.delta.text, end="", flush=True)

        return stream.get_final_message()


if __name__ == "__main__":
    result = basic_extended_thinking(
        "Analyze the time complexity of merge sort and explain why it's O(n log n)"
    )

    print("=== Thinking Process ===")
    for i, thinking in enumerate(result["thinking"]):
        print(f"Step {i + 1}: {thinking}")

    print("\n=== Final Response ===")
    print(result["response"])
