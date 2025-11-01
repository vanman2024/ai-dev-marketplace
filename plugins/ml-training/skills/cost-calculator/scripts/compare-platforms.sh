#!/bin/bash

# compare-platforms.sh
# Compare training costs across Modal, Lambda Labs, and RunPod
# Usage: bash compare-platforms.sh --training-hours 4 --gpu-type a100-40gb

set -e

# Default values
TRAINING_HOURS=""
GPU_TYPE=""
OUTPUT_FORMAT="markdown"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --training-hours)
      TRAINING_HOURS="$2"
      shift 2
      ;;
    --gpu-type)
      GPU_TYPE="$2"
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
if [ -z "$TRAINING_HOURS" ] || [ -z "$GPU_TYPE" ]; then
  echo "Error: --training-hours and --gpu-type are required"
  echo "Usage: bash compare-platforms.sh --training-hours 4 --gpu-type a100-40gb"
  exit 1
fi

# Platform pricing
declare -A MODAL_PRICING
MODAL_PRICING["t4"]=0.59
MODAL_PRICING["l4"]=0.80
MODAL_PRICING["a10"]=1.10
MODAL_PRICING["a100-40gb"]=2.10
MODAL_PRICING["a100-80gb"]=2.50
MODAL_PRICING["h100"]=3.95

declare -A LAMBDA_PRICING
LAMBDA_PRICING["a10"]=0.31
LAMBDA_PRICING["a100-40gb"]=1.29
LAMBDA_PRICING["a100-80gb"]=1.79
LAMBDA_PRICING["h100"]=2.99

declare -A RUNPOD_PRICING
RUNPOD_PRICING["t4"]=0.60
RUNPOD_PRICING["a10"]=0.80
RUNPOD_PRICING["a100-40gb"]=2.00
RUNPOD_PRICING["a100-80gb"]=2.30
RUNPOD_PRICING["h100"]=3.80

# Calculate costs
MODAL_COST=""
LAMBDA_COST=""
RUNPOD_COST=""

if [ -n "${MODAL_PRICING[$GPU_TYPE]}" ]; then
  MODAL_COST=$(echo "scale=2; $TRAINING_HOURS * ${MODAL_PRICING[$GPU_TYPE]}" | bc)
fi

if [ -n "${LAMBDA_PRICING[$GPU_TYPE]}" ]; then
  LAMBDA_COST=$(echo "scale=2; $TRAINING_HOURS * ${LAMBDA_PRICING[$GPU_TYPE]}" | bc)
fi

if [ -n "${RUNPOD_PRICING[$GPU_TYPE]}" ]; then
  RUNPOD_COST=$(echo "scale=2; $TRAINING_HOURS * ${RUNPOD_PRICING[$GPU_TYPE]}" | bc)
fi

# Find cheapest option
CHEAPEST_PLATFORM=""
CHEAPEST_COST=999999

if [ -n "$MODAL_COST" ] && [ "$(echo "$MODAL_COST < $CHEAPEST_COST" | bc)" -eq 1 ]; then
  CHEAPEST_PLATFORM="Modal"
  CHEAPEST_COST=$MODAL_COST
fi

if [ -n "$LAMBDA_COST" ] && [ "$(echo "$LAMBDA_COST < $CHEAPEST_COST" | bc)" -eq 1 ]; then
  CHEAPEST_PLATFORM="Lambda Labs"
  CHEAPEST_COST=$LAMBDA_COST
fi

if [ -n "$RUNPOD_COST" ] && [ "$(echo "$RUNPOD_COST < $CHEAPEST_COST" | bc)" -eq 1 ]; then
  CHEAPEST_PLATFORM="RunPod"
  CHEAPEST_COST=$RUNPOD_COST
fi

# Calculate savings
MODAL_SAVINGS=""
LAMBDA_SAVINGS=""
RUNPOD_SAVINGS=""

if [ -n "$MODAL_COST" ]; then
  MODAL_SAVINGS=$(echo "scale=2; $MODAL_COST - $CHEAPEST_COST" | bc)
  MODAL_SAVINGS_PCT=$(echo "scale=1; ($MODAL_SAVINGS / $MODAL_COST) * 100" | bc)
fi

