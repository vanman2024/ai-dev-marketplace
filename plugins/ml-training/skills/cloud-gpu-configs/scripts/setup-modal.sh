#!/bin/bash
# Setup Modal environment with GPU configuration

set -e

echo "=== Modal GPU Environment Setup ==="
echo ""

# Check if modal is installed
if ! command -v modal &> /dev/null; then
    echo "Modal CLI not found. Installing..."
    pip install modal
fi

# Prompt for Modal token
echo "Enter your Modal token (from https://modal.com/settings):"
read -r MODAL_TOKEN

if [ -z "$MODAL_TOKEN" ]; then
    echo "Error: Modal token is required"
    exit 1
fi

# Set Modal token
modal token set --token-id "$MODAL_TOKEN"

# GPU selection
echo ""
echo "Select default GPU type:"
echo "1) T4 (Budget-friendly, light inference)"
echo "2) L4 (Modern T4 alternative)"
echo "3) A10 (Good all-around, up to 4 GPUs)"
echo "4) L40S (Excellent inference cost/performance, 48GB)"
echo "5) A100 (Standard training, auto 40/80GB)"
echo "6) A100-80GB (Explicit 80GB for large models)"
echo "7) H100 (Cutting-edge, may upgrade to H200)"
echo "8) H100! (Explicit H100, no auto-upgrade)"
echo ""
read -p "Enter choice (1-8): " GPU_CHOICE

case $GPU_CHOICE in
    1) GPU_TYPE="T4" ;;
    2) GPU_TYPE="L4" ;;
    3) GPU_TYPE="A10" ;;
    4) GPU_TYPE="L40S" ;;
    5) GPU_TYPE="A100" ;;
    6) GPU_TYPE="A100-80GB" ;;
    7) GPU_TYPE="H100" ;;
    8) GPU_TYPE="H100!" ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# GPU count
echo ""
read -p "Number of GPUs (1-8, or 1-4 for A10): " GPU_COUNT

if [ -z "$GPU_COUNT" ]; then
    GPU_COUNT=1
fi

# Validate GPU count
if [ "$GPU_TYPE" = "A10" ] && [ "$GPU_COUNT" -gt 4 ]; then
    echo "Error: A10 supports maximum 4 GPUs"
    exit 1
fi

if [ "$GPU_COUNT" -gt 8 ]; then
    echo "Error: Maximum 8 GPUs supported"
    exit 1
fi

# Python version
echo ""
read -p "Python version (default: 3.11): " PYTHON_VERSION
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

# Create modal_image.py from template
echo ""
echo "Creating Modal image configuration..."

cat > modal_image.py <<EOF
"""
Modal GPU Image Configuration
Generated on: $(date)
GPU: $GPU_TYPE x$GPU_COUNT
Python: $PYTHON_VERSION
"""

import modal

# Create Modal app
app = modal.App("ml-training-app")

# Define GPU configuration
GPU_CONFIG = "$GPU_TYPE"
if [ $GPU_COUNT -gt 1 ]; then
    GPU_CONFIG="${GPU_TYPE}:${GPU_COUNT}"
fi

# Create image with ML dependencies
image = (
    modal.Image.debian_slim(python_version="$PYTHON_VERSION")
    .pip_install(
        "torch",
        "transformers",
        "accelerate",
        "datasets",
        "wandb",
        "tensorboard",
        "numpy",
        "pandas",
        "scikit-learn",
        "matplotlib",
        "seaborn",
    )
    .apt_install("git", "wget", "curl")
)

# Example function with GPU
@app.function(
    gpu="$GPU_CONFIG",
    image=image,
    timeout=3600,  # 1 hour
    memory=8192,   # 8GB RAM (adjust as needed)
)
def train_model():
    """Example training function with GPU"""
    import torch

    print(f"GPU Available: {torch.cuda.is_available()}")
    print(f"GPU Count: {torch.cuda.device_count()}")

    if torch.cuda.is_available():
        for i in range(torch.cuda.device_count()):
            print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
            print(f"  Memory: {torch.cuda.get_device_properties(i).total_memory / 1e9:.2f} GB")

    # Your training code here
    pass

# Example function with GPU fallback
@app.function(
    gpu=["$GPU_TYPE", "A100", "L40S"],  # Fallback options
    image=image,
    timeout=3600,
)
def train_with_fallback():
    """Training function with GPU fallback for faster scheduling"""
    import torch
    print(f"Running on: {torch.cuda.get_device_name(0)}")
    # Your training code here
    pass

# Local entrypoint
@app.local_entrypoint()
def main():
    """Run training job"""
    print("Starting training...")
    train_model.remote()
    print("Training complete!")

# To run: modal run modal_image.py
EOF

# Create .modal_config for reference
cat > .modal_config <<EOF
# Modal Configuration
# Generated on: $(date)

MODAL_GPU_TYPE=$GPU_TYPE
MODAL_GPU_COUNT=$GPU_COUNT
MODAL_PYTHON_VERSION=$PYTHON_VERSION
MODAL_APP_NAME=ml-training-app

# Usage:
# modal run modal_image.py
# modal deploy modal_image.py

# Cost Optimization:
# - Use L40S for inference (best cost/performance)
# - Enable GPU fallback for faster scheduling
# - Avoid >2 GPUs unless necessary
# - Consider automatic upgrades (H100 -> H200)
EOF

echo ""
echo "✅ Modal setup complete!"
echo ""
echo "Files created:"
echo "  - modal_image.py (Modal app with GPU configuration)"
echo "  - .modal_config (configuration reference)"
echo ""
echo "GPU Configuration: $GPU_TYPE x$GPU_COUNT"
echo ""
echo "Next steps:"
echo "  1. Edit modal_image.py to add your training code"
echo "  2. Test locally: modal run modal_image.py"
echo "  3. Deploy: modal deploy modal_image.py"
echo ""
echo "Documentation: https://modal.com/docs/guide/gpu"
