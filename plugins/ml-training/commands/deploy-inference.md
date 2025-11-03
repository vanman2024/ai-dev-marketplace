---
description: Deploy trained model for serverless inference
argument-hint: <model-path>
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

Goal: Deploy trained model to serverless endpoint with auto-scaling and return accessible URL

Core Principles:
- Validate model exists before deployment
- Select optimal serverless platform based on model requirements
- Configure auto-scaling for cost efficiency
- Provide clear endpoint access information

Phase 1: Validation
Goal: Parse arguments and validate model availability

Actions:
- Parse $ARGUMENTS for model path
- Validate model path is provided:
  - !{bash echo "$ARGUMENTS" | grep -q . && echo "valid" || echo "Usage: /ml-training:deploy-inference <model-path>"}
- Check if model file/directory exists:
  - !{bash test -e "$ARGUMENTS" && echo "Model found" || echo "Error: Model not found at $ARGUMENTS"}
- Determine model type and size:
  - !{bash du -sh "$ARGUMENTS" 2>/dev/null}
  - !{bash file "$ARGUMENTS" 2>/dev/null || ls -lh "$ARGUMENTS" 2>/dev/null}

Phase 2: Discovery
Goal: Understand deployment context and requirements

Actions:
- Check for existing deployment configurations:
  - !{bash find . -name "inference_*.py" -o -name "deploy_*.py" -o -name "*.modal.py" 2>/dev/null | head -5}
- Load model metadata if available:
  - @config.json (if exists in model path)
  - @model_card.md (if exists)
- Check for requirements files:
  - !{bash ls requirements.txt inference_requirements.txt 2>/dev/null}

Phase 3: Platform Selection
Goal: Determine optimal serverless platform

Actions:
- Analyze model characteristics from Phase 1
- Select platform based on:
  - Model size: Large models (>5GB) -> RunPod or Lambda Labs
  - HuggingFace models -> Modal with GPU support
  - Custom models -> Modal or RunPod with custom container
- Display selected platform and reasoning

Phase 4: Deployment
Goal: Deploy model to serverless endpoint with inference-deployer agent

Actions:

Task(description="Deploy model to serverless inference", subagent_type="inference-deployer", prompt="You are the inference-deployer agent. Deploy the trained model at $ARGUMENTS to a serverless inference endpoint.

Model Path: $ARGUMENTS

Deployment Requirements:
1. Create serverless inference endpoint:
   - Use Modal, RunPod, or Lambda Labs based on model requirements
   - Configure GPU acceleration if model requires it
   - Set up model loading and inference handler
   - Implement health check endpoint

2. Configure auto-scaling:
   - Set min replicas to 0 (scale to zero when idle)
   - Set max replicas based on expected load (default: 10)
   - Configure scale-up threshold (requests per second)
   - Configure scale-down timeout (idle seconds before shutdown)

3. Set up API endpoint:
   - Create /predict or /generate endpoint
   - Accept JSON input with model-specific parameters
   - Return predictions in JSON format
   - Add error handling and validation

4. Configure environment:
   - Load model weights from path
   - Set up dependencies (transformers, torch, etc.)
   - Configure memory limits
   - Set timeout thresholds

5. Create deployment files:
   - inference_endpoint.py (main handler)
   - deploy_inference.sh (deployment script)
   - Update requirements with inference dependencies

Deliverable:
- Deployment files created
- Endpoint URL (or instructions to get URL after deployment)
- Example curl command to test endpoint
- Auto-scaling configuration summary")

Phase 5: Verification
Goal: Verify deployment configuration and test endpoint

Actions:
- List deployment files created:
  - !{bash ls -lh inference_*.py deploy_*.sh 2>/dev/null}
- Display deployment configuration:
  - Show auto-scaling settings
  - Show resource limits (GPU, memory)
  - Show timeout configuration
- Test deployment locally if possible:
  - !{bash python -m py_compile inference_*.py 2>/dev/null && echo "Syntax valid" || echo "Check for syntax errors"}

Phase 6: Summary
Goal: Provide deployment results and access information

Actions:
- Display deployment summary:
  - Model deployed: [model-path]
  - Platform: [selected-platform]
  - Endpoint URL or deployment instructions
  - Auto-scaling config: min=0, max=10, idle-timeout=60s
- Show testing command:
  - Example: curl -X POST [endpoint-url]/predict -H "Content-Type: application/json" -d '{"input": "test"}'
- Show next steps:
  - "Deploy to cloud: bash deploy_inference.sh"
  - "Monitor endpoint: [platform-specific monitoring URL]"
  - "Scale configuration: Edit auto-scaling in inference_endpoint.py"
  - "Update model: Re-run with new model path"
- Display cost optimization tips:
  - "Endpoint scales to zero when idle (no cost)"
  - "Adjust max replicas based on expected load"
  - "Monitor cold start times and adjust keep-warm settings if needed"
