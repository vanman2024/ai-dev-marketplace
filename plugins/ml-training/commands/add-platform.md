---
description: Add cloud GPU platform integration (Modal/Lambda/RunPod)
argument-hint: <modal|lambda|runpod>
---
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

Goal: Add cloud GPU platform integration for ML training with authentication setup and test configuration

Core Principles:
- Parse platform choice from arguments
- Install platform-specific SDK
- Configure authentication
- Create GPU image definition
- Verify setup with test script

Phase 1: Parse Platform Choice
Goal: Determine which platform to integrate

Actions:
- Parse $ARGUMENTS to extract platform name (modal, lambda, or runpod)
- If no argument or invalid platform provided:
  - Use AskUserQuestion to ask: "Which cloud GPU platform? (modal/lambda/runpod)"
- Validate platform choice is one of: modal, lambda, runpod
- Convert to lowercase for consistency

Phase 2: Check Existing Setup
Goal: Understand current project structure

Actions:
- Check for existing requirements.txt: @requirements.txt
- Check for existing platform configs:
  - Modal: Look for modal_*.py files
  - Lambda: Look for lambda_config.json
  - RunPod: Look for runpod_config.json
- Detect Python version from runtime files
- Check if platform SDK already installed

Phase 3: Install Platform SDK
Goal: Install correct SDK for chosen platform

Actions:
Install SDK based on platform:
- Modal: !{bash pip install modal}
- Lambda: !{bash pip install lambda-cloud}
- RunPod: !{bash pip install runpod}

Update requirements.txt with SDK entry

Phase 4: Platform Setup and Authentication
Goal: Configure platform authentication

Actions:
Task(description="Setup platform authentication", subagent_type="ml-architect", prompt="You are the ml-architect agent configuring $ARGUMENTS cloud GPU platform.

Based on platform:

**Modal:**
- Run: python3 -m modal setup (interactive auth)
- Guide user through account creation/login
- Saves token to ~/.modal.toml

**Lambda Labs:**
- Create lambda_config.json with api_key, region, instance_type fields
- Instruct: Get API key from https://cloud.lambdalabs.com/api-keys

**RunPod:**
- Create runpod_config.json with api_key, gpu_type, container_disk_size_gb fields
- Instruct: Get API key from https://www.runpod.io/console/user/settings

Complete authentication setup for $ARGUMENTS platform.")

Phase 5: Create Platform Files
Goal: Create GPU image definition and test script

Actions:
Task(description="Create platform integration files", subagent_type="ml-architect", prompt="You are the ml-architect agent. Create GPU platform files for $ARGUMENTS:

**Modal:** Create modal_image.py with:
- modal.Image.debian_slim() with torch, transformers, accelerate
- @stub.function(gpu='A100') training function
- test_platform.py to verify GPU access

**Lambda Labs:** Create lambda_image.py with:
- launch_instance() function for GPU instances
- test_platform.py to verify API connection

**RunPod:** Create runpod_image.py with:
- create_pod() function for GPU pods
- test_platform.py to verify API connection

Include error handling and GPU verification.")

Phase 6: Summary and Next Steps
Goal: Provide user with setup confirmation and usage guide

Actions:
Display summary:
- Platform integrated: [platform name]
- SDK installed: [version]
- Configuration files created
- Image definition ready
- Authentication status: [configured/needs API key]

Next steps:
1. **For Modal**: Run `python test_platform.py` to verify GPU access
2. **For Lambda/RunPod**: Add API key to config file, then test
3. Use platform for training: See docs/[platform]-training.md
4. Estimate costs: Check platform pricing calculator
5. Set up W&B logging: Run `/ml-training:add-tracking wandb`

Important Notes:
- Modal has free tier with GPU credits
- Lambda Labs requires payment for GPU hours
- RunPod bills by the minute for GPU usage
- Always terminate instances after training to avoid charges
- Consider using spot instances for cost savings
