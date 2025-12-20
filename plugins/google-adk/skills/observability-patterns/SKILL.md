---
name: observability-patterns
description: Comprehensive observability setup patterns for Google ADK agents including logging configuration, Cloud Trace integration, BigQuery Agent Analytics, and third-party observability tools (AgentOps, Phoenix, Weave). Use when implementing monitoring, debugging agent behavior, analyzing agent performance, setting up tracing, or when user mentions observability, logging, tracing, BigQuery analytics, AgentOps, Phoenix, Arize, or Weave.
allowed-tools: Bash, Read, Write, Edit
---

# Observability Patterns Skill

This skill provides comprehensive templates and configurations for implementing observability in Google ADK agents. Includes logging, tracing, BigQuery analytics, Cloud Trace integration, and third-party observability platforms.

## Overview

Google ADK supports multiple observability approaches for monitoring, debugging, and analyzing agent behavior:

1. **Cloud Trace** - Google Cloud native tracing with OpenTelemetry
2. **BigQuery Agent Analytics** - Comprehensive event logging and analysis
3. **AgentOps** - Session replays and unified tracing analytics
4. **Phoenix (Arize)** - Open-source observability with self-hosted control
5. **Weave (W&B)** - Weights & Biases platform for tracking and visualization

This skill covers production-ready observability implementations with security and scalability.

## Available Scripts

### 1. Setup Cloud Trace

**Script**: `scripts/setup-cloud-trace.sh <project-id>`

**Purpose**: Configures Cloud Trace integration for ADK agents

**Parameters**:
- `project-id` - Google Cloud project ID (required)

**Usage**:
```bash
# Setup Cloud Trace for local development
./scripts/setup-cloud-trace.sh my-project-id

# Setup with ADK CLI deployment
adk deploy agent_engine --project=my-project-id --trace_to_cloud ./agent
```

**Environment Variables**:
- `GOOGLE_CLOUD_PROJECT` - Project ID for Cloud Trace
- `GOOGLE_APPLICATION_CREDENTIALS` - Path to service account key

**Output**: Cloud Trace enabled, traces visible in console.cloud.google.com

### 2. Setup BigQuery Agent Analytics

**Script**: `scripts/setup-bigquery-analytics.sh <project-id> <dataset-id> [bucket-name]`

**Purpose**: Configures BigQuery Agent Analytics plugin for comprehensive event logging

**Parameters**:
- `project-id` - Google Cloud project ID (required)
- `dataset-id` - BigQuery dataset name (required)
- `bucket-name` - GCS bucket for multimodal content (optional)

**Usage**:
```bash
# Setup basic BigQuery analytics
./scripts/setup-bigquery-analytics.sh my-project agent-analytics

# Setup with GCS for multimodal content
./scripts/setup-bigquery-analytics.sh my-project agent-analytics my-content-bucket

# Create dataset and table
bq mk --dataset my-project:agent-analytics
bq mk --table agent-analytics.agent_events_v2 templates/bigquery-schema.json
```

**IAM Requirements**:
- `roles/bigquery.jobUser` - Required for BigQuery operations
- `roles/bigquery.dataEditor` - Required for writing data
- `roles/storage.objectCreator` - Required if using GCS offloading

**Output**: BigQuery table created, events streaming to dataset

### 3. Setup AgentOps

**Script**: `scripts/setup-agentops.sh`

**Purpose**: Configures AgentOps integration for session replays and metrics

**Usage**:
```bash
# Install AgentOps
pip install -U agentops

# Setup with API key
AGENTOPS_API_KEY=your_api_key_here ./scripts/setup-agentops.sh

# Verify setup
python -c "import agentops; agentops.init(); print('AgentOps ready')"
```

**Environment Variables**:
- `AGENTOPS_API_KEY` - AgentOps API key from app.agentops.ai/settings/projects

**Output**: AgentOps initialized, sessions visible in dashboard

### 4. Setup Phoenix

**Script**: `scripts/setup-phoenix.sh`

**Purpose**: Configures Phoenix (Arize) integration for open-source observability

