---
allowed-tools: Read(*), Write(*), Bash(*), AskUserQuestion(*)
description: Create new skill using templates - no sub-agents needed
argument-hint: <skill-name> "<description>"
---

**Arguments**: $ARGUMENTS

## Step 1: Parse Arguments

Extract skill name and description:

!{bash echo "$ARGUMENTS" | awk '{print "Skill:", $1}'}

## Step 2: Load Design Principles

Use Read tool to load lifecycle plugin guide:

!{read plugins/domain-plugin-builder/docs/09-lifecycle-plugin-guide.md}

Then use Read tool to load skills vs commands guide:

!{read plugins/domain-plugin-builder/docs/05-skills-vs-commands.md}

**Available for reference (load on-demand):**
- Chaining Patterns: `07-chaining-patterns.md`
- Workflow Examples: `08-workflow-examples.md`

## Step 3: Load Skill Templates

Use Read tool to load skill template:

!{read plugins/domain-plugin-builder/skills/build-assistant/templates/skills/SKILL.md.template}

Then use Read tool to load skill example:

!{read plugins/domain-plugin-builder/skills/build-assistant/templates/skills/skill-example/SKILL.md}

## Step 4: Determine Plugin Location

AskUserQuestion: Which plugin should this skill belong to?

List available plugins or specify plugin name.

## Step 5: Create Skill Directory Structure

!{bash mkdir -p plugins/PLUGIN_NAME/skills/SKILL_NAME}
!{bash mkdir -p plugins/PLUGIN_NAME/skills/SKILL_NAME/templates}
!{bash mkdir -p plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts}

## Step 6: Load Script Templates

Use Read tool to load bash script template:

!{read plugins/domain-plugin-builder/skills/build-assistant/templates/skills/scripts/template-script.sh}

Then use Read tool to load python helper template:

!{read plugins/domain-plugin-builder/skills/build-assistant/templates/skills/scripts/template-helper.py}

Then use Read tool to load scripts README:

!{read plugins/domain-plugin-builder/skills/build-assistant/templates/skills/scripts/README.md}

## Step 7: Populate Scripts Directory

Copy template scripts to skill's scripts/ directory:

!{bash cp plugins/domain-plugin-builder/skills/build-assistant/templates/skills/scripts/*.sh plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts/ 2>/dev/null || true}
!{bash cp plugins/domain-plugin-builder/skills/build-assistant/templates/skills/scripts/*.py plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts/ 2>/dev/null || true}
!{bash cp plugins/domain-plugin-builder/skills/build-assistant/templates/skills/scripts/README.md plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts/ 2>/dev/null || true}

Make scripts executable:

!{bash chmod +x plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts/*.sh 2>/dev/null || true}
!{bash chmod +x plugins/PLUGIN_NAME/skills/SKILL_NAME/scripts/*.py 2>/dev/null || true}

## Step 8: Create SKILL.md

Based on template, create skill file:

Location: plugins/PLUGIN_NAME/skills/SKILL_NAME/SKILL.md

**CRITICAL: Description Field Controls Auto-Invocation**

The description must have explicit trigger keywords so Claude knows when to load this skill.

**Description Format:**
```yaml
description: [What it does]. Use when [action verbs] [specific things], [related tasks], or when user mentions [keywords], [terms], [phrases].
```

**Frontmatter requirements:**
- name: skill-name (capability, not "agent" or "skill that does X")
- description: **MUST include "Use when..." with specific trigger keywords**
- allowed-tools: List of tools skill can use (Read, Bash, Write, etc.)

**Body requirements:**
- Clear examples of good/bad descriptions (auto-loaded from template)
- Step-by-step instructions for how skill provides resources
- List of available scripts with their purposes
- Documentation of templates and their usage
- Success criteria

**Example Good Descriptions:**
- "Validate MCP servers with auto-fix. Use when building MCP servers, validating FastMCP code, or when user mentions MCP validation, server structure."
- "Generate React components with TypeScript. Use when creating components, building UI, scaffolding React, or when user mentions React, components, TypeScript."
- "Detect project framework and structure. Use when initializing projects, analyzing codebases, or when user mentions framework detection, stack analysis."

**Example Bad Descriptions (won't trigger):**
- "Helps with development" ❌ Too vague
- "Skill for files" ❌ No triggers
- "Use when needed" ❌ Not specific

## Step 9: Verify Structure

!{bash tree plugins/PLUGIN_NAME/skills/SKILL_NAME}

## Step 10: Display Summary

**Skill Created:** SKILL_NAME
**Location:** plugins/PLUGIN_NAME/skills/SKILL_NAME
**Plugin:** PLUGIN_NAME

**Structure:**
- SKILL.md ✅ (auto-invocation instructions)
- templates/ ✅ (ready for custom templates)
- scripts/ ✅ (helper scripts)
  - template-script.sh (bash helper template)
  - template-helper.py (python helper template)
  - README.md (script guidelines)

**What's Included:**
- Skill is self-contained (templates + scripts + docs)
- Scripts are mechanical helpers (rename and customize)
- Templates ready for code/config patterns
- SKILL.md needs description with trigger keywords

**Next Steps:**
1. Update SKILL.md description with "Use when..." trigger keywords
2. Customize script templates (rename template-script.sh → detect-something.sh)
3. Add templates to templates/ directory (code patterns, configs)
4. Validate: /multiagent-build-system:skills-validate SKILL_NAME

**Skill Naming Guide:**
- Name describes CAPABILITY (not "agent" or "skill that does X")
- Examples: "MCP Development", "Code Generation", "Project Detection"
- NOT: "MCP Development Agent", "Code Generator Skill"
