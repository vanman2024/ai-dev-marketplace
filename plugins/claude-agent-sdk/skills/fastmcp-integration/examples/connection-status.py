"""
Example: Checking MCP Connection Status

This example shows how to check if your FastMCP Cloud server
connected successfully.
"""

import os
import asyncio
from dotenv import load_dotenv
from claude_agent_sdk import query
from claude_agent_sdk.types import ClaudeAgentOptions

load_dotenv(override=True)  # Override inherited env vars with .env file


async def test_connection():
    """Test FastMCP Cloud connection and report status"""

    print("Testing FastMCP Cloud connection...")
    print("=" * 60)

    # Create environment with required API keys
    # IMPORTANT: Copy full environment to preserve PATH, etc.
    env = os.environ.copy()
    env["ANTHROPIC_API_KEY"] = os.getenv("ANTHROPIC_API_KEY")
    env["FASTMCP_CLOUD_API_KEY"] = os.getenv("FASTMCP_CLOUD_API_KEY")

    async for message in query(
        prompt="Hello",
        options=ClaudeAgentOptions(
            mcp_servers={
                "test-server": {
                    "type": "http",  # ✅ Correct for FastMCP Cloud
                    "url": "https://your-server.fastmcp.app/mcp",
                    "headers": {
                        "Authorization": f"Bearer {os.getenv('FASTMCP_CLOUD_API_KEY')}"
                    }
                }
            },
            max_turns=1,
            env=env  # Pass full environment to subprocess
        )
    ):
        # Check system message for MCP server status
        if hasattr(message, 'type') and message.type == 'system':
            if hasattr(message, 'data') and 'mcp_servers' in message.data:
                for server in message.data['mcp_servers']:
                    name = server.get('name', 'unknown')
                    status = server.get('status', 'unknown')

                    if status == 'connected':
                        print(f"✅ SUCCESS: {name} connected!")

                        # List available tools
                        if 'tools' in message.data:
                            mcp_tools = [t for t in message.data['tools']
                                       if t.startswith(f'mcp__{name}__')]
                            print(f"\n📦 Available tools: {len(mcp_tools)}")
                            for tool in mcp_tools[:5]:  # Show first 5
                                print(f"   - {tool}")
                            if len(mcp_tools) > 5:
                                print(f"   ... and {len(mcp_tools) - 5} more")

                    elif status == 'failed':
                        print(f"❌ FAILED: {name} could not connect")
                        print("\n🔧 Troubleshooting checklist:")
                        print("   1. Verify using 'type': 'http' (not 'sse')")
                        print("   2. Check FASTMCP_CLOUD_API_KEY is valid")
                        print("   3. Verify URL format: https://server.fastmcp.app/mcp")
                        print("   4. Ensure API key is passed in env parameter")
                break


if __name__ == "__main__":
    asyncio.run(test_connection())
