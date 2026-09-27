---
name: seo-strategy-2026
description: Search-market discovery, technical SEO architecture, programmatic SEO governance, domain strategy, and job-board SEO for modern Next.js applications. Use for full-site SEO audits, keyword opportunity mapping, trade/job taxonomy, domain decisions, structured data, internal linking, Search Console analysis, and deciding which pages should or should not be indexed.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, WebFetch
---

# SEO Strategy 2026

## Purpose

This skill extends technical SEO into **search-market strategy**. It is designed to answer both:

- “Is the site implemented correctly for SEO?”
- “Are we targeting the right search opportunities in the first place?”

A technically perfect site can still miss major opportunities if its taxonomy only reflects internal product language. The skill therefore requires discovery of broad root search demand, modifiers, SERP intent, inventory depth, and conversion value before page generation.

## Source-of-truth policy

For implementation details, current official documentation wins over embedded examples or older project docs.

Primary references:

- Google Search Essentials and spam policies
- Google JobPosting structured data documentation
- Google Indexing API documentation for eligible job URLs
- Google Search Console documentation/API
- current Next.js App Router metadata, sitemap, robots, and rendering documentation

Do not treat old SEO checklists as immutable. Search requirements change.

## SEO operating model

Use four linked systems:

1. **Demand system** — what people search for.
2. **Inventory/content system** — what useful jobs/content the product can actually serve.
3. **Page system** — which URLs deserve to exist and be indexed.
4. **Measurement system** — what Search Console and conversion data prove after launch.

No one system should operate independently.

## 1. Search-market discovery

### 1.1 Start broader than the product vocabulary

If the product calls a role “Heavy Equipment Technician,” do not assume that is the largest or best query family. Expand upward and outward:

- mechanic jobs
- heavy duty mechanic jobs
- heavy equipment mechanic jobs
- diesel mechanic jobs
- industrial mechanic jobs
- mining mechanic jobs
- field mechanic jobs
- mobile mechanic jobs
- fly-in fly-out mechanic jobs / FIFO mechanic jobs
- location variants
- industry variants
- certification variants
- equipment/specialty variants when justified

The goal is to discover root demand that the product team may not have named.

### 1.2 Build keyword clusters, not isolated words

Cluster by search intent and likely landing-page need.

Recommended fields for `KEYWORD-MAP.csv`:

```csv
cluster,query,intent,demand_source,demand_date,monthly_volume,ranking_source,ranking_date,current_position,current_url,proposed_url,page_type,inventory_depth,conversion_value,cannibalization_risk,evidence_confidence,status,notes
```

Rules:

- Leave unknown numeric fields blank.
- Never fabricate volume or rank.
- Mark inferred clusters as `hypothesis` until validated.
- Preserve source/date so stale research is obvious.

### 1.3 Find opportunities from Search Console

When Search Console data is available, specifically look for:

- high-impression queries with no strong dedicated page
- positions 4-20 with meaningful impressions
- pages ranking for unintended queries
- multiple URLs competing for the same cluster
- query modifiers repeatedly appearing across pages
- new location or occupation terms emerging organically
- pages with strong ranking but weak CTR
- pages with clicks but weak conversion

These are often higher-confidence opportunities than generic keyword tools.

## 2. Domain strategy

A portfolio of exact-match domains can be useful only when each domain supports a genuine independent product/search experience.

### 2.1 Domain Opportunity Matrix

Score each domain candidate from 0-5 on:

- Search demand
- Distinct audience
- Distinct inventory
- Unique content depth
- Employer/customer proposition
- Brand independence
- Link-earning potential
- Operational maintainability

Also score risk from 0-5:

- Content overlap
- Inventory duplication
- Cannibalization
- Doorway risk
- Scaled-content risk
- Authority fragmentation

Recommended fields:

```csv
domain,vertical,status,search_demand,distinct_audience,distinct_inventory,unique_content,employer_value,brand_independence,link_potential,maintainability,content_overlap,inventory_duplication,cannibalization_risk,doorway_risk,scaled_content_risk,authority_fragmentation,recommendation,evidence,notes
```

### 2.2 Default decision rule

Prefer a category/subdirectory on the strongest relevant domain unless a separate domain has:

- materially different audience/intent,
- enough independent job inventory,
- substantial unique evergreen content,
- a defensible employer/user proposition,
- and enough operational capacity to maintain it as a real product.

