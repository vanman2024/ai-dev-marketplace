---
description: Create new skill(s) using skills-builder agent - analyzes plugin structure or accepts direct specifications (supports parallel creation)
argument-hint: [--analyze <plugin-name>] | [<skill-name> "<description>"] | [<skill-1> "<desc-1>" <skill-2> "<desc-2>" ...]
allowed-tools: Task
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
- Check if $ARGUMENTS starts with --analyze:
  - If yes: Extract plugin name, set mode to "analyze"
  - If no: Parse arguments to detect multiple skill requests
    - Single skill: <skill-name> "<description>"
    - Multiple skills: <skill-1> "<desc-1>" <skill-2> "<desc-2>" ... (creates in parallel)

Phase 3: Launch Skills Builder Agent(s)

Actions:

**For Single Skill:**
Launch the skills-builder agent to create the skill.

Provide the agent with:
- Full arguments: $ARGUMENTS
- Architectural context from Phase 1 (what agents/commands/skills/hooks/MCP are and when to use them)
- The agent will:
  1. Read detailed skills implementation documentation (WebFetch):
     - https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart
     - https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices
     - https://docs.claude.com/en/docs/claude-code/skills
     - https://docs.claude.com/en/docs/claude-code/slash-commands#skills-vs-slash-commands
     - https://github.com/anthropics/claude-cookbooks/tree/main/skills
     - https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
  2. Load local templates and examples
  3. Create skill following best practices

**For Multiple Skills (3 or more skills):**
Launch multiple skills-builder agents IN PARALLEL (all at once):
- Launch skills-builder agent for skill 1 with: <skill-1> "<desc-1>"
- Launch skills-builder agent for skill 2 with: <skill-2> "<desc-2>"
- Launch skills-builder agent for skill 3 with: <skill-3> "<desc-3>"
- (Continue for all requested skills)
- Each agent receives the architectural context from Phase 1
- Each agent will independently fetch detailed skills documentation (listed above)

Wait for ALL agents to complete before proceeding.

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
