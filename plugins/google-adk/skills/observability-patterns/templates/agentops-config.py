"""
AgentOps Configuration for Google ADK Agents

This template shows how to integrate AgentOps for session replays,
metrics, and monitoring with minimal code.

Security: Uses AGENTOPS_API_KEY environment variable
"""

import os
import agentops

# Basic setup
def setup_agentops_basic():
    """
    Minimal AgentOps setup (just 2 lines).

    Requires AGENTOPS_API_KEY environment variable.
    Get your API key from: https://app.agentops.ai/settings/projects
    """
    # Initialize AgentOps (BEFORE ADK imports)
    agentops.init()

    # Your ADK agent code
    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="agentops_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant."
    )

    app = App(root_agent=agent)
    return app

# Advanced setup with configuration
def setup_agentops_advanced():
    """
    AgentOps setup with additional configuration options.
    """
    # Initialize with options
    agentops.init(
        api_key=os.environ.get("AGENTOPS_API_KEY"),

        # Optional: Set default tags for sessions
        default_tags=["production", "adk-agent"],

        # Optional: Auto-end sessions
        auto_start_session=True
    )

    # Your ADK agent code
    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="agentops_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant with advanced AgentOps tracking."
    )

    app = App(root_agent=agent)
    return app

# Manual session management
def setup_agentops_manual_sessions():
    """
    AgentOps with manual session management for granular control.
    """
    # Initialize without auto-start
    agentops.init(auto_start_session=False)

    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="agentops_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant."
    )

    # Start session manually
    session = agentops.start_session(
        tags=["user-123", "conversation-456"]
    )

    app = App(root_agent=agent)

    # End session when done
    # session.end_session(end_state="Success")

    return app, session

# What AgentOps captures
CAPTURED_DATA = {
    "Agent Spans": {
        "name": "adk.agent.{AgentName}",
        "captures": "Agent execution details"
    },
    "LLM Spans": {
        "name": "LLM call",
        "captures": "Prompts, completions, token counts, latency"
    },
    "Tool Spans": {
        "name": "Tool execution",
        "captures": "Tool parameters, results, execution time"
    },
    "Metadata": {
        "costs": "Token costs per LLM call",
        "latency": "Response time per operation",
        "errors": "Error messages and stack traces"
    }
}

# Integration features
AGENTOPS_FEATURES = {
    "Session Replays": "Step-by-step execution visualization",
    "Hierarchical Traces": "Nested span hierarchy (agent -> LLM -> tools)",
    "Metrics Dashboard": "Token usage, costs, latency, error rates",
    "No Conflicts": "Intelligent patching of ADK's OpenTelemetry tracer",
    "Minimal Code": "Just 2 lines to integrate"
}

# Example: Complete integration
if __name__ == "__main__":
    # Check for API key
    if not os.environ.get("AGENTOPS_API_KEY"):
        print("Error: AGENTOPS_API_KEY environment variable not set")
        print("Get your API key from: https://app.agentops.ai/settings/projects")
        exit(1)

    # Setup AgentOps with ADK
    app = setup_agentops_basic()

    print("AgentOps initialized successfully!")
    print("View sessions at: https://app.agentops.ai/")
    print("")
    print("AgentOps captures:")
    for feature, description in AGENTOPS_FEATURES.items():
        print(f"  - {feature}: {description}")
