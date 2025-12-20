# BigQuery Analytics Queries for Google ADK Agents

This document provides a comprehensive collection of BigQuery SQL queries for analyzing Google ADK agent behavior, performance, and costs.

## Table Schema Reference

```sql
-- agent_events_v2 schema
SELECT column_name, data_type, description
FROM `project.dataset.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'agent_events_v2'
```

Key fields:
- `timestamp`: Event recording time
- `event_type`: Event category (LLM_REQUEST, TOOL_STARTING, etc.)
- `content`: JSON payload with event details
- `content_parts`: Multimodal data (images, audio, etc.)
- `trace_id` / `span_id`: OpenTelemetry tracing IDs
- `agent`: Agent name
- `user_id`: User identifier

## Basic Queries

### Recent Events

```sql
-- Get last 100 events
SELECT
  timestamp,
  event_type,
  agent,
  trace_id
FROM `project.dataset.agent_events_v2`
ORDER BY timestamp DESC
LIMIT 100
```

### Events by Type

```sql
-- Count events by type
SELECT
  event_type,
  COUNT(*) as count
FROM `project.dataset.agent_events_v2`
WHERE DATE(timestamp) >= CURRENT_DATE() - 7  -- Last 7 days
GROUP BY event_type
ORDER BY count DESC
```

## Conversation Tracing

### Complete Conversation Trace

```sql
-- Retrieve full conversation using trace_id
SELECT
  timestamp,
  event_type,
  agent,
  JSON_VALUE(content, '$.request') as request,
  JSON_VALUE(content, '$.response') as response,
  JSON_VALUE(content, '$.tool_name') as tool
FROM `project.dataset.agent_events_v2`
WHERE trace_id = 'your-trace-id-here'
ORDER BY timestamp ASC
```

### Conversation Flow Visualization

```sql
-- Get conversation flow with hierarchy
SELECT
  timestamp,
  event_type,
  span_id,
  parent_span_id,
  CASE
    WHEN parent_span_id IS NULL THEN 'root'
    ELSE 'child'
  END as hierarchy_level,
  JSON_VALUE(content, '$.message') as message
FROM `project.dataset.agent_events_v2`
WHERE trace_id = 'your-trace-id-here'
ORDER BY timestamp ASC
```

## Token Usage Analytics

### Total Token Usage by Agent

```sql
-- Aggregate token usage per agent
SELECT
  agent,
  COUNT(*) as llm_calls,
  SUM(CAST(JSON_VALUE(content, '$.usage.prompt_tokens') AS INT64)) as total_prompt_tokens,
  SUM(CAST(JSON_VALUE(content, '$.usage.completion_tokens') AS INT64)) as total_completion_tokens,
  SUM(CAST(JSON_VALUE(content, '$.usage.total_tokens') AS INT64)) as total_tokens
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'LLM_RESPONSE'
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY agent
ORDER BY total_tokens DESC
```

### Daily Token Trends

```sql
-- Token usage trends over time
SELECT
  DATE(timestamp) as day,
  COUNT(*) as llm_calls,
  SUM(CAST(JSON_VALUE(content, '$.usage.total_tokens') AS INT64)) as total_tokens,
  AVG(CAST(JSON_VALUE(content, '$.usage.total_tokens') AS INT64)) as avg_tokens_per_call
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'LLM_RESPONSE'
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY day
ORDER BY day DESC
```

### Top Token-Consuming Users

```sql
-- Users with highest token usage
SELECT
  user_id,
  COUNT(DISTINCT trace_id) as conversations,
  SUM(CAST(JSON_VALUE(content, '$.usage.total_tokens') AS INT64)) as total_tokens,
  AVG(CAST(JSON_VALUE(content, '$.usage.total_tokens') AS INT64)) as avg_tokens_per_response
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'LLM_RESPONSE'
  AND user_id IS NOT NULL
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY user_id
ORDER BY total_tokens DESC
LIMIT 20
```

## Performance Analytics

### Response Time Analysis

```sql
-- Average response time by agent
SELECT
  agent,
  COUNT(*) as requests,
  AVG(CAST(JSON_VALUE(content, '$.latency_ms') AS FLOAT64)) as avg_latency_ms,
  APPROX_QUANTILES(CAST(JSON_VALUE(content, '$.latency_ms') AS FLOAT64), 100)[OFFSET(50)] as median_latency_ms,
  APPROX_QUANTILES(CAST(JSON_VALUE(content, '$.latency_ms') AS FLOAT64), 100)[OFFSET(95)] as p95_latency_ms
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'LLM_RESPONSE'
  AND DATE(timestamp) >= CURRENT_DATE() - 7
