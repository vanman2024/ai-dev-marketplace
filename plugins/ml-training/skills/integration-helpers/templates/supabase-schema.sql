-- Base Supabase Schema Template for ML Applications
-- This template provides the foundation for ML metadata storage
-- Customize based on your specific needs

-- ============================================================================
-- Enable Required Extensions
-- ============================================================================

-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- Enable pgvector for embeddings (if needed)
-- create extension if not exists vector;

-- ============================================================================
-- ML Models Table
-- ============================================================================

create table if not exists ml_models (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  model_type text not null,
  framework text not null,
  version text not null,
  artifact_url text,
  metrics jsonb,
  hyperparameters jsonb,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  created_by uuid references auth.users(id),
  unique(name, version)
);

-- ============================================================================
-- Predictions Table
-- ============================================================================

create table if not exists predictions (
  id uuid default gen_random_uuid() primary key,
  model_id uuid references ml_models(id) on delete cascade,
  model_version text not null,
  input_data jsonb not null,
  prediction jsonb not null,
  confidence float,
  inference_time_ms float,
  user_id uuid references auth.users(id),
  created_at timestamptz default now()
);

-- ============================================================================
-- Indexes
-- ============================================================================

create index idx_ml_models_active on ml_models(is_active, created_at desc);
create index idx_predictions_model on predictions(model_id, created_at desc);
create index idx_predictions_user on predictions(user_id, created_at desc);

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

alter table ml_models enable row level security;
alter table predictions enable row level security;

-- ML Models RLS
create policy "ML models viewable by authenticated users"
  on ml_models for select
  to authenticated
  using (true);

create policy "Users can create their own ML models"
  on ml_models for insert
  to authenticated
  with check (auth.uid() = created_by);

-- Predictions RLS
create policy "Users can view their own predictions"
  on predictions for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can create predictions"
  on predictions for insert
  to authenticated
  with check (auth.uid() = user_id);

-- ============================================================================
-- Triggers
-- ============================================================================

-- Auto-update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_ml_models_updated_at
  before update on ml_models
  for each row
  execute function update_updated_at_column();

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Function to get model statistics
create or replace function get_model_stats(model_uuid uuid)
returns json as $$
declare
  stats json;
begin
  select json_build_object(
    'total_predictions', count(*),
    'avg_confidence', avg(confidence),
    'avg_inference_time_ms', avg(inference_time_ms),
    'first_prediction', min(created_at),
    'last_prediction', max(created_at)
  ) into stats
  from predictions
  where model_id = model_uuid;

  return stats;
end;
$$ language plpgsql security definer;

-- Function to cleanup old predictions (data retention)
create or replace function cleanup_old_predictions(days_to_keep integer default 90)
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