**Usage**:
```bash
# Install Phoenix packages
pip install openinference-instrumentation-google-adk arize-phoenix-otel

# Setup Phoenix with API key
PHOENIX_API_KEY=your_key_here \
PHOENIX_COLLECTOR_ENDPOINT=https://app.phoenix.arize.com/s/your-space \
./scripts/setup-phoenix.sh

# Verify Phoenix connection
python scripts/verify-phoenix.py
```

**Environment Variables**:
- `PHOENIX_API_KEY` - Phoenix API key from phoenix.arize.com
- `PHOENIX_COLLECTOR_ENDPOINT` - Phoenix collector endpoint URL

**Output**: Phoenix tracer initialized, traces visible in Phoenix dashboard

### 5. Setup Weave

**Script**: `scripts/setup-weave.sh <entity> <project>`

**Purpose**: Configures Weave (W&B) integration for observability

**Parameters**:
- `entity` - W&B entity name (visible in Teams sidebar)
- `project` - W&B project name

**Usage**:
```bash
# Install Weave dependencies
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-http

# Setup Weave with API key
WANDB_API_KEY=your_wandb_key_here ./scripts/setup-weave.sh my-team my-project

# Verify Weave connection
python scripts/verify-weave.py
```

**Environment Variables**:
- `WANDB_API_KEY` - W&B API key from wandb.ai/authorize

**Output**: Weave tracer initialized, traces visible in Weave dashboard

### 6. Validate Observability Setup

**Script**: `scripts/validate-observability.sh`

**Purpose**: Validates observability configuration and connectivity

**Checks**:
- Cloud Trace connectivity
- BigQuery dataset and table existence
- AgentOps initialization
- Phoenix endpoint reachability
- Weave endpoint reachability
- IAM permissions
- Environment variables set

**Usage**:
```bash
# Validate all observability configurations
./scripts/validate-observability.sh

# Validate specific tool
./scripts/validate-observability.sh --tool=bigquery
./scripts/validate-observability.sh --tool=cloud-trace
./scripts/validate-observability.sh --tool=agentops
```

**Exit Codes**:
- `0` - All checks passed
- `1` - Configuration missing
- `2` - Connectivity failed
- `3` - Permission issues

## Available Templates

### 1. Cloud Trace Configuration

**Template**: `templates/cloud-trace-config.py`

**Purpose**: Cloud Trace integration for ADK agents

**Features**:
- OpenTelemetry configuration
- Automatic span creation for agent runs
- LLM and tool call tracing
- Error and latency tracking

**Usage**:
```python
# Enable Cloud Trace via ADK CLI
adk deploy agent_engine --project=$GOOGLE_CLOUD_PROJECT --trace_to_cloud ./agent

# Or via Python SDK
from google.adk.app import AdkApp

app = AdkApp(
    agent=my_agent,
    enable_tracing=True
)
```

**Span Labels**:
- `invocation` - Top-level agent invocation
- `agent_run` - Individual agent execution
- `call_llm` - LLM API calls
- `execute_tool` - Tool executions

### 2. BigQuery Analytics Configuration

**Template**: `templates/bigquery-analytics-config.py`

**Purpose**: Complete BigQuery Agent Analytics plugin configuration

**Features**:
- Asynchronous event logging
- Multimodal content with GCS offloading
- OpenTelemetry-style tracing (trace_id, span_id)
- Event filtering and batching
- Custom content formatting

**Usage**:
```python
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin, BigQueryLoggerConfig
)

bq_config = BigQueryLoggerConfig(
    enabled=True,
    gcs_bucket_name="your-bucket-name",
    max_content_length=500 * 1024,  # 500KB inline limit
    batch_size=1,  # Low latency
    event_allowlist=["LLM_RESPONSE", "TOOL_COMPLETED"]
)

plugin = BigQueryAgentAnalyticsPlugin(
    project_id="your-project-id",
    dataset_id="your-dataset-id",
    config=bq_config
)

app = App(root_agent=agent, plugins=[plugin])
```

**Configuration Options**:
- `enabled` - Toggle logging on/off
- `gcs_bucket_name` - GCS bucket for large content
- `max_content_length` - Inline text limit (default 500KB)
- `batch_size` - Events per write (default 1)
- `event_allowlist` - Whitelist specific event types
- `event_denylist` - Blacklist specific event types
- `content_formatter` - Custom formatting function

