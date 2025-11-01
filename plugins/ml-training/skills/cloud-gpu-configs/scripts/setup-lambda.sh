#!/bin/bash
# Setup Lambda Labs environment with GPU instance configuration

set -e

echo "=== Lambda Labs GPU Environment Setup ==="
echo ""

# Check if lambda CLI is installed
if ! command -v lambda &> /dev/null; then
    echo "Lambda CLI not found. Installing..."
    pip install lambda-cloud
fi

# Prompt for Lambda API key
echo "Enter your Lambda Labs API key (from https://cloud.lambdalabs.com/api-keys):"
read -r LAMBDA_API_KEY

if [ -z "$LAMBDA_API_KEY" ]; then
    echo "Error: Lambda API key is required"
    exit 1
fi

# Save API key to config
mkdir -p ~/.lambda_cloud
echo "$LAMBDA_API_KEY" > ~/.lambda_cloud/lambda_keys

# Instance type selection
echo ""
echo "Select Lambda Labs instance type:"
echo ""
echo "Single GPU Instances:"
echo "  1) gpu_1x_a100_sxm4       - 1x A100 40GB  (~\$1.10/hr)"
echo "  2) gpu_1x_a100            - 1x A100 80GB  (~\$1.29/hr)"
echo "  3) gpu_1x_h100_pcie       - 1x H100 80GB  (~\$2.49/hr)"
echo ""
echo "Multi-GPU Instances:"
echo "  4) gpu_8x_a100_80gb_sxm4  - 8x A100 80GB  (~\$10.32/hr)"
echo "  5) gpu_8x_a100            - 8x A100 40GB  (~\$8.80/hr)"
echo "  6) gpu_8x_h100_sxm5       - 8x H100 80GB  (~\$19.92/hr)"
echo ""
read -p "Enter choice (1-6): " INSTANCE_CHOICE

case $INSTANCE_CHOICE in
    1) INSTANCE_TYPE="gpu_1x_a100_sxm4"; GPU_COUNT=1; GPU_NAME="A100 40GB" ;;
    2) INSTANCE_TYPE="gpu_1x_a100"; GPU_COUNT=1; GPU_NAME="A100 80GB" ;;
    3) INSTANCE_TYPE="gpu_1x_h100_pcie"; GPU_COUNT=1; GPU_NAME="H100 80GB" ;;
    4) INSTANCE_TYPE="gpu_8x_a100_80gb_sxm4"; GPU_COUNT=8; GPU_NAME="A100 80GB" ;;
    5) INSTANCE_TYPE="gpu_8x_a100"; GPU_COUNT=8; GPU_NAME="A100 40GB" ;;
    6) INSTANCE_TYPE="gpu_8x_h100_sxm5"; GPU_COUNT=8; GPU_NAME="H100 80GB" ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# SSH key setup
echo ""
echo "SSH Key Configuration:"
read -p "Path to your SSH public key (default: ~/.ssh/id_rsa.pub): " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_rsa.pub}

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Error: SSH key not found at $SSH_KEY_PATH"
    echo "Generate one with: ssh-keygen -t rsa -b 4096"
    exit 1
fi

SSH_KEY_NAME=$(basename "$SSH_KEY_PATH" .pub)
SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")

# Region selection
echo ""
echo "Select region:"
echo "1) us-west-1 (California)"
echo "2) us-east-1 (Virginia)"
echo "3) us-south-1 (Texas)"
echo "4) europe-central-1 (Germany)"
echo ""
read -p "Enter choice (1-4, default: 1): " REGION_CHOICE
REGION_CHOICE=${REGION_CHOICE:-1}

case $REGION_CHOICE in
    1) REGION="us-west-1" ;;
    2) REGION="us-east-1" ;;
    3) REGION="us-south-1" ;;
    4) REGION="europe-central-1" ;;
    *) REGION="us-west-1" ;;
esac

# Create lambda_config.yaml
echo ""
echo "Creating Lambda Labs configuration..."

cat > lambda_config.yaml <<EOF
# Lambda Labs GPU Instance Configuration
# Generated on: $(date)

