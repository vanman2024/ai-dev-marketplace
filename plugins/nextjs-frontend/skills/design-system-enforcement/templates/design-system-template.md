# shadcn/ui with Tailwind v4 Design System Guidelines

**MANDATORY REFERENCE**: All agents MUST read and strictly adhere to these guidelines before creating any components, pages, or UI elements.

---

## Project Configuration

**Project Name**: {{PROJECT_NAME}}
**Primary Brand Color**: {{BRAND_COLOR}}
**Color Scheme**: {{COLOR_SCHEME}}
**Typography Scale**: 4 sizes, 2 weights (ENFORCED)
**Spacing Unit**: 8pt grid (ENFORCED)

---

## Core Design Principles

### 1. Typography System: 4 Sizes, 2 Weights

**STRICTLY ENFORCE**: Only 4 font sizes and 2 font weights allowed.

- **4 Font Sizes Only**:
  - Size 1: {{FONT_SIZE_1}} - Large headings
  - Size 2: {{FONT_SIZE_2}} - Subheadings/Important content
  - Size 3: {{FONT_SIZE_3}} - Body text
  - Size 4: {{FONT_SIZE_4}} - Small text/labels

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

- **60%: Neutral color** - `bg-background`
- **30%: Complementary color** - `text-foreground`
- **10%: Accent color** - `bg-primary` ({{BRAND_COLOR}})

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
  --background: {{BACKGROUND_OKLCH}};
  --foreground: {{FOREGROUND_OKLCH}};
  
  /* 30% - Complementary */
  --muted: {{MUTED_OKLCH}};
  --muted-foreground: {{MUTED_FOREGROUND_OKLCH}};
  
  /* 10% - Accent Brand */
  --primary: {{PRIMARY_OKLCH}};
  --primary-foreground: {{PRIMARY_FOREGROUND_OKLCH}};
}

.dark {
  --background: {{DARK_BACKGROUND_OKLCH}};
  --foreground: {{DARK_FOREGROUND_OKLCH}};
  --primary: {{DARK_PRIMARY_OKLCH}};
  --primary-foreground: {{DARK_PRIMARY_FOREGROUND_OKLCH}};
}

@theme {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
}
```

---

## Code Review Checklist

**MANDATORY VALIDATION**: Every component/page must pass these checks.

- [ ] Typography: Uses only 4 font sizes and 2 font weights
- [ ] Spacing: All spacing values divisible by 8 or 4
- [ ] Colors: Follows 60/30/10 distribution
- [ ] Structure: Elements logically grouped with consistent spacing
- [ ] Uses OKLCH color variables
- [ ] shadcn/ui components only
- [ ] Dark mode support included
- [ ] Accessibility standards maintained

**❌ REJECT IF ANY VIOLATIONS EXIST**

---

## Resources

- **shadcn/ui Documentation**: https://ui.shadcn.com
- **Tailwind CSS v4 Documentation**: https://tailwindcss.com/docs
- **Project Figma**: {{FIGMA_URL}}

---

**Last Updated**: {{LAST_UPDATED}}
**Version**: 1.0.0
