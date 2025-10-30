---
allowed-tools: Task(*), AskUserQuestion(*), Bash(*), Read(*), Write(*), Edit(*), TodoWrite(*)
description: Universal plugin builder - creates complete domain-specific plugins (SDK, Framework, Custom) with all components from start to finish
argument-hint: <plugin-name>
---

**Arguments**: $ARGUMENTS

Goal: Build a complete, production-ready domain-specific plugin with ALL components: commands, agents, skills (with scripts/templates/examples), and full validation.

Core Principles:
- Build EVERYTHING by orchestrating slash commands sequentially
- Create functional scripts, not placeholders
- Validate all components
- Ensure production readiness

## Phase 1: Verify Location

Use Bash tool to check current directory:

!{bash pwd}

Expected: ai-dev-marketplace directory. If not in correct location, tell user to cd there first.

## Phase 2: Gather Requirements

Use AskUserQuestion to gather plugin details:

**Questions:**
1. What type of plugin are you building?
   - SDK Plugin (e.g., FastMCP, Claude Agent SDK, Vercel AI SDK)
   - Framework Plugin (e.g., Next.js, FastAPI, Django)
   - Custom Plugin (domain-specific tooling)

2. Plugin description (one sentence)?

3. For SDK/Framework plugins:
   - Documentation source (URL or Context7 package name)
   - Languages supported (Python, TypeScript, JavaScript)
   - Key features to support (comma-separated list)

4. For Custom plugins:
   - Domain area (testing, deployment, analytics, etc.)
   - Primary use cases

Store all answers for Phase 3.

## Phase 3: Build Complete Plugin

Orchestrate slash commands to create the entire plugin from start to finish:

### Step 1: Create Plugin Structure
- Create complete directory structure
- Build ALL commands: `/domain-plugin-builder:slash-commands-create` for each command
- Build ALL agents: `/domain-plugin-builder:agents-create` for each agent
- Build ALL skills: `/domain-plugin-builder:skills-create` for each skill
  - Skills-builder agent handles complexity of:
    - Functional scripts (NOT placeholders!)
    - scripts/README.md
    - templates/ with actual template files
    - examples/ with working examples
- Generate comprehensive README.md

### Step 2: Run Comprehensive Validation

Run the validation script:

!{bash plugins/domain-plugin-builder/skills/build-assistant/scripts/validate-plugin.sh plugins/$ARGUMENTS}

If validation fails, fix issues and re-run validation.

### Step 3: Update Marketplace Configuration

Register the plugin in marketplace.json:

!{bash plugins/domain-plugin-builder/skills/build-assistant/scripts/sync-marketplace.sh}

### Step 4: Git Commit

Stage and commit all plugin files:

!{bash git add plugins/$ARGUMENTS plugins/domain-plugin-builder/docs/sdks/$ARGUMENTS-documentation.md .claude-plugin/marketplace.json}

!{bash git commit -m "$(cat <<'EOF'
feat: Add $ARGUMENTS plugin

Complete plugin with commands, agents, and skills following domain-plugin-builder patterns.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"}

Context needed:
- Plugin type, description, requirements from Phase 2
- Plugin name: $ARGUMENTS
- Expected output: Complete validated plugin ready for production use

## Phase 4: Display Results

Count components and display comprehensive summary:

!{bash ls plugins/$ARGUMENTS/commands/ | wc -l}
!{bash ls plugins/$ARGUMENTS/agents/ | wc -l}
!{bash ls -d plugins/$ARGUMENTS/skills/*/ 2>/dev/null | wc -l}

Display formatted summary:

**Plugin Created:** $ARGUMENTS
**Location:** plugins/$ARGUMENTS
**Type:** SDK | Framework | Custom (from Phase 2 answers)

**Components:**
- Commands: X/X validated ✅ (use count from first bash command)
- Agents: Y/Y validated ✅ (use count from second bash command)
- Skills: Z/Z validated ✅ (use count from third bash command)

**Total Validation:** ALL PASSED ✅

**Git Status:**
- ✅ Committed to master branch
- Ready to push to origin

**Next Steps:**
1. Push to GitHub:
   `git push origin master`

2. Test the plugin:
   `/$ARGUMENTS:init` (or first command from plugin)

3. Install via marketplace:
   `/plugin install $ARGUMENTS@ai-dev-marketplace`

## Success Criteria

- ✅ Plugin directory structure created
- ✅ All commands created and validated
- ✅ All agents created and validated
- ✅ All skills created with complete structure
- ✅ Skills have functional scripts (not placeholders)
- ✅ README.md comprehensive
- ✅ All validations passing
- ✅ Plugin ready for production use
