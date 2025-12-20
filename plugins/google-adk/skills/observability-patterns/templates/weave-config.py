"""
Weave (Weights & Biases) Configuration for Google ADK Agents

This template shows how to integrate Weave for observability with
W&B's experiment tracking platform.

Security: Uses WANDB_API_KEY environment variable
CRITICAL: Tracer provider MUST be set BEFORE importing ADK components
"""

import os
import base64
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

# Basic Weave setup
def setup_weave_basic(entity: str, project: str):
    """
    Minimal Weave setup for ADK agents.

    Args:
        entity: W&B entity name (visible in Teams sidebar)
        project: W&B project name

    Requires:
        WANDB_API_KEY environment variable
    """
    # Get API key from environment
    wandb_api_key = os.environ.get("WANDB_API_KEY", "your_wandb_key_here")

    # Encode credentials for Basic auth
    auth_string = f"api:{wandb_api_key}"
    encoded_auth = base64.b64encode(auth_string.encode()).decode()

    # Create OTLP exporter for Weave
    exporter = OTLPSpanExporter(
        endpoint="https://trace.wandb.ai/otel/v1/traces",
        headers={
            "Authorization": f"Basic {encoded_auth}",
            "project_id": f"{entity}/{project}"
        }
    )

    # Configure tracer provider (CRITICAL: Do this BEFORE ADK imports)
    provider = TracerProvider()
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    trace.set_tracer_provider(provider)

    # NOW import ADK components
    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="weave_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant with Weave tracking."
    )

    app = App(root_agent=agent)
    return app

# Advanced Weave setup with batch processing
def setup_weave_advanced(entity: str, project: str):
    """
    Weave setup with batched span processing for higher throughput.

    Args:
        entity: W&B entity name
        project: W&B project name
    """
    from opentelemetry.sdk.trace.export import BatchSpanProcessor

    # Get API key
    wandb_api_key = os.environ.get("WANDB_API_KEY", "your_wandb_key_here")

    # Encode credentials
    auth_string = f"api:{wandb_api_key}"
    encoded_auth = base64.b64encode(auth_string.encode()).decode()

    # Create OTLP exporter
    exporter = OTLPSpanExporter(
        endpoint="https://trace.wandb.ai/otel/v1/traces",
        headers={
            "Authorization": f"Basic {encoded_auth}",
            "project_id": f"{entity}/{project}"
        }
    )

    # Use batch processing for better performance
    provider = TracerProvider()
    provider.add_span_processor(
        BatchSpanProcessor(
            exporter,
            max_queue_size=2048,
            max_export_batch_size=512,
            export_timeout_millis=30000
        )
    )
    trace.set_tracer_provider(provider)

    # Import ADK
    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="weave_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant with batched Weave tracking."
    )

    app = App(root_agent=agent)
    return app

# Complete example with error handling
def setup_weave_production(entity: str, project: str):
    """
    Production-ready Weave setup with error handling and validation.

    Args:
        entity: W&B entity name
        project: W&B project name
    """
    # Validate environment
    wandb_api_key = os.environ.get("WANDB_API_KEY")
    if not wandb_api_key:
        raise ValueError("WANDB_API_KEY environment variable not set")

    # Validate parameters
    if not entity or not project:
        raise ValueError("Both entity and project must be specified")

    try:
        # Encode credentials
        auth_string = f"api:{wandb_api_key}"
        encoded_auth = base64.b64encode(auth_string.encode()).decode()

        # Create OTLP exporter with timeout
        exporter = OTLPSpanExporter(
            endpoint="https://trace.wandb.ai/otel/v1/traces",
            headers={
                "Authorization": f"Basic {encoded_auth}",
                "project_id": f"{entity}/{project}"
            },
            timeout=10  # 10 second timeout
        )

        # Configure tracer provider
        provider = TracerProvider()
        from opentelemetry.sdk.trace.export import BatchSpanProcessor

        provider.add_span_processor(
            BatchSpanProcessor(exporter)
        )
        trace.set_tracer_provider(provider)

        print(f"✓ Weave tracer configured for {entity}/{project}")

    except Exception as e:
        print(f"Error configuring Weave: {e}")
        raise

    # Import ADK
    from google.adk.app import App
    from google.adk.core import Agent

    agent = Agent(
        name="production_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a production assistant with Weave observability."
    )

    app = App(root_agent=agent)
    return app

# Weave features
WEAVE_FEATURES = {
    "Timeline View": "Visual timeline of agent calls and tool invocations",
    "Reasoning Analysis": "Track agent reasoning and decision processes",
    "Span Hierarchy": "Nested view of agent -> LLM -> tool execution",
    "Dashboard Integration": "Native W&B dashboard with metrics",
    "Experiment Tracking": "Compare different agent configurations",
    "Cost Tracking": "Monitor token usage and costs",
    "ML Integration": "Connects with W&B training runs and artifacts"
}

# What Weave captures
CAPTURED_DATA = {
    "Agent Calls": "Complete agent execution traces",
    "LLM Interactions": "Prompts, responses, token counts",
    "Tool Invocations": "Tool parameters and results",
    "Timing": "Latency per operation",
    "Custom Metadata": "Tags and attributes",
    "Errors": "Error messages and stack traces"
}

# Critical setup notes
SETUP_NOTES = """
CRITICAL SETUP REQUIREMENTS:

1. Tracer Provider Timing:
   - MUST call trace.set_tracer_provider() BEFORE importing ADK
   - If ADK is imported first, traces won't be captured

2. Correct Order:
   ✓ Import OpenTelemetry packages
   ✓ Configure and set tracer provider
   ✓ THEN import google.adk

3. Entity/Project Names:
   - Entity: Visible in W&B Teams sidebar
   - Project: Created automatically if doesn't exist
   - Format: entity/project in project_id header

4. Authentication:
   - Uses Basic auth with Base64 encoding
   - Format: "api:{WANDB_API_KEY}"
   - Get key from: https://wandb.ai/authorize
"""

# Example: Complete integration
if __name__ == "__main__":
    # Check for API key
    if not os.environ.get("WANDB_API_KEY"):
        print("Error: WANDB_API_KEY environment variable not set")
        print("Get your API key from: https://wandb.ai/authorize")
        exit(1)

    # Setup Weave
    entity = "my-team"
    project = "adk-agents"

    print(SETUP_NOTES)
    print(f"\nSetting up Weave for {entity}/{project}...")

    app = setup_weave_production(entity, project)

    print("\nWeave features:")
    for feature, description in WEAVE_FEATURES.items():
        print(f"  - {feature}: {description}")
    print(f"\nView traces at: https://wandb.ai/{entity}/{project}")
