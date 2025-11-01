#!/bin/bash

# estimate-training-cost.sh
# Calculate ML training costs based on model size, dataset, GPU type, and platform
# Usage: bash estimate-training-cost.sh --model-size 7B --dataset-size 10000 --epochs 3 --gpu t4 --platform modal

set -e

# Default values
MODEL_SIZE=""
DATASET_SIZE=""
EPOCHS=3
BATCH_SIZE="auto"
GPU="t4"
PLATFORM="modal"
PEFT="no"
MIXED_PRECISION="yes"
OUTPUT_FORMAT="json"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --model-size)
      MODEL_SIZE="$2"
      shift 2
      ;;
    --dataset-size)
      DATASET_SIZE="$2"
      shift 2
      ;;
    --epochs)
      EPOCHS="$2"
      shift 2
      ;;
    --batch-size)
      BATCH_SIZE="$2"
      shift 2
      ;;
    --gpu)
      GPU="$2"
      shift 2
      ;;
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --peft)
      PEFT="$2"
      shift 2
      ;;
    --mixed-precision)
      MIXED_PRECISION="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$MODEL_SIZE" ] || [ -z "$DATASET_SIZE" ]; then
  echo "Error: --model-size and --dataset-size are required"
  echo "Usage: bash estimate-training-cost.sh --model-size 7B --dataset-size 10000 --epochs 3 --gpu t4 --platform modal"
  exit 1
fi

# Convert model size to parameters
declare -A MODEL_PARAMS
MODEL_PARAMS["125M"]=125000000
MODEL_PARAMS["350M"]=350000000
MODEL_PARAMS["1B"]=1000000000
MODEL_PARAMS["3B"]=3000000000
MODEL_PARAMS["7B"]=7000000000
MODEL_PARAMS["13B"]=13000000000
MODEL_PARAMS["70B"]=70000000000

if [ -z "${MODEL_PARAMS[$MODEL_SIZE]}" ]; then
  echo "Error: Invalid model size. Supported: 125M, 350M, 1B, 3B, 7B, 13B, 70B"
  exit 1
fi

# GPU pricing per hour
declare -A GPU_PRICE_MODAL
GPU_PRICE_MODAL["t4"]=0.59
GPU_PRICE_MODAL["l4"]=0.80
GPU_PRICE_MODAL["a10"]=1.10
GPU_PRICE_MODAL["a100-40gb"]=2.10
GPU_PRICE_MODAL["a100-80gb"]=2.50
GPU_PRICE_MODAL["h100"]=3.95

declare -A GPU_PRICE_LAMBDA
GPU_PRICE_LAMBDA["a10"]=0.31
GPU_PRICE_LAMBDA["a100-40gb"]=1.29
GPU_PRICE_LAMBDA["a100-80gb"]=1.79
GPU_PRICE_LAMBDA["h100"]=2.99

declare -A GPU_PRICE_RUNPOD
GPU_PRICE_RUNPOD["t4"]=0.60
GPU_PRICE_RUNPOD["a10"]=0.80
GPU_PRICE_RUNPOD["a100-40gb"]=2.00
GPU_PRICE_RUNPOD["h100"]=3.80

# GPU throughput (tokens/sec) - full fine-tuning
declare -A GPU_THROUGHPUT_FULL
GPU_THROUGHPUT_FULL["t4-7B"]=150
GPU_THROUGHPUT_FULL["a10-7B"]=400
GPU_THROUGHPUT_FULL["a100-40gb-7B"]=800
GPU_THROUGHPUT_FULL["a100-80gb-7B"]=800
GPU_THROUGHPUT_FULL["a100-80gb-13B"]=600
GPU_THROUGHPUT_FULL["h100-70B"]=300

# GPU throughput (tokens/sec) - PEFT/LoRA
declare -A GPU_THROUGHPUT_PEFT
GPU_THROUGHPUT_PEFT["t4-7B"]=600
GPU_THROUGHPUT_PEFT["a10-7B"]=1600
GPU_THROUGHPUT_PEFT["a100-40gb-7B"]=3200
GPU_THROUGHPUT_PEFT["a100-40gb-13B"]=1600
GPU_THROUGHPUT_PEFT["a100-80gb-70B"]=400
GPU_THROUGHPUT_PEFT["h100-70B"]=1200

# Calculate total training tokens
AVG_TOKENS_PER_SAMPLE=500
TOTAL_TOKENS=$(echo "$DATASET_SIZE * $AVG_TOKENS_PER_SAMPLE * $EPOCHS" | bc)

# Select throughput based on PEFT setting
THROUGHPUT_KEY="${GPU}-${MODEL_SIZE}"
if [ "$PEFT" = "yes" ]; then
  THROUGHPUT=${GPU_THROUGHPUT_PEFT[$THROUGHPUT_KEY]:-0}
  if [ "$THROUGHPUT" -eq 0 ]; then
    # Estimate: PEFT is ~4x faster than full fine-tuning
    THROUGHPUT_FULL=${GPU_THROUGHPUT_FULL[$THROUGHPUT_KEY]:-150}
    THROUGHPUT=$(echo "$THROUGHPUT_FULL * 4" | bc)
  fi
