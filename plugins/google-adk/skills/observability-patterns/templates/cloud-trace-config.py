"""
Cloud Trace Configuration for Google ADK Agents

This template shows how to configure Cloud Trace integration for ADK agents.
Cloud Trace provides distributed tracing to understand request flows and
identify performance bottlenecks.

Security: No hardcoded credentials - uses Application Default Credentials
"""

import os
from google.adk.app import AdkApp, App
from google.adk.core import Agent

# Option 1: Using AdkApp (Python SDK deployment)
def setup_cloud_trace_sdk():
    """Enable Cloud Trace using Python SDK."""

    # Set project ID from environment
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "your-project-id")

    # Create app with tracing enabled
    app = AdkApp(
        agent=my_agent,
        enable_tracing=True  # Enables Cloud Trace
    )

    return app

# Option 2: Using ADK CLI (recommended for production)
def setup_cloud_trace_cli():
    """
    Enable Cloud Trace using ADK CLI deployment.

    Deploy command:
        adk deploy agent_engine \\
            --project=$GOOGLE_CLOUD_PROJECT \\
            --trace_to_cloud \\
            ./agent

    This automatically configures Cloud Trace for the deployed agent.
    """
    pass

# Option 3: Custom deployment with Cloud Trace exporter
def setup_cloud_trace_custom():
    """Enable Cloud Trace for custom deployment runners."""

    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import SimpleSpanProcessor
    from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter

    # Set up Cloud Trace exporter
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "your-project-id")

    exporter = CloudTraceSpanExporter(
        project_id=project_id
        # Uses Application Default Credentials automatically
    )

    # Configure tracer provider
    provider = TracerProvider()
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    trace.set_tracer_provider(provider)

    # Now create your ADK app
    app = App(root_agent=my_agent)

    return app

# Viewing traces
def view_traces():
    """
    View Cloud Trace data in Google Cloud Console.

    URL: https://console.cloud.google.com/traces/list?project={project_id}

    Trace Explorer shows:
    - Waterfall view of request flows
    - Latency analysis per span
    - Error identification
    - LLM and tool call details

    Span types in ADK:
    - invocation: Top-level agent invocation
    - agent_run: Individual agent execution
    - call_llm: LLM API calls
    - execute_tool: Tool executions
    """
    pass

# Example agent
my_agent = Agent(
    name="example_agent",
    model="gemini-2.0-flash-exp",
    instruction="You are a helpful assistant."
)

if __name__ == "__main__":
    # Use SDK-based setup
    app = setup_cloud_trace_sdk()

    # Or use custom setup
    # app = setup_cloud_trace_custom()

    print(f"Cloud Trace enabled for project: {os.environ.get('GOOGLE_CLOUD_PROJECT')}")
    print(f"View traces at: https://console.cloud.google.com/traces/list?project={os.environ.get('GOOGLE_CLOUD_PROJECT')}")
