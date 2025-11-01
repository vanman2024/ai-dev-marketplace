---
description: Configure training framework (HuggingFace/PyTorch Lightning/Ray)
argument-hint: <huggingface|pytorch-lightning|ray>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
---

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
