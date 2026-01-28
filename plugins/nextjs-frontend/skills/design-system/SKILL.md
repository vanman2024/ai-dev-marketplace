---
name: design-system
description: Load project design system for UI generation. Use when creating components, pages, forms, or any UI elements. Auto-invokes when conversation mentions styling, components, colors, typography, spacing, or UI design.
---

# Design System Context

**Purpose:** Automatically load design system constraints before any UI code generation.

**When this skill activates:**
- Creating new components or pages
- Generating UI elements or forms
- Discussing styling, colors, typography
- Setting up or modifying design tokens
- Any conversation about "design", "styling", "UI", "component"

## Project Design System

First, check if project has a design system file:

!cat design-system.md 2>/dev/null || echo "No design-system.md found - using defaults"

## Default Design Constraints (If No Project Config)

### Typography: 4 Sizes, 2 Weights ONLY

| Size | Tailwind | Use Case |
|------|----------|----------|
| Size 1 | `text-2xl font-semibold` | Large headings |
| Size 2 | `text-lg font-semibold` | Subheadings |
| Size 3 | `text-base font-normal` | Body text |
| Size 4 | `text-sm font-normal` | Small text, labels |

**❌ FORBIDDEN:** text-xs, text-xl, text-3xl, text-4xl, font-bold, font-light, font-medium

### Spacing: 8pt Grid System

**✅ ALLOWED:** 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64px
**❌ FORBIDDEN:** 5, 7, 9, 11, 13, 15, 19, 25px

```
p-1 (4px)  | p-2 (8px)  | p-3 (12px) | p-4 (16px)
p-5 ❌     | p-6 (24px) | p-8 (32px) | p-10 (40px)
```

### Colors: 60/30/10 Rule

- **60%** `bg-background` - White/dark backgrounds
- **30%** `text-foreground` - Text and icons  
- **10%** `bg-primary` - CTAs and highlights ONLY

### Component Library: shadcn/ui Only

All components must use shadcn/ui. Search available components:
- Button, Card, Input, Select, Dialog, Sheet, Tabs
- Form, Table, Badge, Avatar, Tooltip, Dropdown

## Validation Checklist

Before generating UI code, verify:
- [ ] Only 4 font sizes used
- [ ] Only 2 font weights (semibold, normal)
- [ ] All spacing divisible by 4 or 8
- [ ] Accent color ≤ 10% of UI
- [ ] Using shadcn/ui components
- [ ] Proper contrast ratios (WCAG AA)

## Quick Reference

```tsx
// ✅ CORRECT
<h1 className="text-2xl font-semibold">Title</h1>
<p className="text-base text-muted-foreground">Body</p>
<div className="p-4 space-y-4">  {/* 16px padding, 16px gap */}
<Button variant="default">Primary CTA</Button>

// ❌ WRONG
<h1 className="text-4xl font-bold">Title</h1>  // Wrong size & weight
<div className="p-5 space-y-3">  // Not on 8pt grid
<button className="bg-blue-500">Click</button>  // Not shadcn/ui
```
