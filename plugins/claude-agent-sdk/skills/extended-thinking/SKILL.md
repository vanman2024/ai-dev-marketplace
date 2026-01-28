---
name: extended-thinking
description: Deep reasoning with Claude's extended thinking feature for complex multi-step problems. Use when implementing think-aloud reasoning, complex analysis, or debugging difficult issues.
---

# Extended Thinking Skill

Enable Claude to "think out loud" before responding - dramatically improves complex reasoning tasks.

## When to Use Extended Thinking

- Complex math, logic, or coding problems
- Multi-step analysis requiring careful reasoning
- Tasks where you need to verify Claude's thought process
- Debugging intricate issues
- Strategic planning and decision-making

## Budget Guidance

| Complexity | Budget Tokens | Use Case |
|------------|---------------|----------|
| Simple | 1,024 | Quick verification |
| Medium | 4,000-8,000 | Standard analysis |
| Complex | 16,000+ | Deep reasoning |
| Very Complex | 32,000+ | Consider batch processing |

## Key Patterns

### Basic Extended Thinking
See `templates/basic-thinking.ts` and `templates/basic-thinking.py`

### Interleaved Thinking with Tools
Requires beta header: `anthropic-beta: interleaved-thinking-2025-05-14`

### Streaming Extended Thinking
Stream thinking blocks for real-time visibility into reasoning process.
