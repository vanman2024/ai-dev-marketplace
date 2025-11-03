---
description: Estimate training and inference costs
argument-hint: [config-path]
allowed-tools: Bash, Read
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Calculate estimated costs for ML training and inference across different cloud GPU platforms (Modal, Lambda Labs, RunPod) based on training configuration.

Core Principles:
- Parse training configuration to extract compute requirements
- Calculate GPU hours needed based on dataset size and model
- Compare pricing across multiple platforms
- Provide cost breakdown and optimization recommendations

Phase 1: Configuration Discovery
Goal: Parse configuration and extract training parameters

Actions:
- Extract config path from $ARGUMENTS (default: config/training_config.yaml)
- Verify config file exists: !{bash test -f "$ARGUMENTS" && echo "Found" || echo "Not found"}
- Read configuration to extract: model size, dataset size, batch size, epochs, GPU preference
- Example: !{bash echo "Dataset samples: $(grep -i 'num_samples\|dataset_size' "$ARGUMENTS" | head -1)"}

Phase 2: Compute Requirements
Goal: Calculate GPU hours needed for training

Actions:
- Estimate training time based on model and dataset:
  - Small (<1B params): ~0.5-2h per 10k samples | Medium (1B-7B): ~2-8h | Large (7B-70B): ~8-40h
- Calculate total GPU hours: (samples / batch_size) * epochs * time_per_batch
- Factor in: gradient accumulation, evaluation frequency, checkpoint overhead, multi-GPU efficiency

Phase 3: Platform Pricing
Goal: Apply GPU pricing rates

Actions:
- GPU pricing per hour (2025): Modal (A10G: $1.10, A100-40GB: $3.50, A100-80GB: $5.00, H100: $8.00)
- Lambda Labs (A10: $0.60, A100-40GB: $1.10, A100-80GB: $1.30, H100: $2.00)
- RunPod (A10: $0.79, A100-40GB: $1.59, A100-80GB: $2.09, H100: $4.89)
- GPU selection: <7B params use A10 | 7B-13B use A100-40GB | 13B-70B use A100-80GB | >70B use H100

Phase 4: Cost Calculation
Goal: Calculate total training cost per platform

Actions:
- Calculate training cost: GPU_hours * price_per_hour
- Example: !{bash echo "Estimated GPU hours: 24" && echo "Modal A100-40GB: \$84.00 (24h * \$3.50)"}
- Add inference ($0.0001-0.001/request serverless, or same hourly for dedicated)
- Add storage (~$0.02/GB/month for checkpoints and datasets)
- Total cost = training + inference + storage

Phase 5: Cost Breakdown
Goal: Present detailed cost analysis

Actions:
- Display cost comparison table with columns: Platform | GPU Type | Training | Inference/month | Total
- Example: Lambda Labs A100-40GB: $26.40 training, $20 inference, $46.40 total
- Show percentage breakdown: GPU compute, storage, inference, network/egress
- Identify cheapest option and note availability/reliability trade-offs

Phase 6: Optimization Recommendations
Goal: Suggest cost-saving strategies

Actions:
- Recommend optimizations:
  - LoRA/QLoRA: 4-8x savings | Reduce batch size: smaller GPU tier | Gradient checkpointing: trade speed for memory
  - Spot instances: 30-70% savings | Cache preprocessed data | Mixed precision training | Dataset subsampling for experiments
- Provide cost-optimized config suggestions and estimate savings per optimization

Phase 7: Summary
Goal: Present final cost estimate with actionable insights

Actions:
- Display summary: Config path, model size/name, dataset samples, estimated GPU hours, recommended GPU type
- Show best value: [platform] at $[cost] monthly (including inference)
- List optimization opportunities: potential savings $XX/month (XX%), top 3 recommendations
- Next steps: 1) Review estimate and budget 2) Apply optimizations 3) Set up monitoring 4) Deploy with /ml-training:deploy-training
- Save estimate: !{bash mkdir -p estimates && echo "Cost estimate saved to estimates/cost-estimate-$(date +%Y%m%d).txt"}
