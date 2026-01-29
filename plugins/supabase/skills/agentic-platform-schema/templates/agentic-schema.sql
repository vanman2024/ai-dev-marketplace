-- Agentic Platform Contract Schema
-- Standardized tables for AI agent applications

-- Agent runs table
CREATE TABLE IF NOT EXISTS agent_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  agent_name TEXT NOT NULL,
  status TEXT DEFAULT 'running', -- 'running' | 'completed' | 'failed' | 'cancelled'
  input JSONB NOT NULL,
  output JSONB,
  error TEXT,
  metadata JSONB DEFAULT '{}',
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Agent events table (streaming events within a run)
CREATE TABLE IF NOT EXISTS agent_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID REFERENCES agent_runs(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL, -- 'message' | 'tool_call' | 'tool_result' | 'thinking' | 'error'
  data JSONB NOT NULL,
  sequence_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Agent artifacts table (files/outputs from runs)
CREATE TABLE IF NOT EXISTS agent_artifacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID REFERENCES agent_runs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  content_type TEXT NOT NULL, -- 'text/plain' | 'application/json' | 'image/png' | etc.
  content TEXT, -- For text content
  storage_path TEXT, -- For Supabase Storage files
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Agent tool calls table (detailed tool/function tracking)
CREATE TABLE IF NOT EXISTS agent_tool_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID REFERENCES agent_runs(id) ON DELETE CASCADE,
  event_id UUID REFERENCES agent_events(id) ON DELETE CASCADE,
  tool_name TEXT NOT NULL,
  tool_input JSONB NOT NULL,
  tool_output JSONB,
  status TEXT DEFAULT 'pending', -- 'pending' | 'running' | 'completed' | 'failed'
  error TEXT,
  duration_ms INTEGER,
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_agent_runs_user_id ON agent_runs(user_id);
CREATE INDEX idx_agent_runs_status ON agent_runs(status);
CREATE INDEX idx_agent_runs_created_at ON agent_runs(created_at DESC);
CREATE INDEX idx_agent_events_run_id ON agent_events(run_id);
CREATE INDEX idx_agent_events_sequence ON agent_events(run_id, sequence_number);
CREATE INDEX idx_agent_artifacts_run_id ON agent_artifacts(run_id);
CREATE INDEX idx_agent_tool_calls_run_id ON agent_tool_calls(run_id);

-- RLS Policies
ALTER TABLE agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_tool_calls ENABLE ROW LEVEL SECURITY;

-- Users can only access their own runs
CREATE POLICY "Users can view own runs" ON agent_runs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own runs" ON agent_runs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own runs" ON agent_runs
  FOR UPDATE USING (auth.uid() = user_id);

-- Events inherit access from runs
CREATE POLICY "Users can view events for own runs" ON agent_events
  FOR SELECT USING (
    run_id IN (SELECT id FROM agent_runs WHERE user_id = auth.uid())
  );
CREATE POLICY "Users can insert events for own runs" ON agent_events
  FOR INSERT WITH CHECK (
    run_id IN (SELECT id FROM agent_runs WHERE user_id = auth.uid())
  );

-- Artifacts inherit access from runs
CREATE POLICY "Users can view artifacts for own runs" ON agent_artifacts
  FOR SELECT USING (
    run_id IN (SELECT id FROM agent_runs WHERE user_id = auth.uid())
  );
CREATE POLICY "Users can insert artifacts for own runs" ON agent_artifacts
  FOR INSERT WITH CHECK (
    run_id IN (SELECT id FROM agent_runs WHERE user_id = auth.uid())
  );

-- Tool calls inherit access from runs
CREATE POLICY "Users can view tool calls for own runs" ON agent_tool_calls
  FOR SELECT USING (
    run_id IN (SELECT id FROM agent_runs WHERE user_id = auth.uid())
  );
CREATE POLICY "Users can insert tool calls for own runs" ON agent_tool_calls
  FOR INSERT WITH CHECK (
    run_id IN (SELECT id FROM agent_runs WHERE user_id = auth.uid())
  );
