#!/bin/bash
# Scaffold component directory structure following best practices

set -e

PROJECT_ROOT="${1:-.}"

echo "Setting up Astro component architecture..."

# Create component directory structure
mkdir -p "$PROJECT_ROOT/src/components/common"
mkdir -p "$PROJECT_ROOT/src/components/layout"
mkdir -p "$PROJECT_ROOT/src/components/ui"
mkdir -p "$PROJECT_ROOT/src/components/features"

# Create example common components
if [ ! -f "$PROJECT_ROOT/src/components/common/Button.astro" ]; then
  cat > "$PROJECT_ROOT/src/components/common/Button.astro" <<'EOF'
---
export interface Props {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  href?: string;
  type?: 'button' | 'submit' | 'reset';
}

const {
  variant = 'primary',
  size = 'md',
  href,
  type = 'button'
} = Astro.props;

const Element = href ? 'a' : 'button';
---

<Element
  class={`btn btn-${variant} btn-${size}`}
  href={href}
  type={!href ? type : undefined}
>
  <slot />
</Element>

<style>
  .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.375rem;
    font-weight: 500;
    transition: all 0.2s;
  }

  .btn-sm { padding: 0.5rem 1rem; font-size: 0.875rem; }
  .btn-md { padding: 0.75rem 1.5rem; font-size: 1rem; }
  .btn-lg { padding: 1rem 2rem; font-size: 1.125rem; }

  .btn-primary {
    background: #3b82f6;
    color: white;
  }

  .btn-secondary {
    background: #64748b;
    color: white;
  }

  .btn-ghost {
    background: transparent;
    color: #3b82f6;
  }
</style>
EOF
  echo "Created: src/components/common/Button.astro"
fi

if [ ! -f "$PROJECT_ROOT/src/components/common/Card.astro" ]; then
  cat > "$PROJECT_ROOT/src/components/common/Card.astro" <<'EOF'
---
export interface Props {
  title?: string;
  description?: string;
  variant?: 'default' | 'bordered' | 'elevated';
}

const {
  title,
  description,
  variant = 'default'
} = Astro.props;
---

<div class={`card card-${variant}`}>
  {title && <h3 class="card-title">{title}</h3>}
  {description && <p class="card-description">{description}</p>}
  <div class="card-content">
    <slot />
  </div>
</div>

<style>
  .card {
    padding: 1.5rem;
    border-radius: 0.5rem;
  }

  .card-default {
    background: white;
  }

  .card-bordered {
    background: white;
    border: 1px solid #e2e8f0;
  }

  .card-elevated {
    background: white;
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  }

  .card-title {
    margin: 0 0 0.5rem 0;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .card-description {
    margin: 0 0 1rem 0;
    color: #64748b;
  }
</style>
EOF
  echo "Created: src/components/common/Card.astro"
fi

# Create layout components
if [ ! -f "$PROJECT_ROOT/src/components/layout/Header.astro" ]; then
  cat > "$PROJECT_ROOT/src/components/layout/Header.astro" <<'EOF'
---
// Header component with navigation
---

<header class="site-header">
  <div class="container">
    <a href="/" class="logo">Site Name</a>
    <nav class="nav">
      <a href="/">Home</a>
      <a href="/blog">Blog</a>
      <a href="/about">About</a>
    </nav>
  </div>
</header>

<style>
  .site-header {
    padding: 1rem 0;
    border-bottom: 1px solid #e2e8f0;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .logo {
    font-size: 1.25rem;
    font-weight: 700;
    text-decoration: none;
  }

  .nav {
    display: flex;
    gap: 1.5rem;
  }

  .nav a {
    text-decoration: none;
    color: #64748b;
    transition: color 0.2s;
  }

  .nav a:hover {
    color: #0f172a;
  }
</style>
EOF
  echo "Created: src/components/layout/Header.astro"
fi

if [ ! -f "$PROJECT_ROOT/src/components/layout/Footer.astro" ]; then
  cat > "$PROJECT_ROOT/src/components/layout/Footer.astro" <<'EOF'
---
// Footer component
---

<footer class="site-footer">
  <div class="container">
    <p>&copy; {new Date().getFullYear()} Site Name. All rights reserved.</p>
  </div>
</footer>

<style>
  .site-footer {
    margin-top: 4rem;
    padding: 2rem 0;
    border-top: 1px solid #e2e8f0;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1rem;
    text-align: center;
    color: #64748b;
  }
</style>
EOF
  echo "Created: src/components/layout/Footer.astro"
fi

# Create component index
cat > "$PROJECT_ROOT/src/components/README.md" <<'EOF'
# Component Architecture

## Directory Structure

- `common/` - Reusable UI components (Button, Card, Input, etc.)
- `layout/` - Layout components (Header, Footer, Sidebar, etc.)
- `ui/` - Complex UI components (Modal, Dropdown, Tabs, etc.)
- `features/` - Feature-specific components (BlogPostCard, UserProfile, etc.)

## Naming Conventions

- Use PascalCase for component files: `Button.astro`
- Use kebab-case for component directories: `user-profile/`
- Export TypeScript interfaces for props

## Best Practices

1. Keep components focused and single-purpose
2. Use TypeScript interfaces for type safety
3. Leverage slots for composition
4. Fetch data in frontmatter, not in markup
5. Use CSS modules or scoped styles
EOF

echo "Component architecture setup complete!"
echo ""
echo "Created directories:"
echo "  - src/components/common/"
echo "  - src/components/layout/"
echo "  - src/components/ui/"
echo "  - src/components/features/"
echo ""
echo "Created example components:"
echo "  - Button.astro"
echo "  - Card.astro"
echo "  - Header.astro"
echo "  - Footer.astro"
