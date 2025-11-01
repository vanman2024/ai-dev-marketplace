# tailwind-shadcn-setup

A comprehensive skill for setting up Tailwind CSS and shadcn/ui component library in Next.js projects.

## Overview

This skill provides automated setup scripts, configuration templates, and examples for integrating Tailwind CSS and shadcn/ui into Next.js applications. It handles installation, theming, dark mode configuration, and component integration following modern best practices.

## Features

- **Automated Installation**: Scripts for Tailwind CSS and shadcn/ui setup
- **Theme Configuration**: CSS variables-based theming with OKLCH color space
- **Dark Mode Support**: Class-based or system-based dark mode with next-themes
- **Component Templates**: Ready-to-use examples including theme toggle and forms
- **Design Tokens**: Comprehensive color system with semantic naming
- **Framework Support**: Works with both App Router and Pages Router

## Directory Structure

```
tailwind-shadcn-setup/
├── SKILL.md                    # Main skill instructions
├── README.md                   # This file
├── scripts/                    # Setup automation scripts
│   ├── install-tailwind.sh     # Tailwind CSS installation
│   ├── init-shadcn.sh          # shadcn/ui initialization
│   ├── setup-dark-mode.sh      # Dark mode configuration
│   └── setup-theme.sh          # Theme customization
├── templates/                  # Configuration templates
│   ├── globals.css             # CSS variables and theme definitions
│   ├── tailwind.config.ts      # Tailwind configuration
│   ├── theme-provider.tsx      # Theme context provider
│   ├── components.json         # shadcn/ui configuration
│   └── postcss.config.mjs      # PostCSS configuration
└── examples/                   # Component examples
    ├── theme-toggle.tsx        # Dark mode toggle component
    ├── theme-showcase.tsx      # Component showcase page
    ├── sample-form.tsx         # Form example with validation
    └── root-layout.tsx         # Root layout with theme provider
```

## Quick Start

### 1. Complete Setup (New Project)

```bash
# Navigate to your Next.js project
cd your-nextjs-project

# Install Tailwind CSS
bash ./skills/tailwind-shadcn-setup/scripts/install-tailwind.sh

# Initialize shadcn/ui
bash ./skills/tailwind-shadcn-setup/scripts/init-shadcn.sh

# Setup dark mode
bash ./skills/tailwind-shadcn-setup/scripts/setup-dark-mode.sh

# Customize theme (optional)
bash ./skills/tailwind-shadcn-setup/scripts/setup-theme.sh
```

### 2. Add Components

```bash
# Add common UI components
npx shadcn@latest add button card input form dialog

# Copy theme toggle
cp examples/theme-toggle.tsx components/theme-toggle.tsx
```

### 3. Update Root Layout

Copy the theme provider setup from `examples/root-layout.tsx` to your `app/layout.tsx`.

## Scripts Reference

### install-tailwind.sh

Installs Tailwind CSS, PostCSS, and Autoprefixer. Automatically detects:
- Package manager (npm, pnpm, yarn, bun)
- Project structure (App Router vs Pages Router)
- TypeScript support

**What it does:**
- Installs dependencies
- Creates/updates tailwind.config.ts
- Adds Tailwind directives to globals.css
- Configures PostCSS

### init-shadcn.sh

Initializes shadcn/ui component library.

**Interactive prompts:**
- TypeScript support
- Style preference (Default/New York)
- Base color palette
- CSS variables configuration
- Component and utils paths

**Creates:**
- components.json
- lib/utils.ts
- Updated globals.css with CSS variables
- Updated tailwind.config.ts

### setup-dark-mode.sh

Configures dark mode functionality.

**What it does:**
- Installs next-themes
- Creates ThemeProvider component
- Updates Tailwind config for class-based dark mode
- Provides root layout integration guide

### setup-theme.sh

Customizes theme colors and design tokens.

**Features:**
- Interactive base color selection (Slate, Gray, Zinc, Neutral, Stone)
- Updates components.json
- Validates CSS variable configuration
- Provides customization guidance

## Templates Reference

### globals.css

Complete CSS variable definitions for light and dark modes:
- Base colors (background, foreground)
- Semantic colors (primary, secondary, muted, accent, destructive)
- UI elements (card, popover, border, input, ring)
- Chart colors (5 data visualization colors)
- Sidebar navigation colors

Uses OKLCH color space for perceptual uniformity across themes.

### tailwind.config.ts

TypeScript Tailwind configuration with:
- Class-based dark mode
- Content paths for Next.js
- Extended color palette using CSS variables
- Border radius tokens
- tailwindcss-animate plugin

### theme-provider.tsx

Client component wrapping next-themes ThemeProvider:
- Supports class-based theme switching
- System preference detection
- Prevents hydration mismatch

### components.json

