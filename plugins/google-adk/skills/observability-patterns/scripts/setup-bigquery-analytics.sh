#!/bin/bash

# Setup BigQuery Agent Analytics for Google ADK
# Usage: ./setup-bigquery-analytics.sh <project-id> <dataset-id> [bucket-name]

set -e

PROJECT_ID="$1"
DATASET_ID="$2"
BUCKET_NAME="${3:-}"

if [ -z "$PROJECT_ID" ] || [ -z "$DATASET_ID" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 <project-id> <dataset-id> [bucket-name]"
  echo ""
  echo "Arguments:"
  echo "  project-id   - Google Cloud project ID (required)"
  echo "  dataset-id   - BigQuery dataset name (required)"
  echo "  bucket-name  - GCS bucket for multimodal content (optional)"
  exit 1
fi

echo "Setting up BigQuery Agent Analytics"
echo "  Project: $PROJECT_ID"
echo "  Dataset: $DATASET_ID"
echo "  Bucket: ${BUCKET_NAME:-none}"

# Enable BigQuery API
echo "Enabling BigQuery API..."
gcloud services enable bigquery.googleapis.com --project="$PROJECT_ID"

# Create dataset if it doesn't exist
echo "Creating BigQuery dataset..."
bq mk --dataset --location=US "$PROJECT_ID:$DATASET_ID" 2>/dev/null || echo "Dataset already exists"

# Create table with schema
echo "Creating agent_events_v2 table..."
SCHEMA_FILE="$(dirname "$0")/../templates/bigquery-schema.json"
if [ -f "$SCHEMA_FILE" ]; then
  bq mk --table \
    --time_partitioning_field=timestamp \
    --time_partitioning_type=DAY \
    --clustering_fields=event_type,agent,user_id \
    "$PROJECT_ID:$DATASET_ID.agent_events_v2" \
    "$SCHEMA_FILE" 2>/dev/null || echo "Table already exists"
else
  echo "Warning: Schema file not found at $SCHEMA_FILE"
  echo "Create table manually with:"
  echo "  bq mk --table $PROJECT_ID:$DATASET_ID.agent_events_v2 templates/bigquery-schema.json"
fi

# Create GCS bucket if specified
if [ -n "$BUCKET_NAME" ]; then
  echo "Creating GCS bucket..."
  gsutil mb -p "$PROJECT_ID" "gs://$BUCKET_NAME/" 2>/dev/null || echo "Bucket already exists"

  # Set lifecycle policy to delete old objects
  echo "Setting GCS lifecycle policy..."
  cat > /tmp/lifecycle.json <<EOF
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
  gsutil lifecycle set /tmp/lifecycle.json "gs://$BUCKET_NAME/"
  rm /tmp/lifecycle.json
fi

# Check IAM permissions
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  SA_EMAIL=$(jq -r '.client_email' < "$GOOGLE_APPLICATION_CREDENTIALS")
  echo "Granting IAM roles to: $SA_EMAIL"

  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/bigquery.jobUser" \
    --condition=None

  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/bigquery.dataEditor" \
    --condition=None

  if [ -n "$BUCKET_NAME" ]; then
    gsutil iam ch "serviceAccount:$SA_EMAIL:roles/storage.objectCreator" "gs://$BUCKET_NAME/"
  fi
fi

echo "✓ BigQuery Agent Analytics setup complete!"
echo ""
echo "Configuration:"
cat <<EOF
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin, BigQueryLoggerConfig
)

bq_config = BigQueryLoggerConfig(
    enabled=True,
    gcs_bucket_name="$BUCKET_NAME",
    max_content_length=500 * 1024,
    batch_size=1
)

plugin = BigQueryAgentAnalyticsPlugin(
    project_id="$PROJECT_ID",
    dataset_id="$DATASET_ID",
    config=bq_config
)

app = App(root_agent=agent, plugins=[plugin])
EOF
echo ""
echo "Query events:"
echo "  SELECT * FROM \`$PROJECT_ID.$DATASET_ID.agent_events_v2\` LIMIT 10"