instance:
  type: $INSTANCE_TYPE
  gpu_count: $GPU_COUNT
  gpu_name: $GPU_NAME
  region: $REGION

ssh:
  key_name: $SSH_KEY_NAME
  key_path: $SSH_KEY_PATH
  user: ubuntu

startup_script: |
  #!/bin/bash
  # Instance startup script

  # Update system
  sudo apt-get update

  # Install NVIDIA drivers (if needed)
  # Usually pre-installed on Lambda instances

  # Install Python dependencies
  pip install --upgrade pip
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
  pip install transformers accelerate datasets wandb tensorboard

  # Setup workspace
  mkdir -p ~/workspace
  cd ~/workspace

  # Clone your training repo (optional)
  # git clone <your-repo-url>

  echo "Instance setup complete!"

filesystem:
  persistent_storage: true
  storage_size_gb: 512  # Adjust as needed

cost_optimization:
  auto_terminate_idle_minutes: 30  # Terminate after 30 min idle
  snapshot_before_terminate: true

notes: |
  Cost Optimization Tips:
  - Terminate instances when not in use
  - Use persistent storage to avoid re-downloading datasets
  - Single A100 instances are most cost-effective for training
  - Consider spot instances if available for additional savings
EOF

# Create instance launch script
cat > launch_instance.sh <<'EOF'
#!/bin/bash
# Launch Lambda Labs instance

set -e

# Load configuration
INSTANCE_TYPE=$(grep "type:" lambda_config.yaml | awk '{print $2}')
REGION=$(grep "region:" lambda_config.yaml | awk '{print $2}')
SSH_KEY_NAME=$(grep "key_name:" lambda_config.yaml | awk '{print $2}')

echo "Launching Lambda Labs instance..."
echo "Instance Type: $INSTANCE_TYPE"
echo "Region: $REGION"
echo ""

# Check instance availability
echo "Checking instance availability..."
lambda instance-types

# Launch instance
echo ""
echo "Launching instance..."
INSTANCE_ID=$(lambda instance launch \
    --instance-type "$INSTANCE_TYPE" \
    --region "$REGION" \
    --ssh-key-name "$SSH_KEY_NAME" \
    --file-system-size 512 \
    --format json | jq -r '.instance_id')

if [ -z "$INSTANCE_ID" ]; then
    echo "Error: Failed to launch instance"
    exit 1
fi

echo "Instance launched successfully!"
echo "Instance ID: $INSTANCE_ID"
echo ""

# Wait for instance to be ready
echo "Waiting for instance to be ready..."
sleep 30

# Get instance details
INSTANCE_IP=$(lambda instance list --format json | jq -r ".[] | select(.id == \"$INSTANCE_ID\") | .ip")

echo ""
echo "Instance ready!"
echo "IP Address: $INSTANCE_IP"
echo ""
echo "Connect with: ssh ubuntu@$INSTANCE_IP"
echo ""
echo "To terminate: lambda instance terminate $INSTANCE_ID"
EOF

chmod +x launch_instance.sh

# Create monitoring script
cat > monitor_instance.sh <<'EOF'
#!/bin/bash
# Monitor Lambda Labs instance GPU usage

# List instances
echo "=== Lambda Labs Instances ==="
lambda instance list

echo ""
echo "=== GPU Usage ==="
echo "Connect to instance and run: nvidia-smi"
EOF

chmod +x monitor_instance.sh

echo ""
echo "✅ Lambda Labs setup complete!"
echo ""
echo "Files created:"
echo "  - lambda_config.yaml (instance configuration)"
echo "  - launch_instance.sh (launch instance script)"
echo "  - monitor_instance.sh (monitoring script)"
echo ""
echo "GPU Configuration: $GPU_NAME x$GPU_COUNT"
echo "Region: $REGION"
echo ""
echo "Next steps:"
echo "  1. Review lambda_config.yaml"
echo "  2. Launch instance: ./launch_instance.sh"
echo "  3. Connect: ssh ubuntu@<instance-ip>"
echo "  4. Monitor: ./monitor_instance.sh"
echo ""
echo "Documentation: https://docs.lambda.ai/cloud"