shadcn/ui configuration:
- Style and RSC settings
- Tailwind integration paths
- Component aliases
- CSS variables enabled

## Examples Reference

### theme-toggle.tsx

Dropdown menu for theme selection (Light/Dark/System):
- Uses shadcn/ui Button and DropdownMenu
- Animated icons with Lucide React
- Accessible with screen reader support

**Requirements:** Install dropdown-menu component first
```bash
npx shadcn@latest add dropdown-menu
```

### theme-showcase.tsx

Comprehensive component showcase demonstrating:
- All button variants and sizes
- Form components (Input, Label)
- Color palette visualization
- Typography styles
- Card layouts

Great for testing theme changes and component styling.

### sample-form.tsx

Production-ready form example with:
- react-hook-form integration
- Zod schema validation
- shadcn/ui Form components
- Form fields: Input, Textarea, Select
- Error handling and validation messages

**Requirements:**
```bash
npm install react-hook-form zod @hookform/resolvers
npx shadcn@latest add form input textarea select
```

### root-layout.tsx

Root layout template showing:
- Font configuration (Inter)
- ThemeProvider integration
- Metadata setup
- suppressHydrationWarning for theme

Copy this structure to your `app/layout.tsx`.

## Usage in Agents and Commands

This skill can be invoked by:
- `/nextjs-frontend:setup` command
- `frontend-setup` agent
- Any workflow requiring UI library setup

Example agent invocation:
```typescript
// Agent uses skill to set up Tailwind and shadcn/ui
Use the tailwind-shadcn-setup skill to configure the UI library.
```

## Best Practices

1. **Always use CSS variables**: Enable `cssVariables: true` in components.json for runtime theming
2. **Test both themes**: Verify components in light and dark modes
3. **Use semantic colors**: Prefer `bg-primary` over `bg-blue-500` for consistency
4. **Install only needed components**: shadcn/ui copies code, install selectively
5. **Customize thoughtfully**: Modify CSS variables, not Tailwind utilities directly

## Customization Guide

### Changing Base Colors

Edit `app/globals.css` CSS variables:

```css
:root {
  --primary: oklch(0.5 0.2 250);  /* Brand color */
  --primary-foreground: oklch(1 0 0);  /* Contrasting text */
}

.dark {
  --primary: oklch(0.7 0.15 250);  /* Lighter for dark mode */
  --primary-foreground: oklch(0.15 0.01 255);  /* Dark text */
}
```

### Adding Custom Colors

Define new variables and register with Tailwind:

```css
/* In globals.css */
:root {
  --brand: oklch(0.6 0.18 150);
}

@theme inline {
  --color-brand: var(--brand);
}
```

```typescript
// In tailwind.config.ts
extend: {
  colors: {
    brand: "hsl(var(--brand))",
  }
}
```

### Adjusting Border Radius

Modify `--radius` variable in globals.css:

```css
:root {
  --radius: 0.5rem;  /* 8px - default */
  --radius: 0.25rem; /* 4px - sharper */
  --radius: 1rem;    /* 16px - rounder */
}
```

## Troubleshooting

### Tailwind styles not applying

1. Check `tailwind.config.ts` content paths include your files
2. Verify `@tailwind` directives in globals.css
3. Restart dev server after config changes

### Dark mode not working

1. Ensure `darkMode: ["class"]` in tailwind.config.ts
2. Verify ThemeProvider in root layout
3. Check `suppressHydrationWarning` on `<html>` tag

### shadcn/ui components not found

1. Run `npx shadcn@latest init` first
2. Install specific components: `npx shadcn@latest add button`
3. Verify `@/components` alias in tsconfig.json

### Colors look different in dark mode

1. Ensure separate CSS variables for `.dark` class
2. Test contrast ratios for accessibility
3. Use OKLCH color space for perceptual consistency

## Requirements

- Next.js 13.4+ (App Router or Pages Router)
- React 18+
- Node.js 18.17+ or 20+
- TypeScript (recommended)
- Modern package manager (npm, pnpm, yarn, or bun)

## Dependencies Installed

- `tailwindcss` - Utility-first CSS framework
- `postcss` - CSS transformation tool
- `autoprefixer` - Vendor prefix automation
- `next-themes` - Theme management for Next.js
- `tailwindcss-animate` - Animation utilities
- `class-variance-authority` - Component variants (via shadcn/ui)
- `clsx` - Conditional classNames (via shadcn/ui)
- `tailwind-merge` - Merge Tailwind classes (via shadcn/ui)

## Resources

- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [shadcn/ui Documentation](https://ui.shadcn.com)
- [next-themes Documentation](https://github.com/pacocoursey/next-themes)
- [OKLCH Color Picker](https://oklch.com)

## Plugin

Part of the **nextjs-frontend** plugin ecosystem.

**Version:** 1.0.0
**Category:** UI & Styling
**Type:** Setup & Configuration
