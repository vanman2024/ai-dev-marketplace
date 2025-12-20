# Multi-Tool Observability Integration for Google ADK

This example demonstrates how to effectively combine multiple observability tools for comprehensive monitoring, choosing the right tool combinations for your needs.

## Tool Selection Matrix

| Tool | Hosting | Cost | Setup | Data Control | Best For |
|------|---------|------|-------|--------------|----------|
| Cloud Trace | Google Cloud | Free tier + usage | Low | Google Cloud | Infrastructure tracing |
| BigQuery | Google Cloud | Storage + queries | Medium | Google Cloud | Deep analytics |
| AgentOps | SaaS | Free tier + paid | Very Low | Third-party | Quick debugging |
| Phoenix | SaaS/Self-hosted | Free tier + paid | Low | Self-host option | Open-source, data sovereignty |
| Weave | SaaS | Free tier + paid | Medium | Third-party | ML experiments |

## Integration Patterns

### Pattern 1: Google Cloud Native (Recommended for GCP)

**Tools**: Cloud Trace + BigQuery

**Best for**:
- GCP-centric deployments
- Teams already using Google Cloud
- Cost-conscious projects (leverages existing GCP credits)
- Long-term data retention needs

**Setup**:

```python
"""
Google Cloud native observability stack.
Uses Cloud Trace for distributed tracing and BigQuery for analytics.
"""

import os
from google.adk.app import App
from google.adk.core import Agent
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin,
    BigQueryLoggerConfig
)

# Configure BigQuery Analytics
bq_config = BigQueryLoggerConfig(
    enabled=True,
    gcs_bucket_name="your-agent-content",
    max_content_length=500 * 1024,
    batch_size=10
)

bigquery_plugin = BigQueryAgentAnalyticsPlugin(
    project_id=os.environ["GOOGLE_CLOUD_PROJECT"],
    dataset_id="agent_analytics",
    config=bq_config
)

# Create agent
agent = Agent(
    name="gcp_native_agent",
    model="gemini-2.0-flash-exp",
    instruction="You are a helpful assistant with GCP observability."
)

# Create app with both tools
app = App(
    root_agent=agent,
    plugins=[bigquery_plugin]
    # Cloud Trace enabled via deployment: --trace_to_cloud
)
```

**Deployment**:

```bash
adk deploy agent_engine \
  --project=$GOOGLE_CLOUD_PROJECT \
  --trace_to_cloud \
  ./agent
```

**Advantages**:
- Unified billing and IAM
- Seamless integration
- No third-party dependencies
- Powerful SQL analytics in BigQuery

**Monitoring Workflow**:
1. Cloud Trace: Real-time request tracing, latency analysis
2. BigQuery: Historical analytics, cost analysis, user behavior

---

### Pattern 2: Comprehensive Monitoring (Recommended for Production)

**Tools**: Cloud Trace + BigQuery + AgentOps

**Best for**:
- Production deployments needing detailed debugging
- Teams wanting session replays
- Projects with dedicated observability budget
- Complex multi-agent systems

**Setup**:

```python
"""
Comprehensive observability with Cloud Trace, BigQuery, and AgentOps.
Provides infrastructure tracing, detailed analytics, and session replays.
"""

import os
import agentops  # MUST be first

# 1. Initialize AgentOps BEFORE ADK imports
agentops.init()

# 2. Import ADK
from google.adk.app import App
from google.adk.core import Agent
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin,
    BigQueryLoggerConfig
)

# 3. Configure BigQuery
bq_config = BigQueryLoggerConfig(
    enabled=True,
    gcs_bucket_name="your-agent-content",
    max_content_length=500 * 1024,
    batch_size=10,
    event_allowlist=[
        "LLM_RESPONSE",
        "TOOL_COMPLETED",
        "AGENT_STARTING"
    ]
)

bigquery_plugin = BigQueryAgentAnalyticsPlugin(
    project_id=os.environ["GOOGLE_CLOUD_PROJECT"],
    dataset_id="agent_analytics",
    config=bq_config
)

# 4. Create agent
agent = Agent(
    name="production_agent",
    model="gemini-2.0-flash-exp",
    instruction="Production assistant with comprehensive observability."
)

# 5. Create app
app = App(
    root_agent=agent,
    plugins=[bigquery_plugin]
    # Cloud Trace enabled via --trace_to_cloud
)
```

**Advantages**:
- Cloud Trace: Infrastructure-level tracing
- BigQuery: Deep analytics and custom queries
- AgentOps: Easy session debugging with replays

**Monitoring Workflow**:
1. AgentOps: Debug individual sessions, view replays
2. Cloud Trace: Analyze distributed tracing, find bottlenecks
3. BigQuery: Historical trends, cost analysis, user patterns

