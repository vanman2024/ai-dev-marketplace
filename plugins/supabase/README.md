# Supabase Plugin

Comprehensive Supabase integration for AI applications with complete database, auth, storage, realtime, and vector search capabilities.

## Overview

This plugin provides high-level orchestration for Supabase using the cloud-hosted MCP server at `https://mcp.supabase.com/mcp`. It generates AI-optimized database schemas, configures authentication and security, sets up vector search with pgvector, and enables realtime features.

## Features

- **AI-First Database Schemas** - Optimized for chat, RAG, agents, embeddings
- **Vector Search** - pgvector setup with hybrid search (semantic + keyword)
- **Authentication** - All OAuth providers, email auth, magic links
- **Row Level Security** - Template-based RLS policies for multi-tenant apps
- **Realtime** - Subscriptions, presence, broadcast
- **Storage** - File upload with CDN and policies
- **Edge Functions** - AI model integration (embeddings, LLMs)
- **Supabase UI** - Pre-built React components
- **Type Generation** - Auto-generate TypeScript types
- **Comprehensive Testing** - E2E workflows, schema validation, RLS testing

## Installation

This plugin requires the Supabase MCP server to be configured in your `.mcp.json`:

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=${SUPABASE_PROJECT_REF}",
      "headers": {
        "Authorization": "Bearer ${SUPABASE_ACCESS_TOKEN}"
      }
    }
  }
}
```

Set environment variables:
- `SUPABASE_PROJECT_REF` - Your Supabase project reference ID
- `SUPABASE_ACCESS_TOKEN` - Your Supabase access token

## Quick Start

### Initialize Supabase in Project

```bash
/supabase:init
```

This command will:
- Configure Supabase in your project
- Set up environment variables
- Initialize Supabase CLI
- Create initial configuration

### Create Complete AI App

```bash
/supabase:init-ai-app
```

This creates a complete AI application setup including:
- User management with auth
- Conversation/chat schema
- pgvector for embeddings
- RLS policies
- Realtime subscriptions

## Commands

### Initialization
- `/supabase:init` - Initialize Supabase in project
- `/supabase:init-ai-app` - Complete AI app setup
- `/supabase:init-chat-app` - Chat-specific setup
- `/supabase:init-rag-app` - RAG-specific setup

### Features
- `/supabase:add-auth` - Add authentication
- `/supabase:add-storage` - Configure storage buckets
- `/supabase:add-realtime` - Setup realtime subscriptions
- `/supabase:setup-pgvector` - Configure vector search
- `/supabase:setup-ai` - Complete AI features setup
- `/supabase:add-ui-components` - Install Supabase UI

### Schema & Database
- `/supabase:create-schema` - Generate database schema
- `/supabase:add-rls` - Add Row Level Security
- `/supabase:deploy-migration` - Deploy migrations
- `/supabase:generate-types` - Generate TypeScript types

### Testing & Validation
- `/supabase:validate-setup` - Validate configuration
- `/supabase:test-e2e` - Run end-to-end tests
- `/supabase:validate-schema` - Validate database schema
- `/supabase:test-rls` - Test RLS policies
- `/supabase:test-realtime` - Test realtime features

## Architecture

### Multi-Layer Agent System

**Execution Agents** (MCP Wrappers)
- database-executor - Direct SQL execution
- migration-applier - Migration deployment
- project-manager - Project-level operations

**Review Agents** (Validation)
- code-reviewer - SQL/migration review
- security-auditor - RLS policy validation
- performance-analyzer - Query optimization

**Expert Agents** (Orchestration)
- architect - Schema design for AI apps
- security-specialist - Auth & RLS implementation
- realtime-builder - Realtime subscriptions
- ai-specialist - pgvector, embeddings, AI edge functions
- ui-generator - Supabase UI integration

**Testing Agents**
- validator - Setup validation
- tester - End-to-end workflows
- schema-validator - Database integrity

### Skills

Each skill provides scripts, templates, and examples that agents use via Bash/Read tools:

1. **pgvector-setup** - Vector search configuration
   - Scripts: `setup-pgvector.sh`, `create-indexes.sh`, `setup-hybrid-search.sh`, `test-vector-search.sh`
   - Templates: Embedding tables, HNSW/IVFFlat indexes, hybrid search queries
   - Use: Setting up vector search, RAG systems, semantic search

2. **rls-templates** - Row Level Security patterns
   - Scripts: `generate-policy.sh`, `apply-rls-policies.sh`, `test-rls-policies.sh`, `audit-rls.sh`
   - Templates: User isolation, multi-tenant, role-based access, AI chat policies
   - Use: Implementing RLS, securing multi-tenant apps

3. **auth-configs** - Authentication provider configs
   - Scripts: `setup-oauth-provider.sh`, `setup-email-auth.sh`, `configure-jwt.sh`, `test-auth-flow.sh`
   - Templates: OAuth configs (Google, GitHub, Discord), email templates, auth middleware
   - Use: Setting up authentication, OAuth providers, MFA

4. **schema-patterns** - AI application schemas
   - Scripts: `generate-schema.sh`, `apply-migration.sh`, `validate-schema.sh`, `seed-data.sh`
   - Templates: Chat schema, RAG schema, multi-tenant schema, AI usage tracking
   - Use: Designing database schemas for AI apps

5. **e2e-test-scenarios** - Complete test workflows
   - Scripts: `run-e2e-tests.sh`, `test-auth-workflow.sh`, `test-ai-features.sh`, `test-realtime-workflow.sh`
   - Templates: Test suites, CI/CD configs, test cases
   - Use: E2E testing, pre-deployment validation

6. **schema-validation** - SQL validation tools
   - Scripts: `validate-sql-syntax.sh`, `validate-naming.sh`, `validate-constraints.sh`, `validate-indexes.sh`, `validate-rls.sh`
   - Templates: Validation rules, naming conventions
   - Use: Validating schemas before deployment

7. **rls-test-patterns** - RLS testing patterns
   - Scripts: `test-user-isolation.sh`, `test-multi-tenant-isolation.sh`, `test-role-permissions.sh`, `audit-rls-coverage.sh`
   - Templates: Security test plans, vulnerability checklists
   - Use: Security testing, RLS validation

## Documentation

550+ pages of Supabase documentation automatically fetched by agents via WebFetch.

Key documentation areas:
- Database: Tables, migrations, functions, triggers
- Auth: OAuth providers, RLS, sessions
- AI: pgvector, embeddings, semantic search
- Realtime: Subscriptions, presence, broadcast
- Storage: Buckets, policies, CDN
- Edge Functions: AI models, Deno runtime

## Languages Supported

- TypeScript (Next.js, React, Node.js)
- Python (FastAPI, Django)
- JavaScript (vanilla, Node.js)

## Version

1.0.0

## License

MIT