### 3. BigQuery Schema

**Template**: `templates/bigquery-schema.json`

**Purpose**: BigQuery table schema for agent_events_v2

**Schema Fields**:
- `timestamp` - Event recording time
- `event_type` - Event category (LLM_REQUEST, TOOL_STARTING, etc.)
- `content` - Event-specific JSON payload
- `content_parts` - Structured multimodal data
- `trace_id` - OpenTelemetry trace ID
- `span_id` - OpenTelemetry span ID
- `agent` - Agent name
- `user_id` - User identifier

**Partitioning**: By DATE(timestamp) for cost optimization

**Clustering**: By event_type, agent, user_id for query performance

### 4. AgentOps Configuration

**Template**: `templates/agentops-config.py`

**Purpose**: AgentOps integration for session replays

**Features**:
- Minimal two-line integration
- Hierarchical span visualization
- LLM call tracking with prompts and completions
- Token count and latency metrics
- Cost tracking

**Usage**:
```python
import agentops

# Initialize AgentOps (before ADK imports)
agentops.init()

# Your ADK agent code
from google.adk.app import App
app = App(root_agent=my_agent)
```

**Span Hierarchy**:
- Agent spans: Named `adk.agent.{AgentName}`
- LLM spans: Capture prompts, completions, tokens
- Tool spans: Record parameters and results

### 5. Phoenix Configuration

**Template**: `templates/phoenix-config.py`

**Purpose**: Phoenix (Arize) integration for open-source observability

**Features**:
- Self-hosted data control
- OpenInference instrumentation
- Trace evaluation
- Performance debugging
- Custom evaluators

**Usage**:
```python
import os
from phoenix.otel import register

# Set Phoenix credentials
os.environ["PHOENIX_API_KEY"] = "your_api_key_here"
os.environ["PHOENIX_COLLECTOR_ENDPOINT"] = "https://app.phoenix.arize.com/s/your-space"

# Register Phoenix tracer
tracer_provider = register(
    project_name="my-adk-agent",
    auto_instrument=True
)

# Your ADK agent code (Phoenix auto-captures traces)
from google.adk.app import App
app = App(root_agent=my_agent)
```

**Auto-Instrumentation**: Phoenix automatically traces all ADK operations

### 6. Weave Configuration

**Template**: `templates/weave-config.py`

**Purpose**: Weave (W&B) integration for observability

**Features**:
- Timeline of agent calls
- Tool invocation tracking
- Reasoning process analysis
- Span hierarchy visualization
- Dashboard integration

**Usage**:
```python
import os
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
import base64

# Setup Weave exporter
wandb_api_key = os.environ["WANDB_API_KEY"]
entity = "your-entity"
project = "your-project"

auth_string = f"api:{wandb_api_key}"
encoded_auth = base64.b64encode(auth_string.encode()).decode()

exporter = OTLPSpanExporter(
    endpoint="https://trace.wandb.ai/otel/v1/traces",
    headers={
        "Authorization": f"Basic {encoded_auth}",
        "project_id": f"{entity}/{project}"
    }
)

# Configure tracer provider (BEFORE ADK imports)
provider = TracerProvider()
provider.add_span_processor(SimpleSpanProcessor(exporter))
trace.set_tracer_provider(provider)

# Your ADK agent code
from google.adk.app import App
app = App(root_agent=my_agent)
```

**Critical**: Set tracer provider before importing ADK components

## Available Examples

### 1. Complete Observability Setup

**Example**: `examples/complete-observability.md`

**Covers**:
- Multi-tool observability setup
- Cloud Trace + BigQuery combination
- Third-party tool integration
- Production deployment patterns
- Cost optimization strategies

**Step-by-Step Guide**:
1. Enable Cloud Trace for distributed tracing
2. Configure BigQuery for event logging
3. Add AgentOps for session replays
4. Optional: Phoenix or Weave for additional insights
5. Validate all configurations
6. Deploy to production

**Production Checklist**:
- [ ] Cloud Trace enabled in production
- [ ] BigQuery dataset created with proper IAM
- [ ] GCS bucket configured for multimodal content
- [ ] Event filtering configured to control costs
- [ ] Alert rules defined for error rates
- [ ] Dashboard created for key metrics
- [ ] Retention policies set for cost control

