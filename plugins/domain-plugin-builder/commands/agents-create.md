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

Analyze description to determine if this is a complex or simple agent:
- Complex: Multi-step process, multiple competencies, needs phases (e.g., "build complete plugins", "full-stack", "end-to-end")
- Simple: Single focused task, straightforward process (e.g., "validate", "format", "analyze")

For this agent, determine complexity from description and proceed.

## Step 3: Load Templates

Use Read tool to load the agent template with phased WebFetch pattern:

!{read plugins/domain-plugin-builder/skills/build-assistant/templates/agents/agent-with-phased-webfetch.md}

Then use Read tool to load a gold standard example:

!{read plugins/vercel-ai-sdk/agents/vercel-ai-ui-agent.md}

**CRITICAL - ALL Agents MUST Include Phased WebFetch:**

Every agent you create must include a progressive documentation fetching strategy:

```markdown
## Implementation Process

1. **Fetch Documentation**:
   - WebFetch: https://example.com/overview
   - Review core concepts and architecture

2. **Analyze Feature Usage**:
   - If feature X found: WebFetch https://example.com/feature-x
   - If feature Y found: WebFetch https://example.com/feature-y

3. **Fetch Advanced Patterns**:
   - WebFetch: https://example.com/advanced
   - Compare implementation against best practices
```

This ensures agents have access to up-to-date, official documentation at execution time.

## Step 4: Determine Plugin Location

Parse plugin name from context:
- If invoked from /PLUGIN:command, use that plugin
- If PLUGIN_NAME appears in arguments, use that
- Otherwise, use current directory plugin
- Default: domain-plugin-builder

Store plugin name as PLUGIN_NAME for Step 5.

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
