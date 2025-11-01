---
description: Connect ML pipeline to Supabase storage
argument-hint: [table-name]
allowed-tools: Task, Read, Write, Bash, Grep, Glob, mcp__supabase, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Integrate ML training pipeline with Supabase for storing datasets, model metadata, training metrics, and predictions

Core Principles:
- Validate Supabase connection before creating schemas
- Support flexible table naming for different ML workflows
- Ensure data persistence for datasets, metadata, and predictions
- Follow ML-specific schema patterns

Phase 1: Discovery
Goal: Understand integration requirements and current setup

Actions:
- Parse $ARGUMENTS to extract table name
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - What is the primary table name for ML data? (default: ml_training)
  - What data needs to be stored? (datasets/metadata/predictions/all)
  - Are there existing Supabase tables to integrate with?
  - What ML framework is being used? (tensorflow/pytorch/scikit-learn)
- Check for existing Supabase configuration
- Load project config if exists: @supabase/config.toml (if available)
- Verify mcp__supabase is available: !{bash echo "Checking Supabase MCP availability"}

Phase 2: Environment Check
Goal: Verify Supabase connectivity and project structure

Actions:
- Test Supabase connection using mcp__supabase
- Check for existing ML training configuration
- Look for data directory: !{bash ls -la data/ ml_data/ 2>/dev/null || echo "No ML data directory found"}
- Check for Python dependencies: !{bash pip list | grep -E "supabase|psycopg2|sqlalchemy" || echo "May need Supabase client"}
- Verify project has proper .env or config for Supabase credentials

Phase 3: Schema Planning
Goal: Design Supabase schema for ML pipeline

Actions:
- Review ML workflow requirements
- Identify required tables:
  - Datasets table (data sources, versions, statistics)
  - Training runs table (hyperparameters, metrics, timestamps)
  - Models metadata table (versions, performance, deployment status)
  - Predictions table (inference results, model used, timestamps)
- Consider RLS policies for data security
- Plan indexes for query performance

Phase 4: Integration
Goal: Create Supabase schemas and connect ML pipeline

Actions:

Task(description="Create Supabase integration", subagent_type="integration-specialist", prompt="You are the integration-specialist agent. Set up Supabase storage for ML training pipeline using table name: $ARGUMENTS.

Integration Requirements:
- Create comprehensive schema for ML data storage
- Tables needed:
  1. Datasets: id, name, source, format, rows, columns, created_at, metadata_json
  2. Training_runs: id, dataset_id, model_type, hyperparameters_json, metrics_json, status, started_at, completed_at
  3. Models: id, training_run_id, version, performance_metrics, artifact_path, deployed, created_at
  4. Predictions: id, model_id, input_data_json, prediction_result_json, confidence, created_at

Use mcp__supabase to:
- Create tables with proper types and constraints
- Set up foreign key relationships
- Create indexes on frequently queried columns (dataset_id, model_id, created_at)
- Configure RLS policies for secure access
- Create views for common queries (latest models, active training runs)

Python Integration:
- Generate Python helper functions for CRUD operations
- Create connection pooling configuration
- Add data validation before inserts
- Include batch insert utilities for predictions
- Save to: ml_pipeline/supabase_client.py

Configuration:
- Create or update .env.example with required variables
- Document connection setup in README section
- Save schema DDL to: supabase/migrations/ml_schema.sql

Expected output:
- Supabase tables created successfully
- Python client code generated
- Migration files saved
- Integration guide with usage examples")

Phase 5: Verification
Goal: Verify integration works correctly

Actions:
- Check that migration file was created: @supabase/migrations/ml_schema.sql
- Verify Python client exists: @ml_pipeline/supabase_client.py
- Test connection with simple query via mcp__supabase
- Run sanity check: !{bash python -c "from ml_pipeline.supabase_client import test_connection; test_connection()" 2>/dev/null || echo "Manual verification recommended"}
- Confirm all tables were created with proper structure

Phase 6: Summary
Goal: Report integration setup results

Actions:
- Display integration summary:
  - Tables created and their purposes
  - Python client location and key functions
  - Migration files location
  - Example usage for storing datasets
  - Example usage for logging training runs
  - Example usage for storing predictions
- Provide next steps:
  - Review supabase/migrations/ml_schema.sql
  - Configure .env with Supabase credentials
  - Test integration with: python ml_pipeline/supabase_client.py
  - Use /ml-training:add-dataset to start loading data
  - Set up RLS policies via Supabase dashboard if needed
- Highlight security considerations:
  - Keep Supabase credentials secure
  - Configure RLS policies before production
  - Use service role key only server-side
