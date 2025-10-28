---
description: Enable graph memory for tracking relationships between memories and entities
argument-hint: none
allowed-tools: Task(*), Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*)
---

**Arguments**: $ARGUMENTS

Goal: Enable graph memory to track relationships between memories, entities, and concepts.

Core Principles:
- Relationship tracking between memories
- Entity recognition and linking
- Knowledge graph construction
- Advanced queries for connected data

Phase 1: Capability Check
Goal: Verify graph memory is available

Actions:
- Check deployment mode (Platform or OSS)
- If Platform: Graph memory available
- If OSS: Check if memory_relationships table exists
- Verify current Mem0 configuration

Phase 2: Graph Schema Planning
Goal: Design relationship structure

Actions:
- Determine what relationships to track:
  - Entity relationships (person → works at → company)
  - Memory connections (topic A → related to → topic B)
  - Temporal relationships (event A → happened before → event B)
- Plan relationship types and properties
- Design query patterns for graph traversal

Phase 3: Implementation
Goal: Enable graph memory features

Actions:

Launch the mem0-integrator agent to enable graph memory.

Provide the agent with:
- Deployment mode: [Platform or OSS]
- Relationship schema: [Designed in Phase 2]
- Requirements:
  - Enable graph memory in configuration
  - If OSS: Create/verify memory_relationships table
  - Add entity extraction from conversations
  - Store relationships automatically
  - Create helper functions for graph queries
  - Add examples for common relationship queries
- Expected output: Complete graph memory system

Phase 4: Verification
Goal: Test graph memory works

Actions:
- Test relationships are extracted and stored
- Test graph queries return connected memories
- Verify relationship types are correct
- Check performance of graph traversal

Phase 5: Summary
Goal: Show what was enabled

Actions:
- Display graph memory setup:
  - Graph memory: Enabled
  - Relationship types: [List]
  - Query helpers: [List]
  - Files modified: [List]
- Show usage examples:
  - How to query related memories
  - How to traverse the knowledge graph
  - How to visualize relationships
  - How to manually add relationships
- Provide next steps:
  - Test with entity-rich conversations
  - Build knowledge graph queries
  - Use /mem0:configure for graph thresholds
  - Use /mem0:test to validate graph operations
- Provide documentation:
  - Platform: https://docs.mem0.ai/platform/features/graph-memory
  - OSS: https://docs.mem0.ai/open-source/features/graph-memory
