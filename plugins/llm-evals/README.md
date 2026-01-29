# LLM Evals Plugin

Comprehensive LLM testing and evaluation framework for AI applications.

## Features

- **promptfoo** - Prompt regression testing and comparison
- **DeepEval** - pytest-style LLM evaluation
- **Golden Datasets** - Curated test cases with expected outputs
- **Eval Tracking** - Supabase-backed runs, cases, and scores
- **CI/CD Integration** - GitHub Actions for continuous eval

## Quick Start

```bash
# Build complete eval system
/llm-evals:build my-evals

# Add specific features
/llm-evals:add promptfoo          # Prompt regression testing
/llm-evals:add deepeval           # pytest-style LLM tests
/llm-evals:add golden-dataset     # Golden test datasets
/llm-evals:add supabase-tracking  # Eval run tracking
```

## Components

### promptfoo Integration

- YAML-based prompt testing
- Multi-provider comparison
- Assertion-based validation
- HTML report generation

### DeepEval Integration

- pytest-style test syntax
- Built-in metrics (faithfulness, relevance, toxicity)
- Custom metric creation
- Async test execution

### Golden Datasets

- Structured test cases
- Expected output validation
- Category-based organization
- Version tracking

### Supabase Tracking

- `eval_runs` - Track evaluation runs
- `eval_cases` - Individual test cases
- `eval_scores` - Metric scores per case
- Dashboard queries

## Agents

- `eval-orchestrator` - Coordinates evaluation workflows
- `promptfoo-specialist` - promptfoo configuration and execution
- `deepeval-specialist` - DeepEval test creation and running
- `dataset-curator` - Golden dataset management

## Documentation

- [promptfoo Docs](https://promptfoo.dev/docs/intro)
- [DeepEval Docs](https://docs.confident-ai.com/)
