---
description: "Phase 9: Marketing Website - Astro static site with AI content generation (optional companion site)"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Skill, AskUserQuestion
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Create companion marketing website for AI application.

Phase 1: Load State and Requirements
- Load .ai-stack-config.json
- Verify phase8Complete is true (or earlier phase if voice was skipped)
- Extract appName
- Create Phase 9 todo list
- AskUserQuestion: "Do you need a marketing website (landing page, blog, docs)?"
  - Options: Yes / No (not needed for most apps)
  - If "No": Skip to Phase 7 (Save State), mark marketingSiteEnabled: false

Phase 2: Website Type Selection
- AskUserQuestion (if user selected Yes):
  - "What type of website do you need?"
  - Options:
    - Marketing site (landing page, features, pricing)
    - Blog (content marketing)
    - Documentation site
    - All of the above

Phase 3: Website Initialization
- Execute immediately: !{slashcommand /website-builder:init "$APP_NAME-website"}
- Creates Astro project in separate directory
- After completion, verify: !{bash test -d "$APP_NAME-website" && echo "✅" || echo "❌"}

Phase 4: Core Pages (if Marketing site selected)
- Execute immediately: !{slashcommand /website-builder:add-page home}
- After completion, execute immediately: !{slashcommand /website-builder:add-page features}
- After completion, execute immediately: !{slashcommand /website-builder:add-page pricing}
- After completion, execute immediately: !{slashcommand /website-builder:add-page contact}

Phase 5: Blog Setup (if Blog selected)
- Execute immediately: !{slashcommand /website-builder:add-blog}
- After completion, verify: Blog functionality added

Phase 6: AI Content Generation (Optional)
- AskUserQuestion: "Do you want AI-powered content and image generation?"
- If Yes:
  - Execute immediately: !{slashcommand /website-builder:integrate-content-generation}
  - After completion, execute immediately: !{slashcommand /website-builder:generate-content}
  - Uses Google Imagen for images, AI for content

Phase 7: Supabase CMS (Optional)
- AskUserQuestion: "Do you want a Supabase CMS for content management?"
- If Yes:
  - Execute immediately: !{slashcommand /website-builder:integrate-supabase-cms}
  - Uses existing Supabase project from Phase 1

Phase 8: SEO Optimization
- Execute immediately: !{slashcommand /website-builder:optimize-seo}
- After completion, verify: SEO metadata configured

Phase 9: Deployment
- Execute immediately: !{slashcommand /website-builder:deploy}
- Deploys to Vercel/Netlify/Cloudflare Pages
- After completion, capture website URL

Phase 10: Save State
- Update .ai-stack-config.json:
  !{bash jq '.phase = 9 | .phase9Complete = true | .marketingSiteEnabled = true | .marketingSiteUrl = "'$WEBSITE_URL'" | .timestamp = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > tmp && mv tmp .ai-stack-config.json}
- Mark all todos complete
- Display: "✅ Phase 9 Complete - Marketing website deployed"

## Usage

Called by /ai-tech-stack-1:build-full-stack as Phase 9

## What Phase 9 Creates

**Marketing Website:**
- Astro static site (fast, SEO-optimized)
- Landing pages (home, features, pricing, contact)
- Blog with MDX support (optional)
- Documentation pages (optional)
- AI-generated content and images (optional)
- Supabase CMS for content management (optional)
- SEO optimization
- Deployed to CDN/Edge network

**Separate from AI App:**
- Lives in `$APP_NAME-website/` directory
- Separate deployment (Vercel/Netlify/Cloudflare)
- Can link to AI app backend
- Shares Supabase database (optional)

**Total Time:** ~15-20 minutes
