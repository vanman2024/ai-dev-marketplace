---
description: Build a high-converting landing page with SEO, engagement, and conversion optimization
argument-hint: <page-name> [--product|--saas|--newsletter|--webinar]
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

---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

- Never hardcode API keys or secrets
- Use placeholders: `your_api_key_here`
- Protect `.env` files with `.gitignore`

**Arguments**: $ARGUMENTS

Goal: Build a complete, high-converting landing page optimized for SEO, user engagement, and conversion. This command orchestrates multiple specialist agents to create a landing page that ranks, engages, and converts.

Core Principles:
- Mobile-first responsive design
- SEO-optimized from the start (2025 best practices)
- Conversion-focused layout and copy
- Engaging micro-interactions
- Analytics-ready with tracking

Landing Page Types:
- **--product**: Product launch with features, pricing, testimonials
- **--saas**: SaaS homepage with trial signup, feature comparison
- **--newsletter**: Email capture with value proposition
- **--webinar**: Event registration with urgency elements

Phase 1: Discovery
Goal: Understand landing page requirements

Actions:
- Parse $ARGUMENTS for page name and type flag
- Default to --saas if no type specified
- Check project setup:
  ```bash
  test -d app && echo "Next.js App Router: Found" || echo "App Router: Not found"
  grep -q "shadcn" package.json && echo "shadcn/ui: Installed" || echo "shadcn/ui: Not installed"
  ```
- If shadcn/ui not installed, run `/nextjs-frontend:init` first

Phase 2: Gather Requirements
Goal: Collect landing page specifications

Actions:
- Ask user for key information:

1. **Value Proposition**: What problem does the product solve?
2. **Target Audience**: Who is the ideal customer?
3. **Key Features**: 3-5 main features/benefits
4. **Social Proof**: Any testimonials, user counts, logos?
5. **CTA Goal**: Trial signup, demo request, newsletter, purchase?
6. **Urgency Elements**: Limited time offer, scarcity?

- Store responses for use by specialist agents

Phase 3: Content Strategy
Goal: Generate optimized copy using content-optimizer-agent

Actions:
- Invoke content optimizer for headline and copy:

