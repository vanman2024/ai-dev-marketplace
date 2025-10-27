---
allowed-tools: Task(*), AskUserQuestion(*), Bash(*), Read(*)
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

Actions:
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
- Run validation on all components
- Fix any validation errors
- Provide final report with validation results

Context needed:
- Plugin type, description, requirements from Phase 2
- Plugin name: $ARGUMENTS
- Expected output: Complete validated plugin ready for production use

## Phase 4: Display Results

After agent completes, show summary:

**Plugin Created:** {plugin-name}
**Location:** plugins/{plugin-name}
**Type:** SDK | Framework | Custom

**Components:**
- Commands: X/X validated ✅
- Agents: Y/Y validated ✅
- Skills: Z/Z validated ✅

**Total Validation:** ALL PASSED (N/N) ✅

**Next Steps:**
1. Review the plugin: `cat plugins/{plugin-name}/README.md`
2. Test a command: `/{plugin-name}:new-app my-test-project`
3. Commit to git: `git add plugins/{plugin-name} && git commit -m "feat: Add {plugin-name} plugin"`

## Success Criteria

- ✅ Plugin directory structure created
- ✅ All commands created and validated
- ✅ All agents created and validated
- ✅ All skills created with complete structure
- ✅ Skills have functional scripts (not placeholders)
- ✅ README.md comprehensive
- ✅ All validations passing
- ✅ Plugin ready for production use
