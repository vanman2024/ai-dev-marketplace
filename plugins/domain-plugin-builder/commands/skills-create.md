---
description: Create new skill(s) using skills-builder agent - analyzes plugin structure or accepts direct specifications (supports parallel creation)
argument-hint: [--analyze <plugin-name>] | [<skill-name> "<description>"] | [<skill-1> "<desc-1>" <skill-2> "<desc-2>" ...]
allowed-tools: Task, Read, Bash
---

**Arguments**: $ARGUMENTS

Goal: Create properly structured skill(s) by launching the skills-builder agent

Phase 1: Discovery & Architecture Decision Framework
Goal: Load comprehensive component decision framework to understand WHEN to use skills vs commands vs agents vs hooks vs MCP

Actions:
- Load the complete component decision framework:
  @plugins/domain-plugin-builder/docs/frameworks/claude/component-decision-framework.md
- This provides critical understanding of:
  - 🚨 START WITH COMMANDS FIRST (not skills!)
  - Commands are the primitive (closest to prompts)
  - Skills are for MANAGING multiple related commands
  - The "One-Off vs Management" test
  - When NOT to create a skill
  - Real composition hierarchy (skills use commands, not vice versa)
  - Complete decision tree with real examples
  - Anti-patterns to avoid
- This architectural decision-making context will be passed to the skills-builder agent
- Agent will understand when the requested functionality should be a COMMAND instead of a skill

Phase 2: Parse Arguments & Determine Mode

Actions:

Use bash to parse $ARGUMENTS and count how many skills are being requested:

!{bash echo "$ARGUMENTS" | grep -oE '<[^>]+>' | wc -l}

Store the count. Then extract each skill specification:
- If count = 0 and --analyze present: Set mode to "analyze", extract plugin name
- If count = 1: Single skill mode - extract <skill-name> and "<description>"
- If count >= 2: Multiple skills mode - extract all <skill-N> "<desc-N>" pairs

Phase 3: Launch Skills Builder Agent(s)

Actions:

**For --analyze mode:**

Task(description="Analyze plugin for needed skills", subagent_type="domain-plugin-builder:skills-builder", prompt="You are the skills-builder agent. Analyze the plugin structure at plugins/$PLUGIN_NAME to determine what skills are needed.

Architectural context from component-decision-framework.md:
@plugins/domain-plugin-builder/docs/frameworks/claude/component-decision-framework.md

Tasks:
1. Read detailed skills documentation via WebFetch:
   - https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart
   - https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices
   - https://docs.claude.com/en/docs/claude-code/skills
   - https://docs.claude.com/en/docs/claude-code/slash-commands#skills-vs-slash-commands
   - https://github.com/anthropics/claude-cookbooks/tree/main/skills
   - https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
2. Analyze plugin commands and agents
3. Identify what reusable capabilities are needed
4. Report recommended skills to create

Plugin: plugins/$PLUGIN_NAME
Deliverable: List of recommended skills with descriptions")

**For Single Skill:**

Task(description="Create skill", subagent_type="domain-plugin-builder:skills-builder", prompt="You are the skills-builder agent. Create a complete skill with functional scripts, templates, and examples.

Skill name: $SKILL_NAME
Description: $DESCRIPTION

Architectural context from component-decision-framework.md:
@plugins/domain-plugin-builder/docs/frameworks/claude/component-decision-framework.md

Tasks:
1. Read detailed skills documentation via WebFetch:
   - https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart
   - https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices
   - https://docs.claude.com/en/docs/claude-code/skills
   - https://docs.claude.com/en/docs/claude-code/slash-commands#skills-vs-slash-commands
   - https://github.com/anthropics/claude-cookbooks/tree/main/skills
   - https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
2. Load local templates from plugins/domain-plugin-builder/skills/build-assistant/templates/skills/
3. Create complete skill structure:
   - SKILL.md with comprehensive documentation
   - scripts/ with FUNCTIONAL scripts (NOT placeholders)
   - templates/ with actual template files
   - examples/ with working examples
4. Validate the skill structure

Deliverable: Complete functional skill ready to use")

**For Multiple Skills:**

Launch multiple skills-builder agents IN PARALLEL (all at once) using multiple Task() calls in ONE response:

Task(description="Create skill 1", subagent_type="domain-plugin-builder:skills-builder", prompt="Create skill: $SKILL_1 - $DESC_1 [same prompt structure as single skill above]")

Task(description="Create skill 2", subagent_type="domain-plugin-builder:skills-builder", prompt="Create skill: $SKILL_2 - $DESC_2 [same prompt structure as single skill above]")

Task(description="Create skill 3", subagent_type="domain-plugin-builder:skills-builder", prompt="Create skill: $SKILL_3 - $DESC_3 [same prompt structure as single skill above]")

[Continue for all N skills requested]

Each Task() call happens in parallel. Parse $ARGUMENTS to determine how many Task() calls to make.

Wait for ALL agents to complete before proceeding to Phase 4.

Phase 4: Git Commit and Push

Actions:
- Add all created skill directories to git:
  !{bash git add plugins/*/skills/*}
- Commit with descriptive message:
  !{bash git commit -m "$(cat <<'EOF'
feat: Add skill(s) - SKILL_NAMES

Complete skill structure with scripts, templates, and examples.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"}
- Push to GitHub: !{bash git push origin master}

Phase 5: Summary

Actions:
- Display results from all agents (skill names, locations, validation status)
- Show git status (committed and pushed)
- Show next steps for using the skills
- If multiple skills created, list all successfully created skills
