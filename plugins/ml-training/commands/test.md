---
description: Test ML components (data/training/inference)
argument-hint: [component]
allowed-tools: Task, Bash, Read, Grep, Glob, TodoWrite, Skill
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

Goal: Run comprehensive tests on ML components (data pipelines, training jobs, inference endpoints)

Core Principles:
- Test data quality, training correctness, and inference accuracy
- Run independent tests in parallel for speed
- Provide detailed test reports with pass/fail status
- Track test progress and results

Phase 1: Discovery
Goal: Identify what components to test

Actions:
- Create test progress tracker using TodoWrite
- Parse $ARGUMENTS to determine test scope (all, data, training, inference, or specific component)
- Detect project structure and ML framework
- Example: !{bash ls -la data/ models/ 2>/dev/null}
- Load ML configuration if exists
- Example: @ml-config.yaml or @config/ml-training.json
- Identify test targets and scope
- Update todos

Phase 2: Test Environment Check
Goal: Verify test prerequisites

Actions:
- Check if test data exists: !{bash test -d data/test && echo "Found" || echo "Missing"}
- Verify model checkpoints available if needed
- Check inference endpoints if testing inference
- Load test configurations and expected outputs
- Validate environment variables and dependencies
- Update todos

Phase 3: Parallel Test Execution
Goal: Run multiple test suites simultaneously

Actions:

Run the following test agents IN PARALLEL (all at once):

Task(description="Data Quality Tests", subagent_type="ml-tester", prompt="You are the ml-tester agent focused on data testing. Run data quality tests for $ARGUMENTS.

Focus on:
- Data schema validation
- Data integrity checks
- Preprocessing pipeline correctness
- Train/val/test split verification
- Data augmentation validation

Deliverable: Data test report with pass/fail status, coverage metrics, and any issues found")

Task(description="Training Tests", subagent_type="ml-tester", prompt="You are the ml-tester agent focused on training validation. Run training tests for $ARGUMENTS.

Focus on:
- Model architecture validation
- Training loop correctness
- Loss calculation accuracy
- Gradient flow verification
- Checkpoint saving/loading
- Hyperparameter configuration

Deliverable: Training test report with pass/fail status, model metrics, and any issues found")

Task(description="Inference Tests", subagent_type="ml-tester", prompt="You are the ml-tester agent focused on inference validation. Run inference tests for $ARGUMENTS.

Focus on:
- Model loading correctness
- Prediction accuracy
- Input/output format validation
- Performance benchmarks
- Edge case handling
- API endpoint health (if applicable)

Deliverable: Inference test report with pass/fail status, accuracy metrics, latency, and any issues found")

Wait for ALL test agents to complete before proceeding.

Update todos as each test suite completes.

Phase 4: Results Consolidation
Goal: Analyze and combine test results

Actions:
- Review all test agent outputs
- Identify critical failures (blocking issues)
- Categorize warnings and recommendations
- Calculate overall test coverage and pass rate
- Cross-reference findings for validation
- Update todos

Phase 5: Summary
Goal: Present comprehensive test results

Actions:
- Mark all todos complete
- Present consolidated test report:

  **Data Tests**:
  - Pass/Fail status
  - Coverage metrics
  - Issues found

  **Training Tests**:
  - Pass/Fail status
  - Model metrics
  - Issues found

  **Inference Tests**:
  - Pass/Fail status
  - Accuracy/latency metrics
  - Issues found

  **Overall Status**:
  - Total tests run
  - Pass rate
  - Critical issues (high priority fixes needed)
  - Warnings and recommendations
  - Suggested next steps

- If failures detected, provide debugging guidance
- Recommend specific fixes or improvements
