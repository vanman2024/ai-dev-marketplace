"""
Basic Hybrid Agent Example - Python

Demonstrates a simple agent that uses both A2A and MCP protocols:
- A2A for receiving task requests from other agents
- MCP for executing tools to complete tasks
- Integration between both protocols

Usage:
    python examples/python-hybrid-agent.py
"""

import asyncio
import os
from typing import Dict, Any
from dotenv import load_dotenv

# Mock imports (replace with actual SDK imports)
# from a2a import Client as A2AClient, Task, AgentCard
# from mcp import Client as MCPClient


class MockA2AClient:
    """Mock A2A client for demonstration"""

    async def register_agent(self, card):
        print(f"✓ A2A: Registered agent {card['id']}")

    async def listen(self):
        """Simulate receiving tasks"""
        # In real implementation, this yields incoming tasks
        tasks = [
            {"id": "task-1", "type": "search", "params": {"query": "AI trends"}},
            {"id": "task-2", "type": "analyze", "params": {"data": "sample_data"}}
        ]
        for task in tasks:
            yield task
            await asyncio.sleep(1)

    async def send_result(self, task_id, result):
        print(f"✓ A2A: Sent result for task {task_id}")


class MockMCPClient:
    """Mock MCP client for demonstration"""

    async def connect(self):
        print("✓ MCP: Connected to server")

    async def call_tool(self, tool_name, params):
        print(f"✓ MCP: Executing tool '{tool_name}' with params {params}")
        # Simulate tool execution
        await asyncio.sleep(0.5)
        return {"status": "success", "data": f"Result from {tool_name}"}


class HybridAgent:
    """
    Basic hybrid agent combining A2A and MCP
    """

    def __init__(self, agent_id: str):
        load_dotenv()

        self.agent_id = agent_id

        # Initialize A2A client for agent communication
        self.a2a_client = MockA2AClient()
        # In production: self.a2a_client = A2AClient(api_key=os.getenv("A2A_API_KEY"))

        # Initialize MCP client for tool access
        self.mcp_client = MockMCPClient()
        # In production: self.mcp_client = MCPClient(server_url=os.getenv("MCP_SERVER_URL"))

    async def initialize(self) -> None:
        """Initialize the hybrid agent"""
        print(f"\n=== Initializing Hybrid Agent {self.agent_id} ===\n")

        # Register with A2A network
        agent_card = {
            "id": self.agent_id,
            "name": f"Hybrid Agent {self.agent_id}",
            "version": "1.0.0",
            "capabilities": {
                "a2a": {"enabled": True},
                "mcp": {"enabled": True},
                "task_types": ["search", "analyze", "store"]
            }
        }

        await self.a2a_client.register_agent(agent_card)

        # Connect to MCP server
        await self.mcp_client.connect()

        print("\n✓ Agent initialized successfully\n")

    async def execute_task(self, task: Dict[str, Any]) -> Any:
        """
        Execute a task received via A2A using MCP tools

        This is where the integration happens:
        1. Receive task from A2A
        2. Map task to MCP tool
        3. Execute MCP tool
        4. Return result via A2A
        """
        task_type = task["type"]
        params = task["params"]

        print(f"Processing task {task['id']} (type: {task_type})")

        # Map A2A task type to MCP tool name
        tool_mapping = {
            "search": "web_search",
            "analyze": "data_analysis",
            "store": "database_write"
        }

        tool_name = tool_mapping.get(task_type)
        if not tool_name:
            raise ValueError(f"Unknown task type: {task_type}")

        # Execute via MCP
        result = await self.mcp_client.call_tool(tool_name, params)

        print(f"✓ Task {task['id']} completed\n")
        return result

    async def run(self) -> None:
        """Main agent loop: listen for tasks and execute them"""
        print("=== Agent Running ===\n")
        print("Listening for tasks via A2A...\n")

        # Listen for incoming tasks via A2A
        async for task in self.a2a_client.listen():
            try:
                # Execute task using MCP tools
                result = await self.execute_task(task)

                # Send result back via A2A
                await self.a2a_client.send_result(task["id"], result)

            except Exception as e:
                print(f"✗ Error processing task {task['id']}: {e}")


async def main():
    """Example usage of hybrid agent"""

    # Create and initialize agent
    agent = HybridAgent("hybrid-001")
    await agent.initialize()

    # Run agent (will process simulated tasks)
    # In production, this runs indefinitely
    await agent.run()

    print("\n=== Example Complete ===")
    print("\nThis example demonstrates:")
    print("  1. Agent registration via A2A")
    print("  2. MCP server connection")
    print("  3. Task reception via A2A")
    print("  4. Tool execution via MCP")
    print("  5. Result delivery via A2A")
    print("\nNext steps:")
    print("  - Configure .env with real API keys")
    print("  - Replace mock clients with real SDKs")
    print("  - Customize task-to-tool mapping")
    print("  - Add error handling and logging")


if __name__ == "__main__":
    asyncio.run(main())