### 2. BigQuery Analytics Queries

**Example**: `examples/bigquery-queries.md`

**Covers**:
- Conversation trace retrieval
- Token usage analysis
- Error rate tracking
- Tool usage statistics
- Performance metrics
- Cost analysis

**Query Examples**:
```sql
-- Retrieve conversation traces
SELECT timestamp, event_type, JSON_VALUE(content, '$.response')
FROM agent_events_v2
WHERE trace_id = 'your-trace-id'
ORDER BY timestamp ASC;

-- Token usage by agent
SELECT
  agent,
  AVG(CAST(JSON_VALUE(content, '$.usage.total') AS INT64)) as avg_tokens,
  SUM(CAST(JSON_VALUE(content, '$.usage.total') AS INT64)) as total_tokens
FROM agent_events_v2
WHERE event_type = 'LLM_RESPONSE'
GROUP BY agent;

-- Error rate by event type
SELECT
  event_type,
  COUNT(*) as error_count,
  DATE(timestamp) as day
FROM agent_events_v2
WHERE event_type LIKE '%ERROR%'
GROUP BY event_type, day
ORDER BY day DESC, error_count DESC;

-- Tool usage frequency
SELECT
  JSON_VALUE(content, '$.tool_name') as tool,
  COUNT(*) as usage_count
FROM agent_events_v2
WHERE event_type = 'TOOL_COMPLETED'
GROUP BY tool
ORDER BY usage_count DESC;

-- Access multimodal content from GCS
SELECT
  part.mime_type,
  part.object_ref.uri as gcs_uri
FROM agent_events_v2,
UNNEST(content_parts) AS part
WHERE part.storage_mode = 'GCS_REFERENCE';
```

### 3. Multi-Tool Integration

**Example**: `examples/multi-tool-integration.md`

**Covers**:
- Using multiple observability tools together
- Cloud Trace + BigQuery + AgentOps
- Data correlation across platforms
- Tool selection criteria
- Cost vs. insight tradeoffs

**Integration Patterns**:

**Pattern 1: Google Cloud Native**
- Cloud Trace for distributed tracing
- BigQuery for detailed event analysis
- Best for: GCP-centric deployments

**Pattern 2: Comprehensive Monitoring**
- Cloud Trace for infrastructure tracing
- AgentOps for session replays
- BigQuery for analytics
- Best for: Production monitoring with detailed debugging

**Pattern 3: Open Source**
- Phoenix for self-hosted observability
- BigQuery for long-term storage
- Best for: Data sovereignty requirements

**Pattern 4: ML-Focused**
- Weave for experiment tracking
- BigQuery for analytics
- Best for: Research and experimentation

### 4. Production Deployment

**Example**: `examples/production-deployment.md`

**Covers**:
- Production-ready observability configuration
- IAM role setup
- Cost optimization
- Alert configuration
- Dashboard creation
- Incident response

**Production Setup**:
1. **IAM Configuration**:
   - Service account with minimal permissions
   - Separate dev/staging/prod credentials
   - Workload Identity for GKE deployments

2. **Cost Controls**:
   - Event filtering to reduce BigQuery writes
   - GCS lifecycle policies for multimodal content
   - Table partitioning and clustering
   - Retention policies (30-90 days)

3. **Monitoring**:
   - Cloud Monitoring alerts for error rates
   - BigQuery query dashboard in Looker Studio
   - AgentOps session replay for debugging
   - Trace analysis for performance issues

4. **Security**:
   - No credentials in code (environment variables only)
   - VPC Service Controls for data protection
   - Customer-managed encryption keys (CMEK)
   - Audit logging for compliance

## Security Compliance

**CRITICAL:** This skill follows strict security rules:

❌ **NEVER hardcode:**
- API keys (AgentOps, Phoenix, Weave, W&B)
- Google Cloud credentials
- Service account keys
- OAuth tokens
- BigQuery connection strings

✅ **ALWAYS:**
- Use environment variables for secrets
- Generate `.env.example` with placeholders
- Add `.env*` to `.gitignore`
- Use Google Application Default Credentials
- Document credential acquisition process
- Use IAM roles instead of service account keys when possible

