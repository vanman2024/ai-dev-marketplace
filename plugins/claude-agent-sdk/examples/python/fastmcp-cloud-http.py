"""
Claude Agent SDK with FastMCP Cloud (HTTP) - Production Pattern

This example shows how to use Claude Agent SDK with FastMCP Cloud servers.
FastMCP Cloud uses HTTP transport, not SSE.

Architecture: Agent SDK -> Claude Code CLI -> FastMCP Cloud (HTTP) -> Your MCP Server
"""

import os
import asyncio
from dotenv import load_dotenv
from claude_agent_sdk import query
from claude_agent_sdk.types import ClaudeAgentOptions

# Load environment variables
load_dotenv(override=True)  # Override inherited env vars with .env file

# Configuration
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
FASTMCP_CLOUD_API_KEY = os.getenv("FASTMCP_CLOUD_API_KEY")


async def main():
    """
    Example: Using FastMCP Cloud server with HTTP transport

    IMPORTANT: FastMCP Cloud uses "type": "http", NOT "sse"!
    """

    # Validate API keys
    if not ANTHROPIC_API_KEY:
        print("Error: ANTHROPIC_API_KEY not found in .env")
        return

    if not FASTMCP_CLOUD_API_KEY:
        print("Error: FASTMCP_CLOUD_API_KEY not found in .env")
        return

    print("Starting Claude Agent SDK with FastMCP Cloud...")
    print("=" * 80)

    # Use the Agent SDK with FastMCP Cloud
    async for message in query(
        prompt="List available tools from the MCP server",
        options=ClaudeAgentOptions(
            # Model configuration
            model="claude-sonnet-4-20250514",

            # MCP Server Configuration - FastMCP Cloud uses HTTP
            mcp_servers={
                "your-server": {  # Replace with your server name
                    "type": "http",  # ← IMPORTANT: Use "http" for FastMCP Cloud!
                    "url": "https://your-server.fastmcp.app/mcp",  # Your FastMCP Cloud URL
                    "headers": {
                        "Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"
                    }
                }
            },

            # Allow MCP tools
            allowed_tools=[
                "mcp__your-server__*",  # All tools from your server
            ],

            # Permission mode
            permission_mode="bypassPermissions",  # Auto-approve for demo

            # Max conversation turns
            max_turns=10,

            # Working directory
            cwd=os.getcwd(),

            # Environment variables
            env=env
        )
    ):
        # Handle different message types
        if hasattr(message, 'type'):
            if message.type == 'text':
                print(message.text)
            elif message.type == 'system':
                # Check MCP server connection status
                if hasattr(message, 'data') and 'mcp_servers' in message.data:
                    for server in message.data['mcp_servers']:
                        status = server.get('status', 'unknown')
                        name = server.get('name', 'unknown')
                        print(f"MCP Server '{name}': {status}")
                        if status == 'failed':
                            print("  ⚠️  Connection failed - check:")
                            print("     1. URL is correct")
                            print("     2. Using 'type': 'http' (not 'sse')")
                            print("     3. FASTMCP_CLOUD_API_KEY is valid")


if __name__ == "__main__":
    asyncio.run(main())
