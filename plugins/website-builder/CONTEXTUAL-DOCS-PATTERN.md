# Contextual Documentation Pattern for Agents

## Problem

Documentation links were previously condensed into Phase 1 "Discovery" sections, creating:
- **Information overload**: 17-25 links dumped all at once
- **Poor discoverability**: Hard to find the right link when needed
- **Not actionable**: Links separated from the actions that need them

## Solution: Just-In-Time Documentation

Place documentation links **contextually** where they're actually needed, using the pattern:

```markdown
**Action to take:**
- Do the work first

**If [specific situation], fetch [specific docs]:**
- WebFetch: https://docs.astro.build/[relevant-page]
```

## Example: Before vs After

### ❌ Before (Condensed)

```markdown
### 1. Discovery & Core Documentation

**Primary LLM-Optimized Docs** (fetch these first):
- WebFetch: https://docs.astro.build/llms-full.txt
- WebFetch: https://docs.astro.build/_llms-txt/api-reference.txt
- WebFetch: https://docs.astro.build/_llms-txt/deployment-guides.txt

**Specific Topic Links** (fetch when needed):
- Installation: https://docs.astro.build/en/install-and-setup/
- Project structure: https://docs.astro.build/en/basics/project-structure/
- Configuration: https://docs.astro.build/en/guides/configuring-astro/
- TypeScript: https://docs.astro.build/en/guides/typescript/
- Environment variables: https://docs.astro.build/en/guides/environment-variables/
- Editor setup: https://docs.astro.build/en/editor-setup/
- Build with AI: https://docs.astro.build/en/guides/build-with-ai/
- Dev toolbar: https://docs.astro.build/en/guides/dev-toolbar/

**Project Analysis:**
- Read package.json
- Check config
- Ask questions
```

### ✅ After (Contextual)

```markdown
### 1. Discovery & Requirements

**Understand the project first:**
- Read package.json to understand if project exists
- Check existing Astro configuration
- Identify requested features from user input
- Ask targeted questions

**If you need Astro overview:**
- WebFetch: https://docs.astro.build/llms-full.txt

### 2. Analysis & Feature Planning

**Assess project state:**
- Is this new or existing?
- What integrations are required?

**If you need configuration guidance:**
- WebFetch: https://docs.astro.build/_llms-txt/api-reference.txt
- Specific config: https://docs.astro.build/en/guides/configuring-astro/

**If you need project structure help:**
- Read: project-structure.md template
- WebFetch: https://docs.astro.build/en/basics/project-structure/

### 3. Prerequisites Check

**Verify system requirements:**
- Node.js 18.14.1+
- Package manager available

**If prerequisites check fails:**
- WebFetch: https://docs.astro.build/en/install-and-setup/

### 4. Implementation

**Step 1: Create project**
```bash
npm create astro@latest ...
```

**If project creation fails:**
- WebFetch: https://docs.astro.build/en/install-and-setup/

**Step 2: Install integrations**
```bash
npx astro add react mdx tailwind --yes
```

**If you need integration-specific guidance:**
- React: https://docs.astro.build/en/guides/integrations-guide/react/
- MDX: https://docs.astro.build/en/guides/integrations-guide/mdx/
- Tailwind: https://docs.astro.build/en/guides/integrations-guide/tailwind/

**Step 3: Configure TypeScript**

**If TypeScript configuration is unclear:**
- WebFetch: https://docs.astro.build/en/guides/typescript/

### 5. Verification

**Run checks:**
- npm install
- npm run build

**If build fails:**
- WebFetch: https://docs.astro.build/en/guides/troubleshooting/
- Error reference: https://docs.astro.build/en/reference/error-reference/
```

## Key Principles

1. **Action First, Docs Second**
   - Agent takes action
   - Only fetches docs if the action needs help

2. **Conditional Documentation**
   - Use "If X, then fetch Y" pattern
   - Agent only fetches what it actually needs

3. **Proximity to Use**
   - Link appears right before/after the step that uses it
   - No scrolling to find relevant docs

4. **Progressive Disclosure**
   - Start with general LLM docs (fast, concise)
   - Drill down to specific pages only when needed
   - Reserve detailed API references for implementation

5. **Situational Triggers**
   - "If prerequisites check fails" → Installation docs
   - "If TypeScript unclear" → TypeScript guide
   - "If build fails" → Troubleshooting docs

## Benefits

### For Agents
- ✅ **Faster execution**: Don't waste tokens fetching unused docs
- ✅ **Better context**: Relevant docs appear when needed
- ✅ **Clear decision tree**: If/then structure guides actions
- ✅ **Less overwhelming**: See links in digestible chunks

### For Users
- ✅ **Efficient token usage**: Only fetch what's needed
- ✅ **Faster responses**: Less upfront documentation fetching
- ✅ **Better results**: Agent has right docs at right time

## Implementation Status

- ✅ **website-setup** - Fully restructured with contextual docs
- ⏳ **website-architect** - TODO: Apply contextual pattern
- ⏳ **website-content** - TODO: Apply contextual pattern
- ⏳ **website-ai-generator** - TODO: Apply contextual pattern
- ⏳ **website-verifier** - TODO: Apply contextual pattern

## Template Pattern

Use this template when restructuring agents:

```markdown
### Phase N: [Phase Name]

**Do the work:**
- Action step 1
- Action step 2
- Action step 3

**If [specific situation]:**
- WebFetch: [relevant-docs-url]

**If [another situation]:**
- WebFetch: [other-relevant-url]
- Specific guidance: [direct-link]
```

## Documentation Strategy Document

The comprehensive **DOCUMENTATION-STRATEGY.md** remains as a reference map showing:
- All 250+ Astro documentation pages
- Mapping of docs to agents/skills/commands
- LLM endpoints vs direct links
- Coverage analysis

Agents should use DOCUMENTATION-STRATEGY.md as a **lookup reference**, not a list to fetch upfront.

## Next Steps

1. Apply contextual pattern to remaining 4 agents
2. Test agents with real tasks to validate doc placement
3. Measure token savings from just-in-time fetching
4. Document best practices for future agent development
