---
name: design-system-enforcement
description: Mandatory design system guidelines for SvelteKit with Tailwind CSS v4 and shadcn-svelte. Enforces 4 font sizes, 2 weights, 8pt grid spacing, 60/30/10 color rule, OKLCH colors, and accessibility standards. ALL agents MUST read and validate against design system before generating any Svelte component code.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# SvelteKit + Tailwind + shadcn-svelte Design System Enforcement

**Purpose:** Enforce consistent, accessible, and beautiful UI across all SvelteKit projects using shadcn-svelte with Tailwind CSS v4.

**Activation Triggers:**

- Creating new Svelte components
- Generating pages or layouts
- Styling any UI elements
- Before ANY UI code generation
- Component library setup
- Design system validation needed

## Core Design Principles (MANDATORY)

### 1. Typography: 4 Sizes, 2 Weights ONLY

**STRICTLY ENFORCED:**

| Size | Tailwind Class | Pixels | Use Case |
|------|----------------|--------|----------|
| Size 1 | `text-3xl` | 32px | Large headings |
| Size 2 | `text-2xl` | 24px | Subheadings |
| Size 3 | `text-base` | 16px | Body text |
| Size 4 | `text-sm` | 14px | Small text/labels |

**Weights:**
- ✅ `font-semibold` - Headings and emphasis
- ✅ `font-normal` - Body text and UI

**❌ FORBIDDEN:**
- `text-xs`, `text-lg`, `text-xl`, `text-4xl`, etc.
- `font-light`, `font-medium`, `font-bold`, `font-extrabold`

### 2. 8pt Grid System

**STRICTLY ENFORCED:** All spacing via Tailwind utilities divisible by 8 or 4.

**Allowed Tailwind Spacing:**
```
p-1 (4px)   | m-1 (4px)   | gap-1 (4px)
p-2 (8px)   | m-2 (8px)   | gap-2 (8px)
p-3 (12px)  | m-3 (12px)  | gap-3 (12px)
p-4 (16px)  | m-4 (16px)  | gap-4 (16px)
p-5 (20px)  | m-5 (20px)  | gap-5 (20px)
p-6 (24px)  | m-6 (24px)  | gap-6 (24px)
p-8 (32px)  | m-8 (32px)  | gap-8 (32px)
```

**❌ FORBIDDEN:** Custom spacing like `p-[13px]`, `m-[7px]`

### 3. 60/30/10 Color Rule

**STRICTLY ENFORCED:**

- **60% Neutral** - `bg-background` - White/dark backgrounds
- **30% Complementary** - `text-foreground`, `text-muted-foreground` - Text/icons
- **10% Accent** - `bg-primary`, `text-primary` - CTAs and highlights ONLY

**❌ FORBIDDEN:**
- Overusing accent colors (>10%)
- Hardcoded colors (`bg-blue-500`, `text-gray-700`)
- Multiple competing accent colors

