"""
A2A STDIO Server
Provides STDIO transport for local Agent-to-Agent communication following MCP standards.
"""

import os
import sys
import json
from typing import Any

# SECURITY: NEVER hardcode API keys - always use environment variables
API_KEY = os.getenv("ANTHROPIC_API_KEY", "your_anthropic_key_here")


class StdioServer:
    """STDIO-based A2A server using JSON-RPC protocol"""

    def __init__(self):
        self.running = True

    def handle_message(self, message: dict[str, Any]) -> dict[str, Any]:
        """
        Handle incoming A2A message

        Expected format (JSON-RPC):
        {
            "jsonrpc": "2.0",
            "method": "message",
            "params": {
                "content": "Hello",
                "agent_id": "agent-1"
            },
            "id": 1
        }
        """
        method = message.get("method")
        params = message.get("params", {})
        msg_id = message.get("id")

        if method == "message":
            # Process the message
            content = params.get("content", "")
            agent_id = params.get("agent_id", "unknown")

            # Your agent logic here
            response_content = f"Received from {agent_id}: {content}"

            return {
                "jsonrpc": "2.0",
                "result": {
                    "content": response_content,
                    "status": "success"
                },
                "id": msg_id
            }

        elif method == "ping":
            return {
                "jsonrpc": "2.0",
                "result": {"pong": True},
                "id": msg_id
            }

        else:
            return {
                "jsonrpc": "2.0",
                "error": {
                    "code": -32601,
                    "message": f"Method not found: {method}"
                },
                "id": msg_id
            }

    def run(self):
        """Main STDIO loop - reads from stdin, writes to stdout"""
        sys.stderr.write("A2A STDIO Server started\n")
        sys.stderr.flush()

        try:
            while self.running:
                # Read line from stdin
                line = sys.stdin.readline()
                if not line:
                    break

                line = line.strip()
                if not line:
                    continue

                try:
                    # Parse JSON-RPC request
                    request = json.loads(line)

                    # Handle request
                    response = self.handle_message(request)

                    # Write JSON-RPC response to stdout
                    sys.stdout.write(json.dumps(response) + "\n")
                    sys.stdout.flush()

                except json.JSONDecodeError as e:
                    sys.stderr.write(f"Invalid JSON: {e}\n")
                    sys.stderr.flush()

                except Exception as e:
                    sys.stderr.write(f"Error: {e}\n")
                    sys.stderr.flush()

        except KeyboardInterrupt:
            sys.stderr.write("Server stopped\n")
            sys.stderr.flush()


if __name__ == "__main__":
    server = StdioServer()
    server.run()
