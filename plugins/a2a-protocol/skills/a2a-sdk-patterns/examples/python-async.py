#!/usr/bin/env python3
"""
A2A Protocol Python SDK - Async Usage Example
Demonstrates async/await patterns with asyncio
"""

import os
import asyncio
from a2a_protocol import AsyncA2AClient, A2AError

async def send_multiple_messages(client, recipient_ids):
    """Send messages to multiple agents concurrently"""
    tasks = []
    for recipient_id in recipient_ids:
        task = client.send_message(
            recipient_id=recipient_id,
            message={
                "type": "ping",
                "timestamp": asyncio.get_event_loop().time()
            }
        )
        tasks.append(task)

    # Wait for all messages to be sent
    results = await asyncio.gather(*tasks, return_exceptions=True)

    for i, result in enumerate(results):
        if isinstance(result, Exception):
            print(f"Failed to send to {recipient_ids[i]}: {result}")
        else:
            print(f"Sent to {recipient_ids[i]}: {result}")

async def main():
    # Load API key from environment
    api_key = os.getenv("A2A_API_KEY")
    if not api_key:
        raise ValueError("A2A_API_KEY environment variable is required")

    # Initialize async client
    async with AsyncA2AClient(
        api_key=api_key,
        base_url=os.getenv("A2A_BASE_URL", "https://api.a2a.example.com")
    ) as client:
        try:
            # Example 1: Send single message
            response = await client.send_message(
                recipient_id="agent-123",
                message={"type": "request", "action": "status"}
            )
            print(f"Single message response: {response}")

            # Example 2: Send multiple messages concurrently
            recipient_ids = ["agent-123", "agent-456", "agent-789"]
            await send_multiple_messages(client, recipient_ids)

            # Example 3: Stream responses
            async for event in client.subscribe_to_events("agent-123"):
                print(f"Received event: {event}")
                if event.type == "complete":
                    break

        except A2AError as e:
            print(f"Error: {e}")
            return 1

    return 0

if __name__ == "__main__":
    exit(asyncio.run(main()))
