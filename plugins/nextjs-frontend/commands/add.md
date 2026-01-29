---
description: Add a specific feature to an existing Next.js project. Features include page, component, api, auth, ai, supabase, design.
argument-hint: <feature> [options]
---

# Add Next.js Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2` `$3`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Page Features

**If `$0` = "page":**

```
Task(page-generator-agent) Add PAGE.

Requirements:
- Page name: $1 (required)
- Page type: $2 (static, dynamic, parallel, intercepting - default: static)
- Create page component
- Add to app router
- Set up metadata
- Add loading/error states
```

**If `$0` = "layout":**

```
Task(page-generator-agent) Add LAYOUT.

Requirements:
- Layout name: $1 (required)
- Scope: $2 (global, route-group, page - default: route-group)
- Create layout component
- Add shared UI
- Configure slot handling
```

### Component Features

**If `$0` = "component":**

```
Task(component-builder-agent) Add COMPONENT.

Requirements:
- Component name: $1 (required)
- Type: $2 (ui, feature, form, data - default: ui)
- Create component file
- Add props types
- Configure styling
- Add to exports
```

**If `$0` = "form":**

```
Task(component-builder-agent) Add FORM.

Requirements:
- Form name: $1 (required)
- Validation: $2 (zod, yup, none - default: zod)
- Create form component
- Add validation schema
- Set up react-hook-form
- Add error handling
```

### API Features

**If `$0` = "api":**

```
Task(api-route-generator-agent) Add API ROUTE.

Requirements:
- Route name: $1 (required)
- Methods: $2 (get, post, put, delete, all - default: all)
- Create route handler
- Add request validation
- Set up error handling
- Add types
```

### Auth Features

**If `$0` = "auth":**

```
Task(supabase-integration-agent) Add AUTHENTICATION.

Requirements:
- Provider: $1 (clerk, supabase, nextauth - default: clerk)
- Features: $2 (social, email, mfa - default: email)
- Set up auth provider
- Create auth pages
- Add middleware
- Configure protected routes
```

### Database Features

**If `$0` = "supabase":**

```
Task(supabase-integration-agent) Add SUPABASE integration.

Requirements:
- Feature: $1 (auth, database, storage, realtime - default: database)
- Set up Supabase client
- Configure types
- Add data access patterns
- Create hooks
```

### AI Features

**If `$0` = "ai":**

```
Task(ai-sdk-integration-agent) Add AI features.

Requirements:
- Feature: $1 (chat, completion, streaming, tools - default: chat)
- Provider: $2 (openai, anthropic, openrouter - default: openai)
- Set up AI route
- Create chat component
- Add streaming support
- Configure tools
```

### Design Features

**If `$0` = "design":**

```
Task(design-patterns-agent) Add DESIGN PATTERN.

Requirements:
- Pattern: $1 (shadcn, radix, custom - default: shadcn)
- Components: $2 (component list or all)
- Install components
- Configure theme
- Set up design tokens
```

**If `$0` = "ui-search":**

```
Task(ui-search-agent) SEARCH for UI component.

Requirements:
- Query: $1 (description of what you need)
- Source: $2 (shadcn, radix, ui-components - default: all)
- Search for component
- Recommend implementation
- Provide integration code
```

---

## Usage Examples

```bash
# Pages & Layouts
/nextjs-frontend:add page dashboard static
/nextjs-frontend:add page user dynamic
/nextjs-frontend:add layout admin route-group

# Components
/nextjs-frontend:add component Button ui
/nextjs-frontend:add component UserCard feature
/nextjs-frontend:add form ContactForm zod

# API Routes
/nextjs-frontend:add api users all
/nextjs-frontend:add api webhook post

# Auth & Database
/nextjs-frontend:add auth clerk social
/nextjs-frontend:add supabase database

# AI Features
/nextjs-frontend:add ai chat openai
/nextjs-frontend:add ai tools anthropic

# Design
/nextjs-frontend:add design shadcn button,card,dialog
/nextjs-frontend:add ui-search "data table with sorting"
```

---

## Feature Reference

| Feature     | Agent                | $1 Options                      | Description         |
| ----------- | -------------------- | ------------------------------- | ------------------- |
| `page`      | page-generator       | page-name (required)            | App Router page     |
| `layout`    | page-generator       | layout-name (required)          | Layout component    |
| `component` | component-builder    | component-name (required)       | UI component        |
| `form`      | component-builder    | form-name (required)            | Form component      |
| `api`       | api-route-generator  | route-name (required)           | API route           |
| `auth`      | supabase-integration | clerk/supabase/nextauth         | Authentication      |
| `supabase`  | supabase-integration | auth/database/storage/realtime  | Supabase features   |
| `ai`        | ai-sdk-integration   | chat/completion/streaming/tools | AI features         |
| `design`    | design-patterns      | shadcn/radix/custom             | Design system       |
| `ui-search` | ui-search            | description query               | UI component search |
