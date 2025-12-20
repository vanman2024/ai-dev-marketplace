"""
gRPC Transport Configuration for A2A Protocol v0.3+

This template shows how to configure gRPC transport for A2A agents,
providing better performance and streaming capabilities.
"""

from adk import Agent
from a2a import (
    A2AStarletteApplication,
    GrpcTransport,
    AgentCard,
    DefaultRequestHandler
)
import os


def create_grpc_server(
    agent: Agent,
    agent_card: AgentCard,
    secure: bool = True
) -> A2AStarletteApplication:
    """
    Create A2A server with gRPC transport.

    Args:
        agent: Your ADK agent
        agent_card: Agent card configuration
        secure: Whether to use TLS (default: True)

    Returns:
        Configured A2A application with gRPC
    """

    # Configure gRPC transport
    if secure:
        # Production: Use TLS
        transport = GrpcTransport(
            host=os.getenv("GRPC_HOST", "0.0.0.0"),
            port=int(os.getenv("GRPC_PORT", "50051")),
            secure=True,
            cert_file=os.getenv("TLS_CERT_FILE", "/path/to/cert.pem"),
            key_file=os.getenv("TLS_KEY_FILE", "/path/to/key.pem"),
            # Optional: Client certificate verification
            client_ca_file=os.getenv("CLIENT_CA_FILE", None),
            # Optional: gRPC options
            options=[
                ('grpc.max_send_message_length', 10 * 1024 * 1024),  # 10MB
                ('grpc.max_receive_message_length', 10 * 1024 * 1024)
            ]
        )
    else:
        # Development: No TLS
        transport = GrpcTransport(
            host="localhost",
            port=50051,
            secure=False
        )

    # Create request handler
    from a2a import AgentExecutor

    class GrpcAgentExecutor(AgentExecutor):
        def __init__(self, agent: Agent):
            self.agent = agent

        async def execute(self, request):
            result = await self.agent.run(request.params.get('message', ''))
            return {
                "message": result.text,
                "status": "completed"
            }

    handler = DefaultRequestHandler(
        executor=GrpcAgentExecutor(agent)
    )

    # Create A2A application
    app = A2AStarletteApplication(
        handler=handler,
        card=agent_card,
        transport=transport
    )

    return app


def create_streaming_grpc_server(
    agent: Agent,
    agent_card: AgentCard
) -> A2AStarletteApplication:
    """
    Create A2A server with streaming gRPC support.

    Enables real-time streaming of agent responses.
    """

    from a2a import StreamingAgentExecutor

    class StreamingGrpcExecutor(StreamingAgentExecutor):
        def __init__(self, agent: Agent):
            self.agent = agent

        async def execute_stream(self, request):
            """Stream responses as they're generated."""
            async for chunk in self.agent.run_stream(
                request.params.get('message', '')
            ):
                yield {
                    "chunk": chunk.text,
                    "done": chunk.done
                }

    transport = GrpcTransport(
        host=os.getenv("GRPC_HOST", "0.0.0.0"),
        port=int(os.getenv("GRPC_PORT", "50051")),
        secure=True,
        cert_file=os.getenv("TLS_CERT_FILE"),
        key_file=os.getenv("TLS_KEY_FILE"),
        # Enable streaming
        enable_streaming=True
    )

    handler = DefaultRequestHandler(
        executor=StreamingGrpcExecutor(agent)
    )

    app = A2AStarletteApplication(
        handler=handler,
        card=agent_card,
        transport=transport
    )

    return app


def create_grpc_client():
    """
    Create A2A client using gRPC transport.
    """

    from a2a import A2ACardResolver, GrpcClient

    # Create gRPC client
    client = GrpcClient(
        url="grpc://remote-agent.example.com:50051",
        secure=True,
        cert_file=os.getenv("CLIENT_CERT_FILE"),
        # Optional: Server hostname for SNI
        server_hostname="remote-agent.example.com"
    )

    # Discover agent
    resolver = A2ACardResolver(client=client)
    agent_card = await resolver.resolve("grpc://remote-agent.example.com:50051")

    return client, agent_card


if __name__ == "__main__":
    import uvicorn

    # Create example agent
    my_agent = Agent(
        name="grpc-agent",
        instructions="You are a helpful assistant.",
        model="gemini-2.0-flash-exp"
    )

    # Create agent card
    agent_card = AgentCard(
        id="grpc-agent",
        name="gRPC Agent",
        description="Agent with gRPC transport",
        version="1.0.0",
        url=os.getenv("AGENT_URL", "grpc://localhost:50051"),
        capabilities={
            "skills": [],
            "modalities": ["text"],
            "streaming": True
        },
        protocol={
            "version": "0.3",
            "transport": "grpc"
        }
    )

    # Create server
    secure = os.getenv("ENABLE_TLS", "true").lower() == "true"
    app = create_grpc_server(my_agent, agent_card, secure=secure)

    print(f"Starting gRPC server on port 50051 (TLS: {secure})")
    print(f"Agent Card: {agent_card.url}/.well-known/agent.json")

    # Run gRPC server
    # Note: For production, use proper gRPC server deployment
    uvicorn.run(app, host="0.0.0.0", port=8000)
