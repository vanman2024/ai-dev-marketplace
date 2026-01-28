---
description: Build complete Mem0 memory integration - initializes if needed, then runs specialized agents for conversation memory, user context, and graph memory
argument-hint: <project-name> [--backend <platform|oss|supabase>]
---

# Build Complete Mem0 Memory Integration

**Goal:** Create a production-ready Mem0 memory layer for AI applications.

**This command handles everything** - from setup to full integration with conversation memory, user tracking, and optional graph memory.

## Stack (Always Use Latest Versions)

- **Mem0** - Latest (platform or OSS)
- **mem0ai** - Latest Python SDK
- Framework integration (FastAPI, Next.js)

**IMPORTANT:** Always use the latest Mem0 versions. Check `pip index versions mem0ai` for current version.

## Arguments

- `$ARGUMENTS` - Project name and optional backend
- `--backend <name>` - Memory backend (platform, oss, supabase)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and backend choice
2. Auto-detect if Mem0 platform credentials exist
3. Discover architecture documentation for memory requirements
4. Plan memory structure based on use cases

### Phase 2: Mem0 Setup

```
Task("Initialize Mem0", @mem0-integrator, {
  prompt: "Initialize Mem0 integration:
    - Install mem0ai SDK (latest version)
    - Configure API key or OSS settings
    - Create memory client singleton
    - Set up user/session tracking
    Use platform if API key exists, else OSS."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Memory Architecture
Task("Design memory structure", @mem0-memory-architect, {
  prompt: "Design memory architecture:
    - Define memory categories (conversation, user, system)
    - Plan memory retention policies
    - Design user context structure
    - Configure embedding model and vector store
    Follow AI requirements from architecture docs."
})

// Agent 2: Integration
Task("Implement memory layer", @mem0-integrator, {
  prompt: "Implement memory integration:
    - Add memory to chat endpoints
    - Implement user context retrieval
    - Add conversation history management
    - Create memory search utilities
    Integrate with existing AI endpoints."
})

// Agent 3: Verification
Task("Verify memory", @mem0-verifier, {
  prompt: "Verify memory implementation:
    - Test memory storage and retrieval
    - Validate user context accuracy
    - Check memory search relevance
    - Verify retention policies work
    Report any issues."
})
```

### Phase 4: Final Output

**Provide summary:**
- Memory backend configured (platform/oss/supabase)
- Memory types implemented
- Usage examples:
  ```python
  # Add memory
  mem0.add("User prefers dark mode", user_id="user123")
  
  # Search memory
  memories = mem0.search("user preferences", user_id="user123")
  ```

## Utility Commands

- `/mem0:init-platform` - Platform setup only
- `/mem0:init-oss` - Self-hosted OSS setup
- `/mem0:add-conversation-memory` - Conversation history
- `/mem0:add-user-memory` - User preferences/context
- `/mem0:add-graph-memory` - Knowledge graph memory