Examples of questions to answer before splitting domains:

- Would users bookmark or revisit this site independently?
- Could this site remain useful even when one job source disappears?
- Will at least a meaningful portion of its content be unique rather than mirrored from another domain?
- Does it have its own useful category/resource architecture?
- Can it earn backlinks for reasons beyond the domain name?

If not, keep it on the main domain.

## 3. Page taxonomy

### 3.1 Recommended job-site hierarchy

A typical hierarchy might be:

```text
/
/mechanic-jobs/
/heavy-duty-mechanic-jobs/
/mining-mechanic-jobs/
/industrial-mechanic-jobs/
/fifo-mechanic-jobs/
/mechanic-jobs/alberta/
/mechanic-jobs/ontario/
/jobs/{job-slug}/
/resources/{slug}/
```

This is illustrative, not an instruction to create every route.

### 3.2 One intent, one primary canonical page

Every indexed page should have a defined primary cluster. Avoid multiple near-identical pages targeting the same intent.

For each page family document:

- purpose
- primary query cluster
- secondary queries
- URL pattern
- canonical pattern
- index/noindex rule
- required inventory/content threshold
- unique content requirements
- internal-link parents/children
- schema type
- sitemap inclusion
- empty-state behavior

## 4. Programmatic SEO governance

### 4.1 Page creation is not a Cartesian product

Never create all combinations of:

`trade × industry × province × city × equipment × schedule × employer`

simply because the database supports them.

### 4.2 Indexed Page Gate

A proposed programmatic page family must pass all of these:

- **Intent:** a real distinct user/search intent exists.
- **Value:** page offers useful information or inventory beyond a label swap.
- **Depth:** enough jobs/content exist or the page has durable informational value.
- **Distinctness:** it is not substantially redundant with another canonical page.
- **Navigation:** users can reach it naturally through internal links.
- **Indexation:** clear canonical/noindex rules exist.
- **Maintenance:** stale/empty state is handled automatically.
- **Evidence:** demand is evidenced or explicitly documented as a test hypothesis.

### 4.3 Low-inventory rules

Define project-specific thresholds rather than one universal number.

Possible actions when a page drops below threshold:

- remain indexed if it has substantial evergreen value
- consolidate into a broader category
- noindex while preserving user navigation
- redirect only when intent truly maps to another page
- return 404/410 if the page should no longer exist

Do not blanket redirect all empty pages to the homepage.

## 5. JobPosting lifecycle

### 5.1 Single-job pages only

`JobPosting` JSON-LD belongs on the detailed leaf page for a single real job.

Do not place `JobPosting` markup on:

- search results pages
- trade/category pages
- location listing pages
- generic evergreen “we are always hiring” pages unless each page is genuinely a specific open role

### 5.2 Data parity

Structured data must match visible page content. If salary, location, employment type, schedule, or other job details are represented in schema, ensure the user can see corresponding accurate information on the page.

### 5.3 Canonical job URLs

If a job appears through many categories/filters, keep one canonical job detail URL.

Category pages link to it; they do not create duplicate copies of the job page.

### 5.4 Expiration

When a job is no longer open, promptly do one of the current Google-supported expiration actions:

- set an accurate `validThrough` in the past,
- remove the page with 404/410,
- or remove `JobPosting` structured data.

If the site keeps expired pages for historical/user value, make their closed status unmistakable and ensure active-job structured data is not misleading.

Use the Indexing API for eligible job-posting URL updates/removals when configured, while still maintaining sitemaps for broad site discovery.

### 5.5 Sitemap accuracy

- Include canonical job detail pages.
- Use truthful `lastmod` values based on actual content changes.
- Do not update every URL timestamp on every deploy.
- Do not include internal search result/list pages merely to force crawling.

## 6. Technical Next.js requirements

For App Router projects, audit and generally prefer:

- `generateMetadata()` for dynamic routes
- `metadataBase` and canonical URLs
- `app/robots.ts`
- `app/sitemap.ts` or `generateSitemaps()` for scale
- server-rendered meaningful content
- JSON-LD components tied to trusted data
- `notFound()`/redirect/status handling for invalid routes
- stable crawlable href links
- caching/revalidation that does not leave stale job state indefinitely

