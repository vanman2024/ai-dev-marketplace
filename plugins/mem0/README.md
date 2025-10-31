# Mem0 Plugin for Claude Code

> Complete AI memory management plugin supporting Platform (hosted) and Open Source (self-hosted with Supabase) deployment modes

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AI Tech Stack 1](https://img.shields.io/badge/AI%20Tech%20Stack-1-blue)](../domain-plugin-builder/docs/frameworks/plugins/ai-tech-stack-1-definition.md)

## Overview

Mem0 plugin provides intelligent memory management for AI applications, enabling persistent conversation memory, user preference tracking, and knowledge graph construction. Seamlessly integrates with Vercel AI SDK, LangChain, CrewAI, and other AI frameworks.

### Key Features

✅ **Dual Deployment Modes**: Platform (managed) or OSS (self-hosted with Supabase)
✅ **Automatic Integration**: Detects and integrates with existing AI frameworks
✅ **Graph Memory**: Track relationships between memories and entities
✅ **Production-Ready**: Security, performance, and compliance built-in
✅ **Zero Config**: Intelligent defaults with optional customization
✅ **Complete Toolkit**: 9 commands, 3 agents, 3 comprehensive skills

## Quick Start

### Installation

The plugin is part of the **ai-dev-marketplace**:

```bash
# Plugin is auto-installed with ai-dev-marketplace
# Or manually install if needed
claude plugin install mem0@ai-dev-marketplace
```

### Initialize Mem0

```bash
# Interactive setup (asks MCP vs Platform vs OSS)
/mem0:init

# MCP mode (local OpenMemory, private & cross-tool)
/mem0:init-mcp

# Platform mode (hosted, 2-minute setup)
/mem0:init-platform

# OSS mode (self-hosted with Supabase)
/mem0:init-oss
```

### Add Memory to Your App

```bash
# Automatically integrates with detected framework
/mem0:add-conversation-memory

# Add user preference tracking
/mem0:add-user-memory

# Enable graph memory (relationships)
/mem0:add-graph-memory
```

### Test & Validate

```bash
# Comprehensive testing and validation
/mem0:test
```

## Commands

| Command | Description |
|---------|-------------|
| `/mem0:init` | Initialize Mem0 (asks MCP vs Platform vs OSS) |
| `/mem0:init-mcp` | Setup local OpenMemory MCP server |
| `/mem0:init-platform` | Setup hosted Platform mode |
| `/mem0:init-oss` | Setup self-hosted with Supabase |
| `/mem0:add-conversation-memory` | Add conversation tracking |
| `/mem0:add-user-memory` | Add user preference tracking |
| `/mem0:add-graph-memory` | Enable graph relationships |
| `/mem0:configure` | Configure memory settings |
| `/mem0:test` | Comprehensive testing |
| `/mem0:migrate-to-supabase` | Migrate Platform → OSS |

## Agents

### mem0-integrator
Setup and integration specialist. Detects frameworks, generates integration code, configures Supabase persistence.

**Use for**: Initial setup, framework integration, Supabase configuration

### mem0-memory-architect
Memory architecture design specialist. Recommends memory patterns, designs schemas, plans retention strategies.

**Use for**: Architecture decisions, schema design, optimization planning

### mem0-verifier
Validation and testing specialist. Tests operations, benchmarks performance, audits security.

**Use for**: Setup validation, performance testing, security audits

## Skills

### memory-design-patterns
Best practices for memory architecture with decision frameworks, pattern templates, and case studies.

**16 files**: Functional scripts, architecture templates, real-world examples

### supabase-integration
Complete Supabase setup for Mem0 with pgvector, RLS policies, migrations, and security best practices.

**16 files**: Setup scripts, SQL templates, integration examples

### memory-optimization
Performance optimization with query tuning, caching strategies, and cost reduction techniques.

**16 files**: Analysis tools, optimization templates, benchmarking examples

## Documentation

- **[Overview](./docs/overview.md)** - What is Mem0 and why use it
- **[Platform vs OSS](./docs/platform-vs-oss.md)** - Decision guide and comparison
- **[Supabase Setup](./docs/supabase-setup.md)** - OSS mode configuration
- **[API Reference](./docs/api-reference.md)** - Memory operations API

## Architecture

### With AI Tech Stack 1

```
┌─────────────────────────────────────┐
│ AI Tech Stack 1 Foundation          │
│ ├── Next.js (Frontend)              │
│ ├── Vercel AI SDK (AI Orchestration)│
│ ├── Supabase (Database + Auth)      │
│ ├── Mem0 (Memory Layer) ← THIS     │
│ └── FastMCP (Tool Infrastructure)   │
└─────────────────────────────────────┘
```

### Memory Types

**User Memory**: Persistent preferences and profile data
**Agent Memory**: Agent-specific knowledge and patterns
**Session Memory**: Temporary conversation context

### Storage Options

**Vector Memory** (Default): Fast semantic search, simple setup
**Graph Memory** (Advanced): Relationship tracking, knowledge graphs

## Deployment Modes Comparison

| | MCP (Local) | Platform | OSS (Supabase) |
|-|-------------|----------|----------------|
| **Setup** | 3 minutes | 2 minutes | 5 minutes |
| **Cost** | Free (local) | $25-100/mo | $0-25/mo |
| **Data Location** | Local only | Cloud | Your choice |
| **Cross-tool** | ✅ Yes | ❌ No | ❌ No |
| **Privacy** | 100% private | Managed | Full control |
| **Compliance** | DIY | SOC 2 ✅ | DIY |

**Recommendations**:
- MCP for local development & cross-tool memory
- Platform for prototyping & enterprise
- OSS for production at scale

[Full comparison →](./docs/platform-vs-oss.md)

## Use Cases

### Chatbots & Assistants
Remember user preferences, conversation history, personalized responses

### Customer Support
Track interaction history, maintain context, provide relevant solutions

### AI Tutors
Learn student knowledge, adapt teaching style, track progress

### Multi-Agent Systems
Share knowledge between agents, maintain system context

### Knowledge Management
Build knowledge graphs, semantic search, document relationships

## Integration Examples

### With Vercel AI SDK

```typescript
import { MemoryClient } from 'mem0ai';
import { streamText } from 'ai';

const memory = new MemoryClient({ apiKey: process.env.MEM0_API_KEY });

// Retrieve memories before generation
const memories = await memory.search({ query, user_id });

// Use in context
const result = await streamText({
  model: claude('claude-sonnet-4')
  messages: [
    { role: 'system', content: `Context: ${memories}` }
    { role: 'user', content: query }
  ]
});

// Store new memories
await memory.add(result.text, { user_id });
```

### With Supabase (OSS)

```python
from mem0 import Memory

# Configure Mem0 to use Supabase
config = {
    "vector_store": {
        "provider": "postgres"
        "config": {
            "host": os.getenv("SUPABASE_DB_HOST")
            "database": "postgres"
            "user": "postgres"
            "password": os.getenv("SUPABASE_DB_PASSWORD")
        }
    }
}

memory = Memory.from_config(config)
```

## Performance

### Platform Mode
- Add memory: < 500ms (p95)
- Search memory: < 200ms (p95)
- Auto-scaling, managed infrastructure

### OSS Mode (Supabase, optimized)
- Add memory: < 400ms (p95)
- Search memory: < 150ms (p95)
- Full control over tuning

## Security

### Platform
- SOC 2 compliant
- Encryption at rest/transit
- Enterprise SSO
- Audit logs

### OSS (Supabase)
- Row-level security (RLS)
- User/tenant isolation
- Full encryption control
- GDPR compliance tools

## Requirements

### Platform Mode
- Python 3.8+ or Node.js 14+
- Mem0 API key (from app.mem0.ai)

### OSS Mode
- Python 3.8+ or Node.js 14+
- Supabase project
- PostgreSQL with pgvector

## Development

### Project Structure

```
plugins/mem0/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── agents/
│   ├── mem0-integrator.md   # Setup specialist
│   ├── mem0-memory-architect.md  # Design specialist
│   └── mem0-verifier.md     # Testing specialist
├── commands/
│   ├── init.md              # Main initializer
│   ├── init-platform.md     # Platform setup
│   ├── init-oss.md          # OSS setup
│   ├── add-conversation-memory.md
│   ├── add-user-memory.md
│   ├── add-graph-memory.md
│   ├── configure.md
│   ├── test.md
│   └── migrate-to-supabase.md
├── skills/
│   ├── memory-design-patterns/  # Architecture best practices
│   ├── supabase-integration/    # Supabase setup
│   └── memory-optimization/     # Performance tuning
├── docs/
│   ├── overview.md
│   ├── platform-vs-oss.md
│   ├── supabase-setup.md
│   └── api-reference.md
└── README.md
```

## Contributing

This plugin is part of the **ai-dev-marketplace**. Contributions welcome!

1. Fork the repository
2. Create feature branch
3. Follow existing patterns
4. Test thoroughly
5. Submit pull request

## Resources

### Mem0
- **Documentation**: https://docs.mem0.ai
- **Platform Dashboard**: https://app.mem0.ai
- **GitHub**: https://github.com/mem0ai/mem0
- **Discord**: https://mem0.dev/DiD

### AI Tech Stack 1
- **Definition**: See `plugins/domain-plugin-builder/docs/frameworks/plugins/ai-tech-stack-1-definition.md`
- **Other Plugins**: vercel-ai-sdk, supabase, fastmcp, claude-agent-sdk

## License

MIT License - See LICENSE file for details

## Support

- **Plugin Issues**: https://github.com/vanman2024/ai-dev-marketplace/issues
- **Mem0 Support**: https://docs.mem0.ai or Discord
- **Community**: Join the AI Dev Marketplace Discord

## Version

**1.0.0** - Initial release with complete Platform and OSS support

---

**Part of AI Tech Stack 1** - Complete foundation for AI applications

Made with ❤️ by the AI Dev Marketplace team
