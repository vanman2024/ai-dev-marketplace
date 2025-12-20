"""
Research Cluster - Multi-Agent Research System

This example demonstrates a complete multi-agent research system
using A2A protocol for agent-to-agent communication.

Architecture:
- Coordinator Agent: Orchestrates the research workflow
- Search Agent: Gathers information from various sources
- Analysis Agent: Processes and evaluates findings
- Writing Agent: Synthesizes results into reports
"""

from adk import Agent
from a2a import A2ACardResolver, send_task
import asyncio
import os


# Search Agent (can be deployed as separate A2A service)
search_agent = Agent(
    name="search-agent",
    instructions="""
    You are a research search specialist.

    Your responsibilities:
    1. Find relevant information on given topics
    2. Search multiple sources (web, papers, documentation)
    3. Identify high-quality, credible sources
    4. Extract key information and citations

    Return structured results with:
    - Source URLs
    - Key quotes or excerpts
    - Relevance score
    - Publication date
    """,
    tools=[],  # Add search tools (web search, arxiv, etc.)
    model="gemini-2.0-flash-exp"
)


# Analysis Agent (can be deployed as separate A2A service)
analysis_agent = Agent(
    name="analysis-agent",
    instructions="""
    You are a research analysis specialist.

    Your responsibilities:
    1. Evaluate credibility and quality of sources
    2. Identify patterns and themes across findings
    3. Synthesize insights from multiple sources
    4. Flag contradictions or inconsistencies
    5. Extract key takeaways and implications

    Return structured analysis with:
    - Main themes identified
    - Supporting evidence
    - Confidence levels
    - Notable gaps or limitations
    """,
    tools=[],
    model="gemini-2.0-flash-exp"
)


# Writing Agent (can be deployed as separate A2A service)
writing_agent = Agent(
    name="writing-agent",
    instructions="""
    You are a research writing specialist.

    Your responsibilities:
    1. Create clear, well-structured reports
    2. Cite sources appropriately
    3. Present findings objectively
    4. Use proper academic or business writing style
    5. Create executive summaries

    Report structure:
    - Executive Summary
    - Introduction
    - Key Findings (organized by theme)
    - Analysis and Insights
    - Conclusions
    - References
    """,
    tools=[],
    model="gemini-2.0-flash-exp"
)


async def setup_research_cluster():
    """
    Set up the research cluster by discovering deployed A2A agents.

    In production, these agents would be deployed separately
    and discovered via their Agent Cards.
    """

    # If agents are deployed as A2A services:
    if os.getenv("USE_REMOTE_AGENTS", "false").lower() == "true":
        resolver = A2ACardResolver()

        search_card = await resolver.resolve(
            os.getenv("SEARCH_AGENT_URL", "https://search-agent.example.com")
        )
        analysis_card = await resolver.resolve(
            os.getenv("ANALYSIS_AGENT_URL", "https://analysis-agent.example.com")
        )
        writing_card = await resolver.resolve(
            os.getenv("WRITING_AGENT_URL", "https://writing-agent.example.com")
        )

        session_id = f"research-{os.urandom(8).hex()}"

        search_tool = send_task(
            agent_url=search_card.endpoint,
            session_id=session_id
        )
        analysis_tool = send_task(
            agent_url=analysis_card.endpoint,
            session_id=session_id
        )
        writing_tool = send_task(
            agent_url=writing_card.endpoint,
            session_id=session_id
        )

        return search_tool, analysis_tool, writing_tool

    # For local development, use local agents
    return None, None, None


async def conduct_research(topic: str, depth: str = "comprehensive"):
    """
    Conduct research on a topic using the agent cluster.

    Args:
        topic: Research topic
        depth: Research depth (quick, standard, comprehensive)

    Returns:
        Complete research report
    """

    # Set up tools (remote or local)
    search_tool, analysis_tool, writing_tool = await setup_research_cluster()

    # Create coordinator agent
    coordinator = Agent(
        name="research-coordinator",
        instructions=f"""
        You coordinate a research team to investigate topics thoroughly.

        Team Members:
        1. Search Agent - Finds relevant information
        2. Analysis Agent - Evaluates and synthesizes findings
        3. Writing Agent - Creates polished reports

        Research Process:
        1. Break down the topic into key research questions
        2. Use search agent to gather information for each question
        3. Use analysis agent to identify themes and insights
        4. Use writing agent to create the final report

        Research Depth: {depth}
        - quick: 3-5 sources, brief analysis
        - standard: 10-15 sources, moderate analysis
        - comprehensive: 20+ sources, deep analysis
        """,
        tools=[search_tool, analysis_tool, writing_tool] if search_tool else [],
        model="gemini-2.0-flash-exp"
    )

    # Execute research
    result = await coordinator.run(f"Research topic: {topic}")

    return result


async def parallel_research(topics: list):
    """
    Conduct research on multiple topics in parallel.

    Args:
        topics: List of research topics

    Returns:
        Dictionary of results by topic
    """

    # Create tasks for parallel execution
    tasks = [
        conduct_research(topic, depth="standard")
        for topic in topics
    ]

    # Execute in parallel
    results = await asyncio.gather(*tasks)

    return dict(zip(topics, results))


async def iterative_research(
    initial_topic: str,
    max_iterations: int = 3
):
    """
    Conduct iterative research, diving deeper based on findings.

    Args:
        initial_topic: Starting research topic
        max_iterations: Maximum research iterations

    Returns:
        Final comprehensive report
    """

    current_topic = initial_topic
    findings = []

    for iteration in range(max_iterations):
        print(f"\n=== Research Iteration {iteration + 1} ===")

        # Conduct research
        result = await conduct_research(current_topic, depth="standard")
        findings.append(result)

        # If last iteration, create final report
        if iteration == max_iterations - 1:
            # Synthesize all findings
            _, _, writing_tool = await setup_research_cluster()

            if writing_tool:
                final_report = await writing_tool(
                    f"Synthesize these research findings into a comprehensive report:\n\n"
                    + "\n\n".join(findings)
                )
            else:
                final_report = "\n\n".join(findings)

            return final_report

        # Identify next research direction
        # (In real implementation, use analysis agent to determine next steps)
        current_topic = f"Deep dive into aspects of: {current_topic}"


if __name__ == "__main__":
    print("Research Cluster Examples\n")

    # Example 1: Single topic research
    print("Example 1: Single Topic Research")
    result = asyncio.run(
        conduct_research(
            "Impact of AI agents on software development",
            depth="comprehensive"
        )
    )
    print(f"Result:\n{result}\n")

    # Example 2: Parallel research
    print("\nExample 2: Parallel Research")
    topics = [
        "AI agent frameworks",
        "Multi-agent systems",
        "Agent-to-agent communication protocols"
    ]
    results = asyncio.run(parallel_research(topics))
    for topic, result in results.items():
        print(f"\nTopic: {topic}")
        print(f"Result: {result[:200]}...")

    # Example 3: Iterative research
    print("\nExample 3: Iterative Research")
    result = asyncio.run(
        iterative_research(
            "Google Agent Development Kit",
            max_iterations=2
        )
    )
    print(f"Final Report:\n{result}")
