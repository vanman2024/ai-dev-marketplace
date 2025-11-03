---
description: Add training monitoring and logging (TensorBoard/WandB)
argument-hint: [monitoring-tool] [metrics]
allowed-tools: Task, Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Skill
---
## Available Skills

This commands has access to the following skills from the ml-training plugin:

- **cloud-gpu-configs**: Platform-specific configuration templates for Modal, Lambda Labs, and RunPod with GPU selection guides\n- **cost-calculator**: Cost estimation scripts and tools for calculating GPU hours, training costs, and inference pricing across Modal, Lambda Labs, and RunPod platforms. Use when estimating ML training costs, comparing platform pricing, calculating GPU hours, budgeting for ML projects, or when user mentions cost estimation, pricing comparison, GPU budgeting, training cost analysis, or inference cost optimization.\n- **example-projects**: Provides three production-ready ML training examples (sentiment classification, text generation, RedAI trade classifier) with complete training scripts, deployment configs, and datasets. Use when user needs example projects, reference implementations, starter templates, or wants to see working code for sentiment analysis, text generation, or financial trade classification.\n- **integration-helpers**: Integration templates for FastAPI endpoints, Next.js UI components, and Supabase schemas for ML model deployment. Use when deploying ML models, creating inference APIs, building ML prediction UIs, designing ML database schemas, integrating trained models with applications, or when user mentions FastAPI ML endpoints, prediction forms, model serving, ML API deployment, inference integration, or production ML deployment.\n- **monitoring-dashboard**: Training monitoring dashboard setup with TensorBoard and Weights & Biases (WandB) including real-time metrics tracking, experiment comparison, hyperparameter visualization, and integration patterns. Use when setting up training monitoring, tracking experiments, visualizing metrics, comparing model runs, or when user mentions TensorBoard, WandB, training metrics, experiment tracking, or monitoring dashboard.\n- **training-patterns**: Templates and patterns for common ML training scenarios including text classification, text generation, fine-tuning, and PEFT/LoRA. Provides ready-to-use training configurations, dataset preparation scripts, and complete training pipelines. Use when building ML training pipelines, fine-tuning models, implementing classification or generation tasks, setting up PEFT/LoRA training, or when user mentions model training, fine-tuning, classification, generation, or parameter-efficient tuning.\n- **validation-scripts**: Data validation and pipeline testing utilities for ML training projects. Validates datasets, model checkpoints, training pipelines, and dependencies. Use when validating training data, checking model outputs, testing ML pipelines, verifying dependencies, debugging training failures, or ensuring data quality before training.\n
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

Goal: Set up comprehensive training monitoring and logging infrastructure using TensorBoard or Weights & Biases (WandB) for ML training workflows

Core Principles:
- Support both TensorBoard and WandB monitoring tools
- Integrate seamlessly with existing training scripts
- Provide real-time metrics visualization
- Enable experiment tracking and comparison

Phase 1: Discovery
Goal: Understand monitoring requirements and current setup

Actions:
- Parse $ARGUMENTS to extract monitoring tool preference and metrics
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - Which monitoring tool? (tensorboard/wandb/both)
  - What metrics to track? (loss/accuracy/lr/custom)
  - Existing training script location?
  - Remote logging needed? (yes/no)
- Check current project structure: !{bash ls -la 2>/dev/null}
- Look for existing training scripts: !{bash find . -name "train*.py" -o -name "*training*.py" 2>/dev/null | head -5}

Phase 2: Environment Check
Goal: Verify dependencies and training framework

Actions:
- Detect ML framework in use
- Check for PyTorch: !{bash pip list | grep -i torch || echo "Not found"}
- Check for TensorFlow: !{bash pip list | grep -i tensorflow || echo "Not found"}
- Check existing monitoring tools: !{bash pip list | grep -E "tensorboard|wandb" || echo "None installed"}
- Load existing training script if found: @train.py (if exists)
- Check for existing monitoring configuration

Phase 3: Configuration Preparation
Goal: Prepare monitoring tool configuration

Actions:
- Based on selected tool, prepare configuration:
  - **TensorBoard**: Set up log directory structure
  - **WandB**: Prepare API key prompt and project settings
- Check for existing logs: !{bash ls -la logs/ runs/ wandb/ 2>/dev/null || echo "No log directories"}
- Verify write permissions: !{bash test -w . && echo "Writable" || echo "Permission issue"}
- Prepare metrics configuration based on user requirements

Phase 4: Monitoring Integration
Goal: Integrate monitoring using specialized agent

Actions:

Task(description="Set up training monitoring", subagent_type="training-monitor", prompt="You are the training-monitor agent. Set up monitoring and logging infrastructure for ML training with $ARGUMENTS.

Monitoring Configuration:
- Tool: [Extracted from arguments or user input]
- Metrics: [Extracted from arguments or user input]
- Training script: [Detected or provided path]
- Framework: [Detected ML framework]

Requirements:
- Install required monitoring libraries (tensorboard and/or wandb)
- Create monitoring configuration file (monitoring_config.json)
- Integrate logging callbacks into training script
- Set up log directory structure (logs/ or wandb/)
- Add metric tracking code for specified metrics
- Configure visualization dashboard settings
- For WandB: Add API key configuration instructions
- For TensorBoard: Create tensorboard launch script

Integration Tasks:
- Add monitoring imports to training script
- Initialize monitoring client (TensorBoard SummaryWriter or wandb.init)
- Add logging callbacks for metrics tracking
- Configure periodic checkpoint logging
- Add visualization for loss curves, accuracy, learning rate
- Set up custom metric tracking if specified
- Test monitoring integration with dummy data

Expected output:
- monitoring_config.json with tool settings
- Updated training script with monitoring integrated
- Launch script (start_tensorboard.sh or wandb_setup.md)
- Quick start guide for using the monitoring tools
- Example commands to view logs and dashboards")

Phase 5: Verification
Goal: Verify monitoring setup is complete

Actions:
- Check monitoring configuration was created: @monitoring_config.json
- Verify training script was updated
- Check for launch scripts: !{bash ls -la start_tensorboard.sh wandb_setup.md 2>/dev/null || echo "Check monitoring files"}
- Test monitoring imports: !{bash python -c "import tensorboard; print('TensorBoard OK')" 2>/dev/null || python -c "import wandb; print('WandB OK')" 2>/dev/null || echo "Verify installation"}
- Verify log directories exist: !{bash ls -la logs/ wandb/ 2>/dev/null || echo "Log directories not yet created"}

Phase 6: Summary
Goal: Report monitoring setup results

Actions:
- Display setup summary:
  - Monitoring tool(s) installed
  - Metrics being tracked
  - Log directory locations
  - Dashboard access instructions
  - Configuration file location
- Provide usage instructions:
  - How to launch monitoring dashboard
  - How to view real-time metrics
  - How to compare experiments
  - How to access remote dashboards (if WandB)
- Suggest next steps:
  - Run training to test monitoring: python train.py
  - View TensorBoard: tensorboard --logdir=logs
  - View WandB: wandb login && check dashboard URL
  - Review monitoring_config.json for customization
