# Astro Documentation Integration Strategy

## Overview

This document maps Astro's comprehensive documentation (250+ pages) to the website-builder plugin's agents, skills, and commands.

## LLM-Optimized Documentation Endpoints

These endpoints provide AI-friendly documentation:

1. **https://docs.astro.build/llms-full.txt** - Foundation & concepts
2. **https://docs.astro.build/llms-small.txt** - Abridged quick reference
3. **https://docs.astro.build/_llms-txt/api-reference.txt** - Complete API reference
4. **https://docs.astro.build/_llms-txt/how-to-recipes.txt** - Practical recipes
5. **https://docs.astro.build/_llms-txt/cms-guides.txt** - CMS integrations (40+ systems)
6. **https://docs.astro.build/_llms-txt/backend-services.txt** - Backend services (Supabase, Firebase, etc)
7. **https://docs.astro.build/_llms-txt/build-a-blog-tutorial.txt** - Complete blog tutorial
8. **https://docs.astro.build/_llms-txt/deployment-guides.txt** - Deployment platforms (30+)
9. **https://docs.astro.build/_llms-txt/additional-guides.txt** - Advanced topics

## Documentation Coverage Gaps (Need Direct Links)

The LLM endpoints don't cover everything. For these topics, agents should WebFetch specific pages:

### Critical Topics Missing from LLM Docs

1. **Routing & Navigation**
   - Dynamic routes: https://docs.astro.build/en/guides/routing/
   - Endpoints: https://docs.astro.build/en/guides/endpoints/
   - Middleware: https://docs.astro.build/en/guides/middleware/
   - i18n: https://docs.astro.build/en/guides/internationalization/
   - Prefetch: https://docs.astro.build/en/guides/prefetch/
   - View transitions: https://docs.astro.build/en/guides/view-transitions/

2. **Content Management**
   - Content collections: https://docs.astro.build/en/guides/content-collections/
   - Markdown: https://docs.astro.build/en/guides/markdown-content/
   - Images: https://docs.astro.build/en/guides/images/
   - Data fetching: https://docs.astro.build/en/guides/data-fetching/

3. **UI & Styling**
   - Components: https://docs.astro.build/en/basics/astro-components/
   - Layouts: https://docs.astro.build/en/basics/layouts/
   - Styling: https://docs.astro.build/en/guides/styling/
   - Fonts: https://docs.astro.build/en/guides/fonts/
   - Syntax highlighting: https://docs.astro.build/en/guides/syntax-highlighting/
   - Framework components: https://docs.astro.build/en/guides/framework-components/

4. **Server Rendering**
   - On-demand rendering: https://docs.astro.build/en/guides/on-demand-rendering/
   - Server islands: https://docs.astro.build/en/guides/server-islands/
   - Actions: https://docs.astro.build/en/guides/actions/
   - Sessions: https://docs.astro.build/en/guides/sessions/

5. **Testing & Authentication**
   - Testing: https://docs.astro.build/en/guides/testing/
   - Authentication: https://docs.astro.build/en/guides/authentication/
   - E-commerce: https://docs.astro.build/en/guides/ecommerce/

6. **Configuration & Reference**
   - Configuration reference: https://docs.astro.build/en/reference/configuration-reference/
   - CLI reference: https://docs.astro.build/en/reference/cli-reference/
   - Template directives: https://docs.astro.build/en/reference/directives-reference/
   - Routing reference: https://docs.astro.build/en/reference/routing-reference/

7. **Runtime API Modules**
   - astro:actions: https://docs.astro.build/en/reference/modules/astro-actions/
   - astro:assets: https://docs.astro.build/en/reference/modules/astro-assets/
   - astro:content: https://docs.astro.build/en/reference/modules/astro-content/
   - astro:env: https://docs.astro.build/en/reference/modules/astro-env/
   - astro:i18n: https://docs.astro.build/en/reference/modules/astro-i18n/
   - astro:middleware: https://docs.astro.build/en/reference/modules/astro-middleware/
   - astro:transitions: https://docs.astro.build/en/reference/modules/astro-transitions/

8. **Advanced APIs**
   - Integration API: https://docs.astro.build/en/reference/integrations-reference/
   - Adapter API: https://docs.astro.build/en/reference/adapter-reference/
   - Content Loader API: https://docs.astro.build/en/reference/content-loader-reference/
   - Image Service API: https://docs.astro.build/en/reference/image-service-reference/
   - Dev Toolbar App API: https://docs.astro.build/en/reference/dev-toolbar-app-reference/

9. **Experimental Features**
   - Experimental flags: https://docs.astro.build/en/reference/experimental-flags/
   - Content Security Policy: https://docs.astro.build/en/reference/experimental-flags/csp/
   - Live content collections: https://docs.astro.build/en/reference/experimental-flags/live-content-collections/

## Documentation Mapping by Agent

### website-setup Agent

**Primary Focus**: Installation, configuration, project initialization