if [ -n "$LAMBDA_COST" ]; then
  LAMBDA_SAVINGS=$(echo "scale=2; $LAMBDA_COST - $CHEAPEST_COST" | bc)
  LAMBDA_SAVINGS_PCT=$(echo "scale=1; ($LAMBDA_SAVINGS / $LAMBDA_COST) * 100" | bc)
fi

if [ -n "$RUNPOD_COST" ]; then
  RUNPOD_SAVINGS=$(echo "scale=2; $RUNPOD_COST - $CHEAPEST_COST" | bc)
  RUNPOD_SAVINGS_PCT=$(echo "scale=1; ($RUNPOD_SAVINGS / $RUNPOD_COST) * 100" | bc)
fi

# Output results
if [ "$OUTPUT_FORMAT" = "json" ]; then
  cat <<EOF
{
  "training_hours": $TRAINING_HOURS,
  "gpu_type": "${GPU_TYPE^^}",
  "platforms": {
    "modal": {
      "available": $([ -n "$MODAL_COST" ] && echo "true" || echo "false"),
      "cost": ${MODAL_COST:-null},
      "hourly_rate": ${MODAL_PRICING[$GPU_TYPE]:-null},
      "notes": "Serverless, pay-per-second"
    },
    "lambda": {
      "available": $([ -n "$LAMBDA_COST" ] && echo "true" || echo "false"),
      "cost": ${LAMBDA_COST:-null},
      "hourly_rate": ${LAMBDA_PRICING[$GPU_TYPE]:-null},
      "notes": "On-demand hourly, no egress fees"
    },
    "runpod": {
      "available": $([ -n "$RUNPOD_COST" ] && echo "true" || echo "false"),
      "cost": ${RUNPOD_COST:-null},
      "hourly_rate": ${RUNPOD_PRICING[$GPU_TYPE]:-null},
      "notes": "Pay-per-minute, FlashBoot"
    }
  },
  "cheapest": {
    "platform": "$CHEAPEST_PLATFORM",
    "cost": $CHEAPEST_COST
  },
  "savings": {
    "vs_modal": ${MODAL_SAVINGS:-0},
    "vs_lambda": ${LAMBDA_SAVINGS:-0},
    "vs_runpod": ${RUNPOD_SAVINGS:-0}
  }
}
EOF
else
  cat <<EOF
# Platform Cost Comparison

## Training Job: $TRAINING_HOURS hours on ${GPU_TYPE^^}

| Platform | Hourly Rate | Total Cost | Savings vs Cheapest | Notes |
|----------|-------------|------------|---------------------|-------|
EOF

  if [ -n "$MODAL_COST" ]; then
    MARKER=""
    [ "$CHEAPEST_PLATFORM" = "Modal" ] && MARKER="⭐ CHEAPEST"
    echo "| Modal | \$${MODAL_PRICING[$GPU_TYPE]}/hr | \$$MODAL_COST | \$$MODAL_SAVINGS ($MODAL_SAVINGS_PCT%) | Serverless $MARKER |"
  fi

  if [ -n "$LAMBDA_COST" ]; then
    MARKER=""
    [ "$CHEAPEST_PLATFORM" = "Lambda Labs" ] && MARKER="⭐ CHEAPEST"
    echo "| Lambda Labs | \$${LAMBDA_PRICING[$GPU_TYPE]}/hr | \$$LAMBDA_COST | \$$LAMBDA_SAVINGS ($LAMBDA_SAVINGS_PCT%) | On-demand $MARKER |"
  fi

  if [ -n "$RUNPOD_COST" ]; then
    MARKER=""
    [ "$CHEAPEST_PLATFORM" = "RunPod" ] && MARKER="⭐ CHEAPEST"
    echo "| RunPod | \$${RUNPOD_PRICING[$GPU_TYPE]}/hr | \$$RUNPOD_COST | \$$RUNPOD_SAVINGS ($RUNPOD_SAVINGS_PCT%) | Per-minute $MARKER |"
  fi

  cat <<EOF

## Winner: $CHEAPEST_PLATFORM (\$$CHEAPEST_COST)

Recommendation:
- Short jobs (<1 hour): Modal serverless (pay-per-second)
- Long jobs (4+ hours): Lambda Labs (cheapest hourly rate)
- Variable workloads: Modal or RunPod (no idle cost)
EOF
fi
