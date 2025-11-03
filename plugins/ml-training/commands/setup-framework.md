---
description: Configure training framework (HuggingFace/PyTorch Lightning/Ray)
argument-hint: <huggingface|pytorch-lightning|ray>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, Skill
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

Goal: Configure ML training framework with dependencies, cloud image definitions, and config files

Core Principles:
- Validate framework choice before proceeding
- Add dependencies to both local and cloud environments
- Create framework-specific configuration files
- Verify installation and imports work

Phase 1: Validation
Goal: Parse and validate framework argument

Actions:
- Parse $ARGUMENTS for framework choice (huggingface, pytorch-lightning, or ray)
- Validate framework is one of the supported options
- If invalid or missing, display usage: "Usage: /ml-training:setup-framework <huggingface|pytorch-lightning|ray>"
- Display which framework is being configured

Phase 2: Discovery
Goal: Understand current project setup

Actions:
- Check for existing requirements files:
  - !{bash ls requirements.txt pyproject.toml setup.py 2>/dev/null || echo "none"}
- Check for existing cloud configuration:
  - !{bash find . -name "modal_*.py" -o -name "runpod_*.py" -o -name "lambda_*.py" 2>/dev/null | head -5}
- Load existing requirements if found:
  - @requirements.txt (if exists)
  - @pyproject.toml (if exists)

Phase 3: Framework Configuration
Goal: Configure framework dependencies and files

Actions:

Task(description="Configure ML framework", subagent_type="ml-architect", prompt="You are the ml-architect agent. Configure $ARGUMENTS framework for ML training.

Framework: $ARGUMENTS

Configuration Tasks:
1. Add framework dependencies to requirements file:
   - HuggingFace: transformers, datasets, accelerate, peft, bitsandbytes
   - PyTorch Lightning: pytorch-lightning, torchmetrics, lightning-bolts
   - Ray: ray[train], ray[tune], ray[data]

2. Update cloud image definitions to include framework:
   - Add pip install commands for cloud platforms (Modal/RunPod/Lambda)
   - Ensure GPU-compatible versions specified
   - Pin versions for reproducibility

3. Create framework configuration file:
   - HuggingFace: Create training_config.yaml with model, dataset, training args
   - PyTorch Lightning: Create lightning_config.yaml with trainer config
   - Ray: Create ray_config.yaml with scaling config and compute resources

4. Add example training script stub if none exists:
   - Framework-specific training loop template
   - Cloud deployment wrapper

Deliverable: All files updated/created with framework dependencies and configs")

Phase 4: Verification
Goal: Verify framework installation works

Actions:
- Attempt to import framework to verify installation:
  - HuggingFace: !{bash python -c "import transformers; print(f'transformers version: {transformers.__version__}')" 2>&1 || echo "Install with: pip install -r requirements.txt"}
  - PyTorch Lightning: !{bash python -c "import pytorch_lightning; print(f'pytorch-lightning version: {pytorch_lightning.__version__}')" 2>&1 || echo "Install with: pip install -r requirements.txt"}
  - Ray: !{bash python -c "import ray; print(f'ray version: {ray.__version__}')" 2>&1 || echo "Install with: pip install -r requirements.txt"}
- List files created/modified:
  - !{bash ls -lh requirements.txt *_config.yaml train_*.py 2>/dev/null}

Phase 5: Summary
Goal: Report configuration results

Actions:
- Display what was configured:
  - Framework name and version
  - Files created or updated
  - Dependencies added
  - Configuration files created
- Show next steps:
  - "Install dependencies: pip install -r requirements.txt"
  - "Review config file: cat <framework>_config.yaml"
  - "Test cloud deployment: /ml-training:deploy-cloud <modal|runpod|lambda>"
- Note any warnings or issues from verification phase
