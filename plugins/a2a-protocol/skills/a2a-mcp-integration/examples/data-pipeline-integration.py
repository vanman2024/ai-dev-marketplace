"""
Multi-Agent Data Pipeline with A2A + MCP Integration

This example demonstrates a complete data processing pipeline where:
- Multiple agents coordinate via A2A protocol
- Each agent uses MCP tools for specialized tasks
- Data flows through the pipeline via agent delegation
- Results are aggregated and stored

Pipeline Flow:
1. Data Fetcher Agent → Fetches raw data via MCP web search tool
2. Data Processor Agent → Processes data via MCP analysis tool
3. Data Storage Agent → Stores results via MCP database tool

Usage:
    python examples/data-pipeline-integration.py
"""

import asyncio
import os
from typing import Dict, Any, List
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()


@dataclass
class PipelineData:
    """Data structure flowing through pipeline"""
    stage: str
    data: Any
    metadata: Dict[str, Any]


class MockA2AClient:
    """Mock A2A client"""
    def __init__(self):
        self.registered_agents = {}

    async def register_agent(self, card):
        self.registered_agents[card['id']] = card
        print(f"[A2A] Registered: {card['id']}")

    async def discover_agents(self, capabilities=None):
        agents = []
        for agent_id, card in self.registered_agents.items():
            if capabilities:
                # Simple capability matching
                role_match = capabilities.get('role')
                if role_match and card['capabilities'].get('role') == role_match:
                    agents.append(card)
            else:
                agents.append(card)
        return agents

    async def send_task(self, agent_id, task):
        print(f"[A2A] Sending task to {agent_id}: {task['type']}")
        # Simulated response
        return {"result": f"Result from {agent_id}"}


class MockMCPClient:
    """Mock MCP client"""
    async def connect(self):
        print("[MCP] Connected")

    async def call_tool(self, tool_name, params):
        print(f"[MCP] Executing tool: {tool_name}")
        await asyncio.sleep(0.3)  # Simulate work

        # Simulate tool-specific responses
        if tool_name == "web_search":
            return {
                "results": [
                    {"title": "AI Trends 2025", "url": "https://example.com/1"},
                    {"title": "Machine Learning News", "url": "https://example.com/2"}
                ]
            }
        elif tool_name == "data_analysis":
            return {
                "summary": "Analyzed 100 data points",
                "insights": ["Trend 1: Growth in AI", "Trend 2: Cloud adoption"],
                "score": 0.85
            }
        elif tool_name == "database_write":
            return {"status": "success", "record_id": "rec_12345"}

        return {"status": "success"}


class DataFetcherAgent:
    """Agent that fetches data using MCP tools"""

    def __init__(self, a2a_client, mcp_client):
        self.agent_id = "data-fetcher-001"
        self.a2a = a2a_client
        self.mcp = mcp_client

    async def initialize(self):
        """Register with A2A network"""
        card = {
            "id": self.agent_id,
            "name": "Data Fetcher Agent",
            "capabilities": {
                "role": "fetcher",
                "tasks": ["fetch_data", "web_search"]
            }
        }
        await self.a2a.register_agent(card)

    async def fetch_data(self, query: str) -> PipelineData:
        """Fetch data using MCP web search tool"""
        print(f"\n{'='*50}")
        print(f"STAGE 1: Data Fetching")
        print(f"{'='*50}")
        print(f"Query: {query}")

        # Execute MCP tool
        search_results = await self.mcp.call_tool("web_search", {"query": query})

        pipeline_data = PipelineData(
            stage="fetched",
            data=search_results,
            metadata={
                "query": query,
                "fetcher": self.agent_id,
                "result_count": len(search_results.get("results", []))
            }
        )

        print(f"✓ Fetched {pipeline_data.metadata['result_count']} results")
        return pipeline_data


class DataProcessorAgent:
    """Agent that processes data using MCP tools"""

    def __init__(self, a2a_client, mcp_client):
        self.agent_id = "data-processor-001"
        self.a2a = a2a_client
        self.mcp = mcp_client

    async def initialize(self):
        """Register with A2A network"""
        card = {
            "id": self.agent_id,
            "name": "Data Processor Agent",
            "capabilities": {
                "role": "processor",
                "tasks": ["process_data", "analyze"]
            }
        }
        await self.a2a.register_agent(card)

    async def process_data(self, pipeline_data: PipelineData) -> PipelineData:
        """Process data using MCP analysis tool"""
        print(f"\n{'='*50}")
        print(f"STAGE 2: Data Processing")
        print(f"{'='*50}")
        print(f"Processing data from stage: {pipeline_data.stage}")

        # Execute MCP tool
        analysis = await self.mcp.call_tool("data_analysis", {
            "dataset": pipeline_data.data,
            "mode": "comprehensive"
        })

        processed_data = PipelineData(
            stage="processed",
            data=analysis,
            metadata={
                **pipeline_data.metadata,
                "processor": self.agent_id,
                "insights_count": len(analysis.get("insights", [])),
                "score": analysis.get("score", 0)
            }
        )

        print(f"✓ Generated {processed_data.metadata['insights_count']} insights")
        print(f"✓ Analysis score: {processed_data.metadata['score']}")
        return processed_data


