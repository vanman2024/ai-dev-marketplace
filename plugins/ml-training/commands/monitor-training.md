---
description: Monitor active training jobs and display metrics
argument-hint: [job-id]
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

Goal: Monitor active ML training jobs on cloud platforms (Modal, AWS, GCP) and display real-time metrics including job status, GPU utilization, training progress, estimated completion time, and cost

Core Principles:
- Detect cloud platform from job ID format or configuration
- Query platform API for real-time job status
- Display metrics in clear, actionable format
- Calculate cost estimates based on GPU hours

## Phase 1: Job Discovery

Goal: Parse job ID and identify cloud platform

Actions:
- Parse $ARGUMENTS for job ID
- If no job ID provided, list all active jobs across platforms
- Detect platform from job ID format:
  - Modal: starts with "ap-" or use modal CLI
  - AWS SageMaker: job-* format
  - GCP Vertex AI: projects/* format
- Check if Modal CLI available: !{bash which modal}
- Load .env for API credentials if needed: !{bash test -f .env && echo "found" || echo "missing"}

## Phase 2: Query Job Status

Goal: Retrieve job information from cloud platform

Actions:
- **Modal Platform**:
  - List running apps: !{bash modal app list --json}
  - Get specific job status: !{bash modal app logs $ARGUMENTS --raw}
  - Parse JSON output for job metadata
- **AWS SageMaker** (if detected):
  - Query job: !{bash aws sagemaker describe-training-job --training-job-name $ARGUMENTS}
  - Get CloudWatch metrics for GPU utilization
- **GCP Vertex AI** (if detected):
  - Query job: !{bash gcloud ai custom-jobs describe $ARGUMENTS}
  - Get resource metrics
- If platform not detected, report: "Unable to detect platform from job ID: $ARGUMENTS"

## Phase 3: Metrics Display

Goal: Format and display training metrics

Actions:
- Extract key metrics from platform response:
  - Job status (Running, Completed, Failed, Stopped)
  - Start time and elapsed time
  - GPU type and count (e.g., "A100-40GB x2")
  - GPU utilization percentage
  - Memory usage (GPU and system)
  - Current training step/epoch
  - Training loss (if logged)
  - Estimated time remaining (if available)
- Display metrics in formatted table:
  ```
  Job ID: {job-id}
  Platform: {Modal|AWS|GCP}
  Status: {status}
  Duration: {hours}h {minutes}m
  GPU: {type} x{count}
  GPU Util: {percent}%
  Memory: {used}GB / {total}GB
  Progress: Step {current}/{total}
  Loss: {value}
  ETA: {hours}h {minutes}m
  ```

## Phase 4: Cost Calculation

Goal: Estimate training costs based on GPU usage

Actions:
- Calculate billable time from job start to current time
- Apply platform pricing rates:
  - Modal A100-40GB: $1.10/hour
  - Modal A100-80GB: $2.21/hour
  - AWS p4d.24xlarge (A100): $32.77/hour
  - GCP a2-highgpu-1g (A100): $3.67/hour
- Formula: cost = (GPU count) x (hours elapsed) x (rate per GPU hour)
- Display cost estimate:
  ```
  Cost Estimate:
  GPU Hours: {hours}
  Rate: ${rate}/hour x {count} GPUs
  Current Cost: ${amount}
  Projected Total: ${projected} (if ETA available)
  ```

## Phase 5: Summary

Goal: Display actionable information and next steps

Actions:
- Show summary status:
  - Job {job-id} is {Running|Completed|Failed}
  - {elapsed} elapsed, {eta} remaining
  - Current cost: ${amount}
- If job is running:
  - "Use 'modal app logs {job-id}' to stream full logs"
  - "Use 'modal app stop {job-id}' to terminate job"
- If job completed:
  - "Check models/checkpoints/ for saved model"
  - "Review logs/training/ for metrics history"
- If job failed:
  - "Review error logs: modal app logs {job-id} --tail 50"
  - "Check GPU memory errors or timeout issues"
- Refresh suggestion: "Re-run this command to update metrics"
