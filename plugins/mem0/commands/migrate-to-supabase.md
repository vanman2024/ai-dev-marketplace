---
description: Migrate from Mem0 Platform to Open Source with Supabase backend
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, SlashCommand, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Migrate from Mem0 Platform (hosted) to Mem0 OSS (self-hosted with Supabase), preserving all memories and relationships.

Core Principles:
- Export data safely from Platform
- Setup OSS infrastructure
- Import data to Supabase
- Verify data integrity
- Update application code

Phase 1: Pre-Migration Validation
Goal: Ensure migration is feasible

Actions:
- Verify currently using Mem0 Platform
- Check memory count and size
- Estimate migration time
- Warn about potential downtime
- Use AskUserQuestion to confirm:
  - "Ready to migrate from Platform to OSS? This will require downtime."
  - "Do you have Supabase account ready?"

Phase 2: Data Export
Goal: Export all memories from Platform

Actions:
- Use Mem0 Platform export API
- Export memories with metadata
- Export relationships (if graph memory enabled)
- Export user and agent data
- Save exports to local files
- Verify export completeness
- Create backup of exports

Phase 3: OSS Setup
Goal: Initialize Mem0 OSS with Supabase

Actions:
- Run /supabase:init if not already setup
- Run /mem0:init-oss to setup OSS mode
- Wait for setup to complete
- Verify Supabase tables are created
- Verify pgvector extension is enabled

Phase 4: Data Import
Goal: Import memories to Supabase

Actions:

Launch the mem0-integrator agent to import data.

Provide the agent with:
- Export files: [From Phase 2]
- Target: Supabase OSS setup
- Requirements:
  - Import all memories to Supabase tables
  - Preserve memory IDs and metadata
  - Import relationships (if graph memory)
  - Maintain user/agent associations
  - Verify vector embeddings
  - Handle import errors gracefully
  - Provide progress updates
- Expected output: Complete data migration to Supabase

Phase 5: Application Updates
Goal: Update code to use OSS instead of Platform

Actions:
- Update memory client from Platform to OSS configuration
- Change from MemoryClient to Memory with Supabase config
- Update environment variables
- Remove Platform API key
- Add Supabase connection variables
- Test memory operations work with new setup

Phase 6: Verification
Goal: Validate migration was successful

Actions:
- Run /mem0:test to validate OSS setup
- Compare memory counts (Platform export vs Supabase import)
- Test sample memory queries return correct results
- Verify relationships preserved (if graph memory)
- Check user isolation still works
- Test application functionality end-to-end

Phase 7: Summary
Goal: Document migration results

Actions:
- Display migration summary:
  - Memories exported from Platform: [Count]
  - Memories imported to Supabase: [Count]
  - Relationships migrated: [Count]
  - Data integrity: [Verified/Issues]
  - Application updated: [Files modified]
- Show post-migration tasks:
  - Cancel Platform subscription (if desired)
  - Monitor OSS performance
  - Setup backups for Supabase
  - Configure retention policies
- Provide next steps:
  - Optimize OSS performance
  - Setup monitoring
  - Configure auto-backups
  - Use /mem0:configure for OSS tuning
- Provide documentation:
  - OSS configuration: https://docs.mem0.ai/open-source/configuration
  - Supabase best practices: https://supabase.com/docs/guides/database
