#!/bin/bash
# Setup RunPod environment with GPU pod configuration

set -e

echo "=== RunPod GPU Environment Setup ==="
echo ""

# Check if runpodctl is installed
if ! command -v runpodctl &> /dev/null; then
    echo "RunPod CLI not found. Installing..."
    wget -qO- https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-linux-amd64 -O /tmp/runpodctl
    chmod +x /tmp/runpodctl
    sudo mv /tmp/runpodctl /usr/local/bin/runpodctl
fi

# Prompt for RunPod API key
echo "Enter your RunPod API key (from https://runpod.io/console/user/settings):"
read -r RUNPOD_API_KEY

if [ -z "$RUNPOD_API_KEY" ]; then
    echo "Error: RunPod API key is required"
    exit 1
fi

# Configure runpodctl
runpodctl config --apiKey "$RUNPOD_API_KEY"

# GPU selection
echo ""
echo "Select GPU type:"
echo ""
echo "Consumer GPUs (Best Price/Performance):"
echo "  1) RTX 3090      - 24GB VRAM  (~\$0.30-0.40/hr spot)"
echo "  2) RTX 4090      - 24GB VRAM  (~\$0.40-0.60/hr spot)"
echo ""
echo "Professional GPUs:"
echo "  3) A4000         - 16GB VRAM  (~\$0.35/hr spot)"
echo "  4) A5000         - 24GB VRAM  (~\$0.50/hr spot)"
echo "  5) A6000         - 48GB VRAM  (~\$0.75/hr spot)"
echo ""
echo "Data Center GPUs:"
echo "  6) A40           - 48GB VRAM  (~\$0.60/hr spot)"
echo "  7) A100 SXM      - 80GB VRAM  (~\$1.50/hr spot)"
echo "  8) A100 PCIe     - 80GB VRAM  (~\$1.30/hr spot)"
echo "  9) H100 SXM      - 80GB VRAM  (~\$3.00/hr spot)"
echo "  10) H100 PCIe    - 80GB VRAM  (~\$2.75/hr spot)"
echo ""
read -p "Enter choice (1-10): " GPU_CHOICE

case $GPU_CHOICE in
    1) GPU_TYPE="RTX 3090"; GPU_ID="NVIDIA GeForce RTX 3090"; VRAM="24GB" ;;
    2) GPU_TYPE="RTX 4090"; GPU_ID="NVIDIA GeForce RTX 4090"; VRAM="24GB" ;;
    3) GPU_TYPE="A4000"; GPU_ID="NVIDIA RTX A4000"; VRAM="16GB" ;;
    4) GPU_TYPE="A5000"; GPU_ID="NVIDIA RTX A5000"; VRAM="24GB" ;;
    5) GPU_TYPE="A6000"; GPU_ID="NVIDIA RTX A6000"; VRAM="48GB" ;;
    6) GPU_TYPE="A40"; GPU_ID="NVIDIA A40"; VRAM="48GB" ;;
    7) GPU_TYPE="A100 SXM"; GPU_ID="NVIDIA A100-SXM4-80GB"; VRAM="80GB" ;;
    8) GPU_TYPE="A100 PCIe"; GPU_ID="NVIDIA A100-PCIE-80GB"; VRAM="80GB" ;;
    9) GPU_TYPE="H100 SXM"; GPU_ID="NVIDIA H100 80GB HBM3"; VRAM="80GB" ;;
    10) GPU_TYPE="H100 PCIe"; GPU_ID="NVIDIA H100 PCIe"; VRAM="80GB" ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# GPU count
echo ""
read -p "Number of GPUs (1-8, default: 1): " GPU_COUNT
GPU_COUNT=${GPU_COUNT:-1}

if [ "$GPU_COUNT" -gt 8 ]; then
    echo "Error: Maximum 8 GPUs supported"
    exit 1
fi

# Pricing model
echo ""
echo "Select pricing model:"
echo "1) Spot (50-80% cheaper, can be interrupted)"
echo "2) On-Demand (guaranteed availability, higher cost)"
echo ""
read -p "Enter choice (1-2, default: 1): " PRICING_CHOICE
PRICING_CHOICE=${PRICING_CHOICE:-1}