**LLM Docs**:
- llms-full.txt (foundation)
- api-reference.txt (configuration)
- deployment-guides.txt (deployment planning)

**Direct Links**:
- Installation: https://docs.astro.build/en/install-and-setup/
- Project structure: https://docs.astro.build/en/basics/project-structure/
- Configuration: https://docs.astro.build/en/guides/configuring-astro/
- TypeScript: https://docs.astro.build/en/guides/typescript/
- Environment variables: https://docs.astro.build/en/guides/environment-variables/
- Editor setup: https://docs.astro.build/en/editor-setup/
- Dev toolbar: https://docs.astro.build/en/guides/dev-toolbar/

### website-architect Agent

**Primary Focus**: Database schema, architecture, SEO

**LLM Docs**:
- api-reference.txt (API design)
- cms-guides.txt (CMS integration)
- backend-services.txt (Supabase, database)
- additional-guides.txt (advanced patterns)

**Direct Links**:
- Content collections: https://docs.astro.build/en/guides/content-collections/
- Data fetching: https://docs.astro.build/en/guides/data-fetching/
- Middleware: https://docs.astro.build/en/guides/middleware/
- Actions: https://docs.astro.build/en/guides/actions/
- Sessions: https://docs.astro.build/en/guides/sessions/
- Routing: https://docs.astro.build/en/guides/routing/
- Endpoints: https://docs.astro.build/en/guides/endpoints/
- i18n: https://docs.astro.build/en/guides/internationalization/

### website-content Agent

**Primary Focus**: Creating pages, blog posts, MDX content

**LLM Docs**:
- how-to-recipes.txt (practical examples)
- build-a-blog-tutorial.txt (blog creation)
- cms-guides.txt (content management)

**Direct Links**:
- Pages: https://docs.astro.build/en/basics/astro-pages/
- Components: https://docs.astro.build/en/basics/astro-components/
- Layouts: https://docs.astro.build/en/basics/layouts/
- Markdown: https://docs.astro.build/en/guides/markdown-content/
- Content collections: https://docs.astro.build/en/guides/content-collections/
- Syntax highlighting: https://docs.astro.build/en/guides/syntax-highlighting/
- Images: https://docs.astro.build/en/guides/images/
- Fonts: https://docs.astro.build/en/guides/fonts/
- RSS feed: https://docs.astro.build/en/recipes/rss/
- Reading time: https://docs.astro.build/en/recipes/reading-time/
- Modified time: https://docs.astro.build/en/recipes/modified-time/

### website-ai-generator Agent

**Primary Focus**: AI content generation with MCP servers

**LLM Docs**:
- backend-services.txt (API integration)
- how-to-recipes.txt (integration patterns)
- additional-guides.txt (advanced features)

**Direct Links**:
- Build with AI: https://docs.astro.build/en/guides/build-with-ai/
- Data fetching: https://docs.astro.build/en/guides/data-fetching/
- Endpoints: https://docs.astro.build/en/guides/endpoints/
- Server islands: https://docs.astro.build/en/guides/server-islands/
- On-demand rendering: https://docs.astro.build/en/guides/on-demand-rendering/
- Environment variables: https://docs.astro.build/en/guides/environment-variables/
- Dynamic images: https://docs.astro.build/en/recipes/dynamically-importing-images/

### website-verifier Agent

**Primary Focus**: Validation, SEO, performance, accessibility

**LLM Docs**:
- api-reference.txt (validation)
- deployment-guides.txt (production checks)
- how-to-recipes.txt (optimization)

**Direct Links**:
- Testing: https://docs.astro.build/en/guides/testing/
- Troubleshooting: https://docs.astro.build/en/guides/troubleshooting/
- Error reference: https://docs.astro.build/en/reference/error-reference/
- CLI reference: https://docs.astro.build/en/reference/cli-reference/
- Bundle size: https://docs.astro.build/en/recipes/analyze-bundle-size/
- Streaming performance: https://docs.astro.build/en/recipes/streaming-improve-page-performance/
- Docker build: https://docs.astro.build/en/recipes/docker/

## Skills Documentation Mapping

### astro-setup Skill

**Documentation Needed**:
- Installation: https://docs.astro.build/en/install-and-setup/
- Project structure: https://docs.astro.build/en/basics/project-structure/
- Configuration reference: https://docs.astro.build/en/reference/configuration-reference/
- TypeScript: https://docs.astro.build/en/guides/typescript/

### content-collections Skill

**Documentation Needed**:
- Content collections: https://docs.astro.build/en/guides/content-collections/
- astro:content API: https://docs.astro.build/en/reference/modules/astro-content/
- Markdown: https://docs.astro.build/en/guides/markdown-content/
- MDX integration: https://docs.astro.build/en/guides/integrations-guide/mdx/

### component-integration Skill

**Documentation Needed**:
- Components: https://docs.astro.build/en/basics/astro-components/
- Framework components: https://docs.astro.build/en/guides/framework-components/
- React integration: https://docs.astro.build/en/guides/integrations-guide/react/
- Client scripts: https://docs.astro.build/en/guides/client-side-scripts/
- Islands architecture: https://docs.astro.build/en/concepts/islands/

