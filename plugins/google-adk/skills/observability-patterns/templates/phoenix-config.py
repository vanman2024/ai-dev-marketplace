"""
Phoenix (Arize) Configuration for Google ADK Agents

This template shows how to integrate Phoenix for open-source observability
with self-hosted data control.

Security: Uses PHOENIX_API_KEY and PHOENIX_COLLECTOR_ENDPOINT environment variables
"""

import os
from phoenix.otel import register

# Basic Phoenix setup
def setup_phoenix_basic():
    """
    Minimal Phoenix setup with auto-instrumentation.

    Requires environment variables:
    - PHOENIX_API_KEY: API key from phoenix.arize.com
    - PHOENIX_COLLECTOR_ENDPOINT: Collector endpoint URL
    """
    # Set credentials (from environment)
    os.environ["PHOENIX_API_KEY"] = os.environ.get("PHOENIX_API_KEY", "your_api_key_here")
    os.environ["PHOENIX_COLLECTOR_ENDPOINT"] = os.environ.get(
        "PHOENIX_COLLECTOR_ENDPOINT",
        "https://app.phoenix.arize.com/s/your-space"
    )

    # Register Phoenix tracer with auto-instrumentation
    tracer_provider = register(
        project_name="my-adk-agent",
        auto_instrument=True  # Automatically traces all ADK operations
    )

    # Import ADK AFTER Phoenix registration
    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="phoenix_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant with Phoenix observability."
    )

    app = App(root_agent=agent)
    return app, tracer_provider

# Advanced Phoenix setup
def setup_phoenix_advanced():
    """
    Phoenix setup with additional configuration options.
    """
    # Set credentials
    os.environ["PHOENIX_API_KEY"] = os.environ.get("PHOENIX_API_KEY", "your_api_key_here")
    os.environ["PHOENIX_COLLECTOR_ENDPOINT"] = os.environ.get(
        "PHOENIX_COLLECTOR_ENDPOINT",
        "https://app.phoenix.arize.com/s/your-space"
    )

    # Register with custom options
    tracer_provider = register(
        project_name="adk-production",
        auto_instrument=True,

        # Optional: Add custom resource attributes
        # These appear as metadata in Phoenix UI
        # resource_attributes={
        #     "service.name": "my-adk-agent",
        #     "service.version": "1.0.0",
        #     "deployment.environment": "production"
        # }
    )

    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="phoenix_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant with advanced Phoenix tracking."
    )

    app = App(root_agent=agent)
    return app, tracer_provider

# Phoenix features
PHOENIX_FEATURES = {
    "Self-Hosted Control": "Keep data on your infrastructure or use Phoenix Cloud",
    "OpenInference": "Open standard for LLM observability",
    "Auto-Instrumentation": "Automatic trace collection from ADK",
    "Trace Evaluation": "Built-in and custom evaluators for performance",
    "Performance Debugging": "Detailed execution analysis",
    "Cost Tracking": "Token usage and cost monitoring",
    "Open Source": "Full visibility into observability stack"
}

# What Phoenix captures
CAPTURED_DATA = {
    "Traces": "Full execution traces with timing and hierarchy",
    "LLM Calls": "Prompts, completions, model parameters",
    "Tool Usage": "Tool parameters and results",
    "Agent Interactions": "Agent-to-agent communication",
    "Metadata": "Custom attributes and tags",
    "Performance": "Latency, token usage, costs"
}

# Phoenix dashboard features
DASHBOARD_FEATURES = {
    "Trace Explorer": "Search and filter traces by metadata",
    "Latency Analysis": "Identify slow operations",
    "Error Tracking": "Monitor and debug errors",
    "Cost Dashboard": "Track token usage and costs",
    "Custom Evaluators": "Run custom evaluation logic on traces",
    "Experiments": "Compare different agent configurations"
}

# Example: Complete integration
if __name__ == "__main__":
    # Check for required environment variables
    if not os.environ.get("PHOENIX_API_KEY"):
        print("Error: PHOENIX_API_KEY environment variable not set")
        print("Get your API key from: https://phoenix.arize.com/")
        exit(1)

    if not os.environ.get("PHOENIX_COLLECTOR_ENDPOINT"):
        print("Error: PHOENIX_COLLECTOR_ENDPOINT environment variable not set")
        print("Format: https://app.phoenix.arize.com/s/your-space")
        exit(1)

    # Setup Phoenix
    app, tracer = setup_phoenix_basic()

    print("Phoenix initialized successfully!")
    print(f"Collector endpoint: {os.environ['PHOENIX_COLLECTOR_ENDPOINT']}")
    print("")
    print("Phoenix features:")
    for feature, description in PHOENIX_FEATURES.items():
        print(f"  - {feature}: {description}")
    print("")
    print(f"View traces at: {os.environ['PHOENIX_COLLECTOR_ENDPOINT']}")