case $PRICING_CHOICE in
    1) PRICING_MODEL="spot"; PRICING_DESC="Spot (interruptible)" ;;
    2) PRICING_MODEL="on-demand"; PRICING_DESC="On-Demand (guaranteed)" ;;
    *) PRICING_MODEL="spot"; PRICING_DESC="Spot (interruptible)" ;;
esac

# Container image
echo ""
echo "Select container image:"
echo "1) PyTorch (runpod/pytorch:latest)"
echo "2) TensorFlow (runpod/tensorflow:latest)"
echo "3) Custom base (runpod/base:latest)"
echo ""
read -p "Enter choice (1-3, default: 1): " IMAGE_CHOICE
IMAGE_CHOICE=${IMAGE_CHOICE:-1}

case $IMAGE_CHOICE in
    1) CONTAINER_IMAGE="runpod/pytorch:latest"; FRAMEWORK="PyTorch" ;;
    2) CONTAINER_IMAGE="runpod/tensorflow:latest"; FRAMEWORK="TensorFlow" ;;
    3) CONTAINER_IMAGE="runpod/base:latest"; FRAMEWORK="Base" ;;
    *) CONTAINER_IMAGE="runpod/pytorch:latest"; FRAMEWORK="PyTorch" ;;
esac

# Create runpod_config.json
echo ""
echo "Creating RunPod configuration..."

cat > runpod_config.json <<EOF
{
  "pod_config": {
    "name": "ml-training-pod",
    "gpu_type": "$GPU_TYPE",
    "gpu_id": "$GPU_ID",
    "gpu_count": $GPU_COUNT,
    "vram": "$VRAM",
    "pricing_model": "$PRICING_MODEL",
    "container_image": "$CONTAINER_IMAGE",
    "framework": "$FRAMEWORK"
  },
  "compute": {
    "cpu_count": $((GPU_COUNT * 8)),
    "ram_gb": $((GPU_COUNT * 32)),
    "container_disk_gb": 50,
    "volume_disk_gb": 100
  },
  "network": {
    "ports": [
      {
        "port": 8888,
        "protocol": "http",
        "description": "Jupyter Notebook"
      },
      {
        "port": 6006,
        "protocol": "http",
        "description": "TensorBoard"
      },
      {
        "port": 22,
        "protocol": "tcp",
        "description": "SSH"
      }
    ]
  },
  "environment": {
    "JUPYTER_PASSWORD": "training123",
    "WANDB_API_KEY": "",
    "HF_TOKEN": ""
  },
  "startup_script": "#!/bin/bash\n# Install additional dependencies\npip install --upgrade pip\npip install transformers accelerate datasets wandb tensorboard\n\n# Start Jupyter\njupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='' &\n\necho 'Pod setup complete!'\n",
  "cost_optimization": {
    "auto_stop_idle_minutes": 30,
    "use_spot_instances": $([ "$PRICING_MODEL" = "spot" ] && echo "true" || echo "false"),
    "max_bid_price_per_gpu": null
  },
  "notes": "Cost Optimization: Use spot instances for 50-80% savings. RTX 4090 excellent value for smaller models. Enable auto-shutdown to prevent idle costs."
}
EOF

# Create pod launch script
cat > launch_pod.sh <<'EOF'
#!/bin/bash
# Launch RunPod GPU pod

set -e

# Load configuration
GPU_TYPE=$(jq -r '.pod_config.gpu_type' runpod_config.json)
GPU_COUNT=$(jq -r '.pod_config.gpu_count' runpod_config.json)
IMAGE=$(jq -r '.pod_config.container_image' runpod_config.json)
PRICING=$(jq -r '.pod_config.pricing_model' runpod_config.json)

echo "Launching RunPod..."
echo "GPU: $GPU_TYPE x$GPU_COUNT"
echo "Image: $IMAGE"
echo "Pricing: $PRICING"
echo ""

# Check GPU availability
echo "Checking GPU availability..."
runpodctl get gpu

