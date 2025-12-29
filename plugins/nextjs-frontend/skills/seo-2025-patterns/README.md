# SEO 2025 Patterns Skill

Comprehensive SEO patterns and best practices for Next.js applications, updated for 2025 ranking factors.

## Features

- **Core Web Vitals** - LCP, INP (replaces FID), CLS optimization
- **E-E-A-T Signals** - Experience, Expertise, Authoritativeness, Trust
- **Schema Markup** - JSON-LD structured data components
- **Technical SEO** - Metadata, sitemap, robots.txt
- **AI Content Guidelines** - Google's helpful content update compliance

## Quick Start

```typescript
// Load this skill
!{skill seo-2025-patterns}

// Use patterns from SKILL.md
```

## Key Files

- `SKILL.md` - Complete SEO patterns and code examples
- `scripts/seo-audit.sh` - Run SEO validation
- `templates/` - Ready-to-use SEO components
- `examples/` - Implementation examples

## 2025 SEO Changes

1. **INP replaces FID** - Interaction to Next Paint is now Core Web Vital
2. **AI Content Guidelines** - Helpful content with human oversight
3. **E-E-A-T Enhanced** - Experience added as critical factor
4. **Passage Ranking** - Google indexes specific passages
5. **Video SEO** - Video snippets in SERPs

## Usage

```typescript
// 1. Configure Metadata in layout
import type { Metadata } from 'next'

export const metadata: Metadata = {
  metadataBase: new URL('https://example.com'),
  title: { default: 'Site', template: '%s | Site' },
  description: 'Description',
}

// 2. Add Schema components
<OrganizationSchema />
<ArticleSchema {...articleData} />
<FAQSchema items={faqItems} />

// 3. Create sitemap.ts and robots.ts
// 4. Run audit
./scripts/seo-audit.sh
```

## Related

- `seo-specialist-agent` - AI agent for SEO optimization
- `/optimize-seo` - Command to run SEO optimization