else
  THROUGHPUT=${GPU_THROUGHPUT_FULL[$THROUGHPUT_KEY]:-150}
fi

# Apply mixed precision speedup (2x faster)
if [ "$MIXED_PRECISION" = "yes" ]; then
  THROUGHPUT=$(echo "$THROUGHPUT * 2" | bc)
fi

# Calculate training time in hours
TRAINING_SECONDS=$(echo "$TOTAL_TOKENS / $THROUGHPUT" | bc)
TRAINING_HOURS=$(echo "scale=2; $TRAINING_SECONDS / 3600" | bc)

# Get GPU price for selected platform
GPU_PRICE=0
case $PLATFORM in
  modal)
    GPU_PRICE=${GPU_PRICE_MODAL[$GPU]:-0}
    ;;
  lambda)
    GPU_PRICE=${GPU_PRICE_LAMBDA[$GPU]:-0}
    ;;
  runpod)
    GPU_PRICE=${GPU_PRICE_RUNPOD[$GPU]:-0}
    ;;
esac

if [ "$(echo "$GPU_PRICE == 0" | bc)" -eq 1 ]; then
  echo "Error: GPU type '$GPU' not available on platform '$PLATFORM'"
  exit 1
fi

# Calculate costs
COMPUTE_COST=$(echo "scale=2; $TRAINING_HOURS * $GPU_PRICE" | bc)
STORAGE_COST=0.05  # Minimal storage cost for model artifacts
TOTAL_COST=$(echo "scale=2; $COMPUTE_COST + $STORAGE_COST" | bc)

# Calculate cost with optimizations
if [ "$PEFT" = "no" ]; then
  # Calculate what cost would be with PEFT (50% reduction)
  PEFT_COST=$(echo "scale=2; $TOTAL_COST * 0.5" | bc)
  PEFT_SAVINGS=$(echo "scale=2; $TOTAL_COST - $PEFT_COST" | bc)
else
  PEFT_COST=$TOTAL_COST
  PEFT_SAVINGS=0
fi

# Calculate alternative platform costs
ALT_LAMBDA_COST=0
ALT_MODAL_COST=0
if [ "$PLATFORM" != "lambda" ] && [ -n "${GPU_PRICE_LAMBDA[$GPU]}" ]; then
  ALT_LAMBDA_COST=$(echo "scale=2; $TRAINING_HOURS * ${GPU_PRICE_LAMBDA[$GPU]}" | bc)
fi
if [ "$PLATFORM" != "modal" ] && [ -n "${GPU_PRICE_MODAL[$GPU]}" ]; then
  ALT_MODAL_COST=$(echo "scale=2; $TRAINING_HOURS * ${GPU_PRICE_MODAL[$GPU]}" | bc)
fi

# Output results
if [ "$OUTPUT_FORMAT" = "json" ]; then
  cat <<EOF
{
  "model": "$MODEL_SIZE",
  "model_params": ${MODEL_PARAMS[$MODEL_SIZE]},
  "dataset_size": $DATASET_SIZE,
  "epochs": $EPOCHS,
  "total_tokens": $TOTAL_TOKENS,
  "gpu": "${GPU^^}",
  "platform": "${PLATFORM^}",
  "peft_enabled": "$PEFT",
  "mixed_precision": "$MIXED_PRECISION",
  "throughput_tokens_per_sec": $THROUGHPUT,
  "estimated_hours": $TRAINING_HOURS,
  "cost_breakdown": {
    "compute_cost": $COMPUTE_COST,
    "storage_cost": $STORAGE_COST,
    "total_cost": $TOTAL_COST
  },
  "cost_optimizations": {
    "with_peft": $PEFT_COST,
    "savings_with_peft": $PEFT_SAVINGS
  },
  "alternative_platforms": {
    "lambda": ${ALT_LAMBDA_COST:-null},
    "modal": ${ALT_MODAL_COST:-null}
  }
}
EOF
else
  cat <<EOF
Training Cost Estimate
======================
Model: $MODEL_SIZE (${MODEL_PARAMS[$MODEL_SIZE]} parameters)
Dataset: $DATASET_SIZE samples × $EPOCHS epochs = $TOTAL_TOKENS tokens
GPU: ${GPU^^} on ${PLATFORM^}
PEFT: $PEFT | Mixed Precision: $MIXED_PRECISION

Throughput: $THROUGHPUT tokens/sec
Estimated Time: $TRAINING_HOURS hours

Cost Breakdown:
  Compute: \$$COMPUTE_COST
  Storage: \$$STORAGE_COST
  Total: \$$TOTAL_COST

Optimizations:
  With PEFT: \$$PEFT_COST (Save \$$PEFT_SAVINGS)

Alternative Platforms:
  Lambda: \$$ALT_LAMBDA_COST
  Modal: \$$ALT_MODAL_COST
EOF
fi
