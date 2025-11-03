---
description: Add training dataset from Supabase/local/HuggingFace
argument-hint: <source-type> [path]
allowed-tools: Task, Read, Write, Bash, Grep, Glob, mcp__supabase, AskUserQuestion, Skill
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
