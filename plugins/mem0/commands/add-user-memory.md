---
description: Add user preference and profile memory tracking across conversations
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Add user-level memory to track preferences, profile data, and learned facts across all conversations.

Core Principles:
- Persistent user context
- Profile data extraction
- Preference learning
- Cross-conversation continuity

Phase 1: User Model Analysis
Goal: Understand current user data structure

Actions:
- Find user model/schema in codebase
- Check existing user properties
- Identify user identification method (user_id, email, etc.)
- Locate user profile or settings areas

Phase 2: Memory Schema Design
Goal: Plan user memory structure

Actions:
- Determine what user data should be remembered:
  - Preferences (language, tone, interests)
  - Profile facts (occupation, location, etc.)
  - Learned information (habits, patterns)
  - Long-term context
- Design memory categories and tags
- Plan memory retrieval queries

Phase 3: Implementation
Goal: Add user memory tracking

Actions:

Launch the mem0-integrator agent to add user memory.

Provide the agent with:
- User model: [Found in Phase 1]
- Memory schema: [Designed in Phase 2]
- Requirements:
  - Extract user preferences from conversations
  - Store user-level memories with user_id
  - Retrieve user context at conversation start
  - Update user memories as new info is learned
  - Add helper functions for user memory management
  - Generate UI for viewing/editing user memories (optional)
- Expected output: Complete user memory system

Phase 4: Verification
Goal: Test user memory works

Actions:
- Test preferences are learned from conversations
- Test user memories persist across sessions
- Verify user isolation (one user can't see another's memories)
- Check memory retrieval is fast and relevant

Phase 5: Summary
Goal: Show what was added

Actions:
- Display implementation:
  - User memory tracking: Enabled
  - Memory categories: [List]
  - Helper functions: [List]
  - Files modified: [List]
- Show usage examples:
  - How to manually add user memories
  - How to query user preferences
  - How to update user memories
  - How to delete user data (GDPR compliance)
- Provide next steps:
  - Test with user-specific preferences
  - Add UI for user memory management
  - Use /mem0:configure for retention policies
  - Use /mem0:test to validate user isolation
