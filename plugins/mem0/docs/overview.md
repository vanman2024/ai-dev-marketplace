# Mem0 Plugin Overview

Complete AI memory management plugin for Claude Code, supporting both Platform (hosted) and Open Source (self-hosted with Supabase) deployment modes.

## What is Mem0?

Mem0 is an intelligent memory layer for AI applications that enables:
- **Persistent conversation memory** - Remember context across sessions
- **User preference tracking** - Learn and adapt to user preferences
- **Entity extraction** - Identify and track entities and relationships
- **Semantic search** - Find relevant memories using natural language
- **Multi-modal support** - Store text, images, and other media

## Why Use This Plugin?

### Quick Integration
- Initialize Mem0 in < 2 minutes (Platform mode)
- Automatic framework detection (Vercel AI SDK, LangChain, CrewAI)
- Generate integration code automatically
- Zero manual configuration for common frameworks

### Flexible Deployment
- **Platform Mode**: Managed infrastructure, enterprise features, quick setup
- **OSS Mode**: Full control, Supabase backend, unlimited usage
- Easy migration path between modes

### Production-Ready Features
- Graph memory for relationship tracking
- Advanced retrieval with rerankers
- Webhooks for real-time notifications
- Memory export and import
- SOC 2 compliance (Platform mode)
- Row-level security (OSS mode with Supabase)

## Core Concepts

### Memory Types

**User Memory**
- Persistent across all conversations
- Stores user preferences, profile data, learned facts
- Examples: Language preference, interests, past interactions

**Agent Memory**
- Specific to an agent's interactions
- Stores agent-specific knowledge and patterns
- Examples: Agent personality, domain expertise, tools used

**Session/Run Memory**
- Temporary conversation context
- Cleared after session ends
- Examples: Current task state, temporary variables

### Storage Architecture

**Vector Memory** (Default)
- Fast semantic search
- Simple to setup and use
- Scales horizontally
- Best for: Chatbots, FAQ systems, content retrieval

**Graph Memory** (Advanced)
- Track relationships between memories
- Complex queries for connected data
- Entity knowledge graphs
- Best for: Multi-agent systems, knowledge management, research assistants

## Plugin Components

### Commands (9 total)

**Setup Commands**:
- `/mem0:init` - Initialize Mem0 (Platform or OSS)
- `/mem0:init-platform` - Setup hosted Platform
- `/mem0:init-oss` - Setup self-hosted with Supabase

**Feature Commands**:
- `/mem0:add-conversation-memory` - Add conversation tracking
- `/mem0:add-user-memory` - Add user preference tracking
- `/mem0:add-graph-memory` - Enable graph relationships

**Management Commands**:
- `/mem0:configure` - Configure memory settings
- `/mem0:test` - Comprehensive testing
- `/mem0:migrate-to-supabase` - Migrate Platform → OSS

### Agents (3 specialized)

**mem0-integrator**
- Setup and integration specialist
- Framework detection and adaptation
- Supabase configuration (OSS mode)

**mem0-memory-architect**
- Memory architecture design
- Schema optimization
- Retention strategy planning

**mem0-verifier**
- Validation and testing
- Performance benchmarking
- Security auditing

### Skills (3 comprehensive)

**memory-design-patterns**
- Best practices for memory architecture
- Memory type selection guides
- Retention strategies
- Performance patterns

**supabase-integration**
- Supabase schema setup
- pgvector configuration
- RLS policies for isolation
- Migration strategies

**memory-optimization**
- Query optimization
- Caching strategies
- Cost reduction
- Performance tuning

## Quick Start

### 1. Initialize Mem0

```bash
# Interactive setup (asks Platform vs OSS)
/mem0:init

# Or directly choose Platform (hosted)
/mem0:init-platform

# Or directly choose OSS (self-hosted with Supabase)
/mem0:init-oss
```

### 2. Add Conversation Memory

```bash
# Automatically integrates with detected framework
/mem0:add-conversation-memory
```

### 3. Test Setup

```bash
# Comprehensive validation
/mem0:test
```

## Use Cases

### Chatbots & Virtual Assistants
- Remember user preferences and conversation history
- Provide personalized responses
- Track long-term user relationships

### Customer Support
- Maintain customer interaction history
- Track issue resolution patterns
- Provide context-aware support

### AI Tutors & Coaches
- Learn student knowledge levels
- Adapt teaching style
- Track progress over time

### Multi-Agent Systems
- Share knowledge between agents
- Track agent interactions
- Maintain system-wide context

### Knowledge Management
- Build organizational knowledge graphs
- Track document relationships
- Enable semantic search across content

## Architecture

### With AI Tech Stack 1

```
Your Application
    ↓
┌─────────────────────────────────────┐
│ AI Tech Stack 1 Foundation          │
│ ├── Next.js (Frontend)              │
│ ├── Vercel AI SDK (AI Orchestration)│
│ ├── Supabase (Database + Auth)      │
│ ├── Mem0 (Memory Layer) ← THIS     │
│ └── FastMCP (Tool Infrastructure)   │
└─────────────────────────────────────┘
    ↓
Claude API / OpenAI API
```

### Standalone Integration

```
Your Application
    ↓
Framework (LangChain, CrewAI, etc.)
    ↓
Mem0 Memory Layer
    ↓
Platform (Hosted) OR Supabase (OSS)
```

## Performance

### Platform Mode
- Add memory: < 500ms (p95)
- Search memory: < 200ms (p95)
- Managed infrastructure
- Auto-scaling

### OSS Mode (Supabase)
- Add memory: < 400ms (p95) with optimized indexes
- Search memory: < 150ms (p95) with pgvector
- Full control over performance tuning
- Cost-effective at scale

## Security

### Platform Mode
- SOC 2 compliant
- Encryption at rest and in transit
- Enterprise SSO available
- Audit logs

### OSS Mode (Supabase)
- Row-level security (RLS) for isolation
- User/tenant data separation
- Full control over encryption
- GDPR compliance tools

## Cost Considerations

### Platform Mode
**Pros:**
- No infrastructure management
- Predictable pricing
- Enterprise support
- Quick setup

**Cons:**
- Usage-based pricing
- Higher cost at scale
- Less flexibility

### OSS Mode (Supabase)
**Pros:**
- Free tier available
- Predictable costs
- Unlimited usage
- Full control

**Cons:**
- Requires Supabase setup
- Infrastructure management
- Self-support

## Next Steps

1. **Choose deployment mode**: Platform vs OSS
2. **Initialize Mem0**: Run `/mem0:init`
3. **Integrate with your app**: Run `/mem0:add-conversation-memory`
4. **Test setup**: Run `/mem0:test`
5. **Optimize**: Use `/mem0:configure` and memory-optimization skill

## Resources

- **Mem0 Documentation**: https://docs.mem0.ai
- **Platform Dashboard**: https://app.mem0.ai
- **Open Source GitHub**: https://github.com/mem0ai/mem0
- **Supabase Integration**: https://docs.mem0.ai/open-source/configuration
- **AI Tech Stack 1**: See plugins/domain-plugin-builder/docs/frameworks/plugins/ai-tech-stack-1-definition.md

## Support

- **Discord**: https://mem0.dev/DiD
- **GitHub Issues**: https://github.com/mem0ai/mem0/issues
- **Documentation**: https://docs.mem0.ai