Task(description="Generate landing page copy", subagent_type="nextjs-frontend:content-optimizer-agent", prompt="You are the content optimizer agent. Generate high-converting copy for a landing page.

Page Type: $ARGUMENTS
Value Proposition: [from Phase 2]
Target Audience: [from Phase 2]
Features: [from Phase 2]

Generate:
1. **Hero Section**
   - Main headline (benefit-focused, use proven formula)
   - Subheadline (how it works, 1-2 sentences)
   - Primary CTA text
   - Supporting text (no credit card, free trial, etc.)

2. **Social Proof**
   - Logo cloud caption
   - Stats section (3-4 metrics)
   - Testimonial quotes (2-3)

3. **Features Section**
   - Section headline
   - 3-5 feature cards with title + description

4. **Pricing Section** (if applicable)
   - Section headline
   - Plan descriptions
   - CTA text for each plan

5. **FAQ Section**
   - 5-7 common objections as questions
   - Answers that overcome objections

6. **Final CTA**
   - Headline
   - CTA button text
   - Supporting text

7. **Meta Content**
   - Page title (50-60 chars)
   - Meta description (150-160 chars)
   - OG title and description

Deliverable: Complete copy document ready for implementation")

Phase 4: Build Page Structure
Goal: Create landing page with shadcn/ui components

Actions:
- Create page file:
  ```bash
  mkdir -p app/$PAGE_NAME
  ```
- Use page-generator-agent for structure:

Task(description="Build landing page structure", subagent_type="nextjs-frontend:page-generator-agent", prompt="You are the page generator agent. Create a landing page with these sections:

Page: app/$PAGE_NAME/page.tsx
Type: $ARGUMENTS

Sections (in order):
1. **Hero** - Full-width, centered content, gradient background
2. **LogoCloud** - Trusted by logos
3. **Features** - 3-column grid with icons
4. **HowItWorks** - 3-step process with illustrations
5. **Testimonials** - 3-column cards with ratings
6. **Pricing** - 3 tier comparison table
7. **FAQ** - Accordion component
8. **FinalCTA** - Full-width, contrasting background

Requirements:
- Use shadcn/ui components (Button, Card, Accordion)
- Mobile-first responsive design
- Follow design system (4 font sizes, 8pt grid)
- Include placeholder content initially
- Export metadata for SEO

Deliverable: Complete landing page file with all sections")

Phase 5: SEO Optimization
Goal: Apply SEO best practices using seo-specialist-agent

Actions:
- Invoke SEO specialist:

Task(description="Optimize landing page SEO", subagent_type="nextjs-frontend:seo-specialist-agent", prompt="You are the SEO specialist agent. Optimize the landing page for 2025 SEO.

Page: app/$PAGE_NAME/page.tsx

Implement:
1. **Metadata** - generateMetadata function with title, description, OG, Twitter
2. **Schema** - Organization, Product/Service, FAQ JSON-LD
3. **Semantic HTML** - Proper heading hierarchy (h1 → h2 → h3)
4. **Image optimization** - next/image with alt text
5. **Core Web Vitals** - Priority loading for hero image

Deliverable: SEO-optimized page with all technical requirements")

Phase 6: Conversion Optimization
Goal: Apply CRO best practices using conversion-specialist-agent

Actions:
- Invoke conversion specialist:

Task(description="Optimize for conversions", subagent_type="nextjs-frontend:conversion-specialist-agent", prompt="You are the conversion specialist agent. Optimize the landing page for maximum conversions.

Page: app/$PAGE_NAME/page.tsx

Implement:
1. **CTA Optimization**
   - Primary CTA above fold
   - Sticky CTA on mobile
   - Supporting text below buttons
   - Action-oriented button copy

2. **Trust Signals**
   - Logo cloud with hover effects
   - Testimonials with photos and titles
   - Security badges near forms
   - Money-back guarantee badge

3. **Form Optimization**
   - Minimal fields (email only for newsletter)
   - Inline validation
   - Progress indicator for multi-step

4. **Urgency Elements** (if applicable)
   - Countdown timer component
   - Limited spots indicator
   - 'Most popular' badge

Deliverable: Conversion-optimized landing page components")

Phase 7: Engagement Enhancement
Goal: Add micro-interactions using engagement-specialist-agent

Actions:
- Invoke engagement specialist:

Task(description="Add engagement features", subagent_type="nextjs-frontend:engagement-specialist-agent", prompt="You are the engagement specialist agent. Add engaging interactions to the landing page.

Page: app/$PAGE_NAME/page.tsx

Implement:
1. **Scroll Animations**
   - Fade-up for sections
   - Staggered animation for feature cards
   - Parallax for hero background (subtle)

2. **Micro-Interactions**
   - Button hover/click effects
   - Card lift on hover
   - Form focus animations

3. **Progress Indicators**
   - Scroll progress bar (if long page)
   - Step indicators for process section

4. **Social Proof Animations**
   - Testimonial carousel/slider
   - Stats count-up animation
   - Logo cloud subtle movement

Deliverable: Engaging landing page with Framer Motion animations")

Phase 8: Analytics Setup
Goal: Implement tracking using analytics-specialist-agent

Actions:
- Invoke analytics specialist:

Task(description="Setup landing page analytics", subagent_type="nextjs-frontend:analytics-specialist-agent", prompt="You are the analytics specialist agent. Set up comprehensive tracking for the landing page.

Page: app/$PAGE_NAME/page.tsx

Implement:
1. **Pageview Tracking** - GA4 integration
2. **Event Tracking**
   - CTA clicks (with location: hero, pricing, footer)
   - Form submissions
   - Scroll depth (25%, 50%, 75%, 100%)
   - Video plays (if applicable)
3. **Conversion Tracking**
   - Signup/registration events
   - Lead generation events
4. **A/B Test Setup**
   - Variant assignment hook
   - Conversion tracking by variant

Deliverable: Analytics-ready landing page with comprehensive tracking")

Phase 9: Final Integration
Goal: Integrate all specialist outputs into cohesive page

Actions:
- Combine copy from content optimizer
- Apply SEO from SEO specialist
- Add conversion elements from CRO specialist
- Integrate animations from engagement specialist
- Connect analytics from analytics specialist
- Run build to verify:
  ```bash
  npm run build
  ```

Phase 10: Summary
Goal: Present completed landing page

Actions:
- Display completion summary:
```
Landing Page Built Successfully! 🚀
===================================

Page: app/$PAGE_NAME/page.tsx
Type: [--saas|--product|--newsletter|--webinar]

✅ Content: Headlines, copy, CTAs optimized
✅ SEO: Metadata, schema, semantic HTML
✅ Conversion: CTAs, trust signals, forms
✅ Engagement: Animations, micro-interactions
✅ Analytics: GA4, events, A/B ready

Sections Created:
1. Hero with CTA
2. Logo Cloud
3. Features Grid
4. How It Works
5. Testimonials
6. Pricing Table
7. FAQ Accordion
8. Final CTA

Next Steps:
1. Replace placeholder content with real copy
2. Add actual logos and testimonials
3. Connect forms to backend
4. Set up GA4 property
5. Launch and monitor conversions

Preview:
npm run dev
→ Open http://localhost:3000/$PAGE_NAME
```
