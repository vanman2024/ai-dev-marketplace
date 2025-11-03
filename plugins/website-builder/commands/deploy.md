---
description: Deploy Astro website to Vercel with optimized build configuration and environment variables
argument-hint: none
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__context7, Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Deploy Astro website to Vercel with optimized build settings, environment variables, and production configuration

Core Principles:
- Use Vercel CLI for deployment
- Optimize build configuration for Astro
- Configure environment variables securely
- Validate before deploying

Phase 1: Discovery & Requirements
Goal: Understand deployment configuration

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - Deploy to production or preview?
  - Vercel project already exists?
  - Environment variables needed?
  - Custom domain configured?
  - Need to configure build settings?
- Load Vercel deployment docs via Context7
- Summarize requirements

Phase 2: Pre-Deployment Validation
Goal: Verify project is ready for deployment

Actions:

Launch the website-verifier agent to validate deployment readiness.

Provide the agent with:
- Project structure and configuration
- Validation checks:
  - Build succeeds locally
  - No build errors or warnings
  - Environment variables documented
  - SEO meta tags configured
  - Sitemap generated
  - All pages render correctly
- Expected output: Deployment readiness report with any blockers

Phase 3: Deployment Configuration
Goal: Configure Vercel deployment

Actions:

Launch the website-architect agent to configure deployment.

Provide the agent with:
- Deployment requirements from Phase 1
- Validation results from Phase 2
- Configuration to add:
  - vercel.json with build settings
  - .vercelignore for excluded files
  - Environment variable documentation
  - Build output directory configuration
  - Node.js version specification
- Expected output: Complete Vercel configuration files

Phase 4: Deploy
Goal: Execute deployment to Vercel

Actions:
- Check if Vercel CLI installed
- Install if needed: !{bash npm install -g vercel}
- Run deployment: !{bash vercel --prod} or !{bash vercel} for preview
- Capture deployment URL
- Update TodoWrite

Phase 5: Post-Deployment Validation
Goal: Verify deployment succeeded

Actions:
- Check deployment status
- Verify site is accessible
- Test key pages load correctly
- Verify environment variables applied
- Update TodoWrite

Phase 6: Summary
Goal: Document deployment

Actions:
- Mark all todos complete
- Display deployment URL
- Show environment variables configured
- Provide monitoring recommendations
- Show next steps (configure custom domain, setup analytics)
