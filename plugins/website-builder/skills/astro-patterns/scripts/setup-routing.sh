#!/bin/bash
# Initialize routing structure and conventions for Astro project

set -e

PROJECT_ROOT="${1:-.}"

echo "Setting up Astro routing structure..."

# Create pages directory structure
mkdir -p "$PROJECT_ROOT/src/pages"
mkdir -p "$PROJECT_ROOT/src/pages/api"
mkdir -p "$PROJECT_ROOT/src/pages/blog"

# Create basic routing files if they don't exist
if [ ! -f "$PROJECT_ROOT/src/pages/index.astro" ]; then
  cat > "$PROJECT_ROOT/src/pages/index.astro" <<'EOF'
---
import Layout from '@/layouts/Layout.astro';
---

<Layout title="Home">
  <h1>Welcome</h1>
</Layout>
EOF
  echo "Created: src/pages/index.astro"
fi

if [ ! -f "$PROJECT_ROOT/src/pages/404.astro" ]; then
  cat > "$PROJECT_ROOT/src/pages/404.astro" <<'EOF'
---
import Layout from '@/layouts/Layout.astro';
---

<Layout title="404 - Page Not Found">
  <div class="error-page">
    <h1>404</h1>
    <p>Page not found</p>
    <a href="/">Go home</a>
  </div>
</Layout>
EOF
  echo "Created: src/pages/404.astro"
fi

# Create middleware template
if [ ! -f "$PROJECT_ROOT/src/middleware.ts" ]; then
  cat > "$PROJECT_ROOT/src/middleware.ts" <<'EOF'
import { defineMiddleware } from 'astro:middleware';

export const onRequest = defineMiddleware(async (context, next) => {
  // Add custom middleware logic here
  // Example: logging, auth checks, redirects

  return next();
});
EOF
  echo "Created: src/middleware.ts"
fi

# Create redirects configuration
if [ ! -f "$PROJECT_ROOT/src/config/redirects.ts" ]; then
  mkdir -p "$PROJECT_ROOT/src/config"
  cat > "$PROJECT_ROOT/src/config/redirects.ts" <<'EOF'
export const redirects = {
  '/old-path': '/new-path',
  '/legacy/*': '/modern/*',
};
EOF
  echo "Created: src/config/redirects.ts"
fi

echo "Routing structure setup complete!"
echo ""
echo "Created directories:"
echo "  - src/pages/"
echo "  - src/pages/api/"
echo "  - src/pages/blog/"
echo ""
echo "Created files:"
echo "  - src/pages/index.astro (if not exists)"
echo "  - src/pages/404.astro (if not exists)"
echo "  - src/middleware.ts (if not exists)"
echo "  - src/config/redirects.ts (if not exists)"
