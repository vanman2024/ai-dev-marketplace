#!/bin/bash

# create-supabase-schema.sh - Generate Supabase schema for ML metadata storage
# Usage: ./create-supabase-schema.sh <schema-type>

set -e

SCHEMA_TYPE=$1

if [ -z "$SCHEMA_TYPE" ]; then
    echo "Usage: ./create-supabase-schema.sh <schema-type>"
    echo ""
    echo "Schema types:"
    echo "  - ml-models: Model registry with versions and metadata"
    echo "  - predictions: Prediction logs and results"
    echo "  - training-runs: Training job tracking"
    echo "  - model-versions: Version management and deployment"
    echo "  - complete: All ML-related tables"
    echo ""
    echo "Example: ./create-supabase-schema.sh ml-models"
    exit 1
fi

# Determine current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

# Find or create migrations directory
if [ -d "supabase/migrations" ]; then
    MIGRATIONS_DIR="supabase/migrations"
elif [ -d "database/migrations" ]; then
    MIGRATIONS_DIR="database/migrations"
else
    MIGRATIONS_DIR="supabase/migrations"
    mkdir -p "$MIGRATIONS_DIR"
fi

# Generate timestamp for migration
TIMESTAMP=$(date +%Y%m%d%H%M%S)
MIGRATION_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_ml_${SCHEMA_TYPE//-/_}.sql"

echo "Generating Supabase ML schema..."
echo "  Schema Type: $SCHEMA_TYPE"
echo "  Output File: $MIGRATION_FILE"

# Generate schema based on type
case $SCHEMA_TYPE in
    ml-models)
        cat > "$MIGRATION_FILE" << 'EOF'
-- ML Models Registry
-- Stores metadata about trained models including versions, metrics, and artifacts

create table if not exists ml_models (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  model_type text not null, -- classification, regression, text-generation, etc.
  framework text not null, -- scikit-learn, pytorch, tensorflow, etc.
  version text not null,
  artifact_url text, -- Cloud storage URL (S3, GCS, etc.)
  artifact_size_bytes bigint,
  metrics jsonb, -- Accuracy, F1, RMSE, etc.
  hyperparameters jsonb,
  feature_names text[],
  target_classes text[], -- For classification models
  input_schema jsonb, -- Expected input format
  output_schema jsonb, -- Expected output format
  is_active boolean default true,
  is_deployed boolean default false,
  deployment_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  created_by uuid references auth.users(id),
  unique(name, version)
);

-- Indexes for performance
create index idx_ml_models_active on ml_models(is_active, created_at desc);
create index idx_ml_models_type on ml_models(model_type);
create index idx_ml_models_deployed on ml_models(is_deployed);
create index idx_ml_models_name on ml_models(name);

-- RLS policies
alter table ml_models enable row level security;

create policy "ML models are viewable by authenticated users"
  on ml_models for select
  to authenticated
  using (true);

create policy "Users can create their own ML models"
  on ml_models for insert
  to authenticated
  with check (auth.uid() = created_by);

create policy "Users can update their own ML models"
  on ml_models for update
  to authenticated
  using (auth.uid() = created_by);

-- Updated at trigger
create or replace function update_ml_models_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger ml_models_updated_at
  before update on ml_models
  for each row
  execute function update_ml_models_updated_at();
EOF
        ;;
    predictions)
        cat > "$MIGRATION_FILE" << 'EOF'
-- Predictions Log
-- Stores all ML model predictions for monitoring, analytics, and retraining

create table if not exists predictions (
  id uuid default gen_random_uuid() primary key,
  model_id uuid references ml_models(id) on delete cascade,
  model_name text not null,
  model_version text not null,
  input_data jsonb not null,
  prediction jsonb not null,
  confidence float,
  probabilities jsonb, -- For classification models
  inference_time_ms float,
  user_id uuid references auth.users(id),
  session_id text,
  request_id text, -- For tracing
  metadata jsonb, -- Additional context
  created_at timestamptz default now()
);

-- Indexes for performance
create index idx_predictions_model on predictions(model_id, created_at desc);
create index idx_predictions_user on predictions(user_id, created_at desc);
create index idx_predictions_session on predictions(session_id);
create index idx_predictions_created_at on predictions(created_at desc);
create index idx_predictions_request_id on predictions(request_id);

-- Composite index for analytics queries
create index idx_predictions_analytics on predictions(model_id, model_version, created_at desc);

-- RLS policies
alter table predictions enable row level security;

create policy "Users can view their own predictions"
  on predictions for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can create predictions"
  on predictions for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Retention policy helper function
