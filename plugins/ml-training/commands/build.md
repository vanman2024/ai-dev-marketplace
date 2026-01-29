---
description: Build complete ML training pipeline for new or existing projects with data preparation, model training, distributed training, and deployment
argument-hint: [project-name] [--existing]
---

# Build ML Training Pipeline

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(ml-architect) Analyze project for ML pipeline.

Detect: Framework (PyTorch, TensorFlow), existing code
Check: Model requirements, data sources
Output: Pipeline strategy
```

---

## Phase 2: Environment Setup

**Goal:** Set up training environment

**Actions:**

```
Task(ml-architect) Set up ML environment.

Requirements:
- Configure Python environment
- Install ML frameworks
- Set up GPU support
- Configure dependencies
- Create project structure
```

---

## Phase 3: Data Pipeline

**Goal:** Set up data processing

**Actions:**

```
Task(data-specialist) Create data pipeline.

Requirements:
- Set up data loading
- Create preprocessing pipeline
- Add data augmentation
- Configure data loaders
- Add validation splits
```

---

## Phase 4: Model Architecture

**Goal:** Define model

**Actions:**

```
Task(training-architect) Create model architecture.

Requirements:
- Define model structure
- Configure layers
- Set up loss function
- Add metrics
- Create training loop
```

---

## Phase 5: Training Infrastructure

**Goal:** Set up training

**Actions:**

```
Task(training-architect) Configure training.

Requirements:
- Set up optimizer
- Configure learning rate scheduling
- Add checkpointing
- Set up logging
- Configure experiments
```

---

## Phase 6: Distributed Training

**Goal:** Add distributed support

**Actions:**

```
Task(distributed-training-specialist) Configure distributed training.

Requirements:
- Set up multi-GPU training
- Configure data parallel
- Add gradient accumulation
- Set up distributed sampler
```

---

## Phase 7: Monitoring

**Goal:** Add training monitoring

**Actions:**

```
Task(training-monitor) Set up monitoring.

Requirements:
- Add TensorBoard/W&B
- Configure metric logging
- Set up experiment tracking
- Add visualization
```

---

## Phase 8: Deployment

**Goal:** Deploy trained model

**Actions:**

```
Task(inference-deployer) Configure deployment.

Requirements:
- Export model
- Set up inference API
- Configure batching
- Add model serving
```

---

## Summary

**Output:**

```
✅ ML Training Pipeline Complete

To add features:
  /ml-training:add dataset <type>        # Data pipeline
  /ml-training:add model <arch>          # Model architecture
  /ml-training:add distributed <type>    # Distributed training
  /ml-training:add finetune <method>     # Fine-tuning
  /ml-training:add deploy <platform>     # Deployment

To train:
  python train.py
```
