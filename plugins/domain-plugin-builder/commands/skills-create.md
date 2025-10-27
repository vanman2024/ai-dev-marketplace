---
description: Create new skill by orchestrating skills-builder agent to handle complex skill design and implementation
argument-hint: <skill-name> "<description>"
allowed-tools: Task(*)
---

**Arguments**: $ARGUMENTS

Goal: Create a properly structured skill with scripts, templates, and integration understanding by orchestrating the skills-builder agent

Phase 1: Parse Arguments
Goal: Extract skill specifications

Actions:
- Parse $ARGUMENTS to extract skill name and description
- Validate arguments format (name and description required)

Phase 2: Invoke Skills Builder Agent
Goal: Orchestrate complex skill creation through specialized agent

Actions:
- Use Task tool to launch skills-builder agent with subagent_type="domain-plugin-builder:skills-builder"
- Pass skill requirements: name, description, and any additional context
- Agent will handle:
  - Loading framework documentation
  - Determining plugin location
  - Designing skill structure (SKILL.md, scripts/, templates/)
  - Creating helper scripts and templates
  - Implementing validation
  - Verifying framework compliance

Phase 3: Summary
Goal: Report results

Actions:
- Display skill name, location, validation status
- Show next steps for using the skill in agents
