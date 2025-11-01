#!/bin/bash

# calculate-gpu-hours.sh
# Convert training parameters to GPU hours
# Usage: bash calculate-gpu-hours.sh --model-params 7B --tokens-total 30M --gpu a100-40gb

set -e

# Default values
MODEL_PARAMS=""
TOKENS_TOTAL=""
GPU="a100-40gb"
PEFT="no"
MULTI_GPU=1
OUTPUT_FORMAT="json"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --model-params)
      MODEL_PARAMS="$2"
      shift 2
      ;;
    --tokens-total)
      TOKENS_TOTAL="$2"
      shift 2
      ;;
    --gpu)
      GPU="$2"
      shift 2
      ;;
    --peft)
      PEFT="$2"
      shift 2
      ;;
    --multi-gpu)
      MULTI_GPU="$2"
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
if [ -z "$MODEL_PARAMS" ] || [ -z "$TOKENS_TOTAL" ]; then
  echo "Error: --model-params and --tokens-total are required"
  echo "Usage: bash calculate-gpu-hours.sh --model-params 7B --tokens-total 30M --gpu a100-40gb"
  exit 1
fi

# Parse tokens (handle M/B suffixes)
TOKENS_NUM=$(echo "$TOKENS_TOTAL" | sed 's/[^0-9.]//g')
if [[ "$TOKENS_TOTAL" =~ M$ ]]; then
  TOKENS_NUM=$(echo "$TOKENS_NUM * 1000000" | bc)
elif [[ "$TOKENS_TOTAL" =~ B$ ]]; then
  TOKENS_NUM=$(echo "$TOKENS_NUM * 1000000000" | bc)
fi

# GPU throughput benchmarks (tokens/sec) - full fine-tuning
declare -A THROUGHPUT_FULL
THROUGHPUT_FULL["t4-125M"]=500
THROUGHPUT_FULL["t4-350M"]=300
THROUGHPUT_FULL["t4-1B"]=200
THROUGHPUT_FULL["t4-3B"]=180
THROUGHPUT_FULL["t4-7B"]=150

THROUGHPUT_FULL["a10-7B"]=400
THROUGHPUT_FULL["a10-13B"]=250

THROUGHPUT_FULL["a100-40gb-7B"]=800
THROUGHPUT_FULL["a100-40gb-13B"]=600
THROUGHPUT_FULL["a100-40gb-70B"]=200

THROUGHPUT_FULL["a100-80gb-13B"]=600
THROUGHPUT_FULL["a100-80gb-70B"]=250

THROUGHPUT_FULL["h100-70B"]=500

# GPU throughput benchmarks (tokens/sec) - PEFT/LoRA
declare -A THROUGHPUT_PEFT
THROUGHPUT_PEFT["t4-7B"]=600
THROUGHPUT_PEFT["t4-13B"]=400

THROUGHPUT_PEFT["a10-7B"]=1600
THROUGHPUT_PEFT["a10-13B"]=1000

THROUGHPUT_PEFT["a100-40gb-7B"]=3200
THROUGHPUT_PEFT["a100-40gb-13B"]=1600
THROUGHPUT_PEFT["a100-40gb-70B"]=600

THROUGHPUT_PEFT["a100-80gb-70B"]=800

THROUGHPUT_PEFT["h100-70B"]=1200

# Select throughput based on PEFT
THROUGHPUT_KEY="${GPU}-${MODEL_PARAMS}"
if [ "$PEFT" = "yes" ]; then
  THROUGHPUT=${THROUGHPUT_PEFT[$THROUGHPUT_KEY]:-0}
  if [ "$THROUGHPUT" -eq 0 ]; then
    # Estimate: PEFT is ~4x faster
    THROUGHPUT_FULL_VAL=${THROUGHPUT_FULL[$THROUGHPUT_KEY]:-150}
    THROUGHPUT=$(echo "$THROUGHPUT_FULL_VAL * 4" | bc)
  fi
else
  THROUGHPUT=${THROUGHPUT_FULL[$THROUGHPUT_KEY]:-0}
  if [ "$THROUGHPUT" -eq 0 ]; then
    # Default fallback
    THROUGHPUT=150
  fi
fi

# Adjust for multi-GPU (linear scaling with 90% efficiency)
if [ "$MULTI_GPU" -gt 1 ]; then
  SCALING_EFFICIENCY=0.9
  THROUGHPUT=$(echo "scale=0; $THROUGHPUT * $MULTI_GPU * $SCALING_EFFICIENCY" | bc)
fi

# Calculate training time
TRAINING_SECONDS=$(echo "scale=0; $TOKENS_NUM / $THROUGHPUT" | bc)
TRAINING_HOURS=$(echo "scale=2; $TRAINING_SECONDS / 3600" | bc)
TRAINING_DAYS=$(echo "scale=2; $TRAINING_HOURS / 24" | bc)

# GPU hours (accounting for multi-GPU)
GPU_HOURS=$(echo "scale=2; $TRAINING_HOURS * $MULTI_GPU" | bc)

# Estimate with and without optimizations
if [ "$PEFT" = "no" ]; then
  # Calculate with PEFT (4x faster)
  PEFT_THROUGHPUT=$(echo "$THROUGHPUT * 4" | bc)
  PEFT_SECONDS=$(echo "scale=0; $TOKENS_NUM / $PEFT_THROUGHPUT" | bc)
  PEFT_HOURS=$(echo "scale=2; $PEFT_SECONDS / 3600" | bc)
else
  PEFT_HOURS=$TRAINING_HOURS
fi

# Output results
if [ "$OUTPUT_FORMAT" = "json" ]; then
  cat <<EOF
{
  "model_params": "$MODEL_PARAMS",
  "total_tokens": $TOKENS_NUM,
  "gpu": "${GPU^^}",
  "peft_enabled": "$PEFT",
  "num_gpus": $MULTI_GPU,
  "throughput_tokens_per_sec": $THROUGHPUT,
  "training_time": {
    "seconds": $TRAINING_SECONDS,
    "hours": $TRAINING_HOURS,
    "days": $TRAINING_DAYS
  },
  "gpu_hours": $GPU_HOURS,
  "optimizations": {
    "with_peft_hours": $PEFT_HOURS,
    "savings_hours": $(echo "scale=2; $TRAINING_HOURS - $PEFT_HOURS" | bc)
  }
}
EOF
else
  cat <<EOF
GPU Hours Calculation
=====================
Model: $MODEL_PARAMS
Total Tokens: $TOKENS_NUM
GPU: ${GPU^^} × $MULTI_GPU
PEFT: $PEFT

Throughput: $THROUGHPUT tokens/sec

Training Time:
  Seconds: $TRAINING_SECONDS
  Hours: $TRAINING_HOURS
  Days: $TRAINING_DAYS

Total GPU Hours: $GPU_HOURS

Optimizations:
  With PEFT: $PEFT_HOURS hours
  Savings: $(echo "scale=2; $TRAINING_HOURS - $PEFT_HOURS" | bc) hours
EOF
fi
