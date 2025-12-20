#!/bin/bash
# Expose ADK agent via A2A protocol
# Usage: bash expose-agent.sh --platform <cloud-run|agent-engine|gke> --region <region>

set -e

# Parse arguments
PLATFORM="cloud-run"
REGION="us-central1"
AGENT_NAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --agent-name)
      AGENT_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$AGENT_NAME" ]; then
  echo "Error: --agent-name is required"
  echo "Usage: bash expose-agent.sh --agent-name <name> --platform <cloud-run|agent-engine|gke> --region <region>"
  exit 1
fi

echo "Exposing agent: $AGENT_NAME"
echo "Platform: $PLATFORM"
echo "Region: $REGION"

# Generate Agent Card
echo "Generating Agent Card..."
bash "$(dirname "$0")/generate-agent-card.sh" --name "$AGENT_NAME" --output "/.well-known/agent.json"

# Deploy based on platform
case $PLATFORM in
  cloud-run)
    echo "Deploying to Cloud Run..."
    gcloud run deploy "$AGENT_NAME" \
      --source . \
      --region "$REGION" \
      --allow-unauthenticated \
      --set-env-vars "A2A_ENABLED=true"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$AGENT_NAME" --region "$REGION" --format="value(status.url)")
    echo "Agent exposed at: $SERVICE_URL"
    echo "Agent Card: $SERVICE_URL/.well-known/agent.json"
    ;;

  agent-engine)
    echo "Deploying to Agent Engine..."
    adk deploy --platform agent-engine --agent "$AGENT_NAME"
    ;;

  gke)
    echo "Deploying to GKE..."
    kubectl apply -f deployment-config.yaml
    ;;

  *)
    echo "Unknown platform: $PLATFORM"
    exit 1
    ;;
esac

echo "Agent successfully exposed via A2A protocol"
