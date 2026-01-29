---
description: Add a specific feature to an existing SvelteKit project. Features include page, component, layout, api, migrate.
argument-hint: <feature> [options]
---

# Add SvelteKit Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Page Features

**If `$0` = "page":**

```
Task(page-generator-agent) Add PAGE.

Requirements:
- Page name: $1 (required)
- Page type: $2 (static, dynamic, server - default: static)
- Create page component
- Add to routes
- Set up load function
- Configure SEO
```

**If `$0` = "layout":**

```
Task(routing-wiring-agent) Add LAYOUT.

Requirements:
- Layout name: $1 (required)
- Scope: $2 (global, group, page - default: group)
- Create layout component
- Add slots
- Configure inheritance
```

### Component Features

**If `$0` = "component":**

```
Task(component-builder-agent) Add COMPONENT.

Requirements:
- Component name: $1 (required)
- Type: $2 (ui, feature, form - default: ui)
- Create component file
- Add props/slots
- Configure styling
- Add exports
```

### API Features

**If `$0` = "api":**

```
Task(routing-wiring-agent) Add API ROUTE.

Requirements:
- Route name: $1 (required)
- Methods: $2 (get, post, put, delete, all - default: all)
- Create server endpoint
- Add request handling
- Set up response
- Add types
```

### Migration Features

**If `$0` = "migrate":**

```
Task(html-to-svelte-migration-agent) MIGRATE HTML to Svelte.

Requirements:
- Source: $1 (file path or URL)
- Target: $2 (component, page - default: component)
- Convert HTML to Svelte
- Extract components
- Add reactivity
- Configure styling
```

### Design Features

**If `$0` = "design":**

```
Task(design-enforcer-agent) Add DESIGN feature.

Requirements:
- Feature: $1 (theme, tokens, components - default: theme)
- Configure design system
- Add variables
- Create documentation
```

### Routing Features

**If `$0` = "route":**

```
Task(routing-wiring-agent) Add ROUTE configuration.

Requirements:
- Route type: $1 (group, dynamic, optional, rest - required)
- Route name: $2 (route name)
- Create route structure
- Configure parameters
- Add load functions
```

---

## Usage Examples

```bash
# Pages & Layouts
/sveltekit-frontend:add page dashboard static
/sveltekit-frontend:add page user dynamic
/sveltekit-frontend:add layout admin group

# Components
/sveltekit-frontend:add component Button ui
/sveltekit-frontend:add component UserCard feature
/sveltekit-frontend:add component ContactForm form

# API Routes
/sveltekit-frontend:add api users all
/sveltekit-frontend:add api webhook post

# Migration
/sveltekit-frontend:add migrate ./legacy/page.html page
/sveltekit-frontend:add migrate https://example.com component

# Design & Routing
/sveltekit-frontend:add design theme
/sveltekit-frontend:add route dynamic [id]
/sveltekit-frontend:add route group (auth)
```

---

## Feature Reference

| Feature     | Agent             | $1 Options                  | Description         |
| ----------- | ----------------- | --------------------------- | ------------------- |
| `page`      | page-generator    | page-name (required)        | New page            |
| `layout`    | routing-wiring    | layout-name (required)      | Layout component    |
| `component` | component-builder | component-name (required)   | UI component        |
| `api`       | routing-wiring    | route-name (required)       | API endpoint        |
| `migrate`   | migration-agent   | source path/URL (required)  | HTML to Svelte      |
| `design`    | design-enforcer   | theme/tokens/components     | Design system       |
| `route`     | routing-wiring    | group/dynamic/optional/rest | Route configuration |
