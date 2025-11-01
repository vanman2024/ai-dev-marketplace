# Cloud GPU Configurations Skill

Platform-specific configuration templates and GPU selection guidance for Modal, Lambda Labs, and RunPod cloud platforms.

---
name: cloud-gpu-configs
description: Platform-specific configuration templates for Modal, Lambda Labs, and RunPod with GPU selection guides
allowed-tools: Bash, Read, Write, Edit
---

Use when:
- Configuring cloud GPU platforms for ML training
- Selecting appropriate GPU types for workloads
- Setting up Modal, Lambda Labs, or RunPod environments
- Optimizing cost vs performance for GPU compute
- Generating platform-specific configuration files

## GPU Selection Guide

### Modal GPUs

**Available GPUs**: T4, L4, A10, A100 (40GB/80GB), L40S, H100/H200, B200

**Selection Criteria**:
- **T4**: Budget-friendly, light inference ($0.20-0.40/hr)
- **L4**: Modern alternative to T4, better performance
- **A10**: Good all-around option, up to 4 GPUs (24GB VRAM)
- **L40S**: Excellent cost/performance for inference (48GB VRAM)
- **A100**: Training standard, 40GB or 80GB variants
- **H100/H200**: Cutting-edge performance, best software support
- **B200**: Latest Blackwell architecture, premium performance

**Multi-GPU Support**:
- T4, L4, L40S, A100, H100, H200, B200: Up to 8 GPUs
- A10: Up to 4 GPUs

### Lambda Labs GPUs

**Available Instances**:
- **1x A100 (40GB)**: Standard training, $1.10/hr
- **1x A100 (80GB)**: Large models, $1.29/hr
- **8x A100 (40GB)**: Distributed training, $8.80/hr
- **8x A100 (80GB)**: Large-scale training, $10.32/hr
- **1x H100**: Latest generation, $2.49/hr
- **8x H100**: Maximum performance, $19.92/hr

**Selection Criteria**:
- **Single A100**: Most common training workload
- **8x A100**: Multi-node distributed training
- **H100**: When cutting-edge performance needed

### RunPod GPUs

**Available GPUs**: RTX 3090, RTX 4090, A4000, A5000, A6000, A40, A100, H100

**Pricing Models**:
- **Spot Instances**: 50-80% cheaper, can be interrupted
- **On-Demand**: Guaranteed availability, higher cost

**Selection Criteria**:
- **RTX 3090/4090**: Consumer GPUs, excellent price/performance for small models
- **A4000/A5000**: Professional GPUs, stable for production
- **A6000**: 48GB VRAM, large model training
- **A100**: Industry standard, 40GB or 80GB
- **H100**: Premium performance

## Usage

### Setup Modal Environment

```bash
bash scripts/setup-modal.sh
```

Prompts for:
- Modal token
- Default GPU type
- Python version

Creates:
- `modal_image.py` - Configured Modal image
- `.modal_config` - Environment configuration

### Setup Lambda Labs Environment

```bash
bash scripts/setup-lambda.sh
```

Prompts for:
- Lambda API key
- SSH key path
- Preferred instance type

Creates:
- `lambda_config.yaml` - Instance configuration
- SSH configuration

### Setup RunPod Environment

```bash
bash scripts/setup-runpod.sh
```

Prompts for:
- RunPod API key
- GPU type preference
- Spot vs on-demand

Creates:
- `runpod_config.json` - Pod configuration
- Environment setup script

## Templates

### Modal Image Template (`templates/modal_image.py`)

Configurable Modal image with:
- GPU selection
- Python dependencies
- System packages
- CUDA configuration

### Lambda Config Template (`templates/lambda_config.yaml`)

Instance configuration with:
- Instance type selection
- SSH key configuration
- Startup scripts
- Volume mounting

### RunPod Config Template (`templates/runpod_config.json`)

Pod configuration with:
- GPU type and count
- Container image
- Volume configuration
- Network ports

## Examples

- `examples/modal-t4-setup.md` - Budget-friendly Modal setup with T4
- `examples/lambda-a10-setup.md` - Standard Lambda Labs A100 configuration

## Cost Optimization Tips

### Modal
- Use L40S for inference (best cost/performance)
- Enable automatic upgrades (H100 → H200) for no extra cost
- Use GPU fallback for faster scheduling
- Avoid requesting >2 GPUs unless necessary

### Lambda Labs
- Single A100 instances are most cost-effective for training
- Use persistent storage to avoid re-downloading datasets
- Terminate instances when not in use
- Consider 8x A100 only for true distributed workloads

### RunPod
- Use spot instances for interruptible workloads (50-80% savings)
- RTX 4090 offers excellent value for smaller models
- Use on-demand only for production/critical workloads
- Enable auto-shutdown to prevent idle costs

## Performance Considerations

### Memory-Bound Operations
- Consider total VRAM over compute power
- L40S (48GB) often better than A100 (40GB) for inference
- A100 80GB for large model training

### Compute-Bound Operations
- H100/H200 for maximum throughput
- B200 for latest architecture features
- Multiple A100s for distributed training

### Multi-GPU Training
- Use PyTorch DDP or DeepSpeed
- Ensure efficient data loading (multiple workers)
- Profile to avoid CPU bottlenecks
- Consider network bandwidth between GPUs

## Integration with ML Training

This skill integrates with other ml-training components:
- **framework-templates**: Provides GPU configs for generated training scripts
- **training-orchestrator**: Uses these configs for distributed training
- **cost-estimator**: Uses pricing data for budget planning
