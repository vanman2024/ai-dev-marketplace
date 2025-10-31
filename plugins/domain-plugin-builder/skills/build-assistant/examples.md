# Build-Assistant - Examples

## Complete Workflow Examples

### Example 1: Building a New Agent from Scratch

**Scenario**: Create an agent that analyzes code complexity

**Steps**:

1. **Read the template**
```bash
Read: templates/agents/agent.md.template
```

2. **Study the example**
```bash
Read: templates/agents/agent-example.md
```

3. **Create the agent file**
```markdown
---
name: complexity-analyzer
description: Analyzes code complexity and suggests improvements
tools: Read, Grep, Bash
model: claude-sonnet-4-5-20250929
color: purple
---

You are a code complexity analyzer...

## Your Process

### Step 1: Scan Codebase
...
```

4. **Validate the agent**
```bash
scripts/validate-agent.sh agents/complexity-analyzer.md
# ✅ Agent validation passed
```

---

### Example 2: Creating a Slash Command

**Scenario**: Create a command to run complexity analysis

**Steps**:

1. **Read the documentation**
```bash
Read: docs/01-claude-code-slash-commands.md
```

2. **Read the template**
```bash
Read: templates/commands/command.md.template
```

3. **Create the command**
```markdown
---
description: Analyze code complexity and generate report
argument-hint: [target-directory]
allowed-tools: Read(*), Bash(*)
---

User input: $ARGUMENTS

Task
```

4. **Validate the command**
```bash
scripts/validate-command.sh commands/analyze-complexity.md
# ✅ Command validation passed
```

---

### Example 3: Building a Skill with Supporting Files

**Scenario**: Create a skill for database design

**Steps**:

1. **Decide it should be a skill**
```bash
Read: docs/04-skills-vs-commands.md
# Decision: Skill (automatic discovery, complex capability)
```

2. **Create directory structure**
```bash
mkdir -p skills/database-designer/templates
mkdir -p skills/database-designer/scripts
```

3. **Read the template**
```bash
Read: templates/skills/SKILL.md.template
```

4. **Create SKILL.md**
```markdown
---
name: Database Designer
description: Design database schemas with normalization and optimization. Use when designing databases, creating schemas, or working with ERDs.
allowed-tools: Read, Write, Bash
---

# Database Designer

## Instructions

1. Analyze requirements to identify entities
2. Define relationships and cardinality
3. Apply normalization (1NF through 3NF)
4. Generate SQL schema files
5. Create migration scripts

## Available Resources

- templates/schema.sql - SQL schema template
- templates/migration.sql - Migration template
- scripts/generate-erd.py - ERD diagram generator

...
```

5. **Add supporting files**
```bash
# Create template
Write: skills/database-designer/templates/schema.sql

# Create script
Write: skills/database-designer/scripts/generate-erd.py
```

6. **Validate the skill**
```bash
scripts/validate-skill.sh skills/database-designer/
# ✅ Skill validation passed
```

---

### Example 4: Building a Complete Plugin

**Scenario**: Create a testing plugin with commands, agents, and skills

**Steps**:

1. **Read plugin documentation**
```bash
Read: docs/03-claude-code-plugins.md
```

2. **Study the example**
```bash
Read: templates/plugins/example-plugin/
```

3. **Create plugin structure**
```bash
mkdir -p multiagent-testing/.claude-plugin
mkdir -p multiagent-testing/{commands,agents,skills,docs}
```

4. **Create manifest**
```json
{
  "name": "multiagent-testing"
  "version": "1.0.0"
  "description": "Comprehensive testing tools for multiagent projects"
  "components": {
    "commands": 3
    "agents": 2
    "skills": 1
  }
}
```

5. **Add commands**
```bash
# /testing:unit
Write: multiagent-testing/commands/unit.md

# /testing:integration
Write: multiagent-testing/commands/integration.md

# /testing:e2e
Write: multiagent-testing/commands/e2e.md
```

6. **Add agents**
```bash
# test-generator agent
Write: multiagent-testing/agents/test-generator.md

# test-runner agent
Write: multiagent-testing/agents/test-runner.md
```

7. **Add skill**
```bash
# testing-assistant skill
mkdir -p multiagent-testing/skills/testing-assistant
Write: multiagent-testing/skills/testing-assistant/SKILL.md
```

8. **Create README**
```markdown
# multiagent-testing

Comprehensive testing tools for multiagent projects.

## Components

- **Commands**: 3 slash commands
- **Agents**: 2 specialized agents
- **Skills**: 1 testing skill

## Commands

- `/testing:unit` - Run unit tests
- `/testing:integration` - Run integration tests
- `/testing:e2e` - Run end-to-end tests
```

9. **Validate the plugin**
```bash
scripts/validate-plugin.sh multiagent-testing/
# ✅ Plugin validation passed
```

---

### Example 5: Deciding Between Skill and Command

**Scenario 1**: Git commit helper

**Analysis**:
```markdown
Question: Should user explicitly trigger it?
- NO - User might just ask "help me write a commit"

Question: Should Claude discover automatically?
- YES - When user mentions "commit" or "git commit"

Decision: SKILL
- Create skill with "Use when writing commit messages"
- Claude activates when context matches
```

**Scenario 2**: Deployment workflow

**Analysis**:
```markdown
Question: Should user explicitly trigger it?
- YES - Deployment is critical, needs explicit control

Question: Is it a sequential workflow?
- YES - Multiple steps that user controls

Decision: COMMAND
- Create /deploy command
- User explicitly invokes for safety
```

---

### Example 6: Using Validation Scripts

**Running Individual Validations**:

```bash
# Validate an agent
scripts/validate-agent.sh agents/my-agent.md
# ✅ Agent validation passed

# Validate a command
scripts/validate-command.sh commands/my-command.md
# ✅ Command validation passed

# Validate a skill
scripts/validate-skill.sh skills/my-skill/
# ⚠️  WARNING: Description should include 'Use when' trigger context
# (Fix required)

# Validate a plugin
scripts/validate-plugin.sh plugins/my-plugin/
# ❌ ERROR: Missing .claude-plugin/plugin.json
# (Fix required)
```

**Running Comprehensive Tests**:

```bash
# Test entire build system
scripts/test-build-system.sh
# Running comprehensive build system tests...
# ✅ All validations passed
# ✅ All templates exist
# ✅ All scripts executable
```

---

## Quick Reference: Build Workflows

### Agent Workflow
1. Read template → 2. Study example → 3. Create agent → 4. Validate

### Command Workflow
1. Read docs → 2. Read template → 3. Create command → 4. Validate

### Skill Workflow
1. Decide vs command → 2. Read template → 3. Create skill → 4. Add resources → 5. Validate

### Plugin Workflow
1. Read docs → 2. Study example → 3. Create structure → 4. Add components → 5. Create README → 6. Validate

---

**Use these examples as templates when creating your own components!**
