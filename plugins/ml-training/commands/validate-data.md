---
description: Validate training data quality and format
argument-hint: [dataset-path]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

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

Goal: Validate machine learning training data for quality, format consistency, and structural integrity, providing comprehensive statistics and issue reporting.

Core Principles:
- Detect data characteristics, don't assume format
- Validate comprehensively across multiple dimensions
- Provide actionable feedback with clear statistics
- Support common ML data formats (CSV, JSON, Parquet, NPY)

Phase 1: Discovery
Goal: Parse arguments and detect dataset format

Actions:
- Extract dataset path from $ARGUMENTS
- Verify dataset exists and is accessible
- Detect file format based on extension
- Example: !{bash test -e "$ARGUMENTS" && echo "Found: $ARGUMENTS" || echo "Error: Dataset not found"}
- List dataset files if directory provided
- Example: !{bash if [ -d "$ARGUMENTS" ]; then ls -lh "$ARGUMENTS"; fi}

Phase 2: Format Detection
Goal: Identify dataset type and structure

Actions:
- Determine file type (CSV, JSON, Parquet, NPY, etc.)
- Check if single file or directory of files
- Example: !{bash file "$ARGUMENTS"}
- For CSV: Detect delimiter, quote character, header presence
- For JSON: Check if JSONL, nested, or array format
- Report detected format to user

Phase 3: Data Validation
Goal: Run comprehensive validation checks

Actions:

**For CSV files:**
- Check header row exists and is valid
- Count rows and columns
- Example: !{bash head -1 "$ARGUMENTS" && wc -l "$ARGUMENTS"}
- Detect column data types
- Check for missing values per column
- Identify duplicate rows
- Validate delimiter consistency
- Example: !{bash awk -F',' '{print NF}' "$ARGUMENTS" | sort -u}

**For JSON files:**
- Validate JSON syntax
- Example: !{bash python3 -m json.tool "$ARGUMENTS" > /dev/null && echo "Valid JSON" || echo "Invalid JSON"}
- Check schema consistency across records
- Count total records
- Identify missing or null fields

**For Parquet files:**
- Use Python to read and validate
- Example: !{bash python3 -c "import pandas as pd; df=pd.read_parquet('$ARGUMENTS'); print(f'Rows: {len(df)}, Cols: {len(df.columns)}')"}
- Check schema and data types
- Report compression and size

**For NumPy files:**
- Validate array shape and dtype
- Example: !{bash python3 -c "import numpy as np; arr=np.load('$ARGUMENTS'); print(f'Shape: {arr.shape}, Dtype: {arr.dtype}')"}
- Check for NaN or inf values

Phase 4: Quality Checks
Goal: Assess data quality metrics

Actions:
- Calculate basic statistics (min, max, mean for numeric columns)
- Identify outliers or anomalous values
- Check class distribution for classification datasets
- Detect data imbalance issues
- Validate value ranges are reasonable
- Check file size and memory requirements
- Example: !{bash du -h "$ARGUMENTS"}

Phase 5: Issue Reporting
Goal: Summarize validation results and flag problems

Actions:
- Report dataset statistics:
  - Total records/rows
  - Number of features/columns
  - Data types per column
  - Missing value counts
  - File size
- Flag critical issues:
  - Format errors
  - Missing values exceeding threshold
  - Duplicate records
  - Class imbalance
  - Invalid data types
- Provide warnings for potential problems:
  - Small dataset size
  - High missing value percentage
  - Inconsistent formats
- Suggest fixes for identified issues

Phase 6: Summary
Goal: Present comprehensive validation report

Actions:
- Display validation summary:
  - Dataset: [path]
  - Format: [detected format]
  - Status: PASS/FAIL
  - Records: [count]
  - Features: [count]
  - Issues Found: [count]
- List all issues with severity (CRITICAL/WARNING/INFO)
- Recommend next steps:
  - If PASS: Ready for training
  - If FAIL: List required fixes
  - Suggest data cleaning commands if applicable
- Save validation report to file if requested
- Example: !{bash echo "Validation complete for $ARGUMENTS"}
