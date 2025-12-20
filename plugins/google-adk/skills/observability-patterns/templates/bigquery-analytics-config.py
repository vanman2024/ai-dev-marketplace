"""
BigQuery Agent Analytics Configuration for Google ADK

This template shows how to configure the BigQuery Agent Analytics plugin
for comprehensive event logging and analysis.

Security: No hardcoded credentials - uses Application Default Credentials
Version: Requires ADK 1.21.0+ for full multimodal features
"""

import os
from google.adk.app import App
from google.adk.core import Agent
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin,
    BigQueryLoggerConfig
)

# Configuration with all options
def create_full_config():
    """Create BigQuery config with all available options."""

    config = BigQueryLoggerConfig(
        # Enable/disable logging
        enabled=True,

        # GCS bucket for large content (images, audio, etc.)
        # Offloads content larger than max_content_length
        gcs_bucket_name="your-agent-content-bucket",

        # Max inline content size (default: 500KB)
        # Content exceeding this goes to GCS if bucket configured
        max_content_length=500 * 1024,

        # Events per write (default: 1 for low latency)
        # Increase for higher throughput, lower for real-time
        batch_size=1,

        # Filter events by type (optional)
        # Whitelist specific event types
        event_allowlist=[
            "LLM_REQUEST",
            "LLM_RESPONSE",
            "TOOL_STARTING",
            "TOOL_COMPLETED",
            "AGENT_STARTING"
        ],

        # Blacklist specific event types (optional)
        # Use either allowlist OR denylist, not both
        # event_denylist=["DEBUG_EVENT"],

        # Custom content formatter (optional)
        # Use to sanitize sensitive data
        content_formatter=sanitize_content
    )

    return config

# Custom content formatter example
def sanitize_content(content: dict) -> dict:
    """
    Sanitize content before logging to BigQuery.

    Use this to:
    - Remove PII (personally identifiable information)
    - Redact API keys or secrets
    - Truncate large fields
    - Normalize data formats
    """
    # Create a copy to avoid modifying original
    sanitized = content.copy()

    # Example: Redact email addresses
    if "user_email" in sanitized:
        sanitized["user_email"] = "redacted@example.com"

    # Example: Remove API keys
    if "api_key" in sanitized:
        del sanitized["api_key"]

    # Example: Truncate long prompts
    if "prompt" in sanitized and len(sanitized["prompt"]) > 10000:
        sanitized["prompt"] = sanitized["prompt"][:10000] + "..."

    return sanitized

# Minimal configuration
def create_minimal_config():
    """Create minimal BigQuery config for getting started."""

    config = BigQueryLoggerConfig(
        enabled=True,
        batch_size=1  # Low latency for development
    )

    return config

# Production configuration
def create_production_config():
    """Create production-optimized BigQuery config."""

    config = BigQueryLoggerConfig(
        enabled=True,
        gcs_bucket_name=os.environ.get("AGENT_CONTENT_BUCKET"),
        max_content_length=500 * 1024,
        batch_size=10,  # Higher throughput

        # Filter to reduce costs
        event_allowlist=[
            "LLM_RESPONSE",
            "TOOL_COMPLETED",
            "AGENT_STARTING",
            "USER_MESSAGE_RECEIVED"
        ],

        # Sanitize sensitive data
        content_formatter=sanitize_content
    )

    return config

# Setup BigQuery plugin
def setup_bigquery_analytics(config: BigQueryLoggerConfig = None):
    """
    Setup BigQuery Agent Analytics plugin.

    Args:
        config: Optional BigQueryLoggerConfig, defaults to minimal config

    Returns:
        BigQueryAgentAnalyticsPlugin instance
    """
    # Get configuration from environment
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "your-project-id")
    dataset_id = os.environ.get("BIGQUERY_DATASET", "agent_analytics")

    # Use provided config or create minimal config
    if config is None:
        config = create_minimal_config()

    # Create plugin
    plugin = BigQueryAgentAnalyticsPlugin(
        project_id=project_id,
        dataset_id=dataset_id,
        config=config
    )

    return plugin

# Example usage
def create_app_with_analytics():
    """Create ADK app with BigQuery analytics enabled."""

    # Create agent
    agent = Agent(
        name="analytics_agent",
        model="gemini-2.0-flash-exp",
        instruction="You are a helpful assistant with analytics enabled."
    )

    # Setup BigQuery plugin with production config
    analytics_plugin = setup_bigquery_analytics(
        config=create_production_config()
    )

    # Create app with plugin
    app = App(
        root_agent=agent,
        plugins=[analytics_plugin]
    )

    return app

# Event types captured
EVENT_TYPES = {
    # LLM interactions
    "LLM_REQUEST": "LLM API request sent",
    "LLM_RESPONSE": "LLM API response received",
    "LLM_ERROR": "LLM API error occurred",

    # Tool usage
    "TOOL_STARTING": "Tool execution starting",
    "TOOL_COMPLETED": "Tool execution completed",
    "TOOL_ERROR": "Tool execution failed",

    # Agent lifecycle
    "INVOCATION_STARTING": "Agent invocation starting",
    "AGENT_STARTING": "Agent execution starting",
    "USER_MESSAGE_RECEIVED": "User message received",

    # Custom events (from agent.yield_event())
    "CUSTOM_EVENT": "Custom event from agent"
}

if __name__ == "__main__":
    # Create app with analytics
    app = create_app_with_analytics()

    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "your-project-id")
    dataset_id = os.environ.get("BIGQUERY_DATASET", "agent_analytics")

    print(f"BigQuery Analytics configured:")
    print(f"  Project: {project_id}")
    print(f"  Dataset: {dataset_id}")
    print(f"  Table: agent_events_v2")
    print(f"\nQuery events:")
    print(f"  SELECT * FROM `{project_id}.{dataset_id}.agent_events_v2` LIMIT 10")
