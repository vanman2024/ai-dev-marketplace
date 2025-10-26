---
description: Create new skill using templates - no sub-agents needed
argument-hint: <skill-name> "<description>"
allowed-tools: Read(*), Write(*), Bash(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

## Step 1: Parse Arguments

Parse arguments to extract:
- Skill name (first argument)
- Description (second argument in quotes)

## Step 2: Load Design Principles

Use the Read tool to load lifecycle plugin guide:
- Read: plugins/domain-plugin-builder/skills/build-assistant/templates/skills/SKILL.md.template

Then load a working example:
- Read: plugins/domain-plugin-builder/skills/build-assistant/templates/skills/skill-example/SKILL.md

Study the templates to understand:
- SKILL.md frontmatter structure
- "Use when" trigger context pattern
- Instructions format
- Script organization

## Step 3: Determine Plugin Location

Use AskUserQuestion to determine which plugin this skill belongs to, or detect from current context.

## Step 4: Create Skill Directory Structure

Use Bash tool to create directories:
```bash
mkdir -p plugins/PLUGIN_NAME/skills/SKILL_NAME
mkdir -p plugins/PLUGIN_NAME/skills/SKILL_NAME/templates
mkdir -p plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts
```

## Step 5: Create SKILL.md

Create the skill manifest following template structure:

Location: `plugins/PLUGIN_NAME/skills/SKILL_NAME/SKILL.md`

**Frontmatter:**
```yaml
---
name: skill-name
description: Clear description with "Use when" context
allowed-tools: Tool1, Tool2, Tool3
---
```

**Body Structure:**
- Brief introduction
- "Use when" trigger contexts with examples
- Step-by-step instructions
- Required files/templates
- Success criteria

Keep it concise - under 150 lines.

## Step 6: Copy Template Scripts (if needed)

If skill needs helper scripts, use Bash tool to copy templates:
```bash
cp plugins/domain-plugin-builder/skills/build-assistant/templates/skills/scripts/*.sh plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts/ 2>/dev/null || true
chmod +x plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts/*.sh 2>/dev/null || true
```

## Step 7: Validate

Use Bash tool to validate:
```bash
bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-skill.sh plugins/PLUGIN_NAME/skills/SKILL_NAME
```

## Step 8: Display Summary

Show:
- **Skill Created:** SKILL_NAME
- **Location:** plugins/PLUGIN_NAME/skills/SKILL_NAME/
- **Files:** SKILL.md, scripts/, templates/
- **Usage:** Document how to invoke the skill

## Success Criteria

- ✅ SKILL.md has proper frontmatter
- ✅ "Use when" context is clear
- ✅ Instructions are step-by-step
- ✅ Validation passes
- ✅ Scripts are executable
