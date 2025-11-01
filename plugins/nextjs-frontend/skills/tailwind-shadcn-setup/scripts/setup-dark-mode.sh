#!/bin/bash

# setup-dark-mode.sh
# Configures dark mode for shadcn/ui components

set -e

echo "=========================================="
echo "Dark Mode Setup for shadcn/ui"
echo "=========================================="

# Check if we're in a Next.js project
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found. Are you in a Next.js project directory?"
  exit 1
fi

# Check if shadcn/ui is initialized
if [ ! -f "components.json" ]; then
  echo "Error: components.json not found. Run 'npx shadcn@latest init' first."
  exit 1
fi

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
  INSTALL_CMD="pnpm add"
  RUN_CMD="pnpm dlx"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  INSTALL_CMD="yarn add"
  RUN_CMD="npx"
elif [ -f "bun.lockb" ]; then
  PKG_MANAGER="bun"
  INSTALL_CMD="bun add"
  RUN_CMD="bunx"
else
  PKG_MANAGER="npm"
  INSTALL_CMD="npm install"
  RUN_CMD="npx"
fi

# Install next-themes if not already installed
echo ""
echo "Installing next-themes package..."
if ! grep -q "next-themes" package.json; then
  $INSTALL_CMD next-themes
  echo "✓ next-themes installed"
else
  echo "✓ next-themes already installed"
fi

# Detect project structure
if [ -d "app" ]; then
  PROJECT_DIR="app"
elif [ -d "src/app" ]; then
  PROJECT_DIR="src/app"
else
  echo "Error: Could not detect App Router structure."
  exit 1
fi

# Create components directory if it doesn't exist
mkdir -p components

# Create theme provider component
echo ""
echo "Creating theme provider component..."
cat > components/theme-provider.tsx << 'EOF'
"use client"

import * as React from "react"
import { ThemeProvider as NextThemesProvider } from "next-themes"
import { type ThemeProviderProps } from "next-themes/dist/types"

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}
EOF

echo "✓ Created components/theme-provider.tsx"

# Update tailwind.config.ts to use class-based dark mode
echo ""
echo "Configuring Tailwind for class-based dark mode..."

if [ -f "tailwind.config.ts" ]; then
  # Check if darkMode is already configured
  if ! grep -q "darkMode:" tailwind.config.ts; then
    # Add darkMode after the config declaration
    sed -i '/const config.*Config.*{/a \  darkMode: ["class"],' tailwind.config.ts
    echo "✓ Updated tailwind.config.ts with darkMode: ['class']"
  else
    echo "✓ darkMode already configured in tailwind.config.ts"
  fi
elif [ -f "tailwind.config.js" ]; then
  if ! grep -q "darkMode:" tailwind.config.js; then
    sed -i '/module.exports.*{/a \  darkMode: ["class"],' tailwind.config.js
    echo "✓ Updated tailwind.config.js with darkMode: ['class']"
  else
    echo "✓ darkMode already configured in tailwind.config.js"
  fi
fi

# Create or update root layout
echo ""
echo "Please add the ThemeProvider to your root layout:"
echo ""
echo "In $PROJECT_DIR/layout.tsx, wrap your children with <ThemeProvider>:"
echo ""
cat << 'EOF'
import { ThemeProvider } from "@/components/theme-provider"

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
EOF

echo ""
echo "=========================================="
echo "✓ Dark mode setup complete!"
echo "=========================================="
echo ""
echo "What was configured:"
echo "  - Installed next-themes package"
echo "  - Created components/theme-provider.tsx"
echo "  - Configured Tailwind for class-based dark mode"
echo ""
echo "Next steps:"
echo "1. Update your root layout ($PROJECT_DIR/layout.tsx) with ThemeProvider (see above)"
echo "2. Add theme toggle: $RUN_CMD shadcn@latest add dropdown-menu"
echo "3. Copy theme toggle component from examples/theme-toggle.tsx"
echo "4. Test dark mode by toggling in your UI"
echo ""
echo "Theme options:"
echo "  - 'light': Force light mode"
echo "  - 'dark': Force dark mode"
echo "  - 'system': Follow system preference (default)"
echo ""
