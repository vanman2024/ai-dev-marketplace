#!/bin/bash

# init-shadcn.sh
# Initializes shadcn/ui component library for Next.js projects

set -e

echo "=========================================="
echo "shadcn/ui Initialization"
echo "=========================================="

# Check if we're in a Next.js project
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found. Are you in a Next.js project directory?"
  exit 1
fi

# Check if Tailwind is installed
if ! grep -q "tailwindcss" package.json; then
  echo "Warning: Tailwind CSS not detected in package.json"
  echo "shadcn/ui requires Tailwind CSS. Install it first or the init command will handle it."
  echo ""
fi

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
  INIT_CMD="pnpm dlx"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  INIT_CMD="npx"
elif [ -f "bun.lockb" ]; then
  PKG_MANAGER="bun"
  INIT_CMD="bunx"
else
  PKG_MANAGER="npm"
  INIT_CMD="npx"
fi

echo "Detected package manager: $PKG_MANAGER"
echo ""

# Run shadcn/ui init
echo "Running shadcn/ui initialization..."
echo "You will be prompted to configure:"
echo "  - TypeScript: Choose 'Yes' (recommended)"
echo "  - Style: Choose 'Default' or 'New York'"
echo "  - Base color: Choose your preferred neutral (Slate recommended)"
echo "  - CSS variables: Choose 'Yes' (recommended for theming)"
echo "  - Tailwind config: tailwind.config.ts"
echo "  - Components: @/components"
echo "  - Utils: @/lib/utils"
echo ""
echo "Starting in 3 seconds..."
sleep 3

$INIT_CMD shadcn@latest init

echo ""
echo "=========================================="
echo "✓ shadcn/ui initialization complete!"
echo "=========================================="
echo ""
echo "Files created/modified:"
echo "  - components.json (shadcn/ui configuration)"
echo "  - lib/utils.ts (utility functions)"
echo "  - app/globals.css (CSS variables and theme)"
echo "  - tailwind.config.ts (Tailwind configuration)"
echo ""
echo "Next steps:"
echo "1. Add components: $INIT_CMD shadcn@latest add button"
echo "2. Set up dark mode: bash scripts/setup-dark-mode.sh"
echo "3. Customize theme: Edit app/globals.css CSS variables"
echo ""
