---
allowed-tools: Read(*), Write(*), Bash(*)
description: Create new agent using templates - references fullstack-web-builder as gold standard
argument-hint: <agent-name> "<description>" "<tools>"
---

**Arguments**: $ARGUMENTS

Goal: Create a properly structured agent file following framework templates, ensuring it includes phased WebFetch for documentation and stays concise (under 300 lines).

Core Principles:
- Study templates before generating
- Keep agents concise using WebFetch (not embedding docs)
- Match complexity to task (simple vs complex)
- Validate line count and structure

Phase 1: Parse Arguments
Goal: Extract agent specifications

Actions:
- Parse $ARGUMENTS to extract agent name, description, tools
- Determine complexity: complex (multi-step) vs simple (focused task)

Phase 2: Load Templates
Goal: Study framework patterns

Actions:
- Load agent template:
  - @plugins/domain-plugin-builder/skills/build-assistant/templates/agents/agent-with-phased-webfetch.md
- Load gold standard:
  - @plugins/vercel-ai-sdk/agents/vercel-ai-ui-agent.md
- Study structure, WebFetch patterns, how to stay under 300 lines

Phase 3: Determine Location
Goal: Identify where to create file

Actions:
- Detect plugin from context (invocation path, arguments, or default to domain-plugin-builder)
- Store as PLUGIN_NAME

Phase 4: Create Agent
Goal: Generate agent file

Actions:
- Create: plugins/PLUGIN_NAME/agents/AGENT_NAME.md
- **Frontmatter**: name, description ("Use this agent to..."), model: inherit, color: yellow, tools (optional)
- **Body for complex**: Role, Core Competencies (3-5), Implementation Process (5-6 phases with WebFetch URLs), Decision Framework, Communication, Output Standards, Verification
- **Body for simple**: Role, Process steps (3-5), Success criteria
- **CRITICAL**: Include progressive WebFetch for docs

Phase 5: Validate
Goal: Ensure framework compliance

Actions:
- Check exists: !{bash test -f "plugins/PLUGIN_NAME/agents/AGENT_NAME.md" && echo "✅ Created" || echo "❌ Failed"}
- Validate: !{bash bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-agent.sh plugins/PLUGIN_NAME/agents/AGENT_NAME.md}
- Check lines: !{bash wc -l plugins/PLUGIN_NAME/agents/AGENT_NAME.md}

Phase 6: Summary
Goal: Report results

Actions:
- Display agent name, location, line count, validation status, template type