### supabase-cms Skill

**Documentation Needed**:
- Supabase backend: https://docs.astro.build/en/guides/backend/supabase/
- Data fetching: https://docs.astro.build/en/guides/data-fetching/
- Environment variables: https://docs.astro.build/en/guides/environment-variables/
- Actions: https://docs.astro.build/en/guides/actions/
- Sessions: https://docs.astro.build/en/guides/sessions/

### seo-optimization Skill

**Documentation Needed**:
- Sitemap integration: https://docs.astro.build/en/guides/integrations-guide/sitemap/
- Prefetch: https://docs.astro.build/en/guides/prefetch/
- View transitions: https://docs.astro.build/en/guides/view-transitions/
- RSS feed: https://docs.astro.build/en/recipes/rss/
- Images: https://docs.astro.build/en/guides/images/

## Slash Commands Documentation Mapping

### /website-builder:init

**Documentation Needed**:
- Getting started: https://docs.astro.build/en/getting-started/
- Installation: https://docs.astro.build/en/install-and-setup/
- Build with AI: https://docs.astro.build/en/guides/build-with-ai/
- LLM docs: llms-full.txt, api-reference.txt

### /website-builder:add-page

**Documentation Needed**:
- Pages: https://docs.astro.build/en/basics/astro-pages/
- Routing: https://docs.astro.build/en/guides/routing/
- Layouts: https://docs.astro.build/en/basics/layouts/
- LLM docs: how-to-recipes.txt

### /website-builder:add-blog

**Documentation Needed**:
- Blog tutorial: https://docs.astro.build/en/tutorial/0-introduction/
- Content collections: https://docs.astro.build/en/guides/content-collections/
- RSS feed: https://docs.astro.build/en/recipes/rss/
- LLM docs: build-a-blog-tutorial.txt, how-to-recipes.txt

### /website-builder:integrate-supabase-cms

**Documentation Needed**:
- Supabase: https://docs.astro.build/en/guides/backend/supabase/
- Data fetching: https://docs.astro.build/en/guides/data-fetching/
- LLM docs: backend-services.txt, cms-guides.txt

### /website-builder:generate-content

**Documentation Needed**:
- Build with AI: https://docs.astro.build/en/guides/build-with-ai/
- Content collections: https://docs.astro.build/en/guides/content-collections/
- Markdown: https://docs.astro.build/en/guides/markdown-content/
- LLM docs: how-to-recipes.txt, additional-guides.txt

### /website-builder:deploy

**Documentation Needed**:
- Deployment overview: https://docs.astro.build/en/guides/deploy/
- Vercel: https://docs.astro.build/en/guides/deploy/vercel/
- Netlify: https://docs.astro.build/en/guides/deploy/netlify/
- Cloudflare: https://docs.astro.build/en/guides/deploy/cloudflare/
- LLM docs: deployment-guides.txt

## Implementation Strategy

### Phase 1: Update Existing Agents
1. Add comprehensive documentation sections to each agent
2. Include both LLM endpoints and direct links
3. Organize by task/phase for easy reference

### Phase 2: Create New Skills
1. **routing-navigation** - Dynamic routes, middleware, i18n
2. **styling-theming** - CSS, Tailwind, fonts, syntax highlighting
3. **server-rendering** - SSR, server islands, actions
4. **testing-auth** - Testing frameworks, authentication patterns
5. **performance-optimization** - Bundle analysis, streaming, caching

### Phase 3: Enhance Slash Commands
1. Add documentation references to command files
2. Include specific recipe links for common tasks
3. Map integration guides to commands

### Phase 4: Create Documentation Templates
1. Quick reference cards for common tasks
2. Troubleshooting guides
3. Best practices checklists
4. Migration guides (Next.js → Astro, etc.)

## Usage Pattern for Agents

Agents should follow this pattern when accessing documentation:

```markdown
### Documentation Strategy

**Step 1: Check LLM-optimized docs first** (faster, more concise)
- WebFetch: https://docs.astro.build/_llms-txt/[relevant-section].txt

**Step 2: Fetch specific guides if needed** (detailed examples)
- WebFetch: https://docs.astro.build/en/guides/[specific-topic]/

**Step 3: Reference API docs for implementation** (exact syntax)
- WebFetch: https://docs.astro.build/en/reference/[api-section]/

**Step 4: Check recipes for practical examples** (working code)
- WebFetch: https://docs.astro.build/en/recipes/[recipe-name]/
```

## Next Steps

1. ✅ Create this strategy document
2. ⏳ Update all 5 agents with comprehensive documentation sections
3. ⏳ Create 5 new skills for advanced topics
4. ⏳ Add documentation references to all slash commands
5. ⏳ Create quick reference templates
6. ⏳ Test documentation access in real scenarios
7. ⏳ Commit and push all updates
