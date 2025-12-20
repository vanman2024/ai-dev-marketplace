"""
Multi-Agent Orchestration with A2A Protocol

This template demonstrates coordinating multiple specialized A2A agents
to collaborate on complex tasks.
"""

from adk import Agent
from a2a import A2ACardResolver, send_task
import asyncio
import os
from typing import List, Dict


class MultiAgentOrchestrator:
    """
    Orchestrates multiple A2A agents for complex workflows.
    """

    def __init__(self, agent_urls: Dict[str, str]):
        """
        Initialize orchestrator with remote agent URLs.

        Args:
            agent_urls: Dictionary mapping agent roles to URLs
                       e.g., {"research": "https://research-agent.example.com"}
        """
        self.agent_urls = agent_urls
        self.agents = {}
        self.tools = {}

    async def initialize(self):
        """Discover and initialize all remote agents."""
        resolver = A2ACardResolver()

        for role, url in self.agent_urls.items():
            print(f"Discovering {role} agent at {url}...")
            agent_card = await resolver.resolve(url)

            self.agents[role] = agent_card

            # Create send_task tool for this agent
            self.tools[role] = send_task(
                agent_url=agent_card.endpoint,
                session_id=f"session-{os.urandom(8).hex()}"
            )

            print(f"✓ {role}: {agent_card.name} - {agent_card.description}")

    def create_coordinator(self, workflow_type: str) -> Agent:
        """
        Create coordinator agent based on workflow type.

        Args:
            workflow_type: Type of workflow (research, analysis, development)

        Returns:
            Configured coordinator agent
        """

        if workflow_type == "research":
            return self._create_research_coordinator()
        elif workflow_type == "analysis":
            return self._create_analysis_coordinator()
        elif workflow_type == "development":
            return self._create_development_coordinator()
        else:
            raise ValueError(f"Unknown workflow type: {workflow_type}")

    def _create_research_coordinator(self) -> Agent:
        """Create coordinator for research workflow."""
        return Agent(
            name="research-coordinator",
            instructions="""
            You coordinate a team of specialist agents to conduct research:

            1. SEARCH AGENT: Finds relevant information and sources
            2. ANALYSIS AGENT: Evaluates and synthesizes findings
            3. WRITING AGENT: Creates comprehensive reports

            Research Workflow:
            1. Use search agent to gather information on the topic
            2. Use analysis agent to identify key insights and patterns
            3. Use writing agent to synthesize into a clear report

            Always cite sources and validate findings.
            """,
            tools=list(self.tools.values()),
            model="gemini-2.0-flash-exp"
        )

    def _create_analysis_coordinator(self) -> Agent:
        """Create coordinator for data analysis workflow."""
        return Agent(
            name="analysis-coordinator",
            instructions="""
            You coordinate data analysis across specialist agents:

            1. DATA AGENT: Retrieves and preprocesses data
            2. STATS AGENT: Performs statistical analysis
            3. VIZ AGENT: Creates visualizations
            4. REPORT AGENT: Generates insights report

            Analysis Workflow:
            1. Use data agent to load and clean data
            2. Use stats agent to compute metrics and find patterns
            3. Use viz agent to create charts and graphs
            4. Use report agent to summarize findings

            Focus on actionable insights backed by data.
            """,
            tools=list(self.tools.values()),
            model="gemini-2.0-flash-exp"
        )

    def _create_development_coordinator(self) -> Agent:
        """Create coordinator for software development workflow."""
        return Agent(
            name="development-coordinator",
            instructions="""
            You coordinate software development across specialist agents:

            1. DESIGN AGENT: Creates architecture and design docs
            2. CODE AGENT: Implements features and fixes bugs
            3. TEST AGENT: Writes and runs tests
            4. REVIEW AGENT: Reviews code quality and security

            Development Workflow:
            1. Use design agent to plan architecture
            2. Use code agent to implement functionality
            3. Use test agent to validate correctness
            4. Use review agent to ensure quality

            Follow best practices and maintain high code quality.
            """,
            tools=list(self.tools.values()),
            model="gemini-2.0-flash-exp"
        )

    async def execute_workflow(
        self,
        workflow_type: str,
        task: str
    ) -> str:
        """
        Execute a multi-agent workflow.

        Args:
            workflow_type: Type of workflow to execute
            task: Task description

        Returns:
            Workflow result
        """
        coordinator = self.create_coordinator(workflow_type)
        result = await coordinator.run(task)
        return result


async def research_workflow_example():
    """
    Example: Research workflow with multiple agents.
    """
    orchestrator = MultiAgentOrchestrator({
        "search": os.getenv(
            "SEARCH_AGENT_URL",
            "https://search-agent.example.com"
        ),
        "analysis": os.getenv(
            "ANALYSIS_AGENT_URL",
            "https://analysis-agent.example.com"
        ),
        "writing": os.getenv(
            "WRITING_AGENT_URL",
            "https://writing-agent.example.com"
        )
    })

    await orchestrator.initialize()

    result = await orchestrator.execute_workflow(
        workflow_type="research",
        task="Research the impact of AI agents on software development in 2025"
    )

    return result


async def parallel_execution_example():
    """
    Example: Execute multiple agents in parallel.
    """
    resolver = A2ACardResolver()

    # Discover multiple agents
    agent1 = await resolver.resolve("https://agent1.example.com")
    agent2 = await resolver.resolve("https://agent2.example.com")
    agent3 = await resolver.resolve("https://agent3.example.com")

    # Create tools
    session_id = f"session-{os.urandom(8).hex()}"
    tool1 = send_task(agent_url=agent1.endpoint, session_id=session_id)
    tool2 = send_task(agent_url=agent2.endpoint, session_id=session_id)
    tool3 = send_task(agent_url=agent3.endpoint, session_id=session_id)

    # Execute in parallel
    results = await asyncio.gather(
        tool1("Task for agent 1"),
        tool2("Task for agent 2"),
        tool3("Task for agent 3")
    )

    return results


async def hierarchical_agents_example():
    """
    Example: Hierarchical multi-agent system.
    """
    # Top-level coordinator
    orchestrator = MultiAgentOrchestrator({
        "team1_lead": "https://team1-lead.example.com",
        "team2_lead": "https://team2-lead.example.com"
    })

    await orchestrator.initialize()

    # Each team lead coordinates their own sub-agents
    # (which are also A2A agents)

    result = await orchestrator.execute_workflow(
        workflow_type="research",
        task="Multi-team research project"
    )

    return result


if __name__ == "__main__":
    print("Multi-Agent Orchestration Examples\n")

    print("Example 1: Research Workflow")
    result = asyncio.run(research_workflow_example())
    print(f"Result: {result}\n")

    print("Example 2: Parallel Execution")
    results = asyncio.run(parallel_execution_example())
    print(f"Results: {results}\n")

    print("Example 3: Hierarchical Agents")
    result = asyncio.run(hierarchical_agents_example())
    print(f"Result: {result}")
