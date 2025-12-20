"""
Agent Mesh with Centralized MCP Tools Pattern

Architecture:
- Agents form A2A communication mesh (peer-to-peer network)
- Centralized MCP server provides shared tools
- All agents access same tool set via MCP
- Coordination and task delegation via A2A mesh

Use Case: Teams of agents working with shared infrastructure
"""

import asyncio
import os
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from dotenv import load_dotenv

# Import A2A SDK
from a2a import Client as A2AClient, AgentCard, Message

# Import MCP SDK
from mcp import Client as MCPClient

load_dotenv()


@dataclass
class MeshNode:
    """Represents a node in the agent mesh"""
    id: str
    card: AgentCard
    role: str
    status: str = "active"


class CentralizedMCPTools:
    """Centralized MCP tool server shared by all agents"""

    def __init__(self):
        self.mcp_client = MCPClient(
            server_url=os.getenv("MCP_SERVER_URL")
        )
        self.tool_cache: Dict[str, Any] = {}

    async def initialize(self) -> None:
        """Initialize connection to centralized MCP server"""
        await self.mcp_client.connect()
        print("Connected to centralized MCP server")

        # Cache available tools
        tools = await self.mcp_client.list_tools()
        for tool in tools:
            self.tool_cache[tool.name] = tool
            print(f"  Available tool: {tool.name}")

    async def execute_tool(self, tool_name: str, params: Dict[str, Any]) -> Any:
        """Execute a tool on the centralized MCP server"""
        if tool_name not in self.tool_cache:
            raise ValueError(f"Tool not found: {tool_name}")

        print(f"Executing centralized tool: {tool_name}")
        result = await self.mcp_client.call_tool(tool_name, params)
        return result

    def list_tools(self) -> List[str]:
        """List all available tools"""
        return list(self.tool_cache.keys())


