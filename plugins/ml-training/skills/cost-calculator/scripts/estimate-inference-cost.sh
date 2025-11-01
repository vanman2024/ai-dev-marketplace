#!/bin/bash

# estimate-inference-cost.sh
# Calculate ML inference costs based on request volume, latency, and platform
# Usage: bash estimate-inference-cost.sh --requests-per-day 1000 --avg-latency 2 --gpu t4 --platform modal --deployment serverless

set -e

# Default values
REQUESTS_PER_DAY=""
AVG_LATENCY=""
GPU="t4"
PLATFORM="modal"
DEPLOYMENT="serverless"
BATCH_INFERENCE="no"
OUTPUT_FORMAT="json"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --requests-per-day)
      REQUESTS_PER_DAY="$2"
      shift 2
      ;;
    --avg-latency)
      AVG_LATENCY="$2"
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
    --deployment)
      DEPLOYMENT="$2"
      shift 2
      ;;
    --batch-inference)
      BATCH_INFERENCE="$2"
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
if [ -z "$REQUESTS_PER_DAY" ] || [ -z "$AVG_LATENCY" ]; then
  echo "Error: --requests-per-day and --avg-latency are required"
  echo "Usage: bash estimate-inference-cost.sh --requests-per-day 1000 --avg-latency 2 --gpu t4 --platform modal"
  exit 1
fi

# GPU pricing per second
declare -A GPU_PRICE_PER_SEC_MODAL
GPU_PRICE_PER_SEC_MODAL["t4"]=0.000164
GPU_PRICE_PER_SEC_MODAL["a10"]=0.000306
GPU_PRICE_PER_SEC_MODAL["a100-40gb"]=0.000583
GPU_PRICE_PER_SEC_MODAL["h100"]=0.001097

declare -A GPU_PRICE_PER_HOUR_LAMBDA
GPU_PRICE_PER_HOUR_LAMBDA["a10"]=0.31
GPU_PRICE_PER_HOUR_LAMBDA["a100-40gb"]=1.29

declare -A GPU_PRICE_PER_SEC_RUNPOD
GPU_PRICE_PER_SEC_RUNPOD["t4"]=0.000167  # ~0.60/hr
GPU_PRICE_PER_SEC_RUNPOD["a10"]=0.000222
GPU_PRICE_PER_SEC_RUNPOD["a100-40gb"]=0.000556

# Adjust latency for batch inference
if [ "$BATCH_INFERENCE" = "yes" ]; then
  # Batch inference: 10 requests per batch, 15% overhead
  # Latency per request = (batch_latency / 10) = original_latency * 1.15 / 10
  AVG_LATENCY=$(echo "scale=4; $AVG_LATENCY * 1.15 / 10" | bc)
fi

# Calculate daily compute seconds
DAILY_COMPUTE_SEC=$(echo "scale=2; $REQUESTS_PER_DAY * $AVG_LATENCY" | bc)

# Calculate monthly values
REQUESTS_PER_MONTH=$(echo "$REQUESTS_PER_DAY * 30" | bc)
MONTHLY_COMPUTE_SEC=$(echo "$DAILY_COMPUTE_SEC * 30" | bc)

# Calculate costs based on deployment type
if [ "$DEPLOYMENT" = "serverless" ]; then
  # Serverless: pay per second
  PRICE_PER_SEC=0
  case $PLATFORM in
    modal)
      PRICE_PER_SEC=${GPU_PRICE_PER_SEC_MODAL[$GPU]:-0}
      ;;
    runpod)
      PRICE_PER_SEC=${GPU_PRICE_PER_SEC_RUNPOD[$GPU]:-0}
      ;;
    lambda)
      echo "Error: Lambda does not support serverless deployment"
      exit 1
      ;;
  esac

  if [ "$(echo "$PRICE_PER_SEC == 0" | bc)" -eq 1 ]; then
    echo "Error: GPU '$GPU' not available on platform '$PLATFORM'"
    exit 1
  fi

  DAILY_COST=$(echo "scale=2; $DAILY_COMPUTE_SEC * $PRICE_PER_SEC" | bc)
  MONTHLY_COST=$(echo "scale=2; $DAILY_COST * 30" | bc)
  COST_PER_REQUEST=$(echo "scale=8; $DAILY_COST / $REQUESTS_PER_DAY" | bc)

