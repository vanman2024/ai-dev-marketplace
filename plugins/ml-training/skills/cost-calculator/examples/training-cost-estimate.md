# Training Cost Estimate Example

## Scenario: Fine-tuning Llama 2 7B for Trade Industry Classification

### Project Details

**Model:**
- Base Model: Llama 2 7B
- Task: Multi-class classification (10 trade categories)
- Method: LoRA/PEFT fine-tuning

**Dataset:**
- Training samples: 10,000
- Validation samples: 2,000
- Average tokens per sample: 500
- Total training tokens: 10,000 × 500 × 3 epochs = 15M tokens

**Training Configuration:**
- Epochs: 3
- Batch size: 16 (auto-calculated)
- Learning rate: 2e-5
- LoRA rank: 16
- Mixed precision: FP16

---

## Cost Calculation

### Option 1: Modal T4 (with PEFT)

```bash
bash scripts/estimate-training-cost.sh \
  --model-size 7B \
  --dataset-size 10000 \
  --epochs 3 \
  --gpu t4 \
  --platform modal \
  --peft yes \
  --mixed-precision yes
```

**Results:**
```json
{
  "model": "7B",
  "gpu": "T4",
  "platform": "Modal",
  "peft_enabled": "yes",
  "mixed_precision": "yes",
  "throughput_tokens_per_sec": 1200,
  "estimated_hours": 3.47,
  "cost_breakdown": {
    "compute_cost": 2.05,
    "storage_cost": 0.05,
    "total_cost": 2.10
  }
}
```

**Analysis:**
- Training Time: 3.47 hours
- Total Cost: $2.10
- Cost per epoch: $0.70
- Throughput: 1,200 tokens/sec (T4 with PEFT + mixed precision)

---

### Option 2: Lambda A10 (with PEFT)

```bash
bash scripts/estimate-training-cost.sh \
  --model-size 7B \
  --dataset-size 10000 \
  --epochs 3 \
  --gpu a10 \
  --platform lambda \
  --peft yes \
  --mixed-precision yes
```

**Results:**
```json
{
  "model": "7B",
  "gpu": "A10",
  "platform": "Lambda",
  "peft_enabled": "yes",
  "estimated_hours": 1.30,
  "cost_breakdown": {
    "compute_cost": 0.40,
    "storage_cost": 0.05,
    "total_cost": 0.45
  }
}
```

**Analysis:**
- Training Time: 1.30 hours
- Total Cost: $0.45 (Lambda rounds up to 2 hours = $0.62)
- Cost per epoch: $0.21
- Throughput: 3,200 tokens/sec (A10 with PEFT + mixed precision)
- **CHEAPEST OPTION** ✅

---

### Option 3: Modal A100 40GB (with PEFT)

```bash
bash scripts/estimate-training-cost.sh \
  --model-size 7B \
  --dataset-size 10000 \
  --epochs 3 \
  --gpu a100-40gb \
  --platform modal \
  --peft yes \
  --mixed-precision yes
```

**Results:**
```json
{
  "model": "7B",
  "gpu": "A100-40GB",
  "platform": "Modal",
  "estimated_hours": 0.65,
  "cost_breakdown": {
    "compute_cost": 1.37,
    "storage_cost": 0.05,
    "total_cost": 1.42
  }
}
```

**Analysis:**
- Training Time: 0.65 hours (39 minutes)
- Total Cost: $1.42
- Cost per epoch: $0.47
- Throughput: 6,400 tokens/sec (A100 with PEFT + mixed precision)
- **FASTEST OPTION** ✅

---

## Platform Comparison

### Summary Table

| Platform | GPU | Hours | Total Cost | Cost/Hour | Throughput | Notes |
|----------|-----|-------|------------|-----------|------------|-------|
| Lambda | A10 | 1.30 | **$0.62** | $0.31 | 3,200 tok/s | Cheapest (rounds to 2hr) ⭐ |
| Modal | T4 | 3.47 | $2.10 | $0.59 | 1,200 tok/s | Serverless, pay-per-sec |
| Modal | A100 | 0.65 | $1.42 | $2.10 | 6,400 tok/s | Fastest completion ⚡ |

### Recommendation by Use Case

**If cost is priority:**
- Use **Lambda A10** for $0.62 (cheapest)
- Savings: $1.48 vs Modal T4 (70% cheaper)

**If time is priority:**
- Use **Modal A100** for $1.42 (fastest - 39 minutes)
- Completes 5.3x faster than Lambda A10

