---
description: Build complete OpenRouter integration for new or existing projects with model routing, provider switching, and fallbacks
argument-hint: [project-name] [--existing]
---

# Build OpenRouter Integration

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(openrouter-setup-agent) Analyze project for OpenRouter setup.

Detect: Existing AI framework, language
Check: Current LLM integrations
Output: Integration strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up OpenRouter client

**Actions:**

```
Task(openrouter-setup-agent) Set up OpenRouter core.

Requirements:
- Configure API key
- Set up client instance
- Configure base parameters
- Test connection
- Add error handling
```

---

## Phase 3: Model Routing

**Goal:** Configure model routing

**Actions:**

```
Task(openrouter-routing-agent) Set up model routing.

Requirements:
- Configure model preferences
- Set up fallback chains
- Add cost optimization
- Configure latency requirements
- Set up provider priorities
```

---

## Phase 4: Framework Integration

**Goal:** Integrate with AI framework

**Actions:**

```
Based on detected framework:

If Vercel AI SDK:
Task(openrouter-vercel-integration-agent) Integrate with Vercel AI SDK.

If LangChain:
Task(openrouter-langchain-agent) Integrate with LangChain.

Requirements:
- Create provider wrapper
- Configure streaming
- Add tool support
- Set up response handling
```

---

## Summary

**Output:**

```
✅ OpenRouter Integration Complete

To add features:
  /openrouter:add vercel-ai              # Vercel AI SDK
  /openrouter:add langchain              # LangChain
  /openrouter:add routing <strategy>     # Model routing
  /openrouter:add fallback               # Fallback config

To use:
  Import provider from configured location
```
