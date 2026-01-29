---
name: deepeval-testing
description: DeepEval pytest-style LLM testing patterns with built-in metrics, custom evaluators, and CI integration. Use when creating LLM tests, evaluating RAG quality, or measuring faithfulness/relevance.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# DeepEval Testing

Skill for pytest-style LLM evaluation with DeepEval.

## Overview

DeepEval provides:

- pytest-compatible LLM tests
- Built-in metrics (faithfulness, relevance, toxicity)
- Custom metric creation
- Async test execution

## Use When

This skill is automatically invoked when:

- Creating pytest-style LLM tests
- Evaluating RAG quality
- Measuring faithfulness/relevance
- Building custom metrics

## Available Scripts

| Script                     | Description                 |
| -------------------------- | --------------------------- |
| `scripts/init-deepeval.sh` | Initialize DeepEval project |
| `scripts/run-tests.sh`     | Run DeepEval tests          |

## Available Templates

| Template                  | Description          |
| ------------------------- | -------------------- |
| `templates/conftest.py`   | pytest configuration |
| `templates/test_basic.py` | Basic test structure |
| `templates/test_rag.py`   | RAG evaluation tests |

## Built-in Metrics

- `AnswerRelevancyMetric`
- `FaithfulnessMetric`
- `ContextualRelevancyMetric`
- `HallucinationMetric`
- `ToxicityMetric`
- `BiasMetric`
