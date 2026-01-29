-- Common Query Patterns for Agentic Platform Schema

-- ============================================
-- RUN QUERIES
-- ============================================

-- Get recent runs for a user
SELECT * FROM agent_runs
WHERE user_id = $1
ORDER BY created_at DESC
LIMIT 20;

-- Get run with all events
SELECT 
  r.*,
  COALESCE(json_agg(e.* ORDER BY e.sequence_number) FILTER (WHERE e.id IS NOT NULL), '[]') as events
FROM agent_runs r
LEFT JOIN agent_events e ON e.run_id = r.id
WHERE r.id = $1
GROUP BY r.id;

-- Get runs by status
SELECT * FROM agent_runs
WHERE user_id = $1 AND status = $2
ORDER BY created_at DESC;

-- Count runs by agent
SELECT agent_name, COUNT(*) as run_count
FROM agent_runs
WHERE user_id = $1
GROUP BY agent_name
ORDER BY run_count DESC;

-- ============================================
-- EVENT QUERIES
-- ============================================

-- Stream events for a run (for real-time updates)
SELECT * FROM agent_events
WHERE run_id = $1
ORDER BY sequence_number ASC;

-- Get events after sequence number (for pagination/streaming)
SELECT * FROM agent_events
WHERE run_id = $1 AND sequence_number > $2
ORDER BY sequence_number ASC;

-- Get only messages (not tool calls)
SELECT * FROM agent_events
WHERE run_id = $1 AND event_type = 'message'
ORDER BY sequence_number ASC;

-- ============================================
-- ARTIFACT QUERIES
-- ============================================

-- Get all artifacts for a run
SELECT * FROM agent_artifacts
WHERE run_id = $1
ORDER BY created_at ASC;

-- Get artifacts by type
SELECT * FROM agent_artifacts
WHERE run_id = $1 AND content_type LIKE $2
ORDER BY created_at ASC;

-- ============================================
-- TOOL CALL QUERIES
-- ============================================

-- Get tool calls for a run
SELECT * FROM agent_tool_calls
WHERE run_id = $1
ORDER BY started_at ASC;

-- Tool usage analytics
SELECT 
  tool_name,
  COUNT(*) as call_count,
  AVG(duration_ms) as avg_duration_ms,
  SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as error_count
FROM agent_tool_calls
WHERE run_id IN (SELECT id FROM agent_runs WHERE user_id = $1)
GROUP BY tool_name
ORDER BY call_count DESC;

-- Failed tool calls
SELECT * FROM agent_tool_calls
WHERE run_id = $1 AND status = 'failed';

-- ============================================
-- ANALYTICS QUERIES
-- ============================================

-- Daily run counts
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_runs,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
  SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed
FROM agent_runs
WHERE user_id = $1 AND created_at > now() - interval '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Average run duration
SELECT 
  agent_name,
  AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_seconds
FROM agent_runs
WHERE user_id = $1 AND status = 'completed'
GROUP BY agent_name;

-- ============================================
-- SUPABASE REALTIME SUBSCRIPTION (Client-side)
-- ============================================
-- 
-- // Subscribe to new events for a run
-- supabase
--   .channel('run-events')
--   .on('postgres_changes', {
--     event: 'INSERT',
--     schema: 'public',
--     table: 'agent_events',
--     filter: `run_id=eq.${runId}`
--   }, (payload) => {
--     console.log('New event:', payload.new);
--   })
--   .subscribe();
