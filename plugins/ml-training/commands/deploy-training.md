---
description: Deploy training job to cloud GPU platform
argument-hint: [config-path]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion, Skill
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

Goal: Deploy ML training job to cloud GPU platform with cost estimation, progress monitoring, and job status reporting

## Phase 1: Parse and Validate Configuration

Goal: Load config and verify environment setup

Actions:
- Parse $ARGUMENTS for config path or check defaults: !{bash test -f training_config.yaml && echo "training_config.yaml" || test -f config/training.yaml && echo "config/training.yaml" || echo "none"}
- If no config found, ask user: AskUserQuestion("Provide path to training config file:")
- Load config file: @{config-path}
- Extract platform (modal/lambda/runpod), GPU type (A100/A10G/H100), script path, duration estimate
- Verify platform SDK: !{bash python -c "import modal" 2>&1 || python -c "import lambda_cloud" 2>&1 || python -c "import runpod" 2>&1 || echo "missing"}
- Check auth: !{bash test -f ~/.modal.toml || test -f lambda_config.json || test -f runpod_config.json && echo "configured" || echo "missing"}
- If SDK/auth missing, report: "Install SDK with: /ml-training:add-platform [platform]"

## Phase 2: Cost Estimation

Goal: Calculate and confirm deployment costs

Actions:
- Calculate cost from config GPU type and duration (Modal A100: $4.00/hr, A10G: $1.10/hr | Lambda A100: $1.29/hr, A10G: $0.60/hr | RunPod A100: $1.89/hr, A10G: $0.44/hr)
- Display: GPU [type], Duration [hours], Cost $[min]-$[max], Platform [platform]
- Ask confirmation: AskUserQuestion("Proceed with deployment? (yes/no)")
- If no, exit: "Deployment cancelled"

## Phase 3: Deploy Job

Goal: Submit training job to cloud platform

Actions:
Task(description="Deploy training job to cloud platform", subagent_type="training-architect", prompt="You are the training-architect agent. Deploy ML training job to cloud platform from config: {config-path}

**Platform Deployment (based on config platform):**

Modal: Run `modal run {script-path} --config={config-path}`, capture app ID
Lambda: Load lambda_config.json, create instance with GPU from config, SSH start training, capture instance ID
RunPod: Load runpod_config.json, create pod with GPU from config, execute training, capture pod ID

**Error Handling:**
- Deployment fails: Report error details
- Auth fails: Provide setup instructions
- Quota exceeded: Suggest alternatives

**Capture:** Job/instance ID, GPU type, start time, estimated completion, monitoring URL")

## Phase 4: Summary

Goal: Display deployment status and monitoring info

Actions:
- Check W&B: !{bash test -f .env && grep -q "WANDB_API_KEY" .env && echo "enabled" || echo "disabled"}
- Display summary:
  - Status: Job deployed successfully
  - Platform: [platform], GPU: [type], Job ID: [id]
  - Cost estimate: $[amount], ETA: [time]
  - Config: [config-path]
- Monitoring:
  - Modal: modal app logs [app-id] | https://modal.com/apps/[workspace]/[app-id]
  - Lambda: Instance console | https://cloud.lambdalabs.com/instances/[instance-id]
  - RunPod: runpod logs [pod-id] | https://www.runpod.io/console/pods/[pod-id]
  - W&B dashboard (if enabled)
- Next steps:
  1. Monitor with platform commands above
  2. Checkpoints auto-save to configured location
  3. Terminate if needed: [platform-specific command]
  4. Download model: /ml-training:download-model [job-id]
- Warning: Job incurs charges until completion/termination
