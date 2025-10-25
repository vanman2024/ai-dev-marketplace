---
allowed-tools: SlashCommand(*), AskUserQuestion(*), Bash(*), Write(*), WebFetch(*), WebSearch(*), Read(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
description: Universal plugin builder - creates domain-specific plugins (SDK, Framework, Custom) with actual execution
argument-hint: <plugin-name>
---

**Arguments**: $ARGUMENTS

## Overview

Creates domain-specific plugins (SDK plugins, Framework plugins, Custom plugins) using progressive context loading and proper tool execution.

**Key Difference from Lifecycle Builder:**
- Domain plugins = SDK/Framework/Custom specific
- Lifecycle plugins = Development phase specific (01-core, 02-planning, etc.)
- This builder is for domain plugins only

## Step 1: Detect Location

Use Bash tool to check current directory (pwd and ls -la | grep plugins).

Expected: ai-dev-marketplace directory. If not in correct location, tell user to cd there first.

## Step 2: Determine Plugin Type

Use AskUserQuestion tool:

What type of plugin are you building?
- SDK Plugin (e.g., Claude Agent SDK, Vercel AI SDK)
- Framework Plugin (e.g., Next.js, FastAPI)
- Custom Plugin (domain-specific tooling)

Store answer for later phases.

## Step 3: Gather Plugin Details

**For ALL plugins:**
- Plugin Name (default: $ARGUMENTS)
- Description
- Version (default: 1.0.0)

**For SDK/Framework plugins:**
- Documentation Source (URL, Context7 package name)
- Languages Supported (TypeScript, Python, JavaScript)
- Key Features to support

**For Custom plugins:**
- Domain area (e.g., testing, deployment, analytics)
- Primary use cases

## Step 4: Fetch Documentation (SDK/Framework only)

**If URL provided:**
Use WebFetch tool to get:
- Overview/Introduction
- Getting Started guide
- API Reference

**If Context7 package name provided:**
1. Use mcp__context7__resolve-library-id to get library ID
2. Use mcp__context7__get-library-docs to fetch documentation

**For Custom plugins:**
Skip documentation fetching, rely on user requirements.

## Step 5: Create Plugin Scaffold

**CRITICAL: ALL plugins get the SAME structure regardless of type!**

Load proper plugin structure reference:
@/home/gotime2022/Projects/ai-dev-marketplace/plugins/domain-plugin-builder/docs/03-claude-code-plugins.md

**Create directory structure using Bash:**
Use mkdir -p to create: .claude-plugin/, commands/, agents/, skills/, hooks/, scripts/, docs/

**Create plugin.json using Write tool:**
Location: .claude-plugin/plugin.json
Include: name, version (from Step 3), description, author, license (MIT), keywords, homepage, repository

**Create ALL required root files using Write tool:**
1. README.md - Plugin overview, commands, agents, usage
2. LICENSE - MIT License
3. CHANGELOG.md - Initial version entry
4. .gitignore - Standard ignores
5. .mcp.json - MCP servers object (initially empty)

**Every plugin MUST have:**
- .claude-plugin/plugin.json (manifest)
- commands/ (at least 1 command)
- agents/ (at least 1 agent)
- skills/ (optional)
- hooks/ (optional)
- scripts/ (helper scripts)
- docs/ (documentation)
- All 5 root files above

## Step 6: Validate Initial Structure

Use Bash tool to run: validate-plugin.sh plugins/$ARGUMENTS

This verifies directory structure and required files exist.

## Step 7: Create Commands

**CRITICAL: Use the SlashCommand tool to invoke the command builder!**

Use SlashCommand tool to invoke: `/domain-plugin-builder:slash-commands-create <plugin-name> <command-name> "<description>"`

**For SDK/Framework plugins:**
- Create main command like: `new-$ARGUMENTS-app`
- Description should explain it creates and sets up projects with the SDK/Framework

**For Custom plugins:**
- Create workflow command like: `$ARGUMENTS-workflow` or main feature command

**Example invocations:**
- `/domain-plugin-builder:slash-commands-create vercel-ai-sdk new-ai-app "Create and setup a new Vercel AI SDK application"`
- `/domain-plugin-builder:slash-commands-create nextjs-dev new-next-app "Create and setup a new Next.js application"`

The slash-commands-create command will handle pattern selection, templates, and proper structure automatically.

## Step 8: Create Agents

**CRITICAL: Use the SlashCommand tool to invoke the agent builder!**

Use SlashCommand tool to invoke: `/domain-plugin-builder:agents-create <agent-name> "<description>" "<tools>"`

**For SDK/Framework plugins:**
Create verifier agents for each supported language:

**Example invocations:**
- `/domain-plugin-builder:agents-create vercel-ai-verifier-ts "Verifier agent for TypeScript Vercel AI SDK applications" "Bash, Read, Write, WebFetch"`
- `/domain-plugin-builder:agents-create vercel-ai-verifier-js "Verifier agent for JavaScript Vercel AI SDK applications" "Bash, Read, Write, WebFetch"`
- `/domain-plugin-builder:agents-create vercel-ai-verifier-py "Verifier agent for Python Vercel AI SDK applications" "Bash, Read, Write, WebFetch"`

**For Custom plugins:**
Ask what agents are needed, then invoke agents-create for each one.

The agents-create command will handle proper frontmatter, tool configuration, and agent structure automatically.

## Step 9: Create Skills

**Skills = Mechanical helpers (scripts, formatters, validators)**

**Our advantage over Anthropic:** We have proper skills structure with actual functional scripts!

Use AskUserQuestion: What skills does this plugin need?

Examples:
- Code formatters (prettier, black, gofmt)
- Validators (lint, type-check)
- Generators (boilerplate, config files)
- Analyzers (dependency checking, metrics)

For each skill, use Write tool to create:
1. skills/<skill-name>/SKILL.md - Skill description with "Use when..." triggers
2. skills/<skill-name>/scripts/ - ACTUAL FUNCTIONAL SCRIPTS (.sh, .py files)
3. skills/<skill-name>/templates/ - Templates if applicable
4. skills/<skill-name>/scripts/README.md - Script documentation

**CRITICAL:**
- Create REAL working scripts, not placeholders!
- Scripts should be executable (chmod +x for .sh files)
- Skills provide mechanical helpers that commands can invoke

## Step 10: Generate Documentation

Use Write tool to create comprehensive README.md with:
- Plugin overview
- Installation instructions
- Commands documentation with examples
- Agents documentation
- Skills documentation (if any)
- Usage examples
- Documentation sources (URLs used in Step 4)

## Step 11: Run All Validation Scripts

Use Bash tool to run validation scripts for all components:

**Validate commands:** For each .md file in commands/, run validate-command.sh
**Validate agents:** For each .md file in agents/, run validate-agent.sh
**Validate skills:** For each directory in skills/, run validate-skill.sh
**Validate plugin:** Run validate-plugin.sh on plugin directory
**Scan hardcoded paths:** Run scan-hardcoded-paths.sh if available

All validation scripts must pass before considering plugin complete.

## Step 12: Display Summary

Show completion summary with:
- Plugin name and type
- Location
- Components created (commands, agents, skills)
- Validation status (all checks passed)
- Next steps for testing

## Important Notes

- **Domain plugins are NOT lifecycle plugins** - they're SDK/Framework/Custom specific
- **Always use Bash() tool calls** - never `!{bash ...}` markup
- **All validation scripts MUST execute** and pass
- **Create functional scripts** in skills/ directories
- **Root files required**: README.md, LICENSE, CHANGELOG.md, .mcp.json

## Usage Examples

SDK Plugin: /domain-plugin-builder:plugin-create vercel-ai-dev
Framework Plugin: /domain-plugin-builder:plugin-create nextjs-dev
Custom Plugin: /domain-plugin-builder:plugin-create custom-analytics
