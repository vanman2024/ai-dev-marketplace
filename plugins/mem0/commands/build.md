---
description: Build complete Mem0 memory layer for new or existing AI applications with user memory, conversation history, and knowledge persistence
argument-hint: [project-name] [--existing]
---

# Build Mem0 Memory Layer

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(mem0-integrator) Analyze project for Mem0 integration.

Detect: AI framework (Vercel AI, Claude SDK, etc.)
Check: Existing memory handling
Output: Integration strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up Mem0 client

**Actions:**

```
Task(mem0-integrator) Set up Mem0 core.

Requirements:
- Install mem0ai SDK
- Configure API key
- Set up client instance
- Create memory configuration
- Test connection
```

---

## Phase 3: Memory Architecture

**Goal:** Design memory structure

**Actions:**

```
Task(mem0-memory-architect) Design memory architecture.

Requirements:
- Define memory types (user, session, knowledge)
- Set up user ID mapping
- Configure metadata schemas
- Create memory categories
- Set retention policies
```

---

## Phase 4: Integration

**Goal:** Connect to AI application

**Actions:**

```
Task(mem0-integrator) Integrate with AI stack.

Requirements:
- Add memory to conversation flow
- Store conversation context
- Retrieve relevant memories
- Update memories on interactions
- Handle memory search
```

---

## Phase 5: Verification

**Goal:** Test memory operations

**Actions:**

```
Task(mem0-verifier) Verify memory operations.

Requirements:
- Test add memory
- Test search memory
- Test update memory
- Test delete memory
- Verify user isolation
```

---

## Summary

**Output:**

```
✅ Mem0 Memory Layer Complete

To add features:
  /mem0:add user-memory                # User-specific memory
  /mem0:add conversation               # Conversation history
  /mem0:add knowledge                  # Knowledge base
  /mem0:add search                     # Semantic search

To use:
  memory.add(text, user_id=user_id)
  memory.search(query, user_id=user_id)
```
