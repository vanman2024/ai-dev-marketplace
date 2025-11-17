"""
Example: Multiple FastMCP Cloud Servers

This example shows how to connect to multiple FastMCP Cloud servers
in the same Agent SDK application.
"""

import os
import asyncio
from dotenv import load_dotenv
from claude_agent_sdk import query
from claude_agent_sdk.types import ClaudeAgentOptions

load_dotenv(override=True)  # Override inherited env vars with .env file

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
FASTMCP_CLOUD_API_KEY = os.getenv("FASTMCP_CLOUD_API_KEY")


async def main():
    """
    Example: Using multiple MCP servers simultaneously
    """

    async for message in query(
        prompt="List all available tools from all MCP servers",
        options=ClaudeAgentOptions(
            model="claude-sonnet-4-20250514",

            # Multiple FastMCP Cloud servers
            mcp_servers={
                "cats": {
                    "type": "http",
                    "url": "https://catsmcp.fastmcp.app/mcp",
                    "headers": {"Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"}
                },
                "server-2": {
                    "type": "http",
                    "url": "https://your-other-server.fastmcp.app/mcp",
                    "headers": {"Authorization": f"Bearer {FASTMCP_CLOUD_API_KEY}"}
                }
            },

            # Allow tools from all servers
            allowed_tools=[
                "mcp__cats__*",        # All CATS tools
                "mcp__server-2__*",    # All server-2 tools
            ],

            max_turns=5,

            env=env
        )
    ):
        # Print system messages to see connection status
        if hasattr(message, 'type'):
            if message.type == 'system':
                if hasattr(message, 'data') and 'mcp_servers' in message.data:
                    print("\n🔌 MCP Server Status:")
                    for server in message.data['mcp_servers']:
                        name = server.get('name', 'unknown')
                        status = server.get('status', 'unknown')
                        icon = "✅" if status == "connected" else "❌"
                        print(f"   {icon} {name}: {status}")
            elif message.type == 'text':
                print(f"\n{message.text}")


if __name__ == "__main__":
    asyncio.run(main())
