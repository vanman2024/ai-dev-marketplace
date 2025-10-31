# Domain Plugin Builder Documentation

Documentation for building domain-specific plugins for Claude Code.

## Documentation Structure

### Claude Framework (`frameworks/claude/`)

Claude Code framework-specific documentation for building agents, skills, and commands.

- **[component-decision-framework.md](frameworks/claude/component-decision-framework.md)** - When to use commands vs agents vs skills
- **[agent-skills-architecture.md](frameworks/claude/agent-skills-architecture.md)** - Agent and skill design patterns

### Plugin Structure (`frameworks/plugins/`)

Plugin architecture and marketplace organization.

- **[claude-code-plugin-structure.md](frameworks/plugins/claude-code-plugin-structure.md)** - Plugin directory structure and manifest format
- **[plugin-marketplaces.md](frameworks/plugins/plugin-marketplaces.md)** - Plugin marketplace fundamentals
- **[tech-stack-marketplaces.md](frameworks/plugins/tech-stack-marketplaces.md)** - Tech stack marketplace architecture

### Plugin Build Checklist

- **[plugin-build-checklist.md](plugin-build-checklist.md)** - Complete workflow for building, validating, and installing plugins

## Quick Start

### Building a New Plugin

```bash
/domain-plugin-builder:plugin-create my-plugin
```

This command handles everything:
- Creates plugin structure
- Builds all commands, agents, and skills
- Validates all components
- Updates marketplace.json
- Registers commands in settings
- Commits to git

### Adding to an Existing Plugin

**Add command:**
```bash
/domain-plugin-builder:slash-commands-create my-command "description" --plugin=existing-plugin
```

**Add agent:**
```bash
/domain-plugin-builder:agents-create my-agent "description" "tools"
```

**Add skill:**
```bash
/domain-plugin-builder:skills-create my-skill "description"
```

## Validation

**Validate entire plugin:**
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh plugins/my-plugin
```

**Fix tool formatting issues:**
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/fix-tool-formatting.sh
```

## Best Practices

1. **Always use `/domain-plugin-builder:plugin-create`** for new plugins - don't build manually
2. **Validate before committing** - run validation scripts
3. **Follow tool formatting rules** - see CLAUDE.md for correct syntax
4. **Git commit and push immediately** - never leave work uncommitted
5. **Test slash commands** after building - verify they work

## Documentation Notes

- Plugin-specific SDK documentation lives in each plugin's `docs/` directory
- Framework documentation (Claude, plugins) stays in `domain-plugin-builder/docs/frameworks/`
- Build assistant scripts are in `skills/build-assistant/scripts/`

See [CLAUDE.md](../CLAUDE.md) for complete plugin building rules and patterns.
