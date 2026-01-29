---
description: Add a specific feature to an existing Mem0 project. Features include user-memory, conversation, knowledge, search, production.
argument-hint: <feature> [options]
---

# Add Mem0 Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Memory Type Features

**If `$0` = "user-memory":**

```
Task(mem0-memory-architect) Add USER MEMORY.

Requirements:
- Memory scope: $1 (preferences, facts, history - default: all)
- Set up user memory collection
- Configure user ID mapping
- Add memory persistence
- Create retrieval patterns
```

**If `$0` = "conversation":**

```
Task(mem0-integrator) Add CONVERSATION memory.

Requirements:
- Context window: $1 (short, long, rolling - default: rolling)
- Store conversation history
- Add context summarization
- Configure retention
- Implement retrieval
```

**If `$0` = "knowledge":**

```
Task(mem0-memory-architect) Add KNOWLEDGE BASE.

Requirements:
- Knowledge type: $1 (docs, facts, embeddings - default: embeddings)
- Set up knowledge storage
- Add ingestion pipeline
- Configure indexing
- Implement search
```

### Search Features

**If `$0` = "search":**

```
Task(mem0-integrator) Add SEMANTIC SEARCH.

Requirements:
- Search type: $1 (semantic, hybrid, filtered - default: semantic)
- Configure search endpoint
- Add relevance scoring
- Implement filters
- Set up result ranking
```

### Integration Features

**If `$0` = "vercel-ai":**

```
Task(mem0-integrator) Integrate with VERCEL AI SDK.

Requirements:
- Hook type: $1 (middleware, provider - default: middleware)
- Add memory to generateText/streamText
- Configure context injection
- Handle memory updates
```

**If `$0` = "claude-sdk":**

```
Task(mem0-integrator) Integrate with CLAUDE SDK.

Requirements:
- Integration point: $1 (tools, context - default: context)
- Add memory to conversations
- Configure retrieval
- Handle updates
```

### Production Features

**If `$0` = "production":**

```
Task(mem0-verifier) Add PRODUCTION features.

Requirements:
- Feature: $1 (caching, batching, monitoring - default: all)
- Add error handling
- Set up caching
- Configure batching
- Add monitoring
```

---

## Usage Examples

```bash
# Memory types
/mem0:add user-memory preferences
/mem0:add conversation rolling
/mem0:add knowledge embeddings

# Search
/mem0:add search semantic
/mem0:add search hybrid

# Integrations
/mem0:add vercel-ai middleware
/mem0:add claude-sdk context

# Production
/mem0:add production caching
/mem0:add production all
```

---

## Feature Reference

| Feature        | Agent            | $1 Options                      | Description            |
| -------------- | ---------------- | ------------------------------- | ---------------------- |
| `user-memory`  | memory-architect | preferences/facts/history/all   | User-specific memory   |
| `conversation` | integrator       | short/long/rolling              | Conversation history   |
| `knowledge`    | memory-architect | docs/facts/embeddings           | Knowledge base         |
| `search`       | integrator       | semantic/hybrid/filtered        | Semantic search        |
| `vercel-ai`    | integrator       | middleware/provider             | Vercel AI integration  |
| `claude-sdk`   | integrator       | tools/context                   | Claude SDK integration |
| `production`   | verifier         | caching/batching/monitoring/all | Production features    |
