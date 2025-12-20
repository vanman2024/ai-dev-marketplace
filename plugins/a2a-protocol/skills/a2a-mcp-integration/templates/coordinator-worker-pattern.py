"""
Coordinator-Worker Pattern with A2A and MCP Integration

Architecture:
- Coordinator agent receives tasks via A2A
- Delegates to worker agents via A2A
- Workers use MCP tools to execute tasks
- Results flow back through A2A to coordinator

Use Case: Complex workflows requiring specialized agents with tool access
"""

import asyncio
import os
from typing import Dict, Any, List
from dotenv import load_dotenv

# Import A2A SDK
from a2a import Client as A2AClient, Task, AgentCard

# Import MCP SDK
from mcp import Client as MCPClient, Tool

load_dotenv()


class CoordinatorAgent:
    """Coordinator agent that delegates tasks via A2A"""

    def __init__(self):
        self.a2a_client = A2AClient(
            api_key=os.getenv("A2A_API_KEY"),
            base_url=os.getenv("A2A_BASE_URL")
        )
        self.agent_id = os.getenv("HYBRID_AGENT_ID", "coordinator-001")
        self.worker_agents: Dict[str, AgentCard] = {}

    async def discover_workers(self) -> None:
        """Discover available worker agents via A2A"""
        print("Discovering worker agents...")
        agents = await self.a2a_client.discover_agents(
            capabilities=["task_execution"]
        )
        for agent in agents:
            self.worker_agents[agent.id] = agent
            print(f"  Found worker: {agent.name} ({agent.id})")

    async def delegate_task(self, task_type: str, params: Dict[str, Any]) -> Any:
        """Delegate task to appropriate worker via A2A"""
        # Find worker with required capability
        worker = self._select_worker(task_type)
        if not worker:
            raise ValueError(f"No worker found for task type: {task_type}")

        print(f"Delegating {task_type} to {worker.name}...")

        # Send task via A2A
        task = Task(
            type=task_type,
            params=params,
            requester_id=self.agent_id
        )

        response = await self.a2a_client.send_task(
            agent_id=worker.id,
            task=task
        )

        print(f"  Result received from {worker.name}")
        return response.result

    def _select_worker(self, task_type: str) -> AgentCard:
        """Select appropriate worker for task type"""
        # Simple selection logic (extend as needed)
        for worker in self.worker_agents.values():
            if task_type in worker.capabilities.get("task_types", []):
                return worker
        return None

    async def process_workflow(self, workflow: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Process multi-step workflow with task delegation"""
        results = {}

        for step in workflow:
            step_name = step["name"]
            task_type = step["type"]
            params = step["params"]

            print(f"\nExecuting step: {step_name}")
            result = await self.delegate_task(task_type, params)
            results[step_name] = result

        return results


class WorkerAgent:
    """Worker agent that executes tasks using MCP tools"""

    def __init__(self, agent_id: str, capabilities: List[str]):
        # A2A for receiving tasks
        self.a2a_client = A2AClient(
            api_key=os.getenv("A2A_API_KEY"),
            base_url=os.getenv("A2A_BASE_URL")
        )

        # MCP for tool access
        self.mcp_client = MCPClient(
            server_url=os.getenv("MCP_SERVER_URL")
        )

        self.agent_id = agent_id
        self.capabilities = capabilities

    async def register(self) -> None:
        """Register with A2A network"""
        card = AgentCard(
            id=self.agent_id,
            name=f"Worker {self.agent_id}",
            capabilities={
                "task_types": self.capabilities,
                "task_execution": True
            }
        )

        await self.a2a_client.register_agent(card)
        print(f"Worker {self.agent_id} registered")

    async def execute_task(self, task: Task) -> Any:
        """Execute task using MCP tools"""
        print(f"Worker {self.agent_id} executing task: {task.type}")

        # Map task type to MCP tool
        tool_name = self._map_task_to_tool(task.type)

        # Execute via MCP
        result = await self.mcp_client.call_tool(
            tool_name=tool_name,
            params=task.params
        )

        print(f"  Task completed: {task.type}")
        return result

    def _map_task_to_tool(self, task_type: str) -> str:
        """Map A2A task type to MCP tool name"""
        # Example mapping (extend as needed)
        task_to_tool = {
            "search": "web_search",
            "analyze": "data_analysis",
            "store": "database_write"
        }
        return task_to_tool.get(task_type, "default_tool")

    async def listen(self) -> None:
        """Listen for incoming tasks via A2A"""
        print(f"Worker {self.agent_id} listening for tasks...")

        async for task in self.a2a_client.listen():
            try:
                result = await self.execute_task(task)
                await self.a2a_client.send_result(
                    task_id=task.id,
                    result=result
                )
            except Exception as e:
                await self.a2a_client.send_error(
                    task_id=task.id,
                    error=str(e)
                )


async def main():
    """Example usage of coordinator-worker pattern"""

    # Create coordinator
    coordinator = CoordinatorAgent()

    # Discover workers
    await coordinator.discover_workers()

    # Define workflow
    workflow = [
        {
            "name": "fetch_data",
            "type": "search",
            "params": {"query": "renewable energy"}
        },
        {
            "name": "analyze_data",
            "type": "analyze",
            "params": {"dataset": "renewable_energy"}
        },
        {
            "name": "store_results",
            "type": "store",
            "params": {"collection": "analysis_results"}
        }
    ]

    # Execute workflow
    results = await coordinator.process_workflow(workflow)

    print("\n=== Workflow Complete ===")
    for step, result in results.items():
        print(f"{step}: {result}")


if __name__ == "__main__":
    asyncio.run(main())
