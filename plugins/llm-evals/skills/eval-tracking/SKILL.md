---
name: eval-tracking
description: Supabase-backed evaluation tracking with runs, cases, and scores tables. Use when storing eval results, building dashboards, or tracking regression over time.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Eval Tracking

Skill for Supabase-backed evaluation result tracking.

## Overview

Track evaluations with:

- `eval_runs` - Evaluation run metadata
- `eval_cases` - Individual test cases
- `eval_scores` - Metric scores per case

## Use When

This skill is automatically invoked when:

- Storing evaluation results
- Building eval dashboards
- Tracking regression over time
- Comparing run results

## Available Scripts

| Script                      | Description            |
| --------------------------- | ---------------------- |
| `scripts/setup-tracking.sh` | Run Supabase migration |

## Available Templates

| Template                | Description             |
| ----------------------- | ----------------------- |
| `templates/schema.sql`  | Supabase tables and RLS |
| `templates/queries.sql` | Dashboard queries       |