echo ""
read -p "Continue with launch? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Launch cancelled"
    exit 0
fi

# Launch pod (adjust parameters as needed)
echo ""
echo "Launching pod..."

POD_ID=$(runpodctl create pod \
    --name "ml-training-pod" \
    --gpuType "$GPU_TYPE" \
    --imageName "$IMAGE" \
    --containerDiskSize 50 \
    --volumeSize 100 \
    --ports "8888/http,6006/http,22/tcp" \
    $([ "$PRICING" = "spot" ] && echo "--spot" || echo "") \
    --env "JUPYTER_PASSWORD=training123" \
    --startupScript "pip install transformers accelerate datasets wandb" \
    | grep -oP 'Pod ID: \K[a-z0-9-]+')

if [ -z "$POD_ID" ]; then
    echo "Error: Failed to launch pod"
    exit 1
fi

echo ""
echo "✅ Pod launched successfully!"
echo "Pod ID: $POD_ID"
echo ""

# Wait for pod to be ready
echo "Waiting for pod to be ready..."
sleep 30

# Get pod details
runpodctl get pod "$POD_ID"

echo ""
echo "Access your pod:"
echo "  - SSH: runpodctl ssh $POD_ID"
echo "  - Jupyter: Check pod details for URL"
echo "  - TensorBoard: Check pod details for URL"
echo ""
echo "To stop pod: runpodctl stop pod $POD_ID"
echo "To terminate pod: runpodctl remove pod $POD_ID"
EOF

chmod +x launch_pod.sh

# Create monitoring script
cat > monitor_pod.sh <<'EOF'
#!/bin/bash
# Monitor RunPod GPU usage

echo "=== RunPod Pods ==="
runpodctl get pod

echo ""
echo "=== GPU Availability ==="
runpodctl get gpu

echo ""
echo "To monitor specific pod GPU usage:"
echo "  runpodctl ssh <pod-id>"
echo "  nvidia-smi"
EOF

chmod +x monitor_pod.sh

# Create cost tracking script
cat > track_costs.sh <<'EOF'
#!/bin/bash
# Track RunPod costs

echo "=== RunPod Cost Tracking ==="
echo ""

# Get all pods
PODS=$(runpodctl get pod --json | jq -r '.[] | .id')

TOTAL_COST=0

for POD_ID in $PODS; do
    echo "Pod: $POD_ID"
    POD_INFO=$(runpodctl get pod "$POD_ID" --json)

    STATUS=$(echo "$POD_INFO" | jq -r '.status')
    RUNTIME=$(echo "$POD_INFO" | jq -r '.runtime_seconds')
    COST_PER_HR=$(echo "$POD_INFO" | jq -r '.cost_per_hour')

    HOURS=$(echo "scale=2; $RUNTIME / 3600" | bc)
    POD_COST=$(echo "scale=2; $HOURS * $COST_PER_HR" | bc)

    echo "  Status: $STATUS"
    echo "  Runtime: ${HOURS}h"
    echo "  Cost: \$$POD_COST"
    echo ""

    TOTAL_COST=$(echo "$TOTAL_COST + $POD_COST" | bc)
done

echo "Total Cost: \$$TOTAL_COST"
EOF

chmod +x track_costs.sh

echo ""
echo "✅ RunPod setup complete!"
echo ""
echo "Files created:"
echo "  - runpod_config.json (pod configuration)"
echo "  - launch_pod.sh (launch pod script)"
echo "  - monitor_pod.sh (monitoring script)"
echo "  - track_costs.sh (cost tracking script)"
echo ""
echo "GPU Configuration: $GPU_TYPE x$GPU_COUNT"
echo "Pricing Model: $PRICING_DESC"
echo "Framework: $FRAMEWORK"
echo ""
echo "Next steps:"
echo "  1. Review runpod_config.json"
echo "  2. Set WANDB_API_KEY in environment if using Weights & Biases"
echo "  3. Launch pod: ./launch_pod.sh"
echo "  4. Monitor: ./monitor_pod.sh"
echo "  5. Track costs: ./track_costs.sh"
echo ""
echo "Documentation: https://docs.runpod.io"