GROUP BY agent
ORDER BY avg_latency_ms DESC
```

### Slow Requests

```sql
-- Find slowest LLM requests
SELECT
  timestamp,
  agent,
  trace_id,
  CAST(JSON_VALUE(content, '$.latency_ms') AS FLOAT64) as latency_ms,
  CAST(JSON_VALUE(content, '$.usage.total_tokens') AS INT64) as tokens,
  JSON_VALUE(content, '$.model') as model
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'LLM_RESPONSE'
  AND CAST(JSON_VALUE(content, '$.latency_ms') AS FLOAT64) > 5000  -- >5 seconds
  AND DATE(timestamp) >= CURRENT_DATE() - 7
ORDER BY latency_ms DESC
LIMIT 100
```

## Error Analysis

### Error Rate by Type

```sql
-- Errors grouped by type
SELECT
  event_type,
  COUNT(*) as error_count,
  DATE(timestamp) as day
FROM `project.dataset.agent_events_v2`
WHERE event_type LIKE '%ERROR%'
  AND DATE(timestamp) >= CURRENT_DATE() - 7
GROUP BY event_type, day
ORDER BY day DESC, error_count DESC
```

### Error Details with Context

```sql
-- Get error details with full context
SELECT
  timestamp,
  event_type,
  agent,
  trace_id,
  JSON_VALUE(content, '$.error_message') as error_message,
  JSON_VALUE(content, '$.error_type') as error_type,
  JSON_VALUE(content, '$.stack_trace') as stack_trace
FROM `project.dataset.agent_events_v2`
WHERE event_type LIKE '%ERROR%'
  AND DATE(timestamp) >= CURRENT_DATE() - 7
ORDER BY timestamp DESC
LIMIT 100
```

### Error Rate Over Time

```sql
-- Error rate trends
SELECT
  DATE(timestamp) as day,
  event_type,
  COUNT(*) as error_count,
  -- Compare to total events
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY DATE(timestamp)), 2) as error_percentage
FROM `project.dataset.agent_events_v2`
WHERE DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY day, event_type
ORDER BY day DESC, error_count DESC
```

## Tool Usage Analytics

### Tool Usage Frequency

```sql
-- Most frequently used tools
SELECT
  JSON_VALUE(content, '$.tool_name') as tool,
  COUNT(*) as usage_count,
  AVG(CAST(JSON_VALUE(content, '$.execution_time_ms') AS FLOAT64)) as avg_execution_ms
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'TOOL_COMPLETED'
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY tool
ORDER BY usage_count DESC
```

### Tool Success vs. Failure Rate

```sql
-- Tool reliability analysis
WITH tool_events AS (
  SELECT
    JSON_VALUE(content, '$.tool_name') as tool,
    event_type
  FROM `project.dataset.agent_events_v2`
  WHERE event_type IN ('TOOL_COMPLETED', 'TOOL_ERROR')
    AND DATE(timestamp) >= CURRENT_DATE() - 30
)
SELECT
  tool,
  COUNTIF(event_type = 'TOOL_COMPLETED') as successful,
  COUNTIF(event_type = 'TOOL_ERROR') as failed,
  ROUND(COUNTIF(event_type = 'TOOL_COMPLETED') * 100.0 / COUNT(*), 2) as success_rate_pct
