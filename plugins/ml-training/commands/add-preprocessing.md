---
description: Add data preprocessing pipelines (tokenization/transforms)
argument-hint: [tokenizer|transforms]
allowed-tools: Task, Read, Write, Bash, Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: Add data preprocessing pipelines with tokenization for text data or transforms for image data, including data caching

Core Principles:
- Detect preprocessing type from arguments and existing data
- Use HuggingFace tokenizers for text, torchvision transforms for images
- Implement efficient data caching
- Test pipeline before finalizing

Phase 1: Discovery
Goal: Understand preprocessing requirements and existing setup

Actions:
- Parse $ARGUMENTS to identify preprocessing type (tokenizer vs transforms)
- Check for existing data loading code and training scripts
- Example: !{bash find . -name "*.py" -type f | grep -E "(train|data|preprocess)" | head -10}
- Detect data type from existing files (text datasets vs image datasets)
- Load any existing preprocessing configuration

Phase 2: Analysis
Goal: Understand current data pipeline and determine preprocessing needs

Actions:
- Read existing training scripts to understand data format
- Identify model type (language model vs vision model)
- Check for existing tokenizer or transform configurations
- Determine if dataset is local or HuggingFace Hub-based
- Example: !{bash grep -r "from datasets import" . 2>/dev/null | head -5}

Phase 3: Planning
Goal: Design preprocessing pipeline approach

Actions:
- Based on analysis, determine:
  - For text: Which tokenizer (model-specific or custom)
  - For images: Which transforms (resize, normalize, augmentation)
  - Caching strategy (disk vs memory)
  - Batch processing configuration
- Outline integration points with existing data loading
- Present plan to user

Phase 4: Implementation
Goal: Build preprocessing pipeline with agent

Actions:

Task(description="Create preprocessing pipeline", subagent_type="data-specialist", prompt="You are the data-specialist agent. Create a data preprocessing pipeline for $ARGUMENTS.

Context: ML training project using HuggingFace ecosystem and cloud GPUs (Modal/Lambda/RunPod)

Requirements:
- If tokenizer: Use HuggingFace AutoTokenizer with proper padding and truncation
- If transforms: Use torchvision transforms with normalization and augmentation
- Implement data caching to disk for faster iterations
- Support batch processing
- Handle common edge cases (variable length sequences, different image sizes)
- Add preprocessing test function
- Follow HuggingFace datasets .map() pattern for efficiency

Expected output:
- Preprocessing module with tokenizer or transform configuration
- Data caching setup (using datasets.save_to_disk() or torch cache)
- Test function to validate preprocessing
- Integration code for existing training pipeline")

Phase 5: Verification
Goal: Test preprocessing pipeline

Actions:
- Run preprocessing test function to verify correctness
- Example: !{bash python -c "from preprocessing import test_preprocessing; test_preprocessing()"}
- Check cache is created successfully
- Verify processed data format matches model requirements
- Test with small batch to ensure no errors

Phase 6: Summary
Goal: Document preprocessing setup

Actions:
- Summarize preprocessing pipeline created:
  - Type (tokenizer or transforms)
  - Configuration details
  - Caching location and strategy
  - Files created/modified
- Provide usage instructions:
  - How to use in training script
  - How to adjust preprocessing parameters
  - How to clear/rebuild cache
- Suggest next steps (integrate into training, tune hyperparameters)
