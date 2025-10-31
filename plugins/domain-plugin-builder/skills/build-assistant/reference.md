# Build-Assistant - Reference

## Template Variables

### Agent Template Variables
- `{{AGENT_NAME}}` - Kebab-case agent identifier
- `{{DESCRIPTION}}` - Brief description of agent purpose
- `{{TOOLS}}` - Comma-separated list of allowed tools
- `{{MODEL}}` - Model identifier (e.g., claude-sonnet-4-5-20250929)
- `{{COLOR}}` - Agent color for UI (blue, green, purple, etc.)

### Command Template Variables
- `{{COMMAND_NAME}}` - Command name without slash prefix
- `{{DESCRIPTION}}` - Brief description of command purpose
- `{{ARGUMENT_HINT}}` - Syntax hint for arguments
- `{{ALLOWED_TOOLS}}` - Comma-separated list of allowed tools
- `{{SUBAGENT_TYPE}}` - Type of subagent to invoke

### Skill Template Variables
- `{{SKILL_NAME}}` - Display name of skill
- `{{DESCRIPTION}}` - What skill does + "Use when" trigger
- `{{ALLOWED_TOOLS}}` - Optional tools restriction
- `{{TRIGGER_CONTEXT}}` - Keywords that trigger skill
- `{{STEP_BY_STEP_INSTRUCTIONS}}` - Detailed usage guide
- `{{CONCRETE_EXAMPLES}}` - Real-world usage scenarios
- `{{REQUIREMENTS}}` - Prerequisites or dependencies

### Plugin Template Variables
- `{{PLUGIN_NAME}}` - Plugin identifier (kebab-case)
- `{{DISPLAY_NAME}}` - Human-readable plugin name
- `{{VERSION}}` - Semantic version (e.g., 1.0.0)
- `{{DESCRIPTION}}` - Plugin purpose and capabilities
- `{{COMMANDS_COUNT}}` - Number of slash commands
- `{{AGENTS_COUNT}}` - Number of agents
- `{{SKILLS_COUNT}}` - Number of skills

## File Paths

### Template Locations
- Agents: `~/.claude/marketplaces/multiagent-dev/plugins/multiagent-build/skills/build-assistant/templates/agents/`
- Commands: `~/.claude/marketplaces/multiagent-dev/plugins/multiagent-build/skills/build-assistant/templates/commands/`
- Skills: `~/.claude/marketplaces/multiagent-dev/plugins/multiagent-build/skills/build-assistant/templates/skills/`
- Plugins: `~/.claude/marketplaces/multiagent-dev/plugins/multiagent-build/skills/build-assistant/templates/plugins/`

### Script Locations
- Validation: `~/.claude/marketplaces/multiagent-dev/plugins/multiagent-build/skills/build-assistant/scripts/`

### Documentation Locations
- Build docs: `~/.claude/marketplaces/multiagent-dev/plugins/multiagent-build/docs/`

## Validation Requirements

### Agent Validation
- Must have frontmatter with: name, description, tools, model, color
- Description must be clear and concise
- Tools must be comma-separated list
- Model must be valid Claude model identifier
- Color must be valid color name

### Command Validation
- Must have frontmatter with: description, argument-hint
- Must invoke Task tool with subagent_type
- Must include success criteria
- Argument hint must show expected syntax

### Skill Validation
- Must have SKILL.md file
- Must have frontmatter with: name, description
- Description must include "Use when" trigger context
- Must have Instructions section
- Should have Examples section

### Plugin Validation
- Must have `.claude-plugin/plugin.json` manifest
- Manifest must have: name, version, description
- Must have README.md
- Must have at least one component (command/agent/skill)
- Component counts must match actual components

## Component Scopes

### Personal Scope
- Location: `$HOME/.claude/`
- Usage: User-specific components
- Not shared across projects
- Ideal for personal workflows

### Project Scope
- Location: `./.claude/`
- Usage: Project-specific components
- Shared via git repository
- Ideal for team workflows

### Plugin Scope
- Location: `$HOME/.claude/marketplaces/{marketplace}/{plugin}/`
- Usage: Reusable components
- Distributed via marketplace
- Ideal for framework extensions

## Agent Specifications

### Required Frontmatter Fields
```yaml
name: agent-identifier
description: Brief purpose description
tools: Read, Write, Bash
model: claude-sonnet-4-5-20250929
color: blue
```

### Optional Frontmatter Fields
```yaml
project: true  # Project-scoped agent
```

## Command Specifications

### Required Frontmatter Fields
```yaml
description: Brief command description
argument-hint: [required-arg] [optional-arg]
```

### Optional Frontmatter Fields
```yaml
allowed-tools: Read(*), Write(*), Bash(*)  # Tool permissions
```

## Skill Specifications

### Required Frontmatter Fields
```yaml
name: Skill Display Name
description: What it does. Use when trigger context.
```

### Optional Frontmatter Fields
```yaml
allowed-tools: Read, Write, Bash  # Restrict tools when active
```

## Plugin Manifest Schema

```json
{
  "name": "plugin-identifier"
  "version": "1.0.0"
  "description": "Plugin purpose and capabilities"
  "components": {
    "commands": 0
    "agents": 0
    "skills": 0
  }
}
```

## Best Practices

### Naming Conventions
- Agents: kebab-case (e.g., `skill-builder`)
- Commands: kebab-case without slash (e.g., `build-skill`)
- Skills: Title Case (e.g., `Build Assistant`)
- Plugins: kebab-case (e.g., `multiagent-build`)

### Description Writing
- Start with action verb
- Keep under 100 characters
- Include "Use when" for skills
- Mention key capabilities
- Avoid technical jargon

### File Organization
```
enterprise-plugin/
├── .claude-plugin/           # Metadata directory
│   └── plugin.json          # Required: plugin manifest
├── commands/                 # Default command location
│   ├── status.md
│   └──  logs.md
├── agents/                   # Default agent location
│   ├── security-reviewer.md
│   ├── performance-tester.md
│   └── compliance-checker.md
├── skills/                   # Agent Skills
│   ├── code-reviewer/
│   │   └── SKILL.md
│   └── pdf-processor/
│       ├── SKILL.md
│       └── scripts/
├── hooks/                    # Hook configurations
│   ├── hooks.json           # Main hook config
│   └── security-hooks.json  # Additional hooks
├── .mcp.json                # MCP server definitions
├── scripts/                 # Hook and utility scripts
│   ├── security-scan.sh
│   ├── format-code.py
│   └── deploy.js
├── LICENSE                  # License file
└── CHANGELOG.md             # Version history
```