**If flexibility is priority:**
- Use **Modal T4** for $2.10 (serverless, no minimum billing)
- Pay only for 3.47 hours of actual usage

---

## Impact of Optimizations

### Without PEFT (Full Fine-tuning)

```bash
bash scripts/estimate-training-cost.sh \
  --model-size 7B \
  --dataset-size 10000 \
  --epochs 3 \
  --gpu t4 \
  --platform modal \
  --peft no \
  --mixed-precision yes
```

**Results:**
- Throughput: 300 tokens/sec (4x slower without PEFT)
- Training Time: 13.89 hours
- Total Cost: $8.20

**PEFT Savings:**
- Time saved: 10.42 hours (75% faster)
- Cost saved: $6.10 (74% cheaper)

### Without Mixed Precision

```bash
bash scripts/estimate-training-cost.sh \
  --model-size 7B \
  --dataset-size 10000 \
  --epochs 3 \
  --gpu t4 \
  --platform modal \
  --peft yes \
  --mixed-precision no
```

**Results:**
- Throughput: 600 tokens/sec (2x slower without FP16)
- Training Time: 6.94 hours
- Total Cost: $4.10

**Mixed Precision Savings:**
- Time saved: 3.47 hours (50% faster)
- Cost saved: $2.00 (49% cheaper)

### Combined Impact

| Configuration | Time (hrs) | Cost | Speedup | Savings |
|---------------|------------|------|---------|---------|
| No optimizations | 27.78 | $16.40 | 1x | - |
| Mixed precision only | 13.89 | $8.20 | 2x | $8.20 (50%) |
| PEFT only | 6.94 | $4.10 | 4x | $12.30 (75%) |
| **Both optimizations** | **3.47** | **$2.10** | **8x** | **$14.30 (87%)** ✅ |

---

## Monthly Budget Estimation

### Training Schedule: 4 runs/month

**Development Phase (experimenting with hyperparameters):**
- Training runs: 4/month
- Platform: Lambda A10 (cheapest)
- Cost per run: $0.62
- **Monthly training cost: $2.48**

**Production Updates (monthly fine-tuning):**
- Training runs: 1/month
- Platform: Modal A100 (fastest for production)
- Cost per run: $1.42
- **Monthly training cost: $1.42**

### Total Project Cost (6 months)

| Phase | Months | Runs/Month | Platform | Cost/Run | Monthly | Total |
|-------|--------|------------|----------|----------|---------|-------|
| Development | 3 | 4 | Lambda A10 | $0.62 | $2.48 | $7.44 |
| Production | 3 | 1 | Modal A100 | $1.42 | $1.42 | $4.26 |
| **Total** | **6** | - | - | - | - | **$11.70** |

**vs Local RTX 4090:**
- Upfront cost: $1,800
- Power (6 months): $5.64
- **Total: $1,805.64**

**Savings with cloud GPU: $1,793.94 (99.4% cheaper)** 🎉

---

## Real-World Example: RedAI Trade Classifier

### Project Requirements
- Model: Llama 2 7B fine-tuned for trade/apprenticeship classification
- Dataset: 10,000 trade industry job descriptions
- Categories: 10 trade types (electrician, plumber, HVAC, etc.)
- Training: 3 epochs with LoRA

### Chosen Configuration
- **Platform:** Lambda A10
- **GPU:** 1x A10 (24GB VRAM)
- **Method:** LoRA rank 16, FP16
- **Cost:** $0.62 per training run
- **Time:** 1.3 hours

### Development Workflow
1. **Prepare data** (Supabase storage): $0/month (free tier)
2. **Train model** (Lambda A10): $0.62
3. **Evaluate** (local CPU): $0
4. **Iterate** (2-3 more runs): $1.86
5. **Deploy** (Modal serverless inference): See inference-cost-estimate.md

**Total development cost: $2.48** (3-4 training runs)

---

## Key Takeaways

1. **Always use PEFT for 7B+ models**: 75% cost savings, no quality loss
2. **Enable mixed precision**: 2x speedup, automatic on modern GPUs
3. **Lambda A10 cheapest for training**: $0.31/hr beats all platforms
4. **Modal best for serverless**: Pay-per-second, no minimum billing
5. **Cloud GPU 99% cheaper than buying**: No upfront cost, flexible scaling
6. **Optimizations compound**: PEFT + FP16 = 8x faster, 87% cheaper

---

**Next Steps:**
1. Use this estimate to budget training costs
2. See `inference-cost-estimate.md` for deployment costs
3. Run actual training to validate estimates
4. Monitor costs in platform dashboards
5. Apply for Modal startup credits ($50K free)
