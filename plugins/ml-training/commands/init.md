---
description: Initialize ML training project with cloud GPU setup
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion, SlashCommand, Skill
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

Goal: Set up complete ML training project with Python environment, cloud GPU configuration, and proper directory structure optimized for Modal/cloud execution

Core Principles:
- Verify foundation tools first (Python, pip) using /foundation commands
- Lightweight local dependencies (Modal CLI, datasets, supabase)
- Heavy ML dependencies (torch, transformers) run on cloud GPU only
- Clear separation between local and cloud environments

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


## Phase 1: Foundation Verification

Goal: Ensure Python and required tools are available

Actions:
- Parse $ARGUMENTS for project name (default: current directory name)
- Run /foundation:detect to identify Python in project
- Run /foundation:env-check to validate Python 3.9+ installed
- If Python missing, report installation instructions and exit
- Detect OS for environment activation: !{bash uname -s}

## Phase 2: Environment Setup

Goal: Create .env file and virtual environment

Actions:
- Run /foundation:env-vars generate to create .env with:
  - MODAL_TOKEN_ID, MODAL_TOKEN_SECRET
  - ANTHROPIC_API_KEY, SUPABASE_URL, SUPABASE_ANON_KEY
  - HUGGINGFACE_TOKEN, WANDB_API_KEY
- Check if venv exists: !{bash test -d venv && echo "exists" || echo "none"}
- If exists, ask user: Use existing, Delete and recreate, or Skip
- Create venv: !{bash python3 -m venv venv}
- Upgrade pip: !{bash ./venv/bin/pip install --upgrade pip}
- Report activation command: Windows vs Linux/Mac

## Phase 3: Dependencies

Goal: Install lightweight local tools (NO heavy ML libraries)

Actions:
- Create requirements-local.txt with Modal CLI, datasets, supabase, wandb, python-dotenv, tqdm
- Install: !{bash ./venv/bin/pip install -r requirements-local.txt}
- Create requirements-gpu.txt with torch, transformers, accelerate, bitsandbytes, peft, trl (cloud only)
- Report: "Local tools installed. GPU libraries install on Modal cloud."

## Phase 4: Project Structure

Goal: Create ML-specific directories and configuration

Actions:
- Create directories:
  - !{bash mkdir -p data/raw data/processed data/cache}
  - !{bash mkdir -p models/checkpoints models/final}
  - !{bash mkdir -p logs/training logs/evaluation}
  - !{bash mkdir -p scripts notebooks}
- Create .gitignore with patterns for: venv/, .env, data/*, models/*, logs/*, __pycache__/, .ipynb_checkpoints/, .modal_cache/, wandb/
- Create README.md with:
  - Setup instructions (activate venv, configure .env, authenticate Modal)
  - Directory structure explanation
  - Running training: modal run scripts/train.py
  - Local vs Cloud dependencies distinction

## Phase 5: Summary

Goal: Display setup completion and next steps

Actions:
- Show summary:
  - Project: $ARGUMENTS initialized for ML training
  - Python: {version} detected
  - Virtual environment: Created at ./venv
  - Local dependencies: Modal CLI, datasets, supabase installed
  - GPU dependencies: Ready for cloud execution
  - Directories: data/, models/, logs/, scripts/, notebooks/
  - Environment: .env generated (fill in API keys)
- Next steps:
  1. Activate venv: source venv/bin/activate (Linux/Mac) or venv\Scripts\activate (Windows)
  2. Fill in .env file with API keys
  3. Authenticate Modal: modal token new
  4. Test setup: modal app list
  5. Create training script in scripts/train.py
  6. Run on cloud GPU: modal run scripts/train.py
- Warnings:
  - Do NOT install torch/transformers locally
  - Add large data files to .gitignore
  - Never commit .env file
