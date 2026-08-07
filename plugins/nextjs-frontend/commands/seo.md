---
description: Run SEO architecture, market-opportunity discovery, technical audit, implementation, or review for a Next.js project.
argument-hint: <audit|opportunities|architecture|implement|review|init> [scope]
---

# SEO Architect

**Mode:** `$0`
**Scope:** `$1` `$2` `$3`

Route this request to `seo-architect-agent` and load `nextjs-frontend:seo-strategy-2026`.

## Modes

### `init`

Establish the SEO operating system for the current repository.

```text
Task(seo-architect-agent) Initialize SEO architecture for this project.

Requirements:
- Discover current app/router/data architecture first.
- Create docs/seo/ if missing.
- Establish SEO-STRATEGY.md.
- Create KEYWORD-MAP.csv with empty evidence fields rather than fabricated metrics.
- Create DOMAIN-STRATEGY.md and DOMAIN-OPPORTUNITY-MATRIX.csv.
- Create PAGE-TAXONOMY.md.
- Create INTERNAL-LINKING.md.
- Create STRUCTURED-DATA.md.
- Create PROGRAMMATIC-SEO-GUARDRAILS.md.
- Create AUDIT-RUNBOOK.md.
- Create SEO-CHANGELOG.md.
- Update CLAUDE.md with a concise pointer to docs/seo rather than copying all rules into root memory.
- Do not bulk-create SEO pages during initialization.
```

### `audit`

Audit the whole site or the supplied scope.

```text
Task(seo-architect-agent) Perform a complete SEO audit.

Scope: $1 $2 $3

Audit both strategic architecture and technical implementation. Build a route inventory, identify P0-P3 issues, distinguish evidence from hypotheses, and do not modify code unless explicitly requested.
```

### `opportunities`

Find search opportunities beyond the terms already present in the repository.

```text
Task(seo-architect-agent) Perform search-market opportunity discovery.

Scope: $1 $2 $3

Requirements:
- Start with broad root search concepts, then expand by occupation, specialty, industry, work model, location, credential, equipment, and employer intent where justified.
- Use Search Console/keyword/SERP data when available.
- Never invent volume/ranking metrics.
- Update KEYWORD-MAP.csv.
- Identify missing page opportunities and cannibalization.
- Score domain opportunities in DOMAIN-OPPORTUNITY-MATRIX.csv.
- Explicitly call out surprising opportunities the current product taxonomy misses.
```

### `architecture`

Design or revise the SEO information architecture.

```text
Task(seo-architect-agent) Design SEO information architecture.

Scope: $1 $2 $3

Requirements:
- Map search intent to canonical page families.
- Decide domain vs subdirectory using the Domain Opportunity Matrix.
- Define page taxonomy, canonical/index rules, internal-link hierarchy, sitemap inclusion, and low-inventory behavior.
- Apply the programmatic Indexed Page Gate.
- Do not create every possible data permutation.
```

### `implement`

Implement an already-supported SEO change set.

```text
Task(seo-architect-agent) Implement approved SEO changes.

Scope: $1 $2 $3

Requirements:
- Read existing docs/seo and route architecture first.
- Prefer current native Next.js App Router metadata conventions when applicable.
- Validate structured data and representative rendered routes.
- Run build/type/lint checks.
- Update SEO-CHANGELOG.md.
- Do not silently expand scope into new domains or bulk programmatic page families.
```

### `review`

Review a change/PR/implementation from an SEO perspective.

```text
Task(seo-architect-agent) Review the supplied changes as an SEO architect.

Scope: $1 $2 $3

Check for indexation regressions, metadata/canonical/schema errors, broken internal linking, sitemap/robots impacts, rendering issues, programmatic-page risk, job lifecycle errors, and search-intent/cannibalization problems.
```

## Usage examples

```bash
/nextjs-frontend:seo init
/nextjs-frontend:seo audit
/nextjs-frontend:seo audit jobs
/nextjs-frontend:seo opportunities "mechanic jobs Canada"
/nextjs-frontend:seo architecture "trade and location taxonomy"
/nextjs-frontend:seo implement "JobPosting lifecycle"
/nextjs-frontend:seo review "current branch"
```

## Non-negotiable rules

- Search demand is evidence, not intuition.
- Unknown metrics remain blank/unknown.
- A page must earn the right to be indexed.
- A separate domain must earn the right to exist.
- `JobPosting` schema only belongs on a single real job detail page.
- Expired jobs must not continue to masquerade as active postings.
- Do not generate thin trade/location permutations or near-identical domains to manipulate rankings.
