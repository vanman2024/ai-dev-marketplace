#!/usr/bin/env python3
"""
A2A Protocol Python SDK - Basic Usage Example
Demonstrates basic client setup and API operations
"""

import os
from a2a_protocol import A2AClient, A2AError

def main():
    # Load API key from environment
    api_key = os.getenv("A2A_API_KEY")
    if not api_key:
        raise ValueError("A2A_API_KEY environment variable is required")

    # Initialize client
    client = A2AClient(
        api_key=api_key,
        base_url=os.getenv("A2A_BASE_URL", "https://api.a2a.example.com"),
        timeout=30,
        retry_attempts=3
    )

    try:
        # Example: Send a message to another agent
        response = client.send_message(
            recipient_id="agent-123",
            message={
                "type": "request",
                "action": "process_data",
                "data": {
                    "input": "sample data"
                }
            }
        )

        print(f"Message sent successfully!")
        print(f"Response: {response}")

        # Example: Get agent status
        status = client.get_agent_status("agent-123")
        print(f"\nAgent status: {status}")

        # Example: List available agents
        agents = client.list_agents(limit=10)
        print(f"\nAvailable agents:")
        for agent in agents:
            print(f"  - {agent.id}: {agent.name} ({agent.status})")

    except A2AError as e:
        print(f"Error: {e}")
        return 1

    return 0

if __name__ == "__main__":
    exit(main())
