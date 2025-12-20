#!/bin/bash

# Setup Weave (W&B) for Google ADK agents
# Usage: ./setup-weave.sh <entity> <project>

set -e

ENTITY="$1"
PROJECT="$2"

if [ -z "$WANDB_API_KEY" ]; then
  echo "Error: WANDB_API_KEY environment variable not set"
  echo ""
  echo "Get your API key from:"
  echo "  https://wandb.ai/authorize"
  echo ""
  echo "Then run:"
  echo "  export WANDB_API_KEY=your_api_key_here"
  echo "  $0 <entity> <project>"
  exit 1
fi

if [ -z "$ENTITY" ] || [ -z "$PROJECT" ]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 <entity> <project>"
  echo ""
  echo "Arguments:"
  echo "  entity  - W&B entity name (visible in Teams sidebar)"
  echo "  project - W&B project name"
  exit 1
fi

echo "Setting up Weave..."
echo "  Entity: $ENTITY"
echo "  Project: $PROJECT"

# Install Weave dependencies
echo "Installing Weave packages..."
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-http

# Test configuration
echo "Testing Weave configuration..."
python3 -c "
import os
import sys
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
import base64

try:
    wandb_api_key = os.environ['WANDB_API_KEY']
    entity = '$ENTITY'
    project = '$PROJECT'

    auth_string = f'api:{wandb_api_key}'
    encoded_auth = base64.b64encode(auth_string.encode()).decode()

    exporter = OTLPSpanExporter(
        endpoint='https://trace.wandb.ai/otel/v1/traces',
        headers={
            'Authorization': f'Basic {encoded_auth}',
            'project_id': f'{entity}/{project}'
        }
    )

    provider = TracerProvider()
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    trace.set_tracer_provider(provider)

    print('✓ Weave tracer configured successfully!')
except Exception as e:
    print(f'Error configuring Weave: {e}', file=sys.stderr)
    sys.exit(1)
"

echo ""
echo "✓ Weave setup complete!"
echo ""
echo "Add to your agent code (BEFORE ADK imports):"
cat <<EOF
import os
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
import base64

wandb_api_key = os.environ["WANDB_API_KEY"]
entity = "$ENTITY"
project = "$PROJECT"

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

# Now import ADK
from google.adk.app import App
app = App(root_agent=my_agent)
EOF
echo ""
echo "View traces at:"
echo "  https://wandb.ai/$ENTITY/$PROJECT"