FROM tool_events
GROUP BY tool
ORDER BY success_rate_pct ASC
```

### Tool Performance by Agent

```sql
-- Tool usage patterns by agent
SELECT
  agent,
  JSON_VALUE(content, '$.tool_name') as tool,
  COUNT(*) as usage_count,
  AVG(CAST(JSON_VALUE(content, '$.execution_time_ms') AS FLOAT64)) as avg_execution_ms
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'TOOL_COMPLETED'
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY agent, tool
ORDER BY agent, usage_count DESC
```

## Multimodal Content Analysis

### Multimodal Content Usage

```sql
-- Count multimodal content types
SELECT
  part.mime_type,
  part.storage_mode,
  COUNT(*) as count
FROM `project.dataset.agent_events_v2`,
UNNEST(content_parts) AS part
WHERE DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY part.mime_type, part.storage_mode
ORDER BY count DESC
```

### GCS-Offloaded Content

```sql
-- Retrieve GCS URIs for offloaded content
SELECT
  timestamp,
  event_type,
  trace_id,
  part.mime_type,
  part.object_ref.uri as gcs_uri
FROM `project.dataset.agent_events_v2`,
UNNEST(content_parts) AS part
WHERE part.storage_mode = 'GCS_REFERENCE'
  AND DATE(timestamp) >= CURRENT_DATE() - 7
ORDER BY timestamp DESC
LIMIT 100
```

### Large Content Detection

```sql
-- Find events with large inline content
SELECT
  timestamp,
  event_type,
  trace_id,
  LENGTH(part.inline_data) as content_size_bytes
FROM `project.dataset.agent_events_v2`,
UNNEST(content_parts) AS part
WHERE part.storage_mode = 'INLINE'
  AND LENGTH(part.inline_data) > 400000  -- >400KB
  AND DATE(timestamp) >= CURRENT_DATE() - 7
ORDER BY content_size_bytes DESC
LIMIT 100
```

## Cost Analysis

### Estimated Cost by Model

```sql
-- Estimate costs by model (adjust pricing as needed)
WITH pricing AS (
  SELECT 'gemini-2.0-flash-exp' as model, 0.000001 as input_cost, 0.000002 as output_cost UNION ALL
  SELECT 'gemini-pro', 0.00025, 0.0005
)
SELECT
  JSON_VALUE(content, '$.model') as model,
  SUM(CAST(JSON_VALUE(content, '$.usage.prompt_tokens') AS INT64)) as prompt_tokens,
  SUM(CAST(JSON_VALUE(content, '$.usage.completion_tokens') AS INT64)) as completion_tokens,
  p.input_cost * SUM(CAST(JSON_VALUE(content, '$.usage.prompt_tokens') AS INT64)) +
  p.output_cost * SUM(CAST(JSON_VALUE(content, '$.usage.completion_tokens') AS INT64)) as estimated_cost_usd
FROM `project.dataset.agent_events_v2` e
LEFT JOIN pricing p ON JSON_VALUE(e.content, '$.model') = p.model
WHERE event_type = 'LLM_RESPONSE'
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY model, p.input_cost, p.output_cost
ORDER BY estimated_cost_usd DESC
```

### Daily Cost Trends

```sql
-- Daily cost trends (adjust pricing as needed)
SELECT
  DATE(timestamp) as day,
  SUM(CAST(JSON_VALUE(content, '$.usage.prompt_tokens') AS INT64)) as prompt_tokens,
  SUM(CAST(JSON_VALUE(content, '$.usage.completion_tokens') AS INT64)) as completion_tokens,
  -- Gemini 2.0 Flash pricing example
  0.000001 * SUM(CAST(JSON_VALUE(content, '$.usage.prompt_tokens') AS INT64)) +
  0.000002 * SUM(CAST(JSON_VALUE(content, '$.usage.completion_tokens') AS INT64)) as estimated_cost_usd
FROM `project.dataset.agent_events_v2`
WHERE event_type = 'LLM_RESPONSE'
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY day
ORDER BY day DESC
```

## User Behavior Analytics

### Active Users

```sql
-- Daily active users
SELECT
  DATE(timestamp) as day,
  COUNT(DISTINCT user_id) as daily_active_users,
  COUNT(DISTINCT trace_id) as total_conversations
