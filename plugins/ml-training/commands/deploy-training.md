---
description: Deploy training job to cloud GPU platform
argument-hint: [config-path]
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

## Available Skills

This commands has access to the following skills from the ml-training plugin:

- **cloud-gpu-configs**: Platform-specific configuration templates for Modal, Lambda Labs, and RunPod with GPU selection guides
- **cost-calculator**: Cost estimation scripts and tools for calculating GPU hours, training costs, and inference pricing across Modal, Lambda Labs, and RunPod platforms. Use when estimating ML training costs, comparing platform pricing, calculating GPU hours, budgeting for ML projects, or when user mentions cost estimation, pricing comparison, GPU budgeting, training cost analysis, or inference cost optimization.
- **example-projects**: Provides three production-ready ML training examples (sentiment classification, text generation, RedAI trade classifier) with complete training scripts, deployment configs, and datasets. Use when user needs example projects, reference implementations, starter templates, or wants to see working code for sentiment analysis, text generation, or financial trade classification.
- **integration-helpers**: Integration templates for FastAPI endpoints, Next.js UI components, and Supabase schemas for ML model deployment. Use when deploying ML models, creating inference APIs, building ML prediction UIs, designing ML database schemas, integrating trained models with applications, or when user mentions FastAPI ML endpoints, prediction forms, model serving, ML API deployment, inference integration, or production ML deployment.
- **monitoring-dashboard**: Training monitoring dashboard setup with TensorBoard and Weights & Biases (WandB) including real-time metrics tracking, experiment comparison, hyperparameter visualization, and integration patterns. Use when setting up training monitoring, tracking experiments, visualizing metrics, comparing model runs, or when user mentions TensorBoard, WandB, training metrics, experiment tracking, or monitoring dashboard.
- **training-patterns**: Templates and patterns for common ML training scenarios including text classification, text generation, fine-tuning, and PEFT/LoRA. Provides ready-to-use training configurations, dataset preparation scripts, and complete training pipelines. Use when building ML training pipelines, fine-tuning models, implementing classification or generation tasks, setting up PEFT/LoRA training, or when user mentions model training, fine-tuning, classification, generation, or parameter-efficient tuning.
- **validation-scripts**: Data validation and pipeline testing utilities for ML training projects. Validates datasets, model checkpoints, training pipelines, and dependencies. Use when validating training data, checking model outputs, testing ML pipelines, verifying dependencies, debugging training failures, or ensuring data quality before training.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---


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
