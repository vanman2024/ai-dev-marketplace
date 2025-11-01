# shadcn/ui with Tailwind v4 Design System Guidelines

**MANDATORY REFERENCE**: All agents MUST read and strictly adhere to these guidelines before creating any components, pages, or UI elements.

---

## Project Configuration

**Project Name**: TaskFlow AI
**Primary Brand Color**: Blue (#3B82F6)
**Color Scheme**: Light & Dark Mode Support
**Typography Scale**: 4 sizes, 2 weights (ENFORCED)
**Spacing Unit**: 8pt grid (ENFORCED)

---

## Core Design Principles

### 1. Typography System: 4 Sizes, 2 Weights

**STRICTLY ENFORCE**: Only 4 font sizes and 2 font weights allowed.

- **4 Font Sizes Only**:
  - Size 1: text-2xl (24px) - Large headings
  - Size 2: text-lg (18px) - Subheadings/Important content
  - Size 3: text-base (16px) - Body text
  - Size 4: text-sm (14px) - Small text/labels

- **2 Font Weights Only**:
  - Semibold: For headings and emphasis
  - Regular: For body text and general content

**❌ FORBIDDEN**: Using more than 4 font sizes or additional font weights

---

### 2. 8pt Grid System

**STRICTLY ENFORCE**: All spacing values MUST be divisible by 8 or 4.

**Allowed Values**:
- ✅ DO: Use 8, 16, 24, 32, 40, 48, 56, 64px
- ❌ DON'T: Use 25, 11, 7, 13, 15, 19px

**Tailwind Utilities**:
- Padding: p-2 (8px), p-4 (16px), p-6 (24px), p-8 (32px)
- Margin: m-2 (8px), m-4 (16px), m-6 (24px), m-8 (32px)
- Gap: gap-2 (8px), gap-4 (16px), gap-8 (32px)

**❌ FORBIDDEN**: Any spacing value not divisible by 4 or 8

---

### 3. 60/30/10 Color Rule

**STRICTLY ENFORCE**: Color distribution must follow this exact ratio.

- **60%: Neutral color** - `bg-background` (white/dark)
- **30%: Complementary color** - `text-foreground` (gray-900/gray-100)
- **10%: Accent color** - `bg-primary` (Blue #3B82F6)

**❌ FORBIDDEN**: Overusing accent colors (exceeding 10%)

---

### 4. Clean Visual Structure

- **Logical Grouping**: Related elements must be visually connected
- **Deliberate Spacing**: Must follow 8pt grid system
- **Alignment**: Elements must be properly aligned
- **Simplicity Over Flashiness**: Clarity first

---

## Color Variables (globals.css)

```css
:root {
  /* 60% - Neutral Background */
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  
  /* 30% - Complementary */
  --muted: oklch(0.961 0 0);
  --muted-foreground: oklch(0.478 0 0);
  
  /* 10% - Accent Brand (Blue) */
  --primary: oklch(0.549 0.175 252.417);
  --primary-foreground: oklch(0.985 0 0);
  
  /* Additional semantic colors */
  --secondary: oklch(0.961 0 0);
  --secondary-foreground: oklch(0.145 0 0);
  --accent: oklch(0.961 0 0);
  --accent-foreground: oklch(0.145 0 0);
  --destructive: oklch(0.577 0.245 27.325);
  --destructive-foreground: oklch(0.985 0 0);
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --muted: oklch(0.239 0 0);
  --muted-foreground: oklch(0.659 0 0);
  --primary: oklch(0.649 0.175 252.417);
  --primary-foreground: oklch(0.145 0 0);
  --secondary: oklch(0.239 0 0);
  --secondary-foreground: oklch(0.985 0 0);
  --accent: oklch(0.239 0 0);
  --accent-foreground: oklch(0.985 0 0);
  --destructive: oklch(0.477 0.245 27.325);
  --destructive-foreground: oklch(0.985 0 0);
}

@theme {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-destructive-foreground: var(--destructive-foreground);
}
```

---

## Example Component (Button with Design System)

```tsx
import { Button } from "@/components/ui/button"

export function ExampleComponent() {
  return (
    <div className="p-6 bg-background"> {/* 24px padding - divisible by 8 */}
      <h1 className="text-2xl font-semibold mb-4"> {/* Size 1, Semibold, 16px margin */}
        Welcome to TaskFlow
      </h1>
      <p className="text-base font-normal text-foreground mb-6"> {/* Size 3, Regular, 24px margin */}
        Manage your tasks efficiently with AI-powered workflows.
      </p>
      <div className="flex gap-4"> {/* 16px gap - divisible by 8 */}
        <Button className="bg-primary text-primary-foreground"> {/* 10% accent */}
          Get Started
        </Button>
        <Button variant="outline" className="text-foreground"> {/* 30% complementary */}
          Learn More
        </Button>
      </div>
    </div>
  )
}
```

---

## Code Review Checklist

**MANDATORY VALIDATION**: Every component/page must pass these checks.

- [x] Typography: Uses only 4 font sizes (text-2xl, text-lg, text-base, text-sm) and 2 weights (font-semibold, font-normal)
- [x] Spacing: All spacing values divisible by 8 or 4 (p-6=24px, mb-4=16px, gap-4=16px)
- [x] Colors: Follows 60/30/10 distribution (60% bg-background, 30% text-foreground, 10% bg-primary)
- [x] Structure: Elements logically grouped with consistent spacing
- [x] Uses OKLCH color variables from globals.css
- [x] shadcn/ui Button component used
- [x] Dark mode support included via .dark class
- [x] Accessibility: Buttons have proper contrast and keyboard navigation

**❌ REJECT IF ANY VIOLATIONS EXIST**

---

## Resources

- **shadcn/ui Documentation**: https://ui.shadcn.com
- **Tailwind CSS v4 Documentation**: https://tailwindcss.com/docs
- **Project Figma**: https://figma.com/file/taskflow-design-system

---

**Last Updated**: October 31, 2025
**Version**: 1.0.0
