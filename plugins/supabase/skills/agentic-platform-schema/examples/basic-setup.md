# Agentic Platform Schema Setup

## Run Migration

```bash
./scripts/setup-agentic-schema.sh
```

## Or manually in Supabase SQL Editor

Copy contents of `templates/agentic-schema.sql` and run.

## Usage Example

```typescript
// Create a run
const { data: run } = await supabase
  .from('agent_runs')
  .insert({
    user_id: userId,
    agent_name: 'research-agent',
    input: { query: 'What is quantum computing?' },
  })
  .select()
  .single();

// Add event
await supabase.from('agent_events').insert({
  run_id: run.id,
  event_type: 'message',
  data: { role: 'assistant', content: '...' },
  sequence_number: 1,
});

// Complete run
await supabase
  .from('agent_runs')
  .update({
    status: 'completed',
    output: { answer: '...' },
    completed_at: new Date().toISOString(),
  })
  .eq('id', run.id);
```
