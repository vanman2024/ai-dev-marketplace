# ML Training Cost Calculator

Production-ready cost estimation tools for ML training and inference across Modal, Lambda Labs, and RunPod cloud GPU platforms.

## Overview

The cost-calculator skill provides functional scripts to estimate GPU costs, compare platforms, and optimize ML budgets. Use these tools to make data-driven decisions about GPU selection, platform choice, and cost optimizations.

## Quick Start

### Estimate Training Cost

```bash
bash scripts/estimate-training-cost.sh \
  --model-size 7B \
  --dataset-size 10000 \
  --epochs 3 \
  --gpu t4 \
  --platform modal \
  --peft yes
```

Output:
```json
{
  "model": "7B",
  "estimated_hours": 3.47,
  "cost_breakdown": {
    "total_cost": 2.10
  }
}
```

### Estimate Inference Cost

```bash
bash scripts/estimate-inference-cost.sh \
  --requests-per-day 1000 \
  --avg-latency 2 \
  --gpu t4 \
  --platform modal \
  --deployment serverless
```

Output:
```json
{
  "monthly_cost": 9.90,
  "cost_per_request": 0.00033
}
```

### Compare Platforms

```bash
bash scripts/compare-platforms.sh \
  --training-hours 4 \
  --gpu-type a100-40gb
```

Output:
```
Winner: Lambda Labs ($5.16)
Savings: $3.24 (38.6% vs Modal)
```

## Features

### Functional Scripts
- **estimate-training-cost.sh** - Calculate training costs with PEFT/mixed precision
- **estimate-inference-cost.sh** - Estimate serverless vs dedicated inference costs
- **calculate-gpu-hours.sh** - Convert tokens to GPU hours
- **compare-platforms.sh** - Compare Modal, Lambda, RunPod pricing

### Templates
- **cost-breakdown.json** - Complete project budget template
- **platform-pricing.yaml** - Up-to-date GPU pricing data

### Examples
- **training-cost-estimate.md** - Real-world training cost analysis
- **inference-cost-estimate.md** - Production inference cost breakdown

## Platform Pricing

### Modal (Serverless)
- T4: $0.59/hr
- A100 40GB: $2.10/hr
- Free: $30/month + $50K startup credits

### Lambda Labs (On-Demand)
- A10: $0.31/hr (cheapest)
- A100 40GB: $1.29/hr
- Free: None

### RunPod (Per-Minute)
- T4: $0.60/hr
- A100 40GB: $2.00/hr
- Free: None

## Cost Optimizations

### PEFT/LoRA
- **Savings:** 50-90% training cost reduction
- **Speedup:** 4x faster training
- **Use for:** 7B+ models

```bash
# With PEFT: $2.48 for 7B model
--peft yes

# Without PEFT: $12.40 for 7B model
--peft no
```

### Mixed Precision
- **Savings:** 50% training cost reduction
- **Speedup:** 2x faster
- **Use for:** All modern GPUs

```bash
# Enable FP16/BF16 (default)
--mixed-precision yes
```

### Batch Inference
- **Savings:** 85-90% inference cost reduction
- **Trade-off:** 10-30 second latency increase
- **Use for:** Background jobs, non-realtime

```bash
# Batch 10 requests together
--batch-inference yes
```

## Real-World Examples

### Training 7B Model
- Dataset: 10,000 samples
- Epochs: 3
- GPU: Lambda A10 with PEFT
- **Cost: $0.62**
- Time: 1.3 hours

### Inference (1K requests/day)
- Model: 7B classifier
- Latency: 2 seconds
- GPU: Modal T4 serverless
- **Cost: $9.90/month**
- Cost per request: $0.00033

## Dependencies

```bash
# Install required tools
sudo apt-get install -y bc jq

# Optional: YAML processing
pip install yq
```

## Usage Patterns

### Development Phase
```bash
# Estimate multiple training runs
for i in {1..4}; do
  bash scripts/estimate-training-cost.sh \
    --model-size 7B \
    --dataset-size 10000 \
    --gpu a10 \
    --platform lambda \
    --peft yes
done
```

### Production Budgeting
```bash
# Calculate full project cost
TRAINING_COST=$(bash scripts/estimate-training-cost.sh --model-size 7B --dataset-size 10000 --gpu a10 --platform lambda --peft yes --output json | jq -r '.cost_breakdown.total_cost')

INFERENCE_COST=$(bash scripts/estimate-inference-cost.sh --requests-per-day 1000 --avg-latency 2 --gpu t4 --platform modal --deployment serverless --output json | jq -r '.cost_breakdown.monthly_cost')

TOTAL=$(echo "$TRAINING_COST + $INFERENCE_COST" | bc)
echo "Total monthly cost: \$$TOTAL"
```

### Platform Comparison
```bash
# Compare all platforms for training job
bash scripts/compare-platforms.sh \
  --training-hours 4 \
  --gpu-type a100-40gb \
  --output markdown > platform-comparison.md
```

## Cost Optimization Checklist

- [ ] Enable PEFT for 7B+ models (50-90% savings)
- [ ] Enable mixed precision training (2x speedup)
- [ ] Use Lambda A10 for training ($0.31/hr vs Modal T4 $0.59/hr)
- [ ] Use Modal serverless for <4.5K inference requests/day
- [ ] Use batch inference for background jobs (85% savings)
- [ ] Apply for Modal startup credits ($50K free)
- [ ] Monitor actual vs estimated costs
- [ ] Switch to dedicated at >50K requests/day

## Break-even Analysis

### Training
- **Small models (<1B):** T4 sufficient
- **Medium models (1B-7B):** Lambda A10 cheapest
- **Large models (7B-70B):** A100 with PEFT

### Inference
- **<4.5K req/day:** Modal serverless
- **4.5K-50K req/day:** Modal serverless or batch
- **>50K req/day:** Dedicated Lambda A10

## Validation

All scripts include:
- Input validation
- Error handling
- Multiple output formats (JSON/text)
- Real pricing data (updated 2025-11-01)

## Integration

Use with ml-training commands:
```bash
# From ml-training command
COST=$(bash plugins/ml-training/skills/cost-calculator/scripts/estimate-training-cost.sh \
  --model-size 7B \
  --dataset-size 10000 \
  --gpu t4 \
  --platform modal \
  --peft yes \
  --output json | jq -r '.cost_breakdown.total_cost')

echo "Estimated training cost: \$$COST"
```

## Support

- Platform pricing: See `templates/platform-pricing.yaml`
- Training examples: See `examples/training-cost-estimate.md`
- Inference examples: See `examples/inference-cost-estimate.md`
- Cost templates: See `templates/cost-breakdown.json`

---

**Version:** 1.0.0
**Last Updated:** 2025-11-01
**Platforms:** Modal, Lambda Labs, RunPod
**GPU Types:** T4, L4, A10, A100 (40GB/80GB), H100, H200, B200
