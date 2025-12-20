#!/bin/bash

# Validate observability setup for Google ADK
# Usage: ./validate-observability.sh [--tool=<tool-name>]

set -e

TOOL="${1#--tool=}"
TOOL="${TOOL:-all}"

validate_cloud_trace() {
  echo "Validating Cloud Trace..."

  if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
    echo "  ✗ GOOGLE_CLOUD_PROJECT not set"
    return 1
  fi
  echo "  ✓ GOOGLE_CLOUD_PROJECT set"

  if ! gcloud services list --enabled --project="$GOOGLE_CLOUD_PROJECT" 2>/dev/null | grep -q cloudtrace; then
    echo "  ✗ Cloud Trace API not enabled"
    return 1
  fi
  echo "  ✓ Cloud Trace API enabled"

  echo "  ✓ Cloud Trace validation passed"
  return 0
}

validate_bigquery() {
  echo "Validating BigQuery Agent Analytics..."

  if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
    echo "  ✗ GOOGLE_CLOUD_PROJECT not set"
    return 1
  fi
  echo "  ✓ GOOGLE_CLOUD_PROJECT set"

  if ! gcloud services list --enabled --project="$GOOGLE_CLOUD_PROJECT" 2>/dev/null | grep -q bigquery; then
    echo "  ✗ BigQuery API not enabled"
    return 1
  fi
  echo "  ✓ BigQuery API enabled"

  # Check if dataset exists (requires dataset name as parameter)
  # Skipping detailed validation, just check API access
  if ! bq ls --project_id="$GOOGLE_CLOUD_PROJECT" >/dev/null 2>&1; then
    echo "  ⚠ Cannot list datasets (check IAM permissions)"
    return 1
  fi
  echo "  ✓ BigQuery access verified"

  echo "  ✓ BigQuery validation passed"
  return 0
}

validate_agentops() {
  echo "Validating AgentOps..."

  if [ -z "$AGENTOPS_API_KEY" ]; then
    echo "  ✗ AGENTOPS_API_KEY not set"
    return 1
  fi
  echo "  ✓ AGENTOPS_API_KEY set"

  if ! python3 -c "import agentops" 2>/dev/null; then
    echo "  ✗ agentops package not installed"
    return 1
  fi
  echo "  ✓ agentops package installed"

  echo "  ✓ AgentOps validation passed"
  return 0
}

validate_phoenix() {
  echo "Validating Phoenix..."

  if [ -z "$PHOENIX_API_KEY" ] || [ -z "$PHOENIX_COLLECTOR_ENDPOINT" ]; then
    echo "  ✗ PHOENIX_API_KEY or PHOENIX_COLLECTOR_ENDPOINT not set"
    return 1
  fi
  echo "  ✓ Phoenix environment variables set"

  if ! python3 -c "import phoenix.otel" 2>/dev/null; then
    echo "  ✗ arize-phoenix-otel package not installed"
    return 1
  fi
  echo "  ✓ Phoenix packages installed"

  # Test endpoint connectivity
  if ! curl -s -f -H "Authorization: Bearer $PHOENIX_API_KEY" "$PHOENIX_COLLECTOR_ENDPOINT" >/dev/null 2>&1; then
    echo "  ⚠ Phoenix endpoint may not be reachable"
  else
    echo "  ✓ Phoenix endpoint reachable"
  fi

  echo "  ✓ Phoenix validation passed"
  return 0
}

validate_weave() {
  echo "Validating Weave..."

  if [ -z "$WANDB_API_KEY" ]; then
    echo "  ✗ WANDB_API_KEY not set"
    return 1
  fi
  echo "  ✓ WANDB_API_KEY set"

  if ! python3 -c "from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter" 2>/dev/null; then
    echo "  ✗ opentelemetry-exporter-otlp-proto-http package not installed"
    return 1
  fi
  echo "  ✓ OTEL packages installed"

  echo "  ✓ Weave validation passed"
  return 0
}

# Main validation logic
FAILED=0

if [ "$TOOL" = "all" ] || [ "$TOOL" = "cloud-trace" ]; then
  validate_cloud_trace || FAILED=1
  echo ""
fi

if [ "$TOOL" = "all" ] || [ "$TOOL" = "bigquery" ]; then
  validate_bigquery || FAILED=1
  echo ""
fi

if [ "$TOOL" = "all" ] || [ "$TOOL" = "agentops" ]; then
  validate_agentops || FAILED=1
  echo ""
fi

if [ "$TOOL" = "all" ] || [ "$TOOL" = "phoenix" ]; then
  validate_phoenix || FAILED=1
  echo ""
fi

if [ "$TOOL" = "all" ] || [ "$TOOL" = "weave" ]; then
  validate_weave || FAILED=1
  echo ""
fi

if [ $FAILED -eq 0 ]; then
  echo "✓ All validations passed!"
  exit 0
else
  echo "✗ Some validations failed"
  exit 1
fi