class MeshAgent:
    """Agent that participates in A2A mesh and accesses centralized MCP tools"""

    def __init__(
        self,
        agent_id: str,
        role: str,
        centralized_tools: CentralizedMCPTools
    ):
        self.agent_id = agent_id
        self.role = role
        self.centralized_tools = centralized_tools

        # A2A client for mesh communication
        self.a2a_client = A2AClient(
            api_key=os.getenv("A2A_API_KEY"),
            base_url=os.getenv("A2A_BASE_URL")
        )

        # Mesh state
        self.mesh_nodes: Dict[str, MeshNode] = {}
        self.message_handlers: Dict[str, callable] = {}

    async def join_mesh(self) -> None:
        """Join the agent mesh network"""
        # Create agent card
        card = AgentCard(
            id=self.agent_id,
            name=f"{self.role.title()} Agent",
            version="1.0.0",
            capabilities={
                "role": self.role,
                "mesh": True,
                "tools": self.centralized_tools.list_tools()
            }
        )

        # Register with A2A network
        await self.a2a_client.register_agent(card)
        print(f"Agent {self.agent_id} ({self.role}) joined mesh")

        # Discover other mesh nodes
        await self.discover_mesh_nodes()

    async def discover_mesh_nodes(self) -> None:
        """Discover other agents in the mesh"""
        print(f"Discovering mesh nodes...")

        agents = await self.a2a_client.discover_agents(
            capabilities={"mesh": True}
        )

        for agent in agents:
            if agent.id != self.agent_id:
                node = MeshNode(
                    id=agent.id,
                    card=agent,
                    role=agent.capabilities.get("role", "unknown")
                )
                self.mesh_nodes[agent.id] = node
                print(f"  Found node: {agent.name} (role: {node.role})")

    async def broadcast_to_mesh(self, message_type: str, data: Any) -> None:
        """Broadcast message to all nodes in mesh"""
        print(f"Broadcasting {message_type} to mesh...")

        message = Message(
            type=message_type,
            sender=self.agent_id,
            data=data
        )

        for node_id in self.mesh_nodes.keys():
            await self.a2a_client.send_message(node_id, message)

    async def send_to_node(
        self,
        target_id: str,
        message_type: str,
        data: Any
    ) -> Optional[Any]:
        """Send direct message to specific mesh node"""
        if target_id not in self.mesh_nodes:
            raise ValueError(f"Node not in mesh: {target_id}")

        print(f"Sending {message_type} to {target_id}...")

        message = Message(
            type=message_type,
            sender=self.agent_id,
            data=data
        )

        response = await self.a2a_client.send_message_and_wait(
            target_id,
            message
        )

        return response.data if response else None

    async def execute_tool(self, tool_name: str, params: Dict[str, Any]) -> Any:
        """Execute tool on centralized MCP server"""
        result = await self.centralized_tools.execute_tool(tool_name, params)
        print(f"  Tool result: {result}")
        return result

    async def collaborate_on_task(
        self,
        task_description: str,
        task_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Collaborate with mesh nodes to complete a task"""
        print(f"\n=== Starting collaborative task: {task_description} ===")

        # Broadcast task announcement
        await self.broadcast_to_mesh("task_announcement", {
            "description": task_description,
            "coordinator": self.agent_id
        })

        # Collect responses from interested agents
        responses = await self._collect_task_responses()

        # Assign subtasks based on agent roles
        assignments = self._assign_subtasks(responses, task_data)

        # Execute subtasks
        results = {}
        for agent_id, subtask in assignments.items():
            result = await self.send_to_node(
                agent_id,
                "execute_subtask",
                subtask
            )
            results[agent_id] = result

        return results

    async def _collect_task_responses(self) -> List[Dict[str, Any]]:
        """Collect responses from agents interested in task"""
        # Simplified - in real implementation, wait for responses
        return [
            {"agent_id": node_id, "capabilities": node.card.capabilities}
            for node_id, node in self.mesh_nodes.items()
        ]

    def _assign_subtasks(
        self,
        responses: List[Dict[str, Any]],
        task_data: Dict[str, Any]
    ) -> Dict[str, Dict[str, Any]]:
        """Assign subtasks to agents based on their capabilities"""
        # Example assignment logic (extend as needed)
        assignments = {}

        for response in responses:
            agent_id = response["agent_id"]
            role = response["capabilities"].get("role")

            if role == "search":
                assignments[agent_id] = {
                    "type": "search",
                    "params": task_data.get("search_params", {})
                }
            elif role == "analyze":
                assignments[agent_id] = {
                    "type": "analyze",
                    "params": task_data.get("analyze_params", {})
                }
            elif role == "storage":
                assignments[agent_id] = {
                    "type": "store",
                    "params": task_data.get("storage_params", {})
                }

        return assignments

    async def handle_subtask(self, subtask: Dict[str, Any]) -> Any:
        """Handle assigned subtask using centralized tools"""
        subtask_type = subtask["type"]
        params = subtask["params"]

        print(f"Handling subtask: {subtask_type}")

        # Map subtask to MCP tool
        tool_map = {
            "search": "web_search",
            "analyze": "data_analysis",
            "store": "database_write"
        }

        tool_name = tool_map.get(subtask_type)
        if not tool_name:
            raise ValueError(f"Unknown subtask type: {subtask_type}")

        # Execute via centralized MCP
        result = await self.execute_tool(tool_name, params)
        return result

    async def listen(self) -> None:
        """Listen for mesh messages"""
        print(f"Agent {self.agent_id} listening on mesh...")

        async for message in self.a2a_client.listen():
            try:
                if message.type == "execute_subtask":
                    result = await self.handle_subtask(message.data)
                    await self.a2a_client.send_response(
                        message.id,
                        {"result": result}
                    )
                elif message.type == "task_announcement":
                    # Respond if interested based on role
                    print(f"  Task announced: {message.data['description']}")
                    # Implementation for responding to task announcements

            except Exception as e:
                print(f"Error handling message: {e}")


async def main():
    """Example: Agent mesh with centralized MCP tools"""

    # Initialize centralized MCP tool server
    central_tools = CentralizedMCPTools()
    await central_tools.initialize()

    # Create mesh agents with different roles
    search_agent = MeshAgent("agent-search", "search", central_tools)
    analyze_agent = MeshAgent("agent-analyze", "analyze", central_tools)
    storage_agent = MeshAgent("agent-storage", "storage", central_tools)

    # Join mesh
    await search_agent.join_mesh()
    await analyze_agent.join_mesh()
    await storage_agent.join_mesh()

    # Example collaborative task
    task_data = {
        "search_params": {"query": "renewable energy trends"},
        "analyze_params": {"dataset": "search_results"},
        "storage_params": {"collection": "energy_research"}
    }

    results = await search_agent.collaborate_on_task(
        "Research renewable energy trends",
        task_data
    )

    print("\n=== Collaboration Results ===")
    for agent_id, result in results.items():
        print(f"{agent_id}: {result}")


if __name__ == "__main__":
    asyncio.run(main())
