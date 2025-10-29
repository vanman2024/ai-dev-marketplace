---
description: Deploy complete Astro website with all integrations automatically - analyzes project, orchestrates all setup commands
argument-hint: [project-name]
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), TodoWrite(*), SlashCommand(*), mcp__context7
---

**Arguments**: $ARGUMENTS

# Marketing Site Deployment Orchestrator

Goal: Analyze project context, then systematically deploy complete Astro marketing website with all integrations, running commands in optimal order without manual intervention.

NOTE: This is for STATIC MARKETING SITES (blogs, landing pages, documentation). For full-stack AI APPLICATIONS, use /ai-tech-stack-1:build-full-stack instead.

## Core Principles

1. **One Command Deployment**: User runs `/website-builder:deploy-marketing-site` and everything happens automatically
2. **Context-Aware**: Detect existing project vs new project
3. **Parallel When Possible**: Run independent steps concurrently
4. **Sequential When Required**: Respect dependencies (init before integrate)
5. **Comprehensive**: Setup, content, CMS, AI, SEO, deployment - everything

## Deployment Flow

### Phase 1: Discovery & Analysis (5 minutes)

**Understand what we're deploying to:**

Create comprehensive todo list with TodoWrite:
- Analyze project context
- Determine deployment strategy
- Initialize project (if needed)
- Integrate Supabase CMS (if needed)
- Setup AI content generation (if needed)
- Create initial content structure
- Optimize for SEO
- Configure deployment
- Validate everything

**Detect project state:**
- Read package.json (if exists)
- Read astro.config.mjs (if exists)
- Check if Astro project exists
- Check if Supabase is configured
- Check if content-image-generation MCP is available
- Identify what's already setup vs what needs setup

**Determine requirements through intelligent questioning:**

If project doesn't exist, ask:
- Use AskUserQuestion:
  - Question: "What type of Astro website do you want to build?"
    - Header: "Site Type"
    - Options:
      - "Marketing Site" - Static pages optimized for conversion
      - "Blog" - Content-focused with posts and RSS
      - "Documentation" - Technical docs with search
      - "Landing Page" - Single high-converting page
  - Question: "What integrations do you need?"
    - Header: "Integrations"
    - MultiSelect: true
    - Options:
      - "Supabase CMS" - Database-backed content management
      - "AI Content" - Generate content with Claude/Gemini
      - "AI Images" - Generate images with Imagen
      - "React Components" - Interactive UI components
  - Question: "What's your deployment target?"
    - Header: "Deployment"
    - Options:
      - "Vercel" - Deploy to Vercel
      - "Netlify" - Deploy to Netlify
      - "Cloudflare" - Deploy to Cloudflare Pages
      - "Not yet" - Just setup locally for now

**Parse project name from $ARGUMENTS** or use default "my-astro-site"

**Document deployment plan:**
- Write deployment-plan.md with:
  - Project type and requirements
  - What will be installed
  - What commands will run
  - Estimated timeline
  - What user needs to provide (API keys, etc.)

### Phase 2: Project Initialization (10 minutes)

**If project doesn't exist, initialize it:**

SlashCommand: `/website-builder:init $PROJECT_NAME`

This runs the init command which:
- Executes init-project.sh script
- Creates Astro project with TypeScript
- Installs integrations (React, MDX, Tailwind, Sitemap)
- Installs dependencies (Supabase, Zod, date-fns)
- Creates directory structure
- Sets up environment files

**Wait for init to complete** before proceeding.

Mark todo as completed, move to next phase.

### Phase 3: Parallel Integrations (15 minutes)

**Run integrations in parallel when possible:**

These can run simultaneously as they're independent:

1. **Supabase CMS Integration** (if requested)
   - SlashCommand: `/website-builder:integrate-supabase-cms`
   - Sets up database schema
   - Configures RLS policies
   - Creates CMS tables

2. **Content Generation Setup** (if requested)
   - SlashCommand: `/website-builder:integrate-content-generation`
   - Configures content-image-generation MCP
   - Tests AI connectivity
   - Sets up generation workflows

**Run both commands in parallel:**
```
Use Task tool with multiple commands in single message to run concurrently
```

**Wait for both to complete** before proceeding.

Mark todos as completed, move to next phase.

### Phase 4: Content Structure Creation (20 minutes)

**Create initial content based on site type:**

Based on site type selected in Phase 1:

**If Blog:**
- SlashCommand: `/website-builder:add-blog`
  - Creates blog content collection
  - Adds RSS feed
  - Creates blog listing page
  - Generates sample posts

**If Marketing Site or Landing Page:**
- SlashCommand: `/website-builder:add-page home`
- SlashCommand: `/website-builder:add-page about`
- SlashCommand: `/website-builder:add-page contact`

**If Documentation:**
- SlashCommand: `/website-builder:add-page getting-started`
- Create docs content collection
- Setup search functionality

**Run page creation commands sequentially** (they modify same files).

Mark todos as completed, move to next phase.

### Phase 5: AI Content Generation (10 minutes, optional)

**If AI content was requested, generate initial content:**

SlashCommand: `/website-builder:generate-content`
- Generates hero copy
- Creates initial blog posts (if blog)
- Writes page content
- Optimizes for SEO

