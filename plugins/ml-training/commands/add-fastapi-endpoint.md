---
description: Add ML inference endpoint to FastAPI backend
argument-hint: [model-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
---

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
