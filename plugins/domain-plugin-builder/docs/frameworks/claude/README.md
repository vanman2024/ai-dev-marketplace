# Claude Framework Documentation

This directory contains documentation for Claude-specific frameworks and patterns that apply across both Claude Code and the Claude Agent SDK.

## Contents

### [Agent Skills Architecture](./agent-skills-architecture.md)
Complete technical overview of how Agent Skills work in Claude, including:
- Progressive disclosure pattern
- Skill structure and organization
- How agents invoke skills (via tools, not special invocation)
- Development best practices
- Skills vs agents decision framework
- Real-world examples from Supabase plugin

**Key Insight**: Skills are invoked through regular tools (`Bash` for scripts, `Read` for templates/docs), not special skill-invocation tools. The progressive disclosure pattern means agents only load what they need when they need it.

## Cross-Framework Concepts

### Agent Architecture
Agents work the same way whether you're using:
- **Claude Code**: CLI/VSCode extension with plugin system
- **Claude Agent SDK**: TypeScript/Python SDKs for building custom agents
- **Claude.ai**: Web interface with skill support

### Skills Apply Everywhere
Skills built for Claude Code plugins can be referenced by:
- Claude Code agents in the plugin system
- Claude Agent SDK agents via file system access
- Claude.ai when skills are installed

### Plugin Patterns
When building plugins that work across platforms:
- Use WebFetch for documentation (runtime doc fetching)
- Organize skills with scripts/templates/examples structure
- Write agents that delegate to skills via Bash/Read tools
- Create slash commands that orchestrate multiple agents

## Building for Claude

### For Claude Code Plugins
- **Location**: `/plugins/{plugin-name}/`
- **Components**: agents/, commands/, skills/
- **Invocation**: Slash commands trigger agents → agents use skills
- **Distribution**: Marketplace or manual installation

### For Claude Agent SDK
- **Location**: Any project directory with agent definition
- **Components**: Agent files reference skills via file paths
- **Invocation**: Direct agent instantiation in code
- **Distribution**: NPM/PyPI packages or source code

### Shared Best Practices
1. **Progressive Disclosure**: Keep metadata small, load details on-demand
2. **WebFetch for Docs**: Fetch latest documentation at runtime
3. **Script + Template Pattern**: Executable scripts + reusable templates
4. **Clear Triggers**: Skill descriptions must include "Use when" contexts
5. **Security First**: Audit all skill code before deployment

## Reference Documentation

### Official Anthropic Resources
- [Agent Skills Engineering Blog](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Claude Agent SDK](https://github.com/anthropics/claude-agent-sdk)

### Framework-Specific Guides
- [Claude Code Skills Docs](https://docs.claude.com/en/docs/claude-code/skills)
- [Claude Code Plugins Docs](https://docs.claude.com/en/docs/claude-code/plugins)
- [Claude Code Bash Tool](https://docs.claude.com/en/docs/claude-code/bash-tool)
- [Claude Code Tools Reference](https://docs.claude.com/en/docs/claude-code/tools)

## Usage in Plugin Builder

When building plugins using the domain-plugin-builder, reference these docs for:
- **Creating skills**: Follow progressive disclosure pattern from agent-skills-architecture.md
- **Building agents**: Agents should use Bash/Read to invoke skills
- **Writing commands**: Commands orchestrate agents who use skills
- **Documentation**: Include WebFetch URLs in agent definitions

### Example Agent Using Skills
```markdown
---
name: my-agent
description: Does something specific
tools: Bash, Read, Write, Edit
---

You are a specialist agent.

## Phase 1: Discovery
- WebFetch: https://example.com/docs/overview

## Phase 2: Implementation
1. Use the my-skill for setup:
   ```bash
   bash plugins/my-plugin/skills/my-skill/scripts/setup.sh
   ```

2. Review template:
   - Read: plugins/my-plugin/skills/my-skill/templates/config.yaml

3. Customize and apply:
   - Edit the config based on user requirements
   - Write: output/config.yaml
```

## Contributing

When adding Claude framework documentation:
1. Place in `/plugins/domain-plugin-builder/docs/frameworks/claude/`
2. Update this README with links and descriptions
3. Follow Anthropic's official terminology and patterns
4. Include real-world examples from existing plugins
