# Cloud GPU Configurations Skill

Comprehensive platform-specific configuration templates and GPU selection guides for Modal, Lambda Labs, and RunPod cloud GPU platforms.

## Overview

This skill provides:
- **GPU selection guides** for choosing the right GPU for your workload
- **Setup scripts** for configuring Modal, Lambda Labs, and RunPod environments
- **Configuration templates** for each platform
- **Real-world examples** demonstrating budget-friendly and production setups
- **Cost optimization strategies** for efficient GPU usage

## Structure

```
cloud-gpu-configs/
├── SKILL.md                      # Main skill documentation
├── README.md                     # This file
├── scripts/
│   ├── setup-modal.sh           # Interactive Modal setup (functional)
│   ├── setup-lambda.sh          # Interactive Lambda Labs setup (functional)
│   └── setup-runpod.sh          # Interactive RunPod setup (functional)
├── templates/
│   ├── modal_image.py           # Modal training template
│   ├── lambda_config.yaml       # Lambda Labs configuration template
│   └── runpod_config.json       # RunPod configuration template
└── examples/
    ├── modal-t4-setup.md        # Budget-friendly T4 example
    └── lambda-a10-setup.md      # Production A100 example
```

## Quick Start

### Modal Setup

```bash
# Run interactive setup
bash scripts/setup-modal.sh

# Files created:
# - modal_image.py (training app)
# - .modal_config (configuration)

# Test the setup
modal run modal_image.py
```

### Lambda Labs Setup

```bash
# Run interactive setup
bash scripts/setup-lambda.sh

# Files created:
# - lambda_config.yaml (instance config)
# - launch_instance.sh (launch script)
# - monitor_instance.sh (monitoring script)

# Launch instance
./launch_instance.sh
```

### RunPod Setup

```bash
# Run interactive setup
bash scripts/setup-runpod.sh

# Files created:
# - runpod_config.json (pod config)
# - launch_pod.sh (launch script)
# - monitor_pod.sh (monitoring script)
# - track_costs.sh (cost tracking script)

# Launch pod
./launch_pod.sh
```

## GPU Selection Guide

### Modal

| GPU | VRAM | Cost/hr | Best For |
|-----|------|---------|----------|
| T4 | 16GB | $0.20-0.40 | Small models, experimentation |
| L4 | 24GB | $0.40-0.60 | Modern alternative to T4 |
| A10 | 24GB | $0.60-0.80 | All-around training |
| L40S | 48GB | $0.80-1.20 | Inference, large models |
| A100 | 40/80GB | $1.50-2.00 | Standard training |
| H100 | 80GB | $3.00-4.00 | Cutting-edge performance |

### Lambda Labs

| Instance | GPUs | Cost/hr | Best For |
|----------|------|---------|----------|
| gpu_1x_a100_sxm4 | 1x A100 40GB | $1.10 | Standard training |
| gpu_1x_a100 | 1x A100 80GB | $1.29 | Large model training |
| gpu_1x_h100_pcie | 1x H100 80GB | $2.49 | Latest generation |
| gpu_8x_a100 | 8x A100 40GB | $8.80 | Distributed training |
| gpu_8x_h100_sxm5 | 8x H100 80GB | $19.92 | Maximum performance |

### RunPod

| GPU | VRAM | Spot Cost/hr | On-Demand Cost/hr | Best For |
|-----|------|--------------|-------------------|----------|
| RTX 3090 | 24GB | $0.30-0.40 | $0.60-0.80 | Budget training |
| RTX 4090 | 24GB | $0.40-0.60 | $0.80-1.20 | Best value |
| A6000 | 48GB | $0.75 | $1.50 | Large models |
| A100 80GB | 80GB | $1.50 | $3.00 | Production training |
| H100 80GB | 80GB | $3.00 | $6.00 | Premium performance |

## Scripts

### setup-modal.sh

**Features**:
- Installs Modal CLI if needed
- Prompts for Modal token
- GPU type selection (T4, L4, A10, L40S, A100, H100, B200)
- GPU count configuration (1-8)
- Python version selection
- Generates `modal_image.py` with full training template
- Creates `.modal_config` reference file

**Generated Files**:
- `modal_image.py`: Complete Modal app with GPU configuration, training function, and inference function
- `.modal_config`: Configuration reference with GPU type, count, and usage instructions

### setup-lambda.sh

**Features**:
- Installs Lambda CLI if needed
- Prompts for Lambda API key
- Instance type selection (1x/8x A100, H100)
- SSH key configuration
- Region selection (US West/East/South, Europe)
- Generates complete configuration and helper scripts

**Generated Files**:
- `lambda_config.yaml`: Comprehensive instance configuration
- `launch_instance.sh`: Executable script to launch instances
- `monitor_instance.sh`: GPU monitoring script

