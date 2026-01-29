-- Eval Tracking Schema for Supabase

-- Eval runs table
CREATE TABLE IF NOT EXISTS eval_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  tool TEXT NOT NULL, -- 'promptfoo' | 'deepeval'
  status TEXT DEFAULT 'running', -- 'running' | 'completed' | 'failed'
  config JSONB,
  summary JSONB,
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id)
);

-- Eval cases table
CREATE TABLE IF NOT EXISTS eval_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID REFERENCES eval_runs(id) ON DELETE CASCADE,
  input TEXT NOT NULL,
  expected_output TEXT,
  actual_output TEXT,
  passed BOOLEAN,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Eval scores table
CREATE TABLE IF NOT EXISTS eval_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id UUID REFERENCES eval_cases(id) ON DELETE CASCADE,
  metric TEXT NOT NULL,
  score NUMERIC(5,4),
  threshold NUMERIC(5,4),
  passed BOOLEAN,
  reasoning TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_eval_runs_status ON eval_runs(status);
CREATE INDEX idx_eval_cases_run_id ON eval_cases(run_id);
CREATE INDEX idx_eval_scores_case_id ON eval_scores(case_id);

-- RLS
ALTER TABLE eval_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE eval_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE eval_scores ENABLE ROW LEVEL SECURITY;

-- Policies (adjust as needed)
CREATE POLICY "Users can view own runs" ON eval_runs
  FOR SELECT USING (auth.uid() = created_by);
CREATE POLICY "Users can insert own runs" ON eval_runs
  FOR INSERT WITH CHECK (auth.uid() = created_by);
