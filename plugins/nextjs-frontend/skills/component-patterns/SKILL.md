---
name: component-patterns
description: Load component structure patterns for React/Next.js. Use when creating components, discussing component architecture, or reviewing component code. Auto-invokes when user mentions component, tsx, jsx, props, or component structure.
---

# Component Patterns Context

**Purpose:** Ensure consistent component structure across the codebase.

## Discover Existing Patterns

!find src/components -name "*.tsx" -type f 2>/dev/null | head -5 | xargs head -30 2>/dev/null || echo "No existing components found"

## Standard Component Structure

### File Organization
```
src/components/
├── ui/                 # shadcn/ui primitives
│   ├── button.tsx
│   ├── card.tsx
│   └── input.tsx
├── [feature]/          # Feature-specific components
│   ├── feature-card.tsx
│   └── feature-list.tsx
└── layout/             # Layout components
    ├── header.tsx
    ├── sidebar.tsx
    └── footer.tsx
```

### Component Template

```tsx
import { cn } from "@/lib/utils"
import { ComponentProps } from "react"

// 1. Types at top
interface MyComponentProps extends ComponentProps<"div"> {
  title: string
  description?: string
  variant?: "default" | "outline"
}

// 2. Component with forwardRef if needed
export function MyComponent({
  title,
  description,
  variant = "default",
  className,
  ...props
}: MyComponentProps) {
  return (
    <div
      className={cn(
        // Base styles
        "rounded-lg border p-4",
        // Variant styles
        variant === "outline" && "border-2",
        // Custom classes last
        className
      )}
      {...props}
    >
      <h3 className="text-lg font-semibold">{title}</h3>
      {description && (
        <p className="text-sm text-muted-foreground">{description}</p>
      )}
    </div>
  )
}
```

### Key Patterns

1. **Use `cn()` utility** for conditional classes
2. **Extend native element props** with ComponentProps<"element">
3. **Default variants** in function signature
4. **Spread remaining props** with `...props`
5. **className always last** for override capability

### Import Conventions

```tsx
// External libraries first
import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"

// UI components
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"

// Local components
import { FeatureCard } from "@/components/feature/feature-card"

// Utils and types
import { cn } from "@/lib/utils"
import type { User } from "@/types"
```