**Placeholder format:**
```bash
# .env.example
GOOGLE_CLOUD_PROJECT=your-project-id
AGENTOPS_API_KEY=your_agentops_key_here
PHOENIX_API_KEY=your_phoenix_key_here
PHOENIX_COLLECTOR_ENDPOINT=https://app.phoenix.arize.com/s/your-space
WANDB_API_KEY=your_wandb_key_here
```

## Progressive Disclosure

This skill provides immediate setup guidance with references to detailed documentation:

- **Quick Start**: Use setup scripts for immediate configuration
- **Production**: Reference `production-deployment.md` for complete guide
- **Analytics**: Use `bigquery-queries.md` for query templates
- **Integration**: Reference `multi-tool-integration.md` for advanced patterns

Load additional files only when specific customization is needed.

## Common Workflows

### 1. Local Development Setup

```bash
# Enable Cloud Trace for local debugging
export GOOGLE_CLOUD_PROJECT=your-project-id
./scripts/setup-cloud-trace.sh your-project-id

# Start agent with tracing
python my_agent.py
# View traces at console.cloud.google.com/traces
```

### 2. Production Deployment with BigQuery

```bash
# 1. Create BigQuery dataset
bq mk --dataset my-project:agent-analytics

# 2. Create events table
bq mk --table agent-analytics.agent_events_v2 templates/bigquery-schema.json

# 3. Create GCS bucket for multimodal content
gsutil mb gs://my-agent-content/

# 4. Setup BigQuery analytics
./scripts/setup-bigquery-analytics.sh my-project agent-analytics my-agent-content

# 5. Deploy agent
adk deploy agent_engine --project=my-project ./agent

# 6. Validate setup
./scripts/validate-observability.sh --tool=bigquery
```

### 3. Multi-Tool Integration

```bash
# 1. Setup Cloud Trace
export GOOGLE_CLOUD_PROJECT=your-project-id
./scripts/setup-cloud-trace.sh your-project-id

# 2. Setup BigQuery Analytics
./scripts/setup-bigquery-analytics.sh your-project agent-analytics my-bucket

# 3. Setup AgentOps
export AGENTOPS_API_KEY=your_key_here
./scripts/setup-agentops.sh

# 4. Validate all configurations
./scripts/validate-observability.sh
```

## Troubleshooting

### Cloud Trace Not Showing Traces

**Check**:
- `GOOGLE_CLOUD_PROJECT` environment variable is set
- Cloud Trace API is enabled
- Service account has `roles/cloudtrace.agent`
- Tracer initialized before ADK imports

**Debug**:
```bash
# Check Cloud Trace API status
gcloud services list --enabled | grep cloudtrace

# Enable Cloud Trace API
gcloud services enable cloudtrace.googleapis.com

# Test trace export
python scripts/test-cloud-trace.py
```

### BigQuery Events Not Appearing

**Check**:
- Dataset and table exist
- Service account has correct IAM roles
- BigQuery API is enabled
- Plugin configuration is correct
- No event filtering blocking events

**Debug**:
```bash
# Check dataset exists
bq ls my-project:

# Check table schema
bq show --schema agent-analytics.agent_events_v2

# Check IAM permissions
gcloud projects get-iam-policy my-project \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:YOUR_SA_EMAIL"

# Test plugin manually
python scripts/test-bigquery-plugin.py
```

### AgentOps Not Capturing Traces

**Check**:
- AgentOps initialized before ADK imports
- API key is valid
- Network connectivity to app.agentops.ai
- AgentOps package version is latest

**Fix**:
```bash
# Update AgentOps
pip install -U agentops

# Test initialization
python -c "import agentops; agentops.init(); print('Success')"

# Check for conflicts with other tracers
# Ensure AgentOps is initialized first
```

### Phoenix Connection Failed

**Check**:
- Phoenix API key is valid
- Collector endpoint URL is correct
- Network access to Phoenix endpoint
- Required packages installed

**Debug**:
```bash
# Test Phoenix endpoint
curl -H "Authorization: Bearer YOUR_KEY" \
  https://app.phoenix.arize.com/s/YOUR_SPACE

# Verify package versions
pip list | grep -E "(openinference|phoenix)"

# Run verification script
python scripts/verify-phoenix.py
```

