"""
A2A Server Implementation - Expose ADK Agent via A2A Protocol

This template shows how to expose an ADK agent as an A2A service
that other agents can discover and communicate with.
"""

from adk import Agent
from a2a import (
    AgentExecutor,
    DefaultRequestHandler,
    A2AStarletteApplication,
    AgentCard,
    AgentCapabilities,
    AgentSkill
)
import asyncio
import os


# Define your agent's executor
class MyAgentExecutor(AgentExecutor):
    """
    Handles incoming A2A requests and executes them using your ADK agent.
    """

    def __init__(self, agent: Agent):
        self.agent = agent

    async def execute(self, request):
        """
        Process an A2A request.

        Args:
            request: A2A request object containing:
                - message: The task to perform
                - session_id: Session identifier for context
                - context: Additional context data

        Returns:
            Result object with response message and artifacts
        """
        # Extract request parameters
        message = request.params.get('message', '')
        session_id = request.params.get('session_id', 'default')
        context = request.params.get('context', {})

        # Execute using your ADK agent
        result = await self.agent.run(
            message,
            session_id=session_id,
            context=context
        )

        # Return structured response
        return {
            "message": result.text,
            "artifacts": result.artifacts if hasattr(result, 'artifacts') else [],
            "status": "completed"
        }


# Create your ADK agent
my_agent = Agent(
    name="my-agent",
    instructions="""
    You are a helpful assistant that can perform various tasks.
    Respond clearly and concisely to requests.
    """,
    # Add your tools here
    tools=[],
    # Configure your model (replace with actual Gemini model)
    model="gemini-2.0-flash-exp"
)

# Configure Agent Card
agent_card = AgentCard(
    id="my-agent",
    name="My Agent",
    description="A helpful assistant agent that performs various tasks",
    version="1.0.0",
    url=os.getenv("A2A_AGENT_URL", "https://my-agent.example.com"),
    capabilities=AgentCapabilities(
        skills=[
            AgentSkill(
                name="general-assistance",
                description="Provide helpful assistance for various tasks"
            ),
            AgentSkill(
                name="information-retrieval",
                description="Retrieve and synthesize information"
            )
        ],
        modalities=["text"],
        streaming=True
    ),
    protocol={
        "version": "0.3",
        "transport": "grpc"
    }
)

# Create request handler
request_handler = DefaultRequestHandler(
    executor=MyAgentExecutor(my_agent)
)

# Create A2A application
app = A2AStarletteApplication(
    handler=request_handler,
    card=agent_card
)

# Run the server
if __name__ == "__main__":
    import uvicorn

    # Get configuration from environment
    host = os.getenv("A2A_HOST", "0.0.0.0")
    port = int(os.getenv("A2A_PORT", "8000"))

    print(f"Starting A2A server on {host}:{port}")
    print(f"Agent Card will be available at: http://{host}:{port}/.well-known/agent.json")

    uvicorn.run(app, host=host, port=port)
