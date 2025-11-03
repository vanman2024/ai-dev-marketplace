---
description: Optimize training settings for cost and speed
argument-hint: [config-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, Skill
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

Goal: Optimize ML training configuration for cost efficiency and training speed by tuning batch size, mixed precision, gradient accumulation, and other performance settings.

Core Principles:
- Analyze before optimizing: Understand current configuration
- Balance cost and performance: Find optimal trade-offs
- Preserve model quality: Don't sacrifice accuracy for speed
- Validate changes: Ensure configurations are valid

Phase 1: Discovery
Goal: Locate and validate training configuration

Actions:
- Parse $ARGUMENTS for config file path
- If no path provided, search for common config files:
  !{bash find . -maxdepth 3 -type f \( -name "train*.py" -o -name "train*.yaml" -o -name "train*.json" -o -name "config*.yaml" \) 2>/dev/null | head -10}
- Verify config file exists
- Load current configuration: @$ARGUMENTS

Phase 2: Analysis
Goal: Understand current training setup and identify optimization opportunities

Actions:
- Extract key training parameters from config:
  - Batch size
  - Learning rate
  - Precision settings (fp32, fp16, bf16)
  - Gradient accumulation steps
  - Number of GPUs/devices
  - Model architecture details
- Identify GPU/accelerator type if specified
- Calculate current estimated training time and cost

Phase 3: Optimization Planning
Goal: Determine optimal settings based on hardware and model

Actions:

Task(description="Optimize training configuration", subagent_type="cost-optimizer", prompt="You are the cost-optimizer agent. Analyze and optimize the training configuration at: $ARGUMENTS

Current Configuration Context:
- Review the existing training configuration
- Identify batch size, precision, gradient accumulation settings
- Understand hardware constraints and model size

Optimization Tasks:
1. **Batch Size Optimization**:
   - Calculate optimal batch size for available GPU memory
   - Consider gradient accumulation for larger effective batch sizes
   - Balance throughput vs memory usage

2. **Mixed Precision Optimization**:
   - Recommend fp16, bf16, or fp32 based on model and hardware
   - Enable automatic mixed precision (AMP) if beneficial
   - Consider gradient scaling for numerical stability

3. **Gradient Accumulation**:
   - Calculate optimal accumulation steps
   - Balance effective batch size with training speed
   - Recommend micro-batch strategies

4. **Additional Optimizations**:
   - Enable gradient checkpointing if memory-constrained
   - Optimize data loading (num_workers, pin_memory, prefetch)
   - Suggest compile optimizations (torch.compile, CUDA graphs)
   - Recommend distributed training strategies if multi-GPU

5. **Cost-Speed Trade-offs**:
   - Estimate training time with new settings
   - Calculate cost savings vs baseline
   - Provide multiple configuration tiers (balanced, fast, economical)

Expected Output:
- Updated configuration file with optimized settings
- Detailed optimization report showing:
  - Changes made to each parameter
  - Expected speedup and cost savings
  - Trade-offs and recommendations
  - Validation steps to verify improvements")

Phase 4: Validation
Goal: Verify optimized configuration is valid and ready to use

Actions:
- Check that updated config file exists
- Verify syntax is correct (YAML/JSON/Python parsing)
- Confirm all required parameters are present
- Run basic validation if training script has a --validate flag:
  !{bash python $ARGUMENTS --validate 2>&1 || echo "No validation mode available"}

Phase 5: Summary
Goal: Report optimization results and next steps

Actions:
- Display optimization summary:
  - Configuration file location
  - Key changes made (batch size, precision, etc.)
  - Expected performance improvements
  - Estimated cost savings
- Recommend next steps:
  - Test with small dataset to validate settings
  - Monitor GPU memory usage during initial runs
  - Adjust if needed based on actual performance
  - Consider A/B testing configurations
- Provide command to start training with optimized config
