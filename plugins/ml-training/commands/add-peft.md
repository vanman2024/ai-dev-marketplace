---
description: Add parameter-efficient fine-tuning (LoRA/QLoRA/prefix-tuning)
argument-hint: <lora|qlora|prefix-tuning>
allowed-tools: Task, Read, Write, Bash, Grep, Glob, AskUserQuestion, Skill
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

Goal: Configure and add parameter-efficient fine-tuning (PEFT) methods to reduce memory usage and training costs while maintaining model performance

Core Principles:
- Support multiple PEFT methods (LoRA, QLoRA, prefix-tuning)
- Optimize memory efficiency for cloud GPU usage
- Maintain compatibility with HuggingFace PEFT library
- Provide clear memory savings estimates

Phase 1: Discovery
Goal: Understand PEFT method and project requirements

Actions:
- Parse $ARGUMENTS to extract PEFT method (lora/qlora/prefix-tuning)
- If $ARGUMENTS is unclear or missing, use AskUserQuestion to gather:
  - Which PEFT method? (lora/qlora/prefix-tuning)
  - Target model architecture? (llama/mistral/gpt/t5)
  - Training task type? (text-generation/classification/seq2seq)
  - Memory constraints or GPU size?
- Validate that PEFT method is supported
- Check current project setup: !{bash ls -la train*.py config/ 2>/dev/null || echo "No training files found"}

Phase 2: Environment Check
Goal: Verify dependencies and existing configuration

Actions:
- Check for PEFT library installation: !{bash pip list | grep peft || echo "PEFT not installed"}
- Verify transformers version compatibility: !{bash pip list | grep transformers}
- Check for existing training configuration: @config/training_config.json (if exists)
- Locate training script: !{bash find . -name "train*.py" -o -name "*training*.py" | head -5}
- Check for existing PEFT config: !{bash test -f config/peft_config.json && echo "Found" || echo "Not found"}

Phase 3: Configuration Analysis
Goal: Analyze current training setup

Actions:
- Search for model initialization code: !{bash grep -r "AutoModel\|from_pretrained" *.py config/ 2>/dev/null | head -10}
- Check training arguments: !{bash grep -r "TrainingArguments\|Trainer" *.py 2>/dev/null | head -10}
- Identify model size and architecture from existing code
- Determine current memory requirements
- Present findings to user for confirmation

Phase 4: PEFT Configuration
Goal: Create PEFT configuration using specialized agent

Actions:

Task(description="Configure PEFT method", subagent_type="peft-specialist", prompt="You are the peft-specialist agent. Configure parameter-efficient fine-tuning for $ARGUMENTS.

PEFT Method Information:
- Method: [Extracted from arguments - lora/qlora/prefix-tuning]
- Model architecture: [From user input or detected]
- Task type: [From user input or detected]
- Memory constraints: [From user input]

Requirements:
- Install PEFT library if not present: pip install peft
- Create appropriate PEFT configuration based on method:
  - LoRA: Set rank (r), alpha, dropout, target modules
  - QLoRA: Add 4-bit quantization config, NF4 type, compute dtype
  - Prefix-tuning: Set num_virtual_tokens, task type
- Update training script to wrap model with get_peft_model()
- Configure training arguments for PEFT (gradient checkpointing, bf16/fp16)
- Add memory-efficient optimizer (paged_adamw_8bit for QLoRA)
- Calculate and report memory savings estimate
- Create config/peft_config.json with all settings

Expected output:
- PEFT configuration created and saved
- Training script updated with PEFT integration
- Memory savings estimate (e.g., '75% reduction for QLoRA')
- Trainable parameters comparison (before/after)
- Configuration saved to config/peft_config.json")

Phase 5: Verification
Goal: Verify PEFT configuration was applied correctly

Actions:
- Check that PEFT configuration was created: !{bash test -f config/peft_config.json && echo "Created" || echo "Missing"}
- Read configuration: @config/peft_config.json
- Verify training script was updated: !{bash grep -n "get_peft_model\|LoraConfig\|PeftConfig" train*.py 2>/dev/null | head -5}
- Validate PEFT library is installed: !{bash python -c "import peft; print(f'PEFT version: {peft.__version__}')" 2>/dev/null || echo "Import failed"}
- Run dry-run to check trainable parameters: !{bash python -c "import json; config = json.load(open('config/peft_config.json')); print(f'Method: {config.get(\"peft_type\", \"unknown\")}')" 2>/dev/null || echo "Manual check needed"}

Phase 6: Summary
Goal: Report PEFT configuration results

Actions:
- Display configuration summary:
  - PEFT method configured
  - Target modules for parameter-efficient training
  - Estimated memory savings
  - Trainable vs. frozen parameters
  - Configuration file location
  - Updated training script path
- Provide memory efficiency metrics:
  - Original model parameters
  - Trainable parameters with PEFT
  - Percentage reduction
  - Estimated GPU memory requirement
- Suggest next steps:
  - Review config/peft_config.json for fine-tuning
  - Test with small batch: python train.py --dry_run
  - Monitor memory usage during training
  - Use /ml-training:add-platform to deploy on cloud GPU