else
  # Dedicated: pay for 24/7 instance
  PRICE_PER_HOUR=0
  case $PLATFORM in
    lambda)
      PRICE_PER_HOUR=${GPU_PRICE_PER_HOUR_LAMBDA[$GPU]:-0}
      ;;
    modal)
      # Modal hourly price
      declare -A MODAL_HOURLY
      MODAL_HOURLY["t4"]=0.59
      MODAL_HOURLY["a10"]=1.10
      MODAL_HOURLY["a100-40gb"]=2.10
      PRICE_PER_HOUR=${MODAL_HOURLY[$GPU]:-0}
      ;;
    runpod)
      declare -A RUNPOD_HOURLY
      RUNPOD_HOURLY["t4"]=0.60
      RUNPOD_HOURLY["a10"]=0.80
      RUNPOD_HOURLY["a100-40gb"]=2.00
      PRICE_PER_HOUR=${RUNPOD_HOURLY[$GPU]:-0}
      ;;
  esac

  if [ "$(echo "$PRICE_PER_HOUR == 0" | bc)" -eq 1 ]; then
    echo "Error: GPU '$GPU' not available on platform '$PLATFORM'"
    exit 1
  fi

  MONTHLY_COST=$(echo "scale=2; $PRICE_PER_HOUR * 24 * 30" | bc)
  DAILY_COST=$(echo "scale=2; $MONTHLY_COST / 30" | bc)
  COST_PER_REQUEST=$(echo "scale=8; $DAILY_COST / $REQUESTS_PER_DAY" | bc)
fi

# Calculate scaling projections
REQUESTS_10K=$(echo "scale=2; $COST_PER_REQUEST * 10000 * 30" | bc)
REQUESTS_100K=$(echo "scale=2; $COST_PER_REQUEST * 100000 * 30" | bc)

# Calculate dedicated alternative (if currently serverless)
DEDICATED_MONTHLY=0
BREAK_EVEN_REQUESTS=0
if [ "$DEPLOYMENT" = "serverless" ]; then
  # Calculate dedicated cost
  DEDICATED_HOURLY=0
  if [ "$PLATFORM" = "modal" ]; then
    declare -A MODAL_HOURLY
    MODAL_HOURLY["t4"]=0.59
    MODAL_HOURLY["a10"]=1.10
    DEDICATED_HOURLY=${MODAL_HOURLY[$GPU]:-0}
  elif [ "$PLATFORM" = "runpod" ]; then
    declare -A RUNPOD_HOURLY
    RUNPOD_HOURLY["t4"]=0.60
    RUNPOD_HOURLY["a10"]=0.80
    DEDICATED_HOURLY=${RUNPOD_HOURLY[$GPU]:-0}
  fi

  if [ "$(echo "$DEDICATED_HOURLY > 0" | bc)" -eq 1 ]; then
    DEDICATED_MONTHLY=$(echo "scale=2; $DEDICATED_HOURLY * 24 * 30" | bc)
    # Break-even: when serverless cost equals dedicated cost
    # serverless_daily * 30 = dedicated_monthly
    # (requests_per_day * avg_latency * price_per_sec) * 30 = dedicated_monthly
    # requests_per_day = dedicated_monthly / (30 * avg_latency * price_per_sec)
    BREAK_EVEN_REQUESTS=$(echo "scale=0; $DEDICATED_MONTHLY / (30 * $AVG_LATENCY * $PRICE_PER_SEC)" | bc)
  fi
fi

# Output results
if [ "$OUTPUT_FORMAT" = "json" ]; then
  cat <<EOF
{
  "requests_per_day": $REQUESTS_PER_DAY,
  "requests_per_month": $REQUESTS_PER_MONTH,
  "avg_latency_sec": $AVG_LATENCY,
  "gpu": "${GPU^^}",
  "platform": "${PLATFORM^}",
  "deployment": "$DEPLOYMENT",
  "batch_inference": "$BATCH_INFERENCE",
  "cost_breakdown": {
    "daily_compute_seconds": $DAILY_COMPUTE_SEC,
    "daily_cost": $DAILY_COST,
    "monthly_cost": $MONTHLY_COST,
    "cost_per_request": $COST_PER_REQUEST
  },
  "scaling_analysis": {
    "requests_10k_day": $REQUESTS_10K,
    "requests_100k_day": $REQUESTS_100K
  },
  "dedicated_alternative": {
    "monthly_cost": ${DEDICATED_MONTHLY:-null},
    "break_even_requests_day": ${BREAK_EVEN_REQUESTS:-null}
  }
}
EOF
else
  cat <<EOF
Inference Cost Estimate
=======================
Requests: $REQUESTS_PER_DAY/day ($REQUESTS_PER_MONTH/month)
Avg Latency: $AVG_LATENCY seconds
GPU: ${GPU^^} on ${PLATFORM^}
Deployment: $DEPLOYMENT
Batch Inference: $BATCH_INFERENCE

Cost Breakdown:
  Daily Compute: ${DAILY_COMPUTE_SEC}s
  Daily Cost: \$$DAILY_COST
  Monthly Cost: \$$MONTHLY_COST
  Cost per Request: \$$COST_PER_REQUEST

Scaling Analysis:
  10K requests/day: \$$REQUESTS_10K/month
  100K requests/day: \$$REQUESTS_100K/month

Dedicated Alternative:
  Monthly Cost: \$$DEDICATED_MONTHLY
  Break-even: $BREAK_EVEN_REQUESTS requests/day
EOF
fi
