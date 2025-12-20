"""
A2A Client Implementation - Consume Remote A2A Agent

This template shows how to discover and communicate with
a remote A2A agent from your ADK agent.
"""

from adk import Agent
from a2a import A2ACardResolver, send_task
import asyncio
import os


async def consume_remote_agent(remote_agent_url: str):
    """
    Discover and use a remote A2A agent.

    Args:
        remote_agent_url: URL of the remote agent (e.g., https://remote-agent.example.com)

    Returns:
        Result from the remote agent
    """

    # Step 1: Discover the remote agent's capabilities
    print(f"Discovering remote agent at: {remote_agent_url}")

    resolver = A2ACardResolver()
    agent_card = await resolver.resolve(remote_agent_url)

    print(f"Found agent: {agent_card.name}")
    print(f"Description: {agent_card.description}")
    print(f"Capabilities: {agent_card.capabilities}")

    # Step 2: Create send_task tool to communicate with remote agent
    send_task_tool = send_task(
        agent_url=agent_card.endpoint,
        session_id=f"session-{os.urandom(8).hex()}"
    )

    # Step 3: Create your agent that uses the remote agent
    my_agent = Agent(
        name="my-client-agent",
        instructions=f"""
        You have access to a remote agent: {agent_card.name}

        {agent_card.description}

        You can delegate tasks to this remote agent using the send_task tool.
        When a user request matches the remote agent's capabilities, use it.
        """,
        tools=[send_task_tool],
        model="gemini-2.0-flash-exp"
    )

    # Step 4: Use your agent (which can delegate to remote agent)
    result = await my_agent.run(
        "Use the remote agent to help with this task: Research AI agents"
    )

    return result


async def multi_agent_workflow():
    """
    Example of coordinating multiple remote A2A agents.
    """

    # Discover multiple remote agents
    resolver = A2ACardResolver()

    research_agent = await resolver.resolve(
        os.getenv("RESEARCH_AGENT_URL", "https://research-agent.example.com")
    )
    analysis_agent = await resolver.resolve(
        os.getenv("ANALYSIS_AGENT_URL", "https://analysis-agent.example.com")
    )
    writing_agent = await resolver.resolve(
        os.getenv("WRITING_AGENT_URL", "https://writing-agent.example.com")
    )

    # Create tools for each remote agent
    session_id = f"session-{os.urandom(8).hex()}"

    research_tool = send_task(
        agent_url=research_agent.endpoint,
        session_id=session_id
    )
    analysis_tool = send_task(
        agent_url=analysis_agent.endpoint,
        session_id=session_id
    )
    writing_tool = send_task(
        agent_url=writing_agent.endpoint,
        session_id=session_id
    )

    # Create coordinator agent
    coordinator = Agent(
        name="coordinator",
        instructions="""
        You coordinate multiple specialist agents to complete complex tasks:

        1. Research Agent - Gathers information and finds relevant sources
        2. Analysis Agent - Processes data and identifies insights
        3. Writing Agent - Synthesizes findings into clear reports

        For each task:
        1. Use research agent to gather information
        2. Use analysis agent to process findings
        3. Use writing agent to create the final output
        """,
        tools=[research_tool, analysis_tool, writing_tool],
        model="gemini-2.0-flash-exp"
    )

    # Execute multi-agent workflow
    result = await coordinator.run(
        "Create a comprehensive report on the state of AI agents in 2025"
    )

    return result


async def agent_with_fallback():
    """
    Example of using remote agent with local fallback.
    """

    try:
        # Try to use remote specialist agent
        resolver = A2ACardResolver()
        specialist_agent = await resolver.resolve(
            os.getenv("SPECIALIST_AGENT_URL", "https://specialist.example.com")
        )

        specialist_tool = send_task(
            agent_url=specialist_agent.endpoint,
            session_id=f"session-{os.urandom(8).hex()}"
        )

        agent = Agent(
            name="agent-with-fallback",
            instructions="""
            Try to use the specialist agent for complex tasks.
            If it fails or is unavailable, handle the task yourself.
            """,
            tools=[specialist_tool],
            model="gemini-2.0-flash-exp"
        )

    except Exception as e:
        print(f"Remote agent unavailable: {e}")
        print("Falling back to local agent...")

        # Fallback to local agent without remote tools
        agent = Agent(
            name="local-fallback-agent",
            instructions="Handle tasks locally without remote agents.",
            tools=[],
            model="gemini-2.0-flash-exp"
        )

    result = await agent.run("Process this task")
    return result


if __name__ == "__main__":
    # Example 1: Single remote agent
    print("Example 1: Using single remote agent")
    result = asyncio.run(
        consume_remote_agent("https://remote-agent.example.com")
    )
    print(f"Result: {result}")

    # Example 2: Multi-agent workflow
    print("\nExample 2: Multi-agent workflow")
    result = asyncio.run(multi_agent_workflow())
    print(f"Result: {result}")

    # Example 3: Agent with fallback
    print("\nExample 3: Agent with fallback")
    result = asyncio.run(agent_with_fallback())
    print(f"Result: {result}")
