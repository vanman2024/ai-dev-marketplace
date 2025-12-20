#!/bin/bash

# Setup Cloud Trace for Google ADK agents
# Usage: ./setup-cloud-trace.sh <project-id>

set -e

PROJECT_ID="${1:-$GOOGLE_CLOUD_PROJECT}"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID required"
  echo "Usage: $0 <project-id>"
  echo "   or: export GOOGLE_CLOUD_PROJECT=<project-id> && $0"
  exit 1
fi

echo "Setting up Cloud Trace for project: $PROJECT_ID"

# Enable Cloud Trace API
echo "Enabling Cloud Trace API..."
gcloud services enable cloudtrace.googleapis.com --project="$PROJECT_ID"

# Check if service account needs Cloud Trace permissions
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  SA_EMAIL=$(jq -r '.client_email' < "$GOOGLE_APPLICATION_CREDENTIALS")
  echo "Granting Cloud Trace agent role to: $SA_EMAIL"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/cloudtrace.agent" \
    --condition=None
fi

# Set environment variable
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"

echo "✓ Cloud Trace setup complete!"
echo ""
echo "Environment variables:"
echo "  GOOGLE_CLOUD_PROJECT=$PROJECT_ID"
echo ""
echo "Deploy with Cloud Trace enabled:"
echo "  adk deploy agent_engine --project=$PROJECT_ID --trace_to_cloud ./agent"
echo ""
echo "Or enable in Python:"
echo "  app = AdkApp(agent=my_agent, enable_tracing=True)"
echo ""
echo "View traces at:"
echo "  https://console.cloud.google.com/traces/list?project=$PROJECT_ID"
