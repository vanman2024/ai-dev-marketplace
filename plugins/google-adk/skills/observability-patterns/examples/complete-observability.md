# Complete Observability Setup for Google ADK Agents

This example demonstrates a complete multi-tool observability setup for production ADK agents, combining Cloud Trace, BigQuery Analytics, and AgentOps for comprehensive monitoring.

## Overview

This setup provides:
- **Cloud Trace**: Distributed tracing for infrastructure monitoring
- **BigQuery**: Detailed event logging and analytics
- **AgentOps**: Session replays and debugging

## Prerequisites

1. Google Cloud Project with billing enabled
2. ADK 1.21.0+ installed
3. AgentOps account (optional)
4. Required IAM permissions

## Step 1: Enable Google Cloud Services

```bash
# Set project ID
export GOOGLE_CLOUD_PROJECT=your-project-id

# Enable required APIs
gcloud services enable cloudtrace.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable storage.googleapis.com
```

## Step 2: Create BigQuery Dataset and Table

```bash
# Create dataset
bq mk --dataset --location=US $GOOGLE_CLOUD_PROJECT:agent_analytics

# Create table with schema
bq mk --table \
  --time_partitioning_field=timestamp \
  --time_partitioning_type=DAY \
  --clustering_fields=event_type,agent,user_id \
  $GOOGLE_CLOUD_PROJECT:agent_analytics.agent_events_v2 \
  /path/to/templates/bigquery-schema.json
```

## Step 3: Create GCS Bucket for Multimodal Content

```bash
# Create bucket
gsutil mb -p $GOOGLE_CLOUD_PROJECT gs://your-agent-content/

# Set lifecycle policy (90-day retention)
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": 90}
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://your-agent-content/
rm lifecycle.json
```

## Step 4: Configure IAM Permissions

```bash
# If using service account
SA_EMAIL=your-service-account@your-project.iam.gserviceaccount.com

# Grant Cloud Trace permissions
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudtrace.agent"

# Grant BigQuery permissions
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/bigquery.jobUser"

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/bigquery.dataEditor"

# Grant GCS permissions
gsutil iam ch serviceAccount:$SA_EMAIL:roles/storage.objectCreator \
  gs://your-agent-content/
```

## Step 5: Agent Code with All Observability Tools

```python
"""
Complete observability setup for ADK agents.
Combines Cloud Trace, BigQuery Analytics, and AgentOps.
"""

import os

# 1. Initialize AgentOps FIRST (before any ADK imports)
import agentops
agentops.init()

# 2. Import ADK components
from google.adk.app import App
from google.adk.core import Agent
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin,
    BigQueryLoggerConfig
)

# 3. Create BigQuery configuration
bq_config = BigQueryLoggerConfig(
    enabled=True,
    gcs_bucket_name="your-agent-content",
    max_content_length=500 * 1024,
    batch_size=10,  # Higher throughput for production

    # Filter events to control costs
    event_allowlist=[
        "LLM_RESPONSE",
        "TOOL_COMPLETED",
        "AGENT_STARTING",
        "USER_MESSAGE_RECEIVED"
    ]
)

# 4. Create BigQuery plugin
bigquery_plugin = BigQueryAgentAnalyticsPlugin(
    project_id=os.environ["GOOGLE_CLOUD_PROJECT"],
    dataset_id="agent_analytics",
    config=bq_config
)

# 5. Create agent
agent = Agent(
    name="production_agent",
    model="gemini-2.0-flash-exp",
    instruction="""You are a production assistant with comprehensive observability.

All your interactions are tracked for monitoring and improvement."""
)

# 6. Create app with Cloud Trace and BigQuery
app = App(
    root_agent=agent,
    plugins=[bigquery_plugin],
    # Cloud Trace is enabled automatically when deployed with --trace_to_cloud
    # Or set enable_tracing=True for AdkApp
)

if __name__ == "__main__":
    print("Observability configured:")
    print(f"  ✓ Cloud Trace enabled")
    print(f"  ✓ BigQuery Analytics: {os.environ['GOOGLE_CLOUD_PROJECT']}.agent_analytics")
    print(f"  ✓ AgentOps session tracking")
    print(f"\nView data at:")
    print(f"  Cloud Trace: https://console.cloud.google.com/traces/list?project={os.environ['GOOGLE_CLOUD_PROJECT']}")
    print(f"  BigQuery: https://console.cloud.google.com/bigquery?project={os.environ['GOOGLE_CLOUD_PROJECT']}")
    print(f"  AgentOps: https://app.agentops.ai/")
```

## Step 6: Deploy with Cloud Trace

```bash
# Deploy using ADK CLI with Cloud Trace enabled
adk deploy agent_engine \
  --project=$GOOGLE_CLOUD_PROJECT \
  --trace_to_cloud \
  ./agent

# Or for custom deployment, set enable_tracing=True in AdkApp
```

## Step 7: Environment Variables

Create `.env` file (DO NOT commit to git):

```bash
# Google Cloud
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# AgentOps (optional)
AGENTOPS_API_KEY=your_agentops_key_here
```

Create `.env.example` file (safe to commit):

