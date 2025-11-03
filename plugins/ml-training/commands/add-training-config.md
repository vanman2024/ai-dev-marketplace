---
description: Create training configuration for classification/generation/fine-tuning
argument-hint: <classification|generation|fine-tuning>
allowed-tools: Task, Read, Write, Bash, Glob, Grep, Skill
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

Goal: Generate production-ready training configuration including TrainingArguments, hyperparameters, and train.py script for the specified training type.

Core Principles:
- Detect existing project structure before generating configs
- Use appropriate defaults based on training type
- Generate framework-agnostic configurations when possible
- Validate compatibility with detected ML frameworks

Phase 1: Discovery
Goal: Understand project context and training requirements

Actions:
- Parse $ARGUMENTS to extract training type (classification/generation/fine-tuning)
- Detect ML framework in use (PyTorch, TensorFlow, JAX)
- Check for existing training scripts or configurations
- Example: !{bash ls train.py training_config.yaml config/ 2>/dev/null}
- Identify project structure and data locations

Phase 2: Validation
Goal: Verify training type and environment compatibility

Actions:
- Validate training type is one of: classification, generation, fine-tuning
- Check if required dependencies are available
- Example: !{bash python -c "import transformers; import torch; import datasets" 2>&1}
- Load existing configs if present to understand patterns
- Identify GPU/CPU availability for hardware-specific settings

Phase 3: Configuration Design
Goal: Architect training configuration with optimal hyperparameters

Actions:

Task(description="Design training configuration", subagent_type="training-architect", prompt="You are the training-architect agent. Create a comprehensive training configuration for $ARGUMENTS.

Context:
- Training type: Extract from $ARGUMENTS (classification/generation/fine-tuning)
- Detected framework: Based on discovery phase findings
- Project structure: Based on codebase analysis

Requirements:
- Generate TrainingArguments configuration with appropriate hyperparameters
- Set learning rate, batch size, epochs based on training type
- Configure evaluation strategy and checkpointing
- Include mixed precision training settings (fp16/bf16)
- Set up gradient accumulation if needed
- Configure warmup steps and scheduler
- Add logging and early stopping parameters

Training Type Specific Settings:
- Classification: CrossEntropyLoss, accuracy metrics, class weights
- Generation: Language modeling loss, perplexity metrics, generation parameters
- Fine-tuning: LoRA/QLoRA configs, adapter settings, freeze layers

Deliverables:
1. training_config.yaml - Complete TrainingArguments configuration
2. train.py - Training script with data loading, model setup, trainer initialization
3. hyperparameters.json - Searchable hyperparameter ranges for tuning
4. README-TRAINING.md - Documentation on running training and tuning parameters

Follow best practices for reproducibility, mixed precision, and gradient checkpointing.")

Phase 4: File Generation
Goal: Write configuration files to project

Actions:
- Write training_config.yaml to project root or config/ directory
- Write train.py script with proper imports and setup
- Write hyperparameters.json for reference
- Create README-TRAINING.md with usage instructions
- Ensure all files follow project conventions

Phase 5: Verification
Goal: Validate generated configurations

Actions:
- Check that all required files were created
- Validate YAML/JSON syntax
- Example: !{bash python -c "import yaml; yaml.safe_load(open('training_config.yaml'))"}
- Verify train.py has no syntax errors
- Example: !{bash python -m py_compile train.py}
- Check that hyperparameters are in valid ranges

Phase 6: Summary
Goal: Report generated configuration and next steps

Actions:
- Summarize created files and their locations
- Display key hyperparameters set for the training type
- Provide command to start training
- Suggest next steps:
  - Review and adjust hyperparameters for your dataset
  - Prepare dataset using /ml-training:prepare-dataset command
  - Run training with: python train.py --config training_config.yaml
  - Monitor training with TensorBoard or wandb
  - Experiment with hyperparameter tuning ranges provided