create or replace function delete_old_predictions(days_to_keep integer default 90)
returns integer as $$
declare
  deleted_count integer;
begin
  delete from predictions
  where created_at < now() - interval '1 day' * days_to_keep;

  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$ language plpgsql security definer;
EOF
        ;;
    training-runs)
        cat > "$MIGRATION_FILE" << 'EOF'
-- Training Runs
-- Tracks ML model training jobs, experiments, and results

create table if not exists training_runs (
  id uuid default gen_random_uuid() primary key,
  model_id uuid references ml_models(id) on delete cascade,
  run_name text not null,
  dataset_name text not null,
  dataset_size integer,
  dataset_url text,
  train_test_split jsonb, -- {train: 0.8, test: 0.2, validation: 0.1}
  hyperparameters jsonb not null,
  training_metrics jsonb, -- Loss curves, accuracy per epoch
  validation_metrics jsonb,
  test_metrics jsonb,
  final_metrics jsonb, -- Best metrics achieved
  training_duration_seconds integer,
  status text default 'running', -- running, completed, failed, cancelled
  progress_percentage integer default 0,
  current_epoch integer,
  total_epochs integer,
  error_message text,
  logs_url text, -- Training logs location
  artifact_url text, -- Trained model artifact
  checkpoint_urls text[], -- Model checkpoints during training
  gpu_hours_used float,
  compute_cost_usd float,
  created_at timestamptz default now(),
  started_at timestamptz,
  completed_at timestamptz,
  created_by uuid references auth.users(id)
);

-- Indexes for performance
create index idx_training_runs_model on training_runs(model_id, created_at desc);
create index idx_training_runs_status on training_runs(status);
create index idx_training_runs_user on training_runs(created_by, created_at desc);

-- RLS policies
alter table training_runs enable row level security;

create policy "Users can view their own training runs"
  on training_runs for select
  to authenticated
  using (auth.uid() = created_by);

create policy "Users can create training runs"
  on training_runs for insert
  to authenticated
  with check (auth.uid() = created_by);

create policy "Users can update their own training runs"
  on training_runs for update
  to authenticated
  using (auth.uid() = created_by);
EOF
        ;;
    model-versions)
        cat > "$MIGRATION_FILE" << 'EOF'
-- Model Versions
-- Manages model versions, deployments, and A/B testing

create table if not exists model_versions (
  id uuid default gen_random_uuid() primary key,
  model_id uuid references ml_models(id) on delete cascade,
  version text not null,
  parent_version text, -- Previous version for comparison
  changelog text,
  metrics jsonb not null,
  metrics_comparison jsonb, -- Comparison with previous version
  artifact_url text not null,
  artifact_size_bytes bigint,
  is_deployed boolean default false,
  deployment_url text,
  deployment_config jsonb, -- Deployment settings
  traffic_percentage integer default 0, -- For A/B testing
  created_at timestamptz default now(),
  deployed_at timestamptz,
  deprecated_at timestamptz,
  created_by uuid references auth.users(id),
  unique(model_id, version)
);

-- Indexes for performance
create index idx_model_versions_model on model_versions(model_id, created_at desc);
create index idx_model_versions_deployed on model_versions(model_id, is_deployed);
create index idx_model_versions_version on model_versions(model_id, version);

-- RLS policies
alter table model_versions enable row level security;

create policy "Model versions are viewable by authenticated users"
  on model_versions for select
  to authenticated
  using (true);

create policy "Users can create model versions"
  on model_versions for insert
  to authenticated
  with check (auth.uid() = created_by);

create policy "Users can update their own model versions"
  on model_versions for update
  to authenticated
  using (auth.uid() = created_by);

-- Function to promote a version to production
create or replace function promote_model_version(version_id uuid)
returns void as $$
begin
  -- Set all other versions to not deployed
  update model_versions
  set is_deployed = false, traffic_percentage = 0
  where model_id = (select model_id from model_versions where id = version_id);

  -- Deploy the selected version
  update model_versions
  set is_deployed = true, deployed_at = now(), traffic_percentage = 100
  where id = version_id;
end;
$$ language plpgsql security definer;
EOF
        ;;
    complete)
        # Combine all schemas
        cat > "$MIGRATION_FILE" << 'EOF'
-- Complete ML Infrastructure Schema
-- Includes models, predictions, training runs, and versioning

