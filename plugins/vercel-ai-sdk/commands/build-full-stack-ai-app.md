---
description: Build a complete full-stack AI application with chat UI, database persistence, tool integration, and production-ready middleware using parallel specialized agents
argument-hint: [project-name] [--features chat,rag,mcp,voice]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, WebFetch
---

---

🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite, WebFetch, Task)
- ✅ Complete ALL phases before considering this command done
- ❌ DON'T wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON'T treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

---

## Security Requirements

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`

---

**Arguments**: $ARGUMENTS

**Goal**: Build a complete, production-ready full-stack AI application using Vercel AI SDK by orchestrating specialized agents in parallel.

---

## Available Specialized Agents

These agents are available for parallel Task() invocation:

| Agent | Purpose |
|-------|---------|
| vercel-ai-sdk:vercel-ai-provider-agent | AI Gateway, provider setup, fallbacks |
| vercel-ai-sdk:vercel-ai-database-agent | Message persistence, vector DBs, caching |
| vercel-ai-sdk:vercel-ai-tools-agent | Tool calling, MCP integration |
| vercel-ai-sdk:vercel-ai-middleware-agent | Guardrails, caching, rate limiting |
| vercel-ai-sdk:vercel-ai-elements-agent | AI Elements UI components |
| vercel-ai-sdk:vercel-ai-ui-agent | useChat, streaming, generative UI |
| vercel-ai-sdk:vercel-ai-production-agent | Telemetry, testing, error handling |
| vercel-ai-sdk:vercel-ai-verifier-ts | TypeScript verification |

---

## Phase 0: Create Todo List

**Goal:** Track execution progress

**Actions:**
- Create task list with all phases below
- Update todos as each phase completes

---

## Phase 1: Fetch Core Documentation

**Goal:** Get current AI SDK documentation

**Actions:**
- WebFetch: https://ai-sdk.dev/docs/introduction
- WebFetch: https://ai-sdk.dev/docs/getting-started
- WebFetch: https://ai-sdk.dev/docs/ai-sdk-core/overview
- WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/overview

**CRITICAL**: Do NOT skip WebFetch calls.

---

## Phase 2: Gather Requirements

**Goal:** Understand what the user wants to build

**Actions:**
- Parse $ARGUMENTS for project name and features
- If not provided, ask ONE question at a time:
  1. "What would you like to name your project?"
  2. "Which features? (chat, rag, mcp, voice, multi-modal)"
  3. "Which AI provider? (OpenAI, Anthropic, Google, Multiple)"
  4. "Which database? (PostgreSQL, Supabase, MongoDB, None)"
- Store selections for agent prompts
- Update todos

---

## Phase 3: Initialize Project Structure

**Goal:** Create base Next.js project

**Actions:**

```bash
npx create-next-app@latest $PROJECT_NAME --typescript --tailwind --app --src-dir
cd $PROJECT_NAME
npm install ai zod
npx shadcn@latest init -y
```

Update todos

---

## Phase 4: Launch Specialized Agents in Parallel

**Goal:** Build all application layers simultaneously using specialized agents

**CRITICAL: Send ALL Task() calls in a SINGLE MESSAGE for parallel execution!**

Based on user's feature selections, launch the appropriate agents:

---

### Provider Agent (ALWAYS)

Task(description="Configure AI providers", subagent_type="vercel-ai-sdk:vercel-ai-provider-agent", prompt="You are the vercel-ai-provider-agent. Configure AI providers for a new application.

Project: $PROJECT_NAME
Location: $PROJECT_NAME/src/lib/ai/
Primary Provider: $PRIMARY_PROVIDER
Additional Providers: $ADDITIONAL_PROVIDERS (if any)

**Actions:**
1. WebFetch: https://ai-sdk.dev/providers/ai-sdk-providers (latest provider docs)
2. WebFetch provider-specific docs for selected providers
3. Install provider packages: npm install @ai-sdk/$PROVIDER
4. Create src/lib/ai/providers.ts with:
   - Provider imports
   - Provider registry (if multiple)
   - getModel() function
   - Fallback chain (if multiple)
5. Create .env.example with API key placeholders

Deliverable: Working provider configuration with all selected providers")

---

### Database Agent (IF persistence/RAG selected)

Task(description="Set up database layer", subagent_type="vercel-ai-sdk:vercel-ai-database-agent", prompt="You are the vercel-ai-database-agent. Set up database for message persistence.

Project: $PROJECT_NAME
Location: $PROJECT_NAME/src/lib/db/
Database Type: $DATABASE_TYPE
Features: $FEATURES (check for RAG/vectors)

**Actions:**
1. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-message-persistence
2. If RAG: WebFetch https://ai-sdk.dev/docs/ai-sdk-core/embeddings
3. Install database packages (drizzle-orm, vector DB client, etc.)
4. Create src/lib/db/schema.ts with:
   - conversations table
   - messages table
   - embeddings table (if RAG)
5. Create src/lib/db/index.ts with client setup
6. Create drizzle.config.ts
7. Add DATABASE_URL to .env.example

Deliverable: Complete database schema and client configuration")

---

### Tools Agent (IF mcp/tools selected)

Task(description="Implement tool calling", subagent_type="vercel-ai-sdk:vercel-ai-tools-agent", prompt="You are the vercel-ai-tools-agent. Implement tool calling for the application.

Project: $PROJECT_NAME
Location: $PROJECT_NAME/src/lib/ai/
Features: $FEATURES

**Actions:**
1. WebFetch: https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
2. WebFetch: https://ai-sdk.dev/tools (Tools Registry)
3. If MCP: WebFetch https://ai-sdk.dev/docs/ai-sdk-core/mcp-tools
4. Create src/lib/ai/tools.ts with:
   - Tool definitions using Zod schemas
   - Tool implementations
5. If MCP: Create .mcp.json configuration

Deliverable: Working tool definitions ready for use in chat API")

---

### Elements Agent (IF chat UI selected)

Task(description="Install AI Elements components", subagent_type="vercel-ai-sdk:vercel-ai-elements-agent", prompt="You are the vercel-ai-elements-agent. Set up AI Elements chat components.

Project: $PROJECT_NAME
Location: $PROJECT_NAME/src/components/
Features: $FEATURES (check for voice)

**Actions:**
1. WebFetch: https://ai-sdk.dev/elements (component list)
2. WebFetch: https://ai-sdk.dev/elements/usage (setup guide)
3. Initialize: npx ai-elements@latest init
4. Add components: npx ai-elements@latest add chatbot-thread chatbot-messages chatbot-composer
5. If voice: add voice-visualizer waveform-indicator
6. Create src/components/chat/ directory with wrapper components

Deliverable: Installed and configured AI Elements components")

---

### Middleware Agent (IF production features selected)

Task(description="Set up middleware layer", subagent_type="vercel-ai-sdk:vercel-ai-middleware-agent", prompt="You are the vercel-ai-middleware-agent. Implement middleware for production.

Project: $PROJECT_NAME
Location: $PROJECT_NAME/src/lib/middleware/

**Actions:**
1. WebFetch: https://ai-sdk.dev/docs/ai-sdk-core/middleware
2. Install: npm install @upstash/redis @upstash/ratelimit
3. Create src/lib/middleware/rate-limit.ts
4. Create src/lib/middleware/guardrails.ts (optional)
5. Add UPSTASH_* to .env.example

Deliverable: Rate limiting and middleware ready for API routes")

---

### UI Agent (ALWAYS - for chat page)

Task(description="Create chat interface", subagent_type="vercel-ai-sdk:vercel-ai-ui-agent", prompt="You are the vercel-ai-ui-agent. Create the chat page and API route.

Project: $PROJECT_NAME
Features: $FEATURES
Has Database: $HAS_DATABASE
Has Tools: $HAS_TOOLS

**Actions:**
1. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot
2. Create src/app/api/chat/route.ts with:
   - Import from ai and provider
   - streamText implementation
   - Tool calling (if enabled)
   - Message persistence (if database)
   - Error handling
3. Create src/app/chat/page.tsx with:
   - useChat hook
   - AI Elements or custom components
   - Loading and error states

Deliverable: Working chat page with streaming API")

---

**Send ALL applicable Task() calls in ONE message - they execute in parallel!**

Wait for all Task() calls to complete before proceeding.

---

## Phase 5: Integration & Assembly

**Goal:** Connect all components together

**Actions:**
- Read outputs from all agents
- Ensure imports are correct across files
- Update API route to use all configured services
- Verify environment variables in .env.example
- Update todos

---

## Phase 6: Verification

**Goal:** Ensure application compiles and works

**Actions:**

Launch verification agent:

Task(description="Verify TypeScript application", subagent_type="vercel-ai-sdk:vercel-ai-verifier-ts", prompt="You are the vercel-ai-verifier-ts agent. Verify the full-stack AI application.

Project: $PROJECT_NAME

**Actions:**
1. WebFetch: https://ai-sdk.dev/docs/introduction (latest patterns)
2. Run: npx tsc --noEmit
3. Fix any TypeScript errors
4. Verify all imports are correct
5. Check .env.example has all required keys
6. Generate verification report

Deliverable: Verification report with pass/fail status")

---

## Phase 7: Summary

**Goal:** Report what was built

**Actions:**

Display summary:

```
## Full-Stack AI App Created: $PROJECT_NAME

### Agents Used:
- ✅ vercel-ai-provider-agent - Provider configuration
- ✅ vercel-ai-database-agent - Database layer (if applicable)
- ✅ vercel-ai-tools-agent - Tool calling (if applicable)
- ✅ vercel-ai-elements-agent - UI components
- ✅ vercel-ai-middleware-agent - Production middleware (if applicable)
- ✅ vercel-ai-ui-agent - Chat interface
- ✅ vercel-ai-verifier-ts - Verification

### Next Steps:
1. cd $PROJECT_NAME
2. Copy .env.example to .env.local and add your API keys
3. Run database migrations (if applicable): npx drizzle-kit push
4. Start development server: npm run dev
5. Open http://localhost:3000/chat

### Documentation:
- AI SDK: https://ai-sdk.dev/docs
- AI Elements: https://ai-sdk.dev/elements
- Cookbook: https://ai-sdk.dev/cookbook
```

Mark all todos complete.

---

## Important Notes

- **Parallel execution**: Send ALL Task() calls together for speed
- **WebFetch in agents**: Each agent fetches its own documentation
- **Agent independence**: Agents work on separate directories/files
- **Integration phase**: Connect components after parallel work completes
- **Verification**: Always run TypeScript verification at the end