SlashCommand: `/website-builder:generate-images`
- Generates hero images
- Creates blog headers (if blog)
- Generates OG images

**Run both commands in parallel** (independent operations).

Mark todos as completed, move to next phase.

### Phase 6: SEO & Performance Optimization (5 minutes)

**Optimize for search engines and performance:**

SlashCommand: `/website-builder:optimize-seo`
- Generates sitemap
- Optimizes meta tags
- Creates robots.txt
- Adds structured data (JSON-LD)
- Optimizes images
- Configures prefetching

Mark todo as completed, move to next phase.

### Phase 7: Deployment Configuration (10 minutes)

**Setup deployment target:**

SlashCommand: `/website-builder:deploy`

This will:
- Configure deployment for selected platform (Vercel/Netlify/Cloudflare)
- Create deployment configuration files
- Test build process
- Provide deployment instructions

Mark todo as completed, move to next phase.

### Phase 8: Final Validation (5 minutes)

**Verify everything is working:**

Run comprehensive checks:
1. Bash: `npm run check` (Astro validation)
2. Bash: `npm run build` (build test)
3. Check all required files exist
4. Verify environment variables documented
5. Test dev server starts

**If any validation fails:**
- Document issues in validation-report.md
- Provide fix instructions
- DO NOT mark as complete

### Phase 9: Completion Summary

**Mark all todos as completed.**

**Generate deployment summary:**

Create DEPLOYMENT-SUMMARY.md with:
```markdown
# Astro Website Deployment Complete

## Project Details
- Name: $PROJECT_NAME
- Type: [blog/marketing/docs/landing]
- Integrations: [list all installed]

## What Was Created
- ✅ Astro project with TypeScript
- ✅ React + MDX + Tailwind integrations
- ✅ [Supabase CMS if enabled]
- ✅ [AI content generation if enabled]
- ✅ Content structure ([blog/pages])
- ✅ SEO optimization
- ✅ Deployment configuration

## Environment Variables Needed
Review .env.example and configure:
- PUBLIC_SUPABASE_URL
- PUBLIC_SUPABASE_ANON_KEY
- GOOGLE_API_KEY (for AI content)
- ANTHROPIC_API_KEY (for AI content)

## Next Steps
1. Update .env with your API keys
2. Run `npm run dev` to start development
3. Run `npm run build` to build for production
4. Deploy using: [deployment instructions]

## Project Structure
[Show directory tree]

## Commands Available
- npm run dev - Start dev server
- npm run build - Build for production
- npm run preview - Preview production build
- /website-builder:add-page - Add new page
- /website-builder:generate-content - Generate AI content
- /website-builder:generate-images - Generate AI images

## Support
- Documentation: /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/website-builder/
- Astro docs: https://docs.astro.build/
```

**Display summary to user.**

## Error Handling

**If any phase fails:**
1. Mark current todo as failed with error details
2. Stop execution (don't proceed to next phase)
3. Provide troubleshooting guidance
4. Offer to retry the failed phase
5. Create error-report.md with full details

**Common failure scenarios:**
- Node.js version too old → Guide to upgrade
- npm install fails → Check network, clear cache
- MCP server not configured → Provide MCP setup guide
- API keys missing → Remind to configure .env
- Build fails → Run troubleshooting agent

## Timing Estimates

**Total deployment time: ~80 minutes**
- Phase 1 (Discovery): 5 min
- Phase 2 (Init): 10 min
- Phase 3 (Integrations): 15 min
- Phase 4 (Content): 20 min
- Phase 5 (AI Generation): 10 min (optional)
- Phase 6 (SEO): 5 min
- Phase 7 (Deployment): 10 min
- Phase 8 (Validation): 5 min

**User can walk away** - everything runs automatically!

## Parallel Execution Strategy

**Commands that CAN run in parallel:**
- Supabase integration + Content generation setup
- Content generation + Image generation
- Multiple page creation (different pages)

**Commands that MUST run sequentially:**
- Init BEFORE any integrations
- Integrations BEFORE content creation
- Content creation BEFORE AI generation
- Everything BEFORE validation

**Use Task tool for parallelization:**
```
When running parallel commands, use single message with multiple Task invocations
```

## Output Standards

- All phases logged to deployment.log
- Progress updates via TodoWrite
- Clear error messages if anything fails
- Comprehensive summary at the end
- User can resume if interrupted

## Self-Verification Checklist

Before marking deployment as complete:
- ✅ Project initialized successfully
- ✅ All requested integrations configured
- ✅ Content structure created
- ✅ AI content generated (if requested)
- ✅ SEO optimized
- ✅ Deployment configured
- ✅ Build passes validation
- ✅ Dev server starts
- ✅ .env.example documented
- ✅ DEPLOYMENT-SUMMARY.md created

## Usage Examples

**Simple blog deployment:**
```
/website-builder:deploy-full-stack my-blog
```

**Marketing site with AI content:**
```
/website-builder:deploy-full-stack company-website
# Answer questions:
# - Type: Marketing Site
# - Integrations: AI Content, AI Images
# - Deployment: Vercel
```

**Existing project enhancement:**
```
cd existing-astro-project
/website-builder:deploy-full-stack
# Detects existing project, offers to add integrations
```

This command provides the **one-click deployment** you envisioned - analyze project, run all commands in optimal order, complete automation!
