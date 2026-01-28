---
description: Build complete ML training pipeline - initializes if needed, then runs specialized agents for data prep, training, optimization, and deployment
argument-hint: <project-name> [--platform <modal|runpod|vertex>]
---

# Build Complete ML Training Pipeline

**Goal:** Create a production-ready ML training pipeline by orchestrating all specialized agents.

**This command handles everything** - from data preparation to distributed training, optimization, and inference deployment.

## Stack (Always Use Latest Versions)

- **PyTorch** / **Transformers** - Latest for training
- **PEFT** / **LoRA** - Latest for efficient fine-tuning
- **Accelerate** / **DeepSpeed** - Latest for distributed training
- **Modal** / **RunPod** / **Vertex AI** - Latest cloud GPU platforms

**IMPORTANT:** Always use the latest versions. Check pip for current versions.

## Arguments

- `$ARGUMENTS` - Project name and optional platform
- `--platform <name>` - GPU platform (modal, runpod, vertex)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and platform preference
2. Discover architecture documentation for ML requirements
3. Analyze model type, dataset size, and compute needs
4. Plan training strategy (full vs PEFT, single vs distributed)

### Phase 2: Architecture Design

```
Task("Design ML architecture", @ml-architect, {
  prompt: "Design ML pipeline architecture:
    - Analyze model requirements from architecture
    - Select training approach (full fine-tune, LoRA, QLoRA)
    - Choose compute platform based on budget/scale
    - Design experiment tracking strategy
    Create high-level pipeline design."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Data Engineering
Task("Prepare data pipeline", @data-engineer, {
  prompt: "Build data preparation pipeline:
    - Create data loading from Supabase/files
    - Implement preprocessing and tokenization
    - Add data validation and cleaning
    - Configure train/val/test splits
    Follow data requirements from architecture."
})

// Agent 2: Training Configuration
Task("Configure training", @training-architect, {
  prompt: "Set up training configuration:
    - Configure model and tokenizer
    - Set hyperparameters
    - Implement learning rate scheduling
    - Add gradient checkpointing if needed
    Optimize for selected platform."
})

// Agent 3: PEFT Setup (if applicable)
Task("Setup PEFT", @peft-specialist, {
  prompt: "Configure parameter-efficient training:
    - Set up LoRA/QLoRA configuration
    - Configure target modules
    - Implement adapter merging
    - Add quantization if specified
    Skip if full fine-tuning selected."
})

// Agent 4: Distributed Training (if needed)
Task("Configure distributed", @distributed-training-specialist, {
  prompt: "Set up distributed training if multi-GPU:
    - Configure FSDP or DeepSpeed
    - Set up model sharding
    - Implement gradient synchronization
    - Configure checkpointing
    Skip if single-GPU."
})

// Agent 5: Cost Optimization
Task("Optimize costs", @cost-optimizer, {
  prompt: "Optimize training costs:
    - Select optimal GPU type
    - Configure spot instances
    - Set up early stopping
    - Implement checkpoint saving
    Minimize costs while maintaining quality."
})

// Agent 6: Platform Integration
Task("Setup platform", @modal-specialist, {
  prompt: "Configure cloud platform:
    - Set up Modal/RunPod/Vertex deployment
    - Configure GPU instances
    - Implement training script packaging
    - Add resource management
    Use selected platform."
})
```

### Phase 4: Monitoring & Deployment

```
// Training monitoring
Task("Setup monitoring", @training-monitor, {
  prompt: "Configure training monitoring:
    - Set up WandB or TensorBoard
    - Implement metrics logging
    - Add alerting for issues
    - Configure experiment tracking
    Enable full observability."
})

// Inference deployment
Task("Deploy inference", @inference-deployer, {
  prompt: "Prepare model deployment:
    - Export trained model
    - Configure inference endpoint
    - Set up model versioning
    - Add A/B testing capability
    Output deployment configuration."
})
```

### Phase 5: Final Output

**Provide summary:**
- Training pipeline architecture
- Estimated costs and duration
- Run commands:
  ```bash
  # Start training locally
  python train.py --config config.yaml
  
  # Deploy to Modal
  modal run train.py
  
  # Start inference server
  python serve.py
  ```

## Utility Commands

- `/ml-training:prepare-data` - Data preparation only
- `/ml-training:configure-training` - Training config only
- `/ml-training:add-peft` - Add LoRA/QLoRA
- `/ml-training:add-distributed` - Add multi-GPU support
- `/ml-training:deploy-modal` - Deploy to Modal
- `/ml-training:deploy-runpod` - Deploy to RunPod
