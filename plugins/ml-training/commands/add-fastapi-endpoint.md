---
description: Add ML inference endpoint to FastAPI backend
argument-hint: [model-name]
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

Goal: Create FastAPI endpoint for ML model inference with proper request/response handling and error handling

Core Principles:
- Detect project structure before modifying
- Follow existing FastAPI patterns
- Validate model exists before creating endpoint
- Generate type-safe Pydantic models

Phase 1: Discovery
Goal: Understand project structure and model configuration

Actions:
- Parse $ARGUMENTS for model name
- Detect FastAPI backend location
- Example: !{bash find . -name "main.py" -o -name "app.py" | grep -E "(api|backend|server)" | head -5}
- Locate model files and configuration
- Example: !{bash find . -name "*.pt" -o -name "*.pth" -o -name "*.safetensors" | head -10}
- Check for existing routers and endpoint patterns
- Example: @app/routers/ @api/routes/

Phase 2: Validation
Goal: Verify prerequisites and model availability

Actions:
- Validate model name provided in $ARGUMENTS
- Check if FastAPI is installed
- Example: !{bash python -c "import fastapi; print(fastapi.__version__)" 2>/dev/null || echo "Not installed"}
- Verify model file exists
- Confirm model can be loaded
- Check for existing endpoint with same name

Phase 3: Planning
Goal: Design endpoint structure and response models

Actions:
- Determine model input/output shapes
- Plan Pydantic request/response models
- Identify router file location
- Design error handling strategy
- Outline endpoint route and HTTP method

Phase 4: Implementation
Goal: Create FastAPI endpoint with agent

Actions:

Task(description="Create FastAPI inference endpoint", subagent_type="integration-specialist", prompt="You are the integration-specialist agent. Create a FastAPI inference endpoint for $ARGUMENTS.

Context: Model name from $ARGUMENTS, project structure from Phase 1

Requirements:
- Create Pydantic models for request/response validation
- Implement POST endpoint at /api/inference/{model-name}
- Add proper error handling (404, 422, 500)
- Load model efficiently (singleton pattern if needed)
- Add input preprocessing and output postprocessing
- Include logging for requests and errors
- Add endpoint documentation with examples
- Follow existing FastAPI patterns in codebase

Expected output: Router file with endpoint, Pydantic models, error handlers")

Phase 5: Testing
Goal: Verify endpoint functionality

Actions:
- Check endpoint is registered in FastAPI app
- Test endpoint with sample request
- Example: !{bash curl -X POST http://localhost:8000/api/inference/model -H "Content-Type: application/json" -d '{"input": "test"}'}
- Validate error handling with malformed requests
- Check logs for proper request tracking

Phase 6: Summary
Goal: Document endpoint creation and usage

Actions:
- Display endpoint URL and route
- Show example request/response
- List files created/modified:
  - Router file path
  - Pydantic models location
  - Main app registration
- Suggest next steps:
  - Add authentication if needed
  - Configure rate limiting
  - Set up monitoring
  - Add batch inference support