### setup-runpod.sh

**Features**:
- Installs runpodctl if needed
- Prompts for RunPod API key
- GPU type selection (RTX 3090/4090, A4000/A5000/A6000, A40, A100, H100)
- GPU count configuration
- Spot vs On-Demand pricing selection
- Container image selection (PyTorch, TensorFlow, Base)
- Generates pod configuration and helper scripts

**Generated Files**:
- `runpod_config.json`: Complete pod configuration
- `launch_pod.sh`: Executable script to launch pods
- `monitor_pod.sh`: Pod monitoring script
- `track_costs.sh`: Cost tracking script

## Templates

### modal_image.py

Full-featured Modal training template with:
- GPU configuration and fallback
- Training function with Hugging Face Transformers
- Inference function
- Volume mounting for persistence
- Weights & Biases integration
- Multi-GPU support
- Configurable hyperparameters

**Usage**:
```bash
# Replace placeholders
sed -i 's/{{GPU_TYPE}}/A100/g' modal_image.py
sed -i 's/{{PYTHON_VERSION}}/3.11/g' modal_image.py

# Run training
modal run modal_image.py --mode train

# Run inference
modal run modal_image.py --mode inference --text "Test input"
```

### lambda_config.yaml

Comprehensive Lambda Labs configuration with:
- Instance type and GPU specifications
- SSH key configuration
- Startup script with environment setup
- Persistent storage configuration
- Environment variables
- Cost optimization settings
- Monitoring configuration
- Backup configuration

### runpod_config.json

Complete RunPod configuration with:
- Pod specifications (GPU, CPU, RAM)
- Network port configuration
- Environment variables
- Startup script with dependencies
- Volume configuration
- Cost optimization settings
- Monitoring and alerts
- Security settings

## Examples

### modal-t4-setup.md

**Budget-friendly setup** using T4 GPUs ($0.20-0.40/hr):
- Complete BERT training example
- Memory optimization strategies
- Batch size recommendations
- Cost estimation (< $1 per training run)
- Troubleshooting guide
- When to upgrade to larger GPUs

### lambda-a10-setup.md

**Production-grade setup** using A100 GPUs ($1.29/hr):
- LLaMA fine-tuning example
- BFloat16 optimization for A100
- Distributed training with DeepSpeed
- Cost management strategies
- Persistent storage setup
- Comprehensive monitoring
- 8x A100 scaling guidance

## Cost Optimization Tips

### Modal
- Use L40S for inference (best cost/performance)
- Enable automatic upgrades (H100 → H200 free)
- Use GPU fallback for faster scheduling
- Avoid requesting >2 GPUs unless necessary

### Lambda Labs
- Single A100 most cost-effective for training
- Use persistent storage to avoid re-downloads
- Terminate instances when not in use
- Use tmux/screen for persistent sessions

### RunPod
- Use spot instances (50-80% savings)
- RTX 4090 excellent value for smaller models
- Enable auto-shutdown to prevent idle costs
- Monitor GPU utilization (aim for >80%)

## Integration

This skill integrates with:
- **framework-templates**: Provides GPU configs for training scripts
- **training-orchestrator**: Uses configs for distributed training
- **cost-estimator**: Pricing data for budget planning

## Troubleshooting

### Modal
- **OOM errors**: Reduce batch size, enable gradient checkpointing
- **Slow scheduling**: Use GPU fallback options
- **Connection issues**: Check Modal token validity

### Lambda Labs
- **Instance unavailable**: Check different regions or GPU types
- **SSH timeout**: Use tmux, configure SSH keepalive
- **Slow data loading**: Increase dataloader workers, cache datasets

### RunPod
- **Pod stuck**: Check spot instance availability
- **High costs**: Enable auto-shutdown, use spot instances
- **Connection lost**: Verify ports exposed, check pod status

## Resources

### Documentation
- Modal GPU Guide: https://modal.com/docs/guide/gpu
- Lambda Labs Docs: https://docs.lambda.ai/cloud
- RunPod Docs: https://docs.runpod.io

### GPU Specifications
- NVIDIA T4: https://www.nvidia.com/en-us/data-center/tesla-t4/
- NVIDIA A100: https://www.nvidia.com/en-us/data-center/a100/
- NVIDIA H100: https://www.nvidia.com/en-us/data-center/h100/

### Pricing
- Modal Pricing: https://modal.com/pricing
- Lambda Labs Pricing: https://lambdalabs.com/service/gpu-cloud
- RunPod Pricing: https://runpod.io/pricing

## Contributing

To add support for additional platforms:
1. Create `scripts/setup-{platform}.sh`
2. Add template to `templates/{platform}_config.*`
3. Create example in `examples/{platform}-{gpu}-setup.md`
4. Update SKILL.md with platform details

## License

Part of the ml-training plugin for Claude Code.