class DataStorageAgent:
    """Agent that stores data using MCP tools"""

    def __init__(self, a2a_client, mcp_client):
        self.agent_id = "data-storage-001"
        self.a2a = a2a_client
        self.mcp = mcp_client

    async def initialize(self):
        """Register with A2A network"""
        card = {
            "id": self.agent_id,
            "name": "Data Storage Agent",
            "capabilities": {
                "role": "storage",
                "tasks": ["store_data", "database_write"]
            }
        }
        await self.a2a.register_agent(card)

    async def store_data(self, pipeline_data: PipelineData) -> Dict[str, Any]:
        """Store data using MCP database tool"""
        print(f"\n{'='*50}")
        print(f"STAGE 3: Data Storage")
        print(f"{'='*50}")
        print(f"Storing data from stage: {pipeline_data.stage}")

        # Execute MCP tool
        storage_result = await self.mcp.call_tool("database_write", {
            "collection": "pipeline_results",
            "data": {
                "analysis": pipeline_data.data,
                "metadata": pipeline_data.metadata
            }
        })

        print(f"✓ Stored with ID: {storage_result.get('record_id')}")

        return {
            "status": "complete",
            "record_id": storage_result.get("record_id"),
            "metadata": pipeline_data.metadata
        }


class PipelineOrchestrator:
    """Orchestrates the data pipeline using A2A for agent coordination"""

    def __init__(self):
        # Shared MCP client (centralized tools)
        self.mcp_client = MockMCPClient()

        # A2A clients for agent coordination
        self.a2a_client = MockA2AClient()

        # Pipeline agents
        self.fetcher = DataFetcherAgent(self.a2a_client, self.mcp_client)
        self.processor = DataProcessorAgent(self.a2a_client, self.mcp_client)
        self.storage = DataStorageAgent(self.a2a_client, self.mcp_client)

    async def initialize(self):
        """Initialize all agents and MCP connection"""
        print("\n" + "="*50)
        print("INITIALIZING DATA PIPELINE")
        print("="*50 + "\n")

        # Connect to MCP server (shared tools)
        await self.mcp_client.connect()

        # Initialize all agents (register with A2A)
        await self.fetcher.initialize()
        await self.processor.initialize()
        await self.storage.initialize()

        print("\n✓ Pipeline initialized\n")

    async def run_pipeline(self, query: str) -> Dict[str, Any]:
        """Execute the complete pipeline"""
        print("\n" + "="*50)
        print(f"RUNNING PIPELINE: {query}")
        print("="*50)

        # Stage 1: Fetch data
        fetched_data = await self.fetcher.fetch_data(query)

        # Stage 2: Process data
        processed_data = await self.processor.process_data(fetched_data)

        # Stage 3: Store data
        final_result = await self.storage.store_data(processed_data)

        return final_result


async def main():
    """Example: Multi-agent data pipeline"""

    print("\n╔════════════════════════════════════════════════════╗")
    print("║  Multi-Agent Data Pipeline Example               ║")
    print("║  A2A for Coordination + MCP for Tools            ║")
    print("╚════════════════════════════════════════════════════╝\n")

    # Create orchestrator
    orchestrator = PipelineOrchestrator()

    # Initialize pipeline
    await orchestrator.initialize()

    # Run pipeline
    result = await orchestrator.run_pipeline("renewable energy innovations 2025")

    # Display results
    print("\n" + "="*50)
    print("PIPELINE COMPLETE")
    print("="*50)
    print(f"\nStatus: {result['status']}")
    print(f"Record ID: {result['record_id']}")
    print(f"\nMetadata:")
    for key, value in result['metadata'].items():
        print(f"  {key}: {value}")

    print("\n" + "="*50)
    print("KEY INTEGRATION POINTS")
    print("="*50)
    print("\n1. Agent Coordination (A2A):")
    print("   - Agents registered with A2A network")
    print("   - Discovery of specialized agents")
    print("   - Task delegation between stages")

    print("\n2. Tool Execution (MCP):")
    print("   - Centralized MCP server for all tools")
    print("   - web_search tool for data fetching")
    print("   - data_analysis tool for processing")
    print("   - database_write tool for storage")

    print("\n3. Data Flow:")
    print("   - PipelineData structure carries context")
    print("   - Metadata enriched at each stage")
    print("   - Seamless handoff between agents")

    print("\n" + "="*50)
    print("ARCHITECTURE BENEFITS")
    print("="*50)
    print("\n✓ Modular: Each agent has single responsibility")
    print("✓ Scalable: Add more agents or stages easily")
    print("✓ Flexible: Swap tools or agents independently")
    print("✓ Observable: Metadata tracks entire pipeline")
    print("✓ Resilient: Failures isolated to specific stages")

    print("\n" + "="*50)
    print("NEXT STEPS")
    print("="*50)
    print("\n1. Replace mock clients with real A2A/MCP SDKs")
    print("2. Add error handling and retry logic")
    print("3. Implement parallel processing for batches")
    print("4. Add monitoring and logging")
    print("5. Configure real data sources and tools")
    print()


if __name__ == "__main__":
    asyncio.run(main())