```bash
# Google Cloud
GOOGLE_CLOUD_PROJECT=your_project_id_here
GOOGLE_APPLICATION_CREDENTIALS=/path/to/your_service_account_key.json

# AgentOps
AGENTOPS_API_KEY=your_agentops_key_here
```

## Step 8: Validate Setup

```bash
# Run validation script
./scripts/validate-observability.sh

# Should output:
#   ✓ Cloud Trace validation passed
#   ✓ BigQuery validation passed
#   ✓ AgentOps validation passed
```

## Production Checklist

- [ ] Cloud Trace enabled in production deployment
- [ ] BigQuery dataset created with proper IAM roles
- [ ] GCS bucket configured for multimodal content
- [ ] Event filtering configured to control BigQuery costs
- [ ] Table partitioning and clustering optimized
- [ ] Retention policies set (90 days recommended)
- [ ] Alert rules configured for error rates
- [ ] Dashboard created for key metrics
- [ ] No hardcoded credentials in code
- [ ] `.env` files added to `.gitignore`
- [ ] Service account has minimal required permissions
- [ ] Cost monitoring alerts configured

## Cost Optimization

### BigQuery Costs

```python
# Use event filtering to reduce writes
bq_config = BigQueryLoggerConfig(
    event_allowlist=[
        "LLM_RESPONSE",      # Essential for analytics
        "TOOL_COMPLETED",    # Tool usage tracking
        "AGENT_STARTING"     # Session tracking
    ]
    # Excludes DEBUG, TRACE events that generate high volume
)
```

### GCS Lifecycle

```bash
# Automatically delete old multimodal content
gsutil lifecycle set lifecycle.json gs://your-agent-content/
# Contents deleted after 90 days
```

### Table Partitioning

```sql
-- Partition by date enables efficient querying and pruning
-- Only scan data for specific date ranges

SELECT *
FROM agent_events_v2
WHERE DATE(timestamp) >= '2025-01-01'  -- Partition filter
  AND event_type = 'LLM_RESPONSE'
```

## Monitoring Dashboards

### Cloud Trace Dashboard

1. Go to Cloud Console > Trace Explorer
2. Filter by service name (your agent name)
3. Analyze:
   - Request latency distribution
   - Error rates by span type
   - Slowest operations

### BigQuery Dashboard (Looker Studio)

Create dashboard with:

1. **Token Usage Over Time**:
```sql
SELECT
  DATE(timestamp) as day,
  SUM(CAST(JSON_VALUE(content, '$.usage.total') AS INT64)) as total_tokens
FROM agent_events_v2
WHERE event_type = 'LLM_RESPONSE'
GROUP BY day
ORDER BY day DESC
```

2. **Error Rate by Type**:
```sql
SELECT
  event_type,
  COUNT(*) as error_count,
  DATE(timestamp) as day
FROM agent_events_v2
WHERE event_type LIKE '%ERROR%'
GROUP BY event_type, day
ORDER BY day DESC, error_count DESC
```

3. **Tool Usage Frequency**:
```sql
SELECT
  JSON_VALUE(content, '$.tool_name') as tool,
  COUNT(*) as usage_count
FROM agent_events_v2
WHERE event_type = 'TOOL_COMPLETED'
GROUP BY tool
ORDER BY usage_count DESC
```

### AgentOps Dashboard

1. Go to app.agentops.ai
2. View session replays
3. Analyze:
   - Session success rates
   - Average tokens per session
   - Cost per session
   - Error patterns

## Alert Configuration

### Cloud Monitoring Alerts

```bash
# Create alert for high error rate
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="ADK Agent High Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=0.05 \
  --condition-threshold-duration=300s
```

### BigQuery Scheduled Queries

```sql
-- Schedule daily error summary email
CREATE OR REPLACE VIEW agent_daily_errors AS
SELECT
  DATE(timestamp) as day,
  event_type,
  COUNT(*) as count,
  ARRAY_AGG(STRUCT(trace_id, JSON_VALUE(content, '$.error')) LIMIT 10) as samples
FROM agent_events_v2
WHERE event_type LIKE '%ERROR%'
  AND DATE(timestamp) = CURRENT_DATE()
GROUP BY day, event_type
ORDER BY count DESC
```

## Troubleshooting

### No traces in Cloud Trace

1. Verify `--trace_to_cloud` flag used in deployment
2. Check service account has `roles/cloudtrace.agent`
3. Ensure Cloud Trace API is enabled
4. Verify `GOOGLE_CLOUD_PROJECT` is set

### No events in BigQuery

1. Check dataset and table exist
2. Verify service account has BigQuery permissions
3. Check BigQuery API is enabled
4. Verify plugin is configured correctly
5. Check event filtering isn't blocking all events

### AgentOps not showing sessions

1. Ensure `agentops.init()` called before ADK imports
2. Verify `AGENTOPS_API_KEY` is set
3. Check network connectivity to app.agentops.ai
4. Update agentops package: `pip install -U agentops`

## Additional Resources

- Cloud Trace: https://cloud.google.com/trace/docs
- BigQuery: https://cloud.google.com/bigquery/docs
- AgentOps: https://docs.agentops.ai/
- ADK Observability: https://google.github.io/adk-docs/observability/
