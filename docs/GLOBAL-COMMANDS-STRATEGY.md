# Global Commands Strategy

## Problem: Project-Local Commands Don't Scale

**Current issue:**
- Slash commands live in `.claude/commands/` within each plugin directory
- Commands only work when CD'd into that specific plugin directory
- Must manually copy commands to each new project
- No way to orchestrate multi-command workflows across projects

**Example of the pain:**
```bash
cd new-project/
# Want to run: /website-builder:init
# Error: Command not found! (not in this project)

# Have to manually:
1. Copy .claude/commands/ to new-project/.claude/
2. Update settings.json
3. Restart Claude Code
4. THEN run command
```

## Solution: Global Commands in ~/.claude/settings.json

**Commands registered in global settings are available everywhere:**

### Current Global Registration (from settings.json)

```json
{
  "permissions": {
    "allow": [
      "SlashCommand(/website-builder:*)",
      "SlashCommand(/website-builder:init)",
      "SlashCommand(/website-builder:add-page)",
      "SlashCommand(/website-builder:add-blog)",
      "SlashCommand(/website-builder:integrate-supabase-cms)",
      "SlashCommand(/website-builder:generate-content)",
      "SlashCommand(/website-builder:deploy)",
      // ... etc
    ]
  },
  "enabledPlugins": {
    "website-builder@ai-dev-marketplace": true
  }
}
```

**This means:**
- ✅ Commands work from ANY directory
- ✅ No need to copy command files to each project
- ✅ One central registry
- ✅ Can orchestrate across project boundaries

## Command Discovery Flow

When you run `/website-builder:init`:

1. **Claude Code checks global settings.json**
   - Is `SlashCommand(/website-builder:init)` in allow list? ✅
   - Is `website-builder@ai-dev-marketplace` plugin enabled? ✅

2. **Claude Code locates command file**
   - Looks in: `~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/website-builder/commands/init.md`
   - Loads command definition

3. **Claude Code executes command**
   - Expands command prompt
   - Runs in current working directory context
   - Has access to all globally allowed tools

## Orchestration: Master Commands

**Master commands coordinate multiple sub-commands:**

### Example: `/website-builder:deploy-full-stack`

```markdown
Phase 1: Discovery
- Analyze current directory
- Determine what's needed

Phase 2: Init (if needed)
- SlashCommand: /website-builder:init $PROJECT_NAME
- Waits for completion

Phase 3: Parallel Integrations
- SlashCommand: /website-builder:integrate-supabase-cms (parallel)
- SlashCommand: /website-builder:integrate-content-generation (parallel)
- Waits for both

Phase 4: Content Creation
- SlashCommand: /website-builder:add-blog (sequential)
- SlashCommand: /website-builder:add-page home (sequential)

Phase 5: AI Generation
- SlashCommand: /website-builder:generate-content (parallel)
- SlashCommand: /website-builder:generate-images (parallel)

Phase 6: Optimization & Deployment
- SlashCommand: /website-builder:optimize-seo (sequential)
- SlashCommand: /website-builder:deploy (sequential)
```

**Benefits:**
- 🚀 **One command deploys entire stack**
- ⚡ **Parallel execution where possible**
- 📋 **Sequential execution where required**
- 🎯 **Context-aware** (detects existing vs new project)
- ✅ **Comprehensive** (handles everything)

## Execution Strategies

### Sequential Execution

When commands have dependencies:

```markdown
1. Run command A
2. Wait for A to complete
3. Run command B
4. Wait for B to complete
```

**Implementation:**
```markdown
SlashCommand: /website-builder:init my-project
# Wait for init to finish before proceeding

SlashCommand: /website-builder:integrate-supabase-cms
# Must wait for Supabase before continuing
```

### Parallel Execution

When commands are independent:

```markdown
1. Launch command A (don't wait)
2. Launch command B (don't wait)
3. Wait for both A and B to complete
```

**Implementation using Task tool:**
```markdown
Use Task tool to launch multiple agents in parallel:
- Task(website-setup agent): Integrate Supabase
- Task(website-ai-generator agent): Setup AI content gen

Both run concurrently, then sync before next phase.
```

## Command Categories

### 1. Initialization Commands
**Must run first, blocks everything else:**
- `/website-builder:init`
- `/nextjs-frontend:init`
- `/fastmcp:new-server`

### 2. Integration Commands
**Can often run in parallel:**
- `/website-builder:integrate-supabase-cms`
- `/website-builder:integrate-content-generation`
- `/nextjs-frontend:integrate-supabase`
- `/nextjs-frontend:integrate-ai-sdk`

### 3. Content Commands
**May need to run sequentially (file conflicts):**
- `/website-builder:add-page`
- `/website-builder:add-blog`
- `/website-builder:add-component`

### 4. Generation Commands
**Can run in parallel:**
- `/website-builder:generate-content`
- `/website-builder:generate-images`

### 5. Optimization Commands
**Run near the end:**
- `/website-builder:optimize-seo`