---

### Pattern 3: Open Source Stack (Recommended for Data Sovereignty)

**Tools**: Phoenix + BigQuery

**Best for**:
- Self-hosted requirements
- Data sovereignty needs
- Open-source preference
- Research and experimentation

**Setup**:

```python
"""
Open-source observability with Phoenix and BigQuery.
Phoenix provides self-hosted tracing, BigQuery for long-term storage.
"""

import os
from phoenix.otel import register

# 1. Setup Phoenix credentials
os.environ["PHOENIX_API_KEY"] = os.environ.get("PHOENIX_API_KEY", "your_key_here")
os.environ["PHOENIX_COLLECTOR_ENDPOINT"] = os.environ.get(
    "PHOENIX_COLLECTOR_ENDPOINT",
    "https://app.phoenix.arize.com/s/your-space"
)

# 2. Register Phoenix tracer
tracer_provider = register(
    project_name="adk-agent",
    auto_instrument=True
)

# 3. Import ADK
from google.adk.app import App
from google.adk.core import Agent
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin,
    BigQueryLoggerConfig
)

# 4. Configure BigQuery
bq_config = BigQueryLoggerConfig(
    enabled=True,
    gcs_bucket_name="your-agent-content"
)

bigquery_plugin = BigQueryAgentAnalyticsPlugin(
    project_id=os.environ["GOOGLE_CLOUD_PROJECT"],
    dataset_id="agent_analytics",
    config=bq_config
)

# 5. Create agent
agent = Agent(
    name="opensource_agent",
    model="gemini-2.0-flash-exp",
    instruction="Assistant with open-source observability."
)

# 6. Create app
app = App(
    root_agent=agent,
    plugins=[bigquery_plugin]
)
```

**Advantages**:
- Phoenix: Self-hosted option, full control
- OpenInference: Open standard for portability
- BigQuery: Powerful analytics
- No vendor lock-in

**Monitoring Workflow**:
1. Phoenix: Real-time tracing, evaluation, debugging
2. BigQuery: Historical analytics, custom queries

---

### Pattern 4: ML Experimentation (Recommended for Research)

**Tools**: Weave + BigQuery

**Best for**:
- ML research teams
- Experiment tracking needs
- W&B users
- Model comparison workflows

**Setup**:

```python
"""
ML-focused observability with Weave and BigQuery.
Weave for experiment tracking, BigQuery for analytics.
"""

import os
import base64

# 1. Setup OTEL for Weave (BEFORE ADK imports)
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

wandb_api_key = os.environ["WANDB_API_KEY"]
entity = "my-team"
project = "adk-experiments"

auth_string = f"api:{wandb_api_key}"
encoded_auth = base64.b64encode(auth_string.encode()).decode()

exporter = OTLPSpanExporter(
    endpoint="https://trace.wandb.ai/otel/v1/traces",
    headers={
        "Authorization": f"Basic {encoded_auth}",
        "project_id": f"{entity}/{project}"
    }
)

provider = TracerProvider()
provider.add_span_processor(SimpleSpanProcessor(exporter))
trace.set_tracer_provider(provider)

# 2. Import ADK
from google.adk.app import App
from google.adk.core import Agent
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin,
    BigQueryLoggerConfig
)

# 3. Configure BigQuery
bq_config = BigQueryLoggerConfig(enabled=True)

bigquery_plugin = BigQueryAgentAnalyticsPlugin(
    project_id=os.environ["GOOGLE_CLOUD_PROJECT"],
    dataset_id="agent_analytics",
    config=bq_config
)

# 4. Create agent
agent = Agent(
    name="experiment_agent",
    model="gemini-2.0-flash-exp",
    instruction="Assistant for ML experimentation."
)

# 5. Create app
app = App(
    root_agent=agent,
    plugins=[bigquery_plugin]
)
```

**Advantages**:
- Weave: Experiment tracking, model comparison
- W&B integration: Connect with training runs
- BigQuery: Long-term analytics

**Monitoring Workflow**:
1. Weave: Compare agent configurations, A/B testing
2. BigQuery: Analyze performance metrics, costs

---

## Data Correlation Across Tools

### Using trace_id for Unified Debugging

All tools support OpenTelemetry trace_id. Use it to correlate data:

**1. Find error in AgentOps**:
- View session replay
- Note the trace_id

**2. Get detailed trace in Cloud Trace**:
```bash
# Cloud Trace web UI
https://console.cloud.google.com/traces/list?project=PROJECT_ID&tid=TRACE_ID
```