-- ML Models Registry
create table if not exists ml_models (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  model_type text not null,
  framework text not null,
  version text not null,
  artifact_url text,
  artifact_size_bytes bigint,
  metrics jsonb,
  hyperparameters jsonb,
  feature_names text[],
  target_classes text[],
  input_schema jsonb,
  output_schema jsonb,
  is_active boolean default true,
  is_deployed boolean default false,
  deployment_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  created_by uuid references auth.users(id),
  unique(name, version)
);

-- Predictions Log
create table if not exists predictions (
  id uuid default gen_random_uuid() primary key,
  model_id uuid references ml_models(id) on delete cascade,
  model_name text not null,
  model_version text not null,
  input_data jsonb not null,
  prediction jsonb not null,
  confidence float,
  probabilities jsonb,
  inference_time_ms float,
  user_id uuid references auth.users(id),
  session_id text,
  request_id text,
  metadata jsonb,
  created_at timestamptz default now()
);

-- Training Runs
create table if not exists training_runs (
  id uuid default gen_random_uuid() primary key,
  model_id uuid references ml_models(id) on delete cascade,
  run_name text not null,
  dataset_name text not null,
  dataset_size integer,
  dataset_url text,
  train_test_split jsonb,
  hyperparameters jsonb not null,
  training_metrics jsonb,
  validation_metrics jsonb,
  test_metrics jsonb,
  final_metrics jsonb,
  training_duration_seconds integer,
  status text default 'running',
  progress_percentage integer default 0,
  current_epoch integer,
  total_epochs integer,
  error_message text,
  logs_url text,
  artifact_url text,
  checkpoint_urls text[],
  gpu_hours_used float,
  compute_cost_usd float,
  created_at timestamptz default now(),
  started_at timestamptz,
  completed_at timestamptz,
  created_by uuid references auth.users(id)
);

-- Model Versions
create table if not exists model_versions (
  id uuid default gen_random_uuid() primary key,
  model_id uuid references ml_models(id) on delete cascade,
  version text not null,
  parent_version text,
  changelog text,
  metrics jsonb not null,
  metrics_comparison jsonb,
  artifact_url text not null,
  artifact_size_bytes bigint,
  is_deployed boolean default false,
  deployment_url text,
  deployment_config jsonb,
  traffic_percentage integer default 0,
  created_at timestamptz default now(),
  deployed_at timestamptz,
  deprecated_at timestamptz,
  created_by uuid references auth.users(id),
  unique(model_id, version)
);

-- Indexes
create index idx_ml_models_active on ml_models(is_active, created_at desc);
create index idx_ml_models_type on ml_models(model_type);
create index idx_ml_models_deployed on ml_models(is_deployed);
create index idx_predictions_model on predictions(model_id, created_at desc);
create index idx_predictions_user on predictions(user_id, created_at desc);
create index idx_training_runs_model on training_runs(model_id, created_at desc);
create index idx_training_runs_status on training_runs(status);
create index idx_model_versions_deployed on model_versions(model_id, is_deployed);

-- RLS Policies
alter table ml_models enable row level security;
alter table predictions enable row level security;
alter table training_runs enable row level security;
alter table model_versions enable row level security;

-- ML Models policies
create policy "ML models viewable by authenticated" on ml_models for select to authenticated using (true);
create policy "Users create own models" on ml_models for insert to authenticated with check (auth.uid() = created_by);
create policy "Users update own models" on ml_models for update to authenticated using (auth.uid() = created_by);

-- Predictions policies
create policy "Users view own predictions" on predictions for select to authenticated using (auth.uid() = user_id);
create policy "Users create predictions" on predictions for insert to authenticated with check (auth.uid() = user_id);

-- Training runs policies
create policy "Users view own training runs" on training_runs for select to authenticated using (auth.uid() = created_by);
create policy "Users create training runs" on training_runs for insert to authenticated with check (auth.uid() = created_by);
create policy "Users update own training runs" on training_runs for update to authenticated using (auth.uid() = created_by);

-- Model versions policies
create policy "Model versions viewable by authenticated" on model_versions for select to authenticated using (true);
create policy "Users create model versions" on model_versions for insert to authenticated with check (auth.uid() = created_by);
create policy "Users update own versions" on model_versions for update to authenticated using (auth.uid() = created_by);
EOF
        ;;
    *)
        echo "Error: Unknown schema type: $SCHEMA_TYPE"
        echo "Valid types: ml-models, predictions, training-runs, model-versions, complete"
        exit 1
        ;;
esac

echo ""
echo "✓ Supabase ML schema created: $MIGRATION_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the generated migration file"
echo "  2. Apply migration to your Supabase project:"
echo "     supabase migration up"
echo "  3. Or apply directly via SQL editor in Supabase dashboard"
echo "  4. Test the schema with some sample data"
