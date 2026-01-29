---
description: Build complete LLM evaluation system with promptfoo, DeepEval, golden datasets, and Supabase tracking
argument-hint: [project-name] [--existing]
---

# Build LLM Evals System

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Setup

**Goal:** Initialize eval project structure

**Actions:**

```
Task(eval-orchestrator) Set up eval project.

Requirements:
- Create evals/ directory structure
- Initialize package.json for promptfoo
- Set up pytest environment for DeepEval
- Configure environment variables
```

---

## Phase 2: promptfoo Setup

**Goal:** Configure prompt regression testing

**Actions:**

```
Task(promptfoo-specialist) Set up promptfoo.

Requirements:
- Create promptfooconfig.yaml
- Define providers (OpenAI, Anthropic, etc.)
- Set up initial prompts
- Configure assertions
- Add test cases
```

---

## Phase 3: DeepEval Setup

**Goal:** Configure pytest-style LLM tests

**Actions:**

```
Task(deepeval-specialist) Set up DeepEval.

Requirements:
- Install deepeval package
- Create test_llm.py structure
- Configure metrics (faithfulness, relevance)
- Set up conftest.py
- Add sample tests
```

---

## Phase 4: Golden Datasets

**Goal:** Create curated test datasets

**Actions:**

```
Task(dataset-curator) Create golden datasets.

Requirements:
- Define dataset schema
- Create initial test cases
- Organize by category
- Add expected outputs
- Version tracking setup
```

---

## Phase 5: Supabase Tracking

**Goal:** Set up eval run tracking

**Actions:**

```
Task(eval-orchestrator) Configure Supabase tracking.

Requirements:
- Create eval_runs table
- Create eval_cases table
- Create eval_scores table
- Add RLS policies
- Create tracking functions
```

---

## Phase 6: CI/CD Integration

**Goal:** Automate eval runs

**Actions:**

```
Task(eval-orchestrator) Set up CI/CD.

Requirements:
- GitHub Actions workflow
- Scheduled eval runs
- PR-triggered evals
- Slack/Discord notifications
- Dashboard integration
```

---

## Summary

**Output:**

```
✅ LLM Evals System Complete

Structure:
  evals/
  ├── promptfoo/
  │   ├── promptfooconfig.yaml
  │   └── prompts/
  ├── deepeval/
  │   ├── test_llm.py
  │   └── conftest.py
  ├── datasets/
  │   └── golden/
  └── tracking/
      └── supabase.sql

Run evals:
  npx promptfoo eval           # Prompt regression
  pytest evals/deepeval/       # DeepEval tests

Add features:
  /llm-evals:add promptfoo
  /llm-evals:add deepeval
  /llm-evals:add golden-dataset
```
