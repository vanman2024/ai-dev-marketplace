"""
Claude Agent SDK - Basic Query Example

This is the simplest way to use the Claude Agent SDK.
"""

import os
import asyncio
from dotenv import load_dotenv
from claude_agent_sdk import query
from claude_agent_sdk.types import ClaudeAgentOptions

# Load environment variables
load_dotenv(override=True)  # Override inherited env vars with .env file

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")


async def main():
    """Basic query example"""

    if not ANTHROPIC_API_KEY:
        print("Error: ANTHROPIC_API_KEY not found in .env")
        return

    print("Asking Claude a question...")

    # Create environment with API key
    # IMPORTANT: Copy full environment, then override API key
    # This ensures subprocess gets PATH and other required env vars
    env = os.environ.copy()
    env["ANTHROPIC_API_KEY"] = ANTHROPIC_API_KEY

    # Simple query
    async for message in query(
        prompt="Hello! Tell me about the Claude Agent SDK in 2 sentences.",
        options=ClaudeAgentOptions(
            model="claude-sonnet-4-20250514",
            max_turns=1,
            env=env  # Pass full environment to subprocess
        )
    ):
        if hasattr(message, 'type') and message.type == 'text':
            print(f"\nClaude: {message.text}")


if __name__ == "__main__":
    asyncio.run(main())