### 4. OKLCH Color Variables (globals.css)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* 60% - Neutral Background */
    --background: oklch(1 0 0);
    --foreground: oklch(0.145 0 0);

    /* 30% - Complementary */
    --muted: oklch(0.961 0 0);
    --muted-foreground: oklch(0.451 0 0);

    /* 10% - Accent Brand */
    --primary: oklch(0.623 0.214 259.815);
    --primary-foreground: oklch(0.985 0 0);

    /* Supporting Colors */
    --card: oklch(1 0 0);
    --card-foreground: oklch(0.145 0 0);
    --popover: oklch(1 0 0);
    --popover-foreground: oklch(0.145 0 0);
    --secondary: oklch(0.961 0 0);
    --secondary-foreground: oklch(0.145 0 0);
    --accent: oklch(0.961 0 0);
    --accent-foreground: oklch(0.145 0 0);
    --destructive: oklch(0.577 0.245 27.325);
    --destructive-foreground: oklch(0.985 0 0);
    --border: oklch(0.898 0 0);
    --input: oklch(0.898 0 0);
    --ring: oklch(0.623 0.214 259.815);
    --radius: 0.5rem;
  }

  .dark {
    --background: oklch(0.145 0 0);
    --foreground: oklch(0.985 0 0);
    --muted: oklch(0.269 0 0);
    --muted-foreground: oklch(0.631 0 0);
    --primary: oklch(0.623 0.214 259.815);
    --primary-foreground: oklch(0.985 0 0);
    --card: oklch(0.145 0 0);
    --card-foreground: oklch(0.985 0 0);
    --popover: oklch(0.145 0 0);
    --popover-foreground: oklch(0.985 0 0);
    --secondary: oklch(0.269 0 0);
    --secondary-foreground: oklch(0.985 0 0);
    --accent: oklch(0.269 0 0);
    --accent-foreground: oklch(0.985 0 0);
    --destructive: oklch(0.396 0.141 25.723);
    --destructive-foreground: oklch(0.985 0 0);
    --border: oklch(0.269 0 0);
    --input: oklch(0.269 0 0);
    --ring: oklch(0.623 0.214 259.815);
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

---

## shadcn-svelte Component Standards

### Button Component

**Location**: `$lib/components/ui/button`

#### Variants (When to Use)

| Variant | Use Case | Example |
|---------|----------|---------|
| `default` | Primary actions, CTAs | "Submit", "Save" |
| `secondary` | Secondary actions | "Cancel", "Back" |
| `destructive` | Dangerous actions | "Delete", "Remove" |
| `outline` | Tertiary actions | "Learn More" |
| `ghost` | Minimal UI, toolbars | Icon buttons |
| `link` | Inline text actions | "Forgot password?" |

#### Sizes

| Size | Height | Padding | Use Case |
|------|--------|---------|----------|
| `sm` | h-9 (36px) | px-3 | Compact UI, tables |
| `default` | h-10 (40px) | px-4 | Standard forms |
| `lg` | h-11 (44px) | px-8 | Hero sections |
| `icon` | h-10 w-10 | - | Icon-only |

#### Code Examples

```svelte
<script>
  import { Button } from "$lib/components/ui/button";
</script>

<!-- Primary CTA -->
<Button>Get Started</Button>

<!-- Secondary -->
<Button variant="secondary">Cancel</Button>

<!-- Destructive -->
<Button variant="destructive">Delete</Button>

<!-- Small in table -->
<Button size="sm" variant="outline">Edit</Button>

<!-- Icon button -->
<Button size="icon" variant="ghost">
  <Settings class="h-4 w-4" />
</Button>

<!-- Button group - gap-2 (8px) -->
<div class="flex gap-2">
  <Button variant="outline">Cancel</Button>
  <Button>Save</Button>
</div>
```

### Card Component

**Location**: `$lib/components/ui/card`

#### Standard Structure

```svelte
<script>
  import * as Card from "$lib/components/ui/card";
</script>

<Card.Root>
  <Card.Header>
    <Card.Title>Card Title</Card.Title>
    <Card.Description>Optional description</Card.Description>
  </Card.Header>
  <Card.Content>
    <!-- Main content -->
  </Card.Content>
  <Card.Footer>
    <!-- Actions -->
  </Card.Footer>
</Card.Root>
```

#### Card Spacing Rules

- **Card.Header**: `p-6` (24px)
- **Card.Content**: `p-6 pt-0` (24px, no top)
- **Card.Footer**: `p-6 pt-0` (24px, no top)
- **Gap between cards**: `gap-4` (16px) or `gap-6` (24px)

#### Card Patterns

```svelte
<!-- Simple card -->
<Card.Root>
  <Card.Header>
    <Card.Title class="text-2xl font-semibold">Statistics</Card.Title>
  </Card.Header>
  <Card.Content>
    <p class="text-base">Content here</p>
  </Card.Content>
</Card.Root>

<!-- Card with actions -->
<Card.Root>
  <Card.Header>
    <Card.Title>Settings</Card.Title>
    <Card.Description>Manage preferences</Card.Description>
  </Card.Header>
  <Card.Content>
    <!-- Form -->
  </Card.Content>
  <Card.Footer class="flex justify-end gap-2">
    <Button variant="outline">Cancel</Button>
    <Button>Save</Button>
  </Card.Footer>
</Card.Root>

<!-- Card grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <Card.Root>...</Card.Root>
  <Card.Root>...</Card.Root>
</div>
```

### Form Elements

#### Input with Label

```svelte
<script>
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
</script>

<div class="space-y-2">
  <Label for="email">Email</Label>
  <Input id="email" type="email" placeholder="you@example.com" />
</div>
```

#### Form Layout

```svelte
<form class="space-y-4">
  <div class="space-y-2">
    <Label>Field 1</Label>
    <Input />
  </div>
  <div class="space-y-2">
    <Label>Field 2</Label>
    <Input />
  </div>
  <Button type="submit">Submit</Button>
</form>

<!-- Two-column -->
<div class="grid grid-cols-2 gap-4">
  <div class="space-y-2">
    <Label>First Name</Label>
    <Input />
  </div>
  <div class="space-y-2">
    <Label>Last Name</Label>
    <Input />
  </div>
</div>
```

### Badge Component

```svelte
<script>
  import { Badge } from "$lib/components/ui/badge";
</script>

<Badge>Active</Badge>
<Badge variant="secondary">Category</Badge>
<Badge variant="destructive">Failed</Badge>
<Badge variant="outline">Beta</Badge>
```

### Dialog/Modal

```svelte
<script>
  import * as Dialog from "$lib/components/ui/dialog";
  import { Button } from "$lib/components/ui/button";
</script>

<Dialog.Root>
  <Dialog.Trigger asChild let:builder>
    <Button builders={[builder]}>Open</Button>
  </Dialog.Trigger>
  <Dialog.Content>
    <Dialog.Header>
      <Dialog.Title>Dialog Title</Dialog.Title>
      <Dialog.Description>Description here</Dialog.Description>
    </Dialog.Header>
    <div class="py-4">
      <!-- Content -->
    </div>
    <Dialog.Footer>
      <Button variant="outline">Cancel</Button>
      <Button>Confirm</Button>
    </Dialog.Footer>
  </Dialog.Content>
</Dialog.Root>
```

---

## Layout Patterns

### Page Container

```svelte
<!-- Standard -->
<div class="container mx-auto px-4 py-8">
  <!-- Content -->
</div>

<!-- With max-width -->
<div class="container mx-auto px-4 py-8 max-w-4xl">
  <!-- Centered content -->
</div>
```

### Section Spacing

```svelte
<!-- Between sections: py-8 or py-16 -->
<section class="py-8">
  <h2 class="text-2xl font-semibold mb-4">Section Title</h2>
  <!-- Content -->
</section>

<!-- Content grouping: space-y-4 or space-y-6 -->
<div class="space-y-4">
  <Component1 />
  <Component2 />
</div>
```

### Grid Layouts

```svelte
<!-- Responsive grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {#each items as item}
    <Card.Root>...</Card.Root>
  {/each}
</div>

<!-- Sidebar layout -->
<div class="flex gap-6">
  <aside class="w-64 shrink-0">
    <!-- Sidebar -->
  </aside>
  <main class="flex-1">
    <!-- Main content -->
  </main>
</div>
```

---

## Agent Enforcement Rules

### Before Generating ANY Svelte Component

**MANDATORY CHECKLIST:**

1. [ ] Read `design-system.md` or this skill
2. [ ] Use ONLY 4 font sizes: `text-3xl`, `text-2xl`, `text-base`, `text-sm`
3. [ ] Use ONLY 2 font weights: `font-semibold`, `font-normal`
4. [ ] All spacing via Tailwind (p-2, m-4, gap-4, etc.)
5. [ ] Colors via semantic classes: `bg-background`, `text-foreground`, `bg-primary`
6. [ ] Use shadcn-svelte components from `$lib/components/ui/`
7. [ ] Follow 60/30/10 color distribution

### Anti-Patterns to Avoid

**❌ DON'T DO THIS:**

```svelte
<!-- Wrong: Custom colors -->
<Button class="bg-blue-500">Delete</Button>

<!-- Wrong: Arbitrary spacing -->
<div class="p-[13px] m-[7px] gap-[5px]">

<!-- Wrong: Too many font sizes -->
<p class="text-xs">Small</p>
<p class="text-lg">Large</p>
<p class="text-xl">Larger</p>

<!-- Wrong: Extra font weights -->
<h1 class="font-bold">Title</h1>
<span class="font-light">Light</span>
```

**✅ DO THIS:**

```svelte
<!-- Correct: Semantic colors -->
<Button variant="destructive">Delete</Button>

<!-- Correct: 8pt grid spacing -->
<div class="p-4 m-2 gap-4">

<!-- Correct: 4 sizes only -->
<h1 class="text-3xl font-semibold">Heading</h1>
<h2 class="text-2xl font-semibold">Subheading</h2>
<p class="text-base">Body text</p>
<span class="text-sm text-muted-foreground">Label</span>
```

---

## Quick Reference

### Typography
| Class | Size | Use |
|-------|------|-----|
| `text-3xl font-semibold` | 32px | Page headings |
| `text-2xl font-semibold` | 24px | Section headings |
| `text-base` | 16px | Body text |
| `text-sm` | 14px | Labels, meta |

### Spacing
| Class | Value |
|-------|-------|
| `p-2 / m-2 / gap-2` | 8px |
| `p-4 / m-4 / gap-4` | 16px |
| `p-6 / m-6 / gap-6` | 24px |
| `p-8 / m-8 / gap-8` | 32px |

### Colors
| Class | Use |
|-------|-----|
| `bg-background` | 60% - Page/section backgrounds |
| `text-foreground` | 30% - Primary text |
| `text-muted-foreground` | 30% - Secondary text |
| `bg-primary text-primary-foreground` | 10% - CTAs only |

---

**Framework:** SvelteKit + Tailwind CSS v4 + shadcn-svelte
**Enforcement:** Mandatory for all agents
**Version:** 1.0.0
