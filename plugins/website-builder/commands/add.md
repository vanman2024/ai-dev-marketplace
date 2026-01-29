---
description: Add a specific feature to an existing website project. Features include page, section, seo, analytics, conversion, ai-content.
argument-hint: <feature> [options]
---

# Add Website Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Page Features

**If `$0` = "page":**

```
Task(website-architect) Add PAGE.

Requirements:
- Page name: $1 (required)
- Page type: $2 (landing, product, about, contact, blog - default: landing)
- Create page component
- Add sections
- Configure SEO
- Add to navigation
```

**If `$0` = "section":**

```
Task(website-content-agent) Add SECTION.

Requirements:
- Section type: $1 (hero, features, testimonials, pricing, cta, faq - required)
- Style: $2 (minimal, bold, corporate - default: minimal)
- Create section component
- Add content placeholders
- Configure animations
```

### Content Features

**If `$0` = "content":**

```
Task(website-content) Add CONTENT.

Requirements:
- Content type: $1 (copy, images, video - default: copy)
- Page: $2 (target page)
- Create content structure
- Add placeholders
- Configure CMS (if needed)
```

**If `$0` = "ai-content":**

```
Task(website-ai-generator) Generate AI CONTENT.

Requirements:
- Content type: $1 (landing, blog, product - required)
- Tone: $2 (professional, casual, technical - default: professional)
- Generate content with AI
- Create copy variants
- Add SEO optimization
```

### SEO Features

**If `$0` = "seo":**

```
Task(website-seo-agent) Add SEO optimization.

Requirements:
- Feature: $1 (meta, sitemap, schema, all - default: all)
- Page: $2 (specific page or all)
- Add meta tags
- Configure Open Graph
- Create schema markup
- Generate sitemap
```

### Analytics Features

**If `$0` = "analytics":**

```
Task(website-analytics-agent) Add ANALYTICS.

Requirements:
- Provider: $1 (ga4, plausible, mixpanel, posthog - default: ga4)
- Features: $2 (basic, events, funnels - default: basic)
- Install analytics
- Set up tracking
- Configure events
- Add dashboard
```

### Conversion Features

**If `$0` = "conversion":**

```
Task(website-conversion-agent) Add CONVERSION optimization.

Requirements:
- Feature: $1 (cta, forms, popup, all - default: all)
- Create CTA components
- Add form handling
- Configure popups
- Set up A/B tests
```

### Engagement Features

**If `$0` = "engagement":**

```
Task(website-engagement-agent) Add ENGAGEMENT feature.

Requirements:
- Feature: $1 (chat, notifications, social, all - default: all)
- Add chat widget
- Configure notifications
- Add social sharing
- Set up interactions
```

### Verification Features

**If `$0` = "verify":**

```
Task(website-verifier) VERIFY website.

Requirements:
- Check: $1 (links, seo, performance, all - default: all)
- Run verification checks
- Generate report
- List issues
- Recommend fixes
```

---

## Usage Examples

```bash
# Pages & Sections
/website-builder:add page pricing landing
/website-builder:add page blog blog
/website-builder:add section hero bold
/website-builder:add section testimonials minimal

# Content
/website-builder:add content copy landing
/website-builder:add ai-content landing professional
/website-builder:add ai-content blog casual

# SEO & Analytics
/website-builder:add seo all
/website-builder:add seo schema home
/website-builder:add analytics ga4 events
/website-builder:add analytics plausible

# Conversion & Engagement
/website-builder:add conversion cta
/website-builder:add conversion popup
/website-builder:add engagement chat

# Verification
/website-builder:add verify all
/website-builder:add verify performance
```

---

## Feature Reference

| Feature      | Agent            | $1 Options                         | Description          |
| ------------ | ---------------- | ---------------------------------- | -------------------- |
| `page`       | architect        | page-name (required)               | Website page         |
| `section`    | content-agent    | hero/features/testimonials/pricing | Page section         |
| `content`    | content          | copy/images/video                  | Content              |
| `ai-content` | ai-generator     | landing/blog/product               | AI-generated content |
| `seo`        | seo-agent        | meta/sitemap/schema/all            | SEO optimization     |
| `analytics`  | analytics-agent  | ga4/plausible/mixpanel/posthog     | Analytics setup      |
| `conversion` | conversion-agent | cta/forms/popup/all                | Conversion features  |
| `engagement` | engagement-agent | chat/notifications/social/all      | Engagement features  |
| `verify`     | verifier         | links/seo/performance/all          | Site verification    |
