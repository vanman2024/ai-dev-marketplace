---
description: Complete AI application setup - chains schema creation, pgvector setup, auth, realtime, and type generation for a full-stack AI app
argument-hint: <app-type> [chat|rag|agents|multi-tenant]
allowed-tools: SlashCommand, Task
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

Goal: Set up complete AI application infrastructure by chaining multiple Supabase configuration commands.

Phase 1: Determine App Type

Actions:
- Parse app type from arguments: chat, rag, agents, or multi-tenant
- If no app type specified, ask user to choose
- Load appropriate schema pattern based on type

Phase 2: Chain Schema Setup

Actions:
- Invoke /supabase:create-schema $APP_TYPE
- Wait for schema creation to complete
- Verify schema created successfully

Phase 3: Chain AI Features

Actions:
- Invoke /supabase:setup-ai
- Configure pgvector for embeddings
- Set up AI edge functions
- Verify AI features configured

Phase 4: Chain Authentication

Actions:
- Invoke /supabase:add-auth
- Configure OAuth providers
- Set up RLS policies
- Verify auth working

Phase 5: Chain Realtime (if applicable)

Actions:
- If app type is chat or multi-tenant:
  - Invoke /supabase:add-realtime
  - Configure realtime subscriptions
  - Verify realtime features

Phase 6: Generate Types

Actions:
- Invoke /supabase:generate-types
- Generate TypeScript types from schema
- Verify types generated correctly

Phase 7: Validation

Actions:
- Invoke /supabase:validate-setup
- Run comprehensive validation
- Report any issues

Phase 8: Summary

Actions:
- Display complete setup summary:
  - ✅ Database schema created
  - ✅ pgvector configured for AI
  - ✅ Authentication set up
  - ✅ Realtime enabled (if applicable)
  - ✅ TypeScript types generated
  - ✅ Validation passed
- Show next steps for development
