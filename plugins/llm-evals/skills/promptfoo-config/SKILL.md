---
name: promptfoo-config
description: promptfoo configuration patterns for prompt regression testing, multi-provider comparison, and assertion-based validation. Use when setting up prompt testing, comparing LLM providers, or creating eval pipelines.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# promptfoo Configuration

Skill for configuring promptfoo prompt evaluation and testing.

## Overview

promptfoo enables:

- Prompt regression testing
- Multi-provider comparison
- Assertion-based validation
- HTML report generation

## Use When

This skill is automatically invoked when:

- Setting up prompt testing
- Comparing LLM providers
- Creating evaluation pipelines
- Defining test assertions

## Available Scripts

| Script                      | Description                  |
| --------------------------- | ---------------------------- |
| `scripts/init-promptfoo.sh` | Initialize promptfoo project |
| `scripts/run-eval.sh`       | Run evaluation with output   |

## Available Templates

| Template                         | Description         |
| -------------------------------- | ------------------- |
| `templates/promptfooconfig.yaml` | Basic configuration |
| `templates/multi-provider.yaml`  | Provider comparison |
| `templates/assertions.yaml`      | Assertion examples  |

## Best Practices

1. Use YAML anchors for repeated config
2. Store prompts in separate files
3. Use variables for dynamic tests
4. Set appropriate thresholds
