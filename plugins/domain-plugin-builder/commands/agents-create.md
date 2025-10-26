---
allowed-tools: Read(*), Write(*), Bash(*), AskUserQuestion(*)
description: Create new agent using templates - references fullstack-web-builder as gold standard
argument-hint: <agent-name> "<description>" "<tools>"
---

**Arguments**: $ARGUMENTS

## Step 1: Parse Arguments

Extract components from arguments:

!{bash echo "$ARGUMENTS" | awk '{print "Name:", $1}'}

## Step 2: Determine Agent Complexity

AskUserQuestion: Is this a complex agent with multiple competencies or a simple agent?

- Complex: Use comprehensive template (like fullstack-web-builder)
- Simple: Use basic agent pattern

## Step 3: Load Templates (CRITICAL - Read These Files)

**REQUIRED - Load the master agent template:**
@plugins/domain-plugin-builder/skills/build-assistant/templates/agents/agent-with-phased-webfetch.md

This template includes phased WebFetch calls structure:
- Discovery Phase: Core documentation
- Analysis Phase: Feature-specific docs
- Planning Phase: Advanced documentation
- Implementation Phase: Reference docs
- Verification Phase: Validation

**GOLD STANDARD Reference (study this pattern):**
@plugins/vercel-ai-sdk/agents/vercel-ai-ui-agent.md
@plugins/vercel-ai-sdk/agents/vercel-ai-data-agent.md

## Step 4: Determine Plugin Location

AskUserQuestion: Which plugin should this agent belong to?

List available plugins or specify new plugin name.

## Step 5: Create Agent File

Based on template and user inputs, create agent file:

Location: plugins/PLUGIN_NAME/agents/AGENT_NAME.md

**Frontmatter requirements:**
- name: agent-name
- description: Use pattern from fullstack-web-builder (trigger context + examples)
- model: inherit
- color: yellow

**Body requirements (for complex agents):**
- Role description and primary responsibility
- Core Competencies sections (3-5 areas)
- Project Approach with numbered phases (5-6 phases)
- Decision-Making Framework
- Communication Style
- Output Standards
- Self-Verification Checklist
- Collaboration guidelines

**Body requirements (for simple agents):**
- Clear role description
- Numbered process steps
- Success criteria

## Step 6: Validate Created File

Check that file was created successfully:

!{bash test -f "plugins/PLUGIN_NAME/agents/AGENT_NAME.md" && echo "✅ Agent created" || echo "❌ Agent creation failed"}

## Step 7: Display Summary

**Agent Created:** AGENT_NAME
**Location:** plugins/PLUGIN_NAME/agents/AGENT_NAME.md
**Template Used:** comprehensive | simple
**Pattern:** Based on fullstack-web-builder.md