FROM `project.dataset.agent_events_v2`
WHERE user_id IS NOT NULL
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY day
ORDER BY day DESC
```

### User Engagement Patterns

```sql
-- User engagement metrics
SELECT
  user_id,
  COUNT(DISTINCT DATE(timestamp)) as days_active,
  COUNT(DISTINCT trace_id) as total_conversations,
  MIN(timestamp) as first_interaction,
  MAX(timestamp) as last_interaction,
  TIMESTAMP_DIFF(MAX(timestamp), MIN(timestamp), DAY) as user_lifetime_days
FROM `project.dataset.agent_events_v2`
WHERE user_id IS NOT NULL
  AND DATE(timestamp) >= CURRENT_DATE() - 30
GROUP BY user_id
ORDER BY days_active DESC, total_conversations DESC
LIMIT 100
```

## Data Retention and Cleanup

### Table Size Analysis

```sql
-- Check table size and partition info
SELECT
  DATE(timestamp) as partition_date,
  COUNT(*) as row_count,
  ROUND(SUM(LENGTH(TO_JSON_STRING(content))) / 1024 / 1024, 2) as content_size_mb
FROM `project.dataset.agent_events_v2`
GROUP BY partition_date
ORDER BY partition_date DESC
```

### Delete Old Partitions

```sql
-- Delete partitions older than 90 days (CAUTION: Destructive)
-- Run this as a scheduled query or manual cleanup

DELETE FROM `project.dataset.agent_events_v2`
WHERE DATE(timestamp) < CURRENT_DATE() - 90
```

## Scheduled Queries

### Daily Error Summary

```sql
-- Schedule this query to run daily and email results
CREATE OR REPLACE VIEW daily_error_summary AS
SELECT
  event_type,
  COUNT(*) as error_count,
  ARRAY_AGG(
    STRUCT(
      timestamp,
      trace_id,
      agent,
      JSON_VALUE(content, '$.error_message') as error
    )
    ORDER BY timestamp DESC
    LIMIT 10
  ) as recent_samples
FROM `project.dataset.agent_events_v2`
WHERE event_type LIKE '%ERROR%'
  AND DATE(timestamp) = CURRENT_DATE()
GROUP BY event_type
ORDER BY error_count DESC
```

### Weekly Performance Report

```sql
-- Schedule weekly for performance insights
SELECT
  'Week of ' || CAST(DATE_TRUNC(CURRENT_DATE(), WEEK) AS STRING) as report_period,
  COUNT(DISTINCT user_id) as active_users,
  COUNT(DISTINCT trace_id) as conversations,
  SUM(CAST(JSON_VALUE(content, '$.usage.total_tokens') AS INT64)) as total_tokens,
  AVG(CAST(JSON_VALUE(content, '$.latency_ms') AS FLOAT64)) as avg_latency_ms,
  COUNTIF(event_type LIKE '%ERROR%') as errors
FROM `project.dataset.agent_events_v2`
WHERE DATE(timestamp) >= DATE_TRUNC(CURRENT_DATE(), WEEK)
```

## Export Queries

### Export to GCS for Further Analysis

```bash
# Export query results to GCS
bq query --use_legacy_sql=false \
  --destination_table=project:dataset.temp_export \
  --replace \
  'SELECT * FROM agent_events_v2 WHERE DATE(timestamp) = CURRENT_DATE()'

bq extract \
  --destination_format=NEWLINE_DELIMITED_JSON \
  project:dataset.temp_export \
  gs://your-bucket/exports/agent_events_$(date +%Y%m%d).json
```

## Additional Resources

- BigQuery SQL Reference: https://cloud.google.com/bigquery/docs/reference/standard-sql/
- JSON Functions: https://cloud.google.com/bigquery/docs/reference/standard-sql/json_functions
- Performance Optimization: https://cloud.google.com/bigquery/docs/best-practices-performance-overview
