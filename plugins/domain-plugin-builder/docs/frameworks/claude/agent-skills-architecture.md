# Agent Skills Architecture

**Source**: [Anthropic - Equipping Agents for the Real World with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)

## Core Concept

Agent Skills are **organized folders of instructions, scripts, and resources that agents can discover and load dynamically to perform better at specific tasks**. They transform general-purpose agents into specialized ones by packaging domain expertise in composable, portable formats.

## Skill Structure

A skill requires a directory containing:

1. **SKILL.md file** with YAML frontmatter including required metadata: `name` and `description`
2. **Additional referenced files** organized within the skill directory for complex capabilities
3. **Optional code** that agents can execute as tools

### Directory Layout Example
```
skills/
  my-skill/
    SKILL.md           # Core skill instructions with frontmatter
    scripts/           # Executable scripts agents can run
    templates/         # Code/config templates
    examples/          # Usage examples
    reference.md       # Additional reference material (loaded on-demand)
    forms.md          # Form templates (loaded on-demand)
```

## Progressive Disclosure Pattern

This is the foundational design principle. Skills organize information in layers:

- **Level 1 (Metadata)**: The skill name and description load into Claude's system prompt at startup, enabling it to recognize when a skill is relevant
- **Level 2 (Core Content)**: Full SKILL.md content loads only when Claude determines the skill applies to the current task
- **Level 3+ (Details)**: Additional bundled files (like `reference.md`, `forms.md`) load only as needed during execution

> "Agents with a filesystem and code execution tools don't need to read the entirety of a skill into their context window when working on a particular task. This means that the amount of context that can be bundled into a skill is effectively unbounded."

## Context Window Behavior

When triggered, the sequence follows:

1. **Startup**: Core system prompt and skill metadata (name + description) occupy initial context
2. **Skill Trigger**: Claude invokes tools (e.g., Bash) to read relevant SKILL.md files into context
3. **Selective Loading**: Claude loads referenced supporting files only when needed
4. **Execution**: Claude proceeds with task using loaded instructions and scripts

### Analogy
Think of skills as "a well-organized manual that starts with a table of contents, then specific chapters, and finally a detailed appendix."

## How Agents Invoke Skills

Skills are invoked through **tool calls**, not special skill-invocation tools: 1. **Discovery**: Agent recognizes skill is relevant based on metadata in system prompt
2. **Loading**: Agent uses `Read` tool to load `SKILL.md` into context
3. **Script Execution**: Agent uses `Bash` tool to execute scripts from `skills/*/scripts/*.sh`
4. **Template Usage**: Agent uses `Read` tool to load templates from `skills/*/templates/*`
5. **Reference Lookup**: Agent uses `Read` tool to load additional docs as needed

### Example Invocation Pattern
```bash
# Agent loads skill instructions
Read: plugins/supabase/skills/pgvector-setup/SKILL.md

# Agent executes skill script
Bash: bash plugins/supabase/skills/pgvector-setup/scripts/setup-pgvector.sh "$DB_URL"

# Agent loads template for customization
Read: plugins/supabase/skills/pgvector-setup/templates/embedding-table-schema.sql

# Agent loads example for guidance
Read: plugins/supabase/skills/pgvector-setup/examples/semantic-search-usage.md
```

## Development Best Practices

### 1. Start with Evaluation
Identify capability gaps by running agents on representative tasks, then build skills incrementally to address shortcomings.

**Process**:
- Run agent on real tasks
- Observe failures and gaps
- Build skills targeting specific capability gaps
- Iterate based on usage patterns

### 2. Structure for Scale
Split unwieldy SKILL.md files into separate referenced documents. Keep mutually exclusive contexts separate to reduce token usage. Distinguish between code meant for execution versus reference documentation.

**Guidelines**:
- Keep SKILL.md under 150 lines (core instructions only)
- Move large reference material to separate `.md` files
- Put executable code in `scripts/` directory
- Put reusable templates in `templates/` directory
- Put usage examples in `examples/` directory

### 3. Think from Claude's Perspective
Monitor real-world usage and iterate based on observations. Pay special attention to **skill name and description**—these determine when Claude triggers the skill.

**Critical Elements**:
- **Name**: Short, descriptive, kebab-case (e.g., `pgvector-setup`)
- **Description**: Include trigger contexts using "Use when" pattern
  - Good: "Use when setting up vector search, building RAG systems, or when user mentions pgvector, embeddings, semantic search"
  - Bad: "Configures pgvector" (too vague, no trigger context)

### 4. Iterate with Claude
Collaborate with Claude to capture successful approaches and common mistakes into reusable context and code within the skill.

**Workflow**:
- Use skills on real tasks
- Ask Claude to document successful patterns
- Refine skill based on actual usage
- Add common edge cases to examples

## Security Considerations

> "We recommend installing skills only from trusted sources."

When using less-trusted skills, thoroughly audit:
- Bundled files for malicious content
- Code dependencies and external packages
- Any instructions directing Claude toward external network sources
- Script permissions and execution scope

## Skills vs. Agents: When to Use Each

### Use Skills When
- Adding **domain-specific expertise** to general-purpose agents
- Need **portable, reusable capabilities** across multiple agents
- Want to **specialize existing agents** without creating new ones
- Building **tool libraries** (scripts, templates, utilities)
- Packaging **best practices** and patterns

### Use Agents When
- Building **standalone autonomous systems**
- Need **orchestration across multiple tasks**
- Require **multi-step workflows** with decision logic
- Creating **specialized workers** for complex domains
- Need **stateful coordination** between operations

**Key Distinction**: Skills specialize existing agents; agents handle independent, complex task workflows.

## Implementation Status

Agent Skills are supported today across:
- **Claude.ai** - Web interface
- **Claude Code** - VSCode extension / CLI
- **Claude Agent SDK** - TypeScript/Python SDKs
- **Claude Developer Platform** - API integration

Upcoming features will support the full lifecycle of creating, editing, discovering, sharing, and using skills.

## Real-World Example: Supabase Plugin Skills

The Supabase plugin demonstrates skill organization:

```
plugins/supabase/skills/
  pgvector-setup/              # Vector search configuration
    SKILL.md                   # Core instructions
    scripts/
      setup-pgvector.sh        # Enable extension
      create-indexes.sh        # HNSW/IVFFlat indexes
      setup-hybrid-search.sh   # Semantic + keyword
      test-vector-search.sh    # Performance validation
    templates/
      embedding-table-schema.sql
      hnsw-index.sql
      hybrid-search-query.sql
    examples/
      semantic-search-usage.md
      rag-implementation-guide.md

  auth-configs/                # Authentication setup
    scripts/
      setup-oauth-provider.sh  # OAuth configuration
      setup-email-auth.sh      # Email/password auth
      configure-jwt.sh         # JWT settings
    templates/
      google-oauth-config.json
      email-templates/
        confirmation.html
        magic-link.html
      auth-middleware.ts

  rls-templates/               # Row Level Security
    scripts/
      generate-policy.sh       # Policy generation
      apply-rls-policies.sh    # Policy deployment
      test-rls-policies.sh     # Security testing
      audit-rls.sh            # Coverage audit
    templates/
      user-isolation.sql
      multi-tenant.sql
      role-based-access.sql
```

Each skill provides specialized capabilities that multiple Supabase agents can use, following the progressive disclosure pattern.

## References

- [Anthropic Engineering Blog: Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Claude Code Documentation: Skills](https://docs.claude.com/en/docs/claude-code/skills)
- [Claude Code Documentation: Plugins](https://docs.claude.com/en/docs/claude-code/plugins)
