---
description: Add a specific eval feature to an existing project. Features include promptfoo, deepeval, golden-dataset, supabase-tracking.
argument-hint: <feature> [options]
---

# Add LLM Eval Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialist:

### promptfoo

**If `$0` = "promptfoo":**

```
Task(promptfoo-specialist) Add promptfoo.

Requirements:
- Provider: $1 (openai, anthropic, google - default: openai)
- Install promptfoo CLI
- Create promptfooconfig.yaml
- Set up initial prompts
- Add sample assertions
```

### DeepEval

**If `$0` = "deepeval":**

```
Task(deepeval-specialist) Add DeepEval.

Requirements:
- Metrics: $1 (faithfulness, relevance, toxicity - default: all)
- Install deepeval package
- Create test structure
- Configure metrics
- Add sample tests
```

### Golden Dataset

**If `$0` = "golden-dataset":**

```
Task(dataset-curator) Add golden dataset.

Requirements:
- Category: $1 (qa, summarization, code, chat - default: qa)
- Create dataset schema
- Add initial cases
- Set up validation
```

### Supabase Tracking

**If `$0` = "supabase-tracking":**

```
Task(eval-orchestrator) Add Supabase tracking.

Requirements:
- Create eval tables
- Add tracking functions
- Set up RLS policies
- Create dashboard queries
```

---

## Usage Examples

```bash
# promptfoo
/llm-evals:add promptfoo openai
/llm-evals:add promptfoo anthropic

# DeepEval
/llm-evals:add deepeval faithfulness
/llm-evals:add deepeval all

# Golden datasets
/llm-evals:add golden-dataset qa
/llm-evals:add golden-dataset code

# Tracking
/llm-evals:add supabase-tracking
```