### 6. Deployment Commands
**Must run last:**
- `/website-builder:deploy`
- `/deployment:deploy`

### 7. Orchestration Commands
**Master commands that run others:**
- `/website-builder:deploy-full-stack` ⭐ NEW
- `/nextjs-frontend:build-full-app`
- `/supabase:init-ai-app`

## Parallelization Rules

**Safe to parallelize:**
- ✅ Different plugins (website-builder + nextjs-frontend)
- ✅ Read-only operations (generate content + generate images)
- ✅ Independent integrations (Supabase + AI)
- ✅ Non-conflicting file writes (different pages)

**NOT safe to parallelize:**
- ❌ Same file edits (two commands editing astro.config.mjs)
- ❌ Dependent operations (init → integrate)
- ❌ Database migrations (sequential schema changes)
- ❌ Build processes (npm install conflicts)

## Global Command Registration Process

### Step 1: Create Command File

```bash
~/.claude/plugins/marketplaces/ai-dev-marketplace/
  plugins/
    website-builder/
      commands/
        deploy-full-stack.md  # New command
```

### Step 2: Register in Global Settings

```bash
~/.claude/settings.json
```

```json
{
  "permissions": {
    "allow": [
      "SlashCommand(/website-builder:deploy-full-stack)"
    ]
  }
}
```

### Step 3: Use from Anywhere

```bash
cd ~/Projects/new-website/
/website-builder:deploy-full-stack my-site
# Works! No local setup needed
```

## Best Practices

### 1. Design for Global Use
Commands should:
- Work from any directory
- Detect context (new vs existing project)
- Handle missing dependencies gracefully
- Provide clear error messages

### 2. Use Context Detection
```markdown
**Detect project state:**
- Read package.json (if exists)
- Check for astro.config.mjs
- Determine: new project or existing?
- Adjust workflow accordingly
```

### 3. Implement Idempotency
Commands should be safe to run multiple times:
- Check if already done before doing
- Skip completed steps
- Only install missing dependencies

### 4. Provide Progress Feedback
Use TodoWrite to show progress:
```markdown
- ✅ Project initialized
- ⏳ Installing integrations (2/3 complete)
- ⏳ Generating content...
- ⏸️  Deployment pending
```

### 5. Handle Errors Gracefully
```markdown
**If npm install fails:**
1. Log error to deployment.log
2. Provide troubleshooting steps
3. Ask user if they want to retry
4. Don't proceed to dependent steps
```

## Example Orchestration: Full-Stack AI Website

```bash
cd ~/Projects/
/website-builder:deploy-full-stack my-ai-blog
```

**What happens:**
1. ✅ Detects: new project needed
2. ⏳ Runs: `/website-builder:init my-ai-blog`
3. ⏳ Runs parallel:
   - `/website-builder:integrate-supabase-cms`
   - `/website-builder:integrate-content-generation`
4. ⏳ Creates content: `/website-builder:add-blog`
5. ⏳ Generates parallel:
   - `/website-builder:generate-content`
   - `/website-builder:generate-images`
6. ⏳ Optimizes: `/website-builder:optimize-seo`
7. ⏳ Deploys: `/website-builder:deploy`
8. ✅ **Done!** Complete AI blog in ~80 minutes

**User experience:**
- Run ONE command
- Answer a few questions
- Walk away
- Come back to fully deployed site

## Future Enhancements

### 1. Resume from Failure
```markdown
If Phase 3 fails:
- Save state to .deployment-state.json
- User can run: /website-builder:resume-deployment
- Skips completed phases, retries failed phase
```

### 2. Dry Run Mode
```markdown
/website-builder:deploy-full-stack --dry-run
- Shows what WOULD be done
- Estimates time
- Doesn't actually execute
```

### 3. Custom Workflows
```markdown
/website-builder:deploy-full-stack --workflow=minimal
# Only: init + blog + deploy

/website-builder:deploy-full-stack --workflow=ai-heavy
# All: init + integrations + AI generation + SEO + deploy
```

### 4. Progress Dashboard
Real-time UI showing:
- Current phase
- Commands running (parallel)
- Time elapsed / estimated remaining
- Logs streaming

## Migration Path

**Moving from project-local to global:**

1. ✅ Commands already in global settings.json
2. ⏳ Create orchestration commands (deploy-full-stack)
3. ⏳ Test from different directories
4. ⏳ Document usage patterns
5. ⏳ Create more master orchestrators

**Backward compatibility:**
- Keep command files in plugin directories (source of truth)
- Global settings just references them
- Works both ways (local OR global)

## Conclusion

Global commands + orchestration = **True automation**

**Before:**
```bash
cd project/
/init
# wait...
/integrate-supabase
# wait...
/add-blog
# wait...
/generate-content
# wait...
# ... 8 more manual steps
```

**After:**
```bash
cd project/
/deploy-full-stack
# Everything happens automatically!
```

This is the vision you described - **one command deployment** with intelligent orchestration!
