---
description: Optimize Next.js application for 2025 SEO (Core Web Vitals, E-E-A-T, Schema markup)
argument-hint: [page-path] [--full-audit]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite, Task)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

- Never hardcode API keys or secrets
- Use placeholders: `your_ga_id_here`, `your_site_url_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only

**Arguments**: $ARGUMENTS

Goal: Optimize a Next.js application for 2025 SEO best practices including Core Web Vitals, E-E-A-T signals, Schema markup, meta optimization, and technical SEO.

Core Principles:
- Focus on 2025 ranking factors (INP replaces FID, AI content guidelines)
- Implement E-E-A-T signals (Experience, Expertise, Authoritativeness, Trust)
- Add comprehensive Schema.org structured data
- Optimize Core Web Vitals (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- Create dynamic sitemaps and robots.txt

Phase 1: Discovery
Goal: Understand current SEO state and scope

Actions:
- Parse $ARGUMENTS to extract page path and --full-audit flag
- Check for existing SEO setup:
  ```bash
  test -f app/sitemap.ts && echo "Sitemap: Found" || echo "Sitemap: Missing"
  test -f app/robots.ts && echo "Robots: Found" || echo "Robots: Missing"
  grep -r "Metadata" app/layout.tsx 2>/dev/null && echo "Metadata: Found" || echo "Metadata: Check needed"
  ```
- Identify target scope:
  - If specific page path provided: optimize that page
  - If --full-audit: optimize entire site
  - Default: optimize key pages (home, about, pricing)

Phase 2: SEO Audit
Goal: Run comprehensive SEO analysis using seo-specialist-agent

Actions:
- Invoke SEO specialist agent for detailed audit:

Task(description="SEO audit for Next.js app", subagent_type="nextjs-frontend:seo-specialist-agent", prompt="You are the SEO specialist agent. Perform a comprehensive 2025 SEO audit for this Next.js application.

Target: $ARGUMENTS

Audit Checklist:
1. **Technical SEO**
   - Check app/layout.tsx for Metadata API usage
   - Verify sitemap.ts exists and generates all pages
   - Verify robots.ts with proper rules
   - Check for canonical URLs
   - Verify mobile responsiveness

2. **Meta Optimization**
   - Check all pages for unique title tags
   - Verify meta descriptions (150-160 chars)
   - Check Open Graph tags
   - Verify Twitter cards
   - Check for duplicate content

3. **Core Web Vitals Preparation**
   - Check for next/image usage
   - Verify font optimization (next/font)
   - Check for lazy loading implementation
   - Identify render-blocking resources

4. **E-E-A-T Signals**
   - Check for author information
   - Verify About page exists
   - Check for contact information
   - Look for testimonials/reviews

5. **Schema Markup**
   - Check for existing JSON-LD
   - Identify required schema types

Deliverable: Detailed audit report with specific recommendations and priority levels (High/Medium/Low)")

Phase 3: Implement Meta Configuration
Goal: Set up comprehensive metadata configuration

Actions:
- If metadata not properly configured, create/update app/layout.tsx:
  ```typescript
  // Ensure metadata export exists with:
  // - metadataBase
  // - title template
  // - description
  // - openGraph configuration
  // - twitter configuration
  // - robots configuration
  ```
- Create metadata utility file if complex configuration needed
- Add page-specific generateMetadata functions

Phase 4: Sitemap & Robots
Goal: Implement dynamic sitemap and robots.txt

Actions:
- Create or update app/sitemap.ts:
  ```bash
  test -f app/sitemap.ts || echo "Creating sitemap.ts"
  ```
- Create or update app/robots.ts:
  ```bash
  test -f app/robots.ts || echo "Creating robots.ts"
  ```
- Ensure sitemap includes all indexable pages
- Configure robots to allow crawling, block /api/ and /_next/

Phase 5: Schema Markup Implementation
Goal: Add structured data for rich snippets

Actions:
- Create JSON-LD components for:
  - Organization schema (all pages)
  - WebSite schema (home page)
  - Article schema (blog posts)
  - FAQ schema (FAQ sections)
  - BreadcrumbList (navigation)
- Add schema components to appropriate pages

Phase 6: Core Web Vitals Optimization
Goal: Optimize for LCP, INP, and CLS

Actions:
- Check image optimization:
  ```bash
  grep -r "next/image" app --include="*.tsx" | wc -l
  ```
- If images not using next/image, flag for update
- Check font configuration:
  ```bash
  grep -r "next/font" app --include="*.tsx" | wc -l
  ```
- Verify priority attribute on above-fold images
- Check for layout shift prevention (explicit dimensions)

Phase 7: Generate SEO Report
Goal: Create comprehensive SEO status report

Actions:
- Generate markdown report with:
  - Current SEO score
  - Implemented optimizations
  - Remaining recommendations
  - Core Web Vitals checklist
  - Testing instructions

Display final summary:
```
SEO Optimization Complete
========================
✅ Metadata configured in app/layout.tsx
✅ Dynamic sitemap at app/sitemap.ts
✅ Robots.txt at app/robots.ts
✅ Schema markup implemented
✅ Core Web Vitals optimized

Next Steps:
1. Test with Google Search Console
2. Run PageSpeed Insights
3. Submit sitemap to Google
4. Monitor Core Web Vitals in production
```