**3. Query BigQuery for full context**:
```sql
SELECT *
FROM agent_events_v2
WHERE trace_id = 'YOUR_TRACE_ID'
ORDER BY timestamp ASC
```

**4. Analyze in Phoenix or Weave**:
- Search for trace_id in Phoenix UI
- Filter Weave dashboard by trace_id

---

## Cost vs. Insight Tradeoffs

### Low Budget ($0-$50/month)

**Recommendation**: Cloud Trace only or Cloud Trace + Limited BigQuery

```python
# Minimal cost setup
bq_config = BigQueryLoggerConfig(
    enabled=True,
    batch_size=100,  # Reduce write frequency
    event_allowlist=["LLM_RESPONSE", "AGENT_STARTING"]  # Filter events
)
```

**Cost optimization**:
- Use free Cloud Trace tier
- Filter BigQuery events aggressively
- Set 30-day retention in BigQuery
- No third-party tools

---

### Medium Budget ($50-$500/month)

**Recommendation**: Cloud Trace + BigQuery + AgentOps Free Tier

```python
bq_config = BigQueryLoggerConfig(
    enabled=True,
    batch_size=10,
    event_allowlist=[
        "LLM_RESPONSE",
        "TOOL_COMPLETED",
        "AGENT_STARTING",
        "USER_MESSAGE_RECEIVED"
    ]
)
```

**Cost optimization**:
- Moderate event filtering
- 90-day retention
- AgentOps free tier for debugging
- GCS lifecycle for multimodal content

---

### High Budget ($500+/month)

**Recommendation**: All tools (Cloud Trace + BigQuery + AgentOps Pro + Phoenix/Weave)

```python
bq_config = BigQueryLoggerConfig(
    enabled=True,
    batch_size=1,  # Real-time
    # No event filtering (capture everything)
)
```

**Full observability**:
- No event filtering
- Real-time streaming
- Multiple third-party tools
- Long-term retention (1+ year)

---

## Tool Combinations Quick Reference

| Use Case | Tools | Why |
|----------|-------|-----|
| **Startup MVP** | Cloud Trace only | Free, simple, good enough |
| **Growing SaaS** | Cloud Trace + BigQuery | Analytics + infrastructure monitoring |
| **Enterprise** | Cloud Trace + BigQuery + AgentOps | Comprehensive debugging + analytics |
| **Regulated Industry** | Phoenix (self-hosted) + BigQuery | Data sovereignty + analytics |
| **ML Research** | Weave + BigQuery | Experiment tracking + analytics |
| **Open Source Project** | Phoenix only | Community-friendly, self-hosted |

---

## Environment Variable Management

Create `.env.example` for all tools:

```bash
# Google Cloud (always needed)
GOOGLE_CLOUD_PROJECT=your_project_id_here
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service_account_key.json

# AgentOps (optional)
AGENTOPS_API_KEY=your_agentops_key_here

# Phoenix (optional)
PHOENIX_API_KEY=your_phoenix_key_here
PHOENIX_COLLECTOR_ENDPOINT=https://app.phoenix.arize.com/s/your_space

# Weave (optional)
WANDB_API_KEY=your_wandb_key_here
```

---

## Monitoring Dashboards

### Unified Dashboard Approach

**Option 1: Looker Studio** (Google Cloud native)
- Connect BigQuery dataset
- Create charts for key metrics
- Embed Cloud Trace links

**Option 2: Grafana** (Multi-tool)
- BigQuery datasource for queries
- Phoenix datasource for traces
- W&B datasource for experiments
- Cloud Trace integration

**Option 3: Tool-Native** (Simplest)
- Cloud Trace: Google Cloud Console
- BigQuery: BigQuery Studio or Looker
- AgentOps: AgentOps dashboard
- Phoenix: Phoenix UI
- Weave: W&B dashboard

---

## Troubleshooting Multi-Tool Setups

### Data Not Appearing in One Tool

**Check initialization order**:
1. AgentOps: Initialize FIRST (before ADK)
2. Phoenix/Weave: Register tracer BEFORE ADK
3. BigQuery: Plugin added to App
4. Cloud Trace: Deployment flag or AdkApp config

### Conflicting Tracers

**AgentOps** handles conflicts automatically by patching ADK's tracer.

**Phoenix + Weave**: Don't use together (choose one OTEL tracer).

**Cloud Trace + Third-party**: Compatible (different trace backends).

---

## Additional Resources

- Cloud Trace: https://cloud.google.com/trace/docs
- BigQuery: https://cloud.google.com/bigquery/docs
- AgentOps: https://docs.agentops.ai/
- Phoenix: https://docs.arize.com/phoenix/
- Weave: https://docs.wandb.ai/weave/
