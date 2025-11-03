---
description: Add training dataset from Supabase/local/HuggingFace
argument-hint: <source-type> [path]
allowed-tools: Task, Read, Write, Bash, Grep, Glob, mcp__supabase, AskUserQuestion, Skill
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

Goal: Load and validate training datasets from multiple sources (Supabase, local files, or HuggingFace) for ML training workflows

Core Principles:
- Detect source type from arguments or ask user
- Validate data format before accepting
- Support multiple data sources seamlessly
- Provide clear feedback on dataset statistics

Phase 1: Discovery
Goal: Understand dataset source and requirements

Actions:
- Parse $ARGUMENTS to extract source type and path
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - What is the data source? (supabase/local/huggingface)
  - What is the dataset path or identifier?
  - What is the expected data format? (csv/json/parquet/custom)
  - Any preprocessing requirements?
- Validate that source type is supported
- Check if project has required dependencies installed
- Example: !{bash pip list | grep -E "datasets|supabase|torch"}

Phase 2: Environment Check
Goal: Verify environment and dependencies

Actions:
- Check for datasets library installation
- If source is Supabase, verify mcp__supabase is available
- Check for existing dataset configuration
- Look for data directory: !{bash ls -la data/ 2>/dev/null || echo "No data directory"}
- Load any existing dataset configs: @data/config.json (if exists)

Phase 3: Source Validation
Goal: Verify dataset source accessibility

Actions:
- Based on source type, validate access:
  - **Supabase**: Test connection and query table structure
  - **Local**: Verify file/directory exists
  - **HuggingFace**: Verify dataset identifier is valid
- Example local check: !{bash test -f "$path" && echo "Found" || echo "Not found"}
- Present dataset source details to user for confirmation

Phase 4: Dataset Loading
Goal: Load and validate dataset using specialized agent

Actions:

Task(description="Load and validate dataset", subagent_type="data-engineer", prompt="You are the data-engineer agent. Load the dataset from $ARGUMENTS and validate its format.

Source Information:
- Source type: [Extracted from arguments]
- Path/Identifier: [Extracted from arguments]
- Expected format: [From user input or detected]

Requirements:
- Connect to data source (use mcp__supabase for Supabase sources)
- Load dataset using appropriate method (datasets library for HF, pandas for local, SQL for Supabase)
- Validate data schema and format
- Check for missing values and data quality issues
- Create data loader configuration
- Generate dataset statistics (rows, columns, dtypes, missing %)

Expected output:
- Dataset successfully loaded confirmation
- Schema and statistics summary
- Data loader configuration saved to data/loader_config.json
- Sample of first few rows for verification")

Phase 5: Verification
Goal: Verify dataset was loaded correctly

Actions:
- Check that data loader configuration was created
- Read configuration: @data/loader_config.json
- Verify dataset statistics make sense
- Check for any validation warnings from agent
- Run quick sanity check: !{bash python -c "import json; config = json.load(open('data/loader_config.json')); print(f'Loaded {config.get(\"num_rows\", 0)} rows')" 2>/dev/null || echo "Manual verification needed"}

Phase 6: Summary
Goal: Report dataset loading results

Actions:
- Display dataset summary:
  - Source type and location
  - Number of rows and columns
  - Data types and schema
  - Any quality issues detected
  - Configuration file location
- Suggest next steps:
  - Review data/loader_config.json
  - Run /ml-training:preprocess if preprocessing needed
  - Use /ml-training:train to start training