### 6.1 Rendering check

For representative pages, verify the actual rendered HTML includes:

- title
- meta description
- canonical
- H1
- primary content
- crawlable links
- intended JSON-LD

Do not assume a React component means Google receives useful HTML.

## 7. Internal linking system

Create a deliberate graph.

Examples:

- homepage -> major occupation pages
- occupation -> specialty/industry pages
- occupation -> major location pages
- location -> relevant occupation pages
- category/location pages -> active jobs
- job detail -> relevant category + location
- guides/resources -> relevant job categories
- job categories -> relevant guides/certification/salary resources

Prefer useful natural anchors. Avoid mass exact-match anchor repetition.

## 8. Content standards

SEO content should help a job seeker make a decision, not just fill a template.

For job category/location pages, useful content can include verified/current information such as:

- what roles are represented
- common qualifications/certifications
- common equipment/specialties
- typical work settings
- schedule patterns
- current job inventory summary
- region-specific considerations when factually supported
- related career resources

Do not invent salary ranges, employer facts, certifications, or regional requirements.

## 9. Backlinks and authority

Do not treat “buy backlinks” as a mandatory line item.

Evaluate link opportunities by whether they are legitimate, attributable, and useful. Potential categories include:

- industry associations
- trade schools/apprenticeship resources
- employer partnerships
- original labour-market research
- useful salary/career datasets
- trade guides/tools worth citing
- media/PR around genuinely newsworthy data

Any paid placement must be evaluated against current Google link-spam guidance and disclosure/link-attribute requirements.

## 10. Audit runbook

### A. Repository audit

1. Inventory public routes.
2. Identify route families.
3. Inspect metadata/canonical logic.
4. Inspect sitemap/robots.
5. Inspect structured data.
6. Trace job data lifecycle.
7. Identify filter/facet URL behavior.
8. Identify redirects/status handling.
9. Identify internal-link structure.
10. Run build/type/lint tests.

### B. Live-site audit

When live access exists:

1. sample rendered HTML by route type
2. check status/canonical chains
3. test robots and sitemaps
4. validate structured data
5. test representative expired jobs
6. assess Core Web Vitals/PageSpeed data
7. check crawl/indexation discrepancies

### C. Search-market audit

1. import GSC query/page data
2. import keyword dataset if available
3. derive broad root terms
4. derive occupation/specialty/industry/location/work-model modifiers
5. map current URLs to clusters
6. identify missing pages
7. identify cannibalization
8. identify domain opportunities
9. prioritize by evidence × value × effort × risk

## 11. Required deliverable structure

When establishing SEO in a project, create or maintain:

```text
docs/seo/
  SEO-STRATEGY.md
  KEYWORD-MAP.csv
  DOMAIN-STRATEGY.md
  DOMAIN-OPPORTUNITY-MATRIX.csv
  PAGE-TAXONOMY.md
  INTERNAL-LINKING.md
  STRUCTURED-DATA.md
  PROGRAMMATIC-SEO-GUARDRAILS.md
  AUDIT-RUNBOOK.md
  SEO-CHANGELOG.md
```

The repository's `CLAUDE.md` should point Claude to these files rather than duplicating all SEO rules in root memory.

## 12. Prioritization formula

Use a simple decision model, not fake mathematical precision.

Score 1-5 where evidence exists:

- Demand
- Business/conversion value
- Current near-ranking opportunity
- Inventory/content fit
- Strategic differentiation
- Effort
- Cannibalization/spam risk

A useful prioritization heuristic:

`Opportunity = (Demand + Conversion + NearRanking + Fit + Differentiation) - (Effort + Risk)`

Always preserve the underlying evidence and explain important judgment calls.

## 13. Completion checklist

Before completing an SEO architecture task:

- [ ] route inventory exists
- [ ] keyword opportunities extend beyond current site vocabulary
- [ ] evidence and hypotheses are separated
- [ ] each indexed page family has a defined purpose
- [ ] programmatic pages pass the Indexed Page Gate
- [ ] domain opportunities have been scored before launch
- [ ] job schema is restricted to single-job pages
- [ ] expiration lifecycle is defined
- [ ] sitemap/robots/canonical rules are defined
- [ ] internal-link graph is documented
- [ ] technical implementation validates/builds if changed
- [ ] SEO changelog/backlog updated