### Weave Traces Not Appearing

**Check**:
- Tracer provider set BEFORE ADK imports
- W&B API key is valid
- Entity and project names are correct
- OTEL exporter configured properly

**Fix**:
```python
# Verify initialization order
# 1. Import OTEL packages
# 2. Configure and set tracer provider
# 3. THEN import ADK

# Correct order:
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
trace.set_tracer_provider(TracerProvider())  # FIRST

from google.adk.app import App  # THEN
```

## Dependencies

**Required**:
- `google-adk>=1.21.0` - ADK framework (version 1.21.0+ for full BigQuery features)
- `google-cloud-trace>=1.13.0` - Cloud Trace client (optional)
- `google-cloud-bigquery>=3.0.0` - BigQuery client (optional)

**Optional (Third-party tools)**:
- `agentops>=0.3.0` - AgentOps integration
- `openinference-instrumentation-google-adk>=0.1.0` - Phoenix instrumentation
- `arize-phoenix-otel>=0.1.0` - Phoenix OTEL exporter
- `opentelemetry-sdk>=1.20.0` - OpenTelemetry SDK for Weave
- `opentelemetry-exporter-otlp-proto-http>=1.20.0` - OTLP exporter for Weave

**Installation**:
```bash
# Core ADK with Cloud Trace
pip install google-adk google-cloud-trace

# With BigQuery Analytics
pip install google-adk google-cloud-bigquery

# With AgentOps
pip install google-adk agentops

# With Phoenix
pip install google-adk openinference-instrumentation-google-adk arize-phoenix-otel

# With Weave
pip install google-adk opentelemetry-sdk opentelemetry-exporter-otlp-proto-http

# All observability tools
pip install google-adk google-cloud-trace google-cloud-bigquery agentops \
  openinference-instrumentation-google-adk arize-phoenix-otel \
  opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
```

## Best Practices

1. **Multi-Layer Observability**: Use Cloud Trace for infrastructure, BigQuery for analytics, and AgentOps for debugging
2. **Cost Control**: Implement event filtering and retention policies to manage BigQuery costs
3. **Security**: Never hardcode credentials; use environment variables and IAM roles
4. **Progressive Rollout**: Start with Cloud Trace, add BigQuery when analytics needed
5. **Tool Selection**: Choose tools based on requirements (open-source vs. managed, cost vs. features)
6. **Data Correlation**: Use trace_id across all tools for unified debugging
7. **Alert Configuration**: Set up alerts for error rates, latency spikes, and cost anomalies
8. **Dashboard Creation**: Build custom dashboards in Looker Studio, Grafana, or tool-native UIs

## Additional Resources

- **Cloud Trace**: https://cloud.google.com/trace/docs
- **BigQuery Agent Analytics**: https://google.github.io/adk-docs/observability/bigquery-agent-analytics/
- **AgentOps**: https://app.agentops.ai/
- **Phoenix (Arize)**: https://arize.com/docs/phoenix/
- **Weave (W&B)**: https://docs.wandb.ai/weave/
- **ADK Observability Guide**: https://google.github.io/adk-docs/observability/
- **OpenTelemetry**: https://opentelemetry.io/docs/

## Tool Comparison

| Feature | Cloud Trace | BigQuery | AgentOps | Phoenix | Weave |
|---------|------------|----------|----------|---------|-------|
| **Hosting** | Google Cloud | Google Cloud | SaaS | SaaS/Self-hosted | SaaS |
| **Cost** | Free tier + usage | Storage + queries | Free tier + paid | Free tier + paid | Free tier + paid |
| **Setup Complexity** | Low | Medium | Very Low | Low | Medium |
| **Data Control** | Google Cloud | Google Cloud | Third-party | Self-host option | Third-party |
| **Query Flexibility** | Low | Very High | Medium | High | Medium |
| **Real-time** | Yes | Near real-time | Yes | Yes | Yes |
| **Custom Dashboards** | Limited | Full (Looker) | Built-in | Built-in | Built-in |
| **Best For** | Infrastructure tracing | Deep analytics | Quick debugging | Open-source, control | ML experiments |
