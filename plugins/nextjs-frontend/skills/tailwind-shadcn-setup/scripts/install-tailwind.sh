#!/bin/bash

# install-tailwind.sh
# Installs and configures Tailwind CSS for Next.js projects

set -e

echo "=========================================="
echo "Tailwind CSS Installation for Next.js"
echo "=========================================="

# Check if we're in a Next.js project
if [ ! -f "package.json" ]; then
  echo "Error: package.json not found. Are you in a Next.js project directory?"
  exit 1
fi

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
  INSTALL_CMD="pnpm add -D"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  INSTALL_CMD="yarn add -D"
elif [ -f "bun.lockb" ]; then
  PKG_MANAGER="bun"
  INSTALL_CMD="bun add -D"
else
  PKG_MANAGER="npm"
  INSTALL_CMD="npm install -D"
fi

echo "Detected package manager: $PKG_MANAGER"

# Install Tailwind CSS and dependencies
echo ""
echo "Installing Tailwind CSS, PostCSS, and Autoprefixer..."
$INSTALL_CMD tailwindcss postcss autoprefixer

# Initialize Tailwind config
echo ""
echo "Initializing Tailwind configuration..."
npx tailwindcss init -p

# Detect project structure (App Router vs Pages Router)
if [ -d "app" ]; then
  PROJECT_TYPE="app"
  CSS_FILE="app/globals.css"
  echo "Detected: Next.js App Router"
elif [ -d "src/app" ]; then
  PROJECT_TYPE="src/app"
  CSS_FILE="src/app/globals.css"
  echo "Detected: Next.js App Router (src directory)"
elif [ -d "pages" ]; then
  PROJECT_TYPE="pages"
  CSS_FILE="styles/globals.css"
  echo "Detected: Next.js Pages Router"
elif [ -d "src/pages" ]; then
  PROJECT_TYPE="src/pages"
  CSS_FILE="src/styles/globals.css"
  echo "Detected: Next.js Pages Router (src directory)"
else
  echo "Warning: Could not detect Next.js structure. Assuming App Router."
  PROJECT_TYPE="app"
  CSS_FILE="app/globals.css"
fi

# Update tailwind.config.js to TypeScript if project uses TypeScript
if [ -f "tsconfig.json" ]; then
  echo ""
  echo "Converting tailwind.config.js to TypeScript..."
  mv tailwind.config.js tailwind.config.ts

  # Create TypeScript version
  cat > tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss"

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
export default config
EOF
fi

# Add Tailwind directives to CSS file
echo ""
echo "Adding Tailwind directives to $CSS_FILE..."

if [ ! -f "$CSS_FILE" ]; then
  # Create CSS file if it doesn't exist
  mkdir -p "$(dirname "$CSS_FILE")"
  touch "$CSS_FILE"
fi

# Check if Tailwind directives already exist
if ! grep -q "@tailwind base;" "$CSS_FILE"; then
  # Prepend Tailwind directives
  echo -e "@tailwind base;\n@tailwind components;\n@tailwind utilities;\n\n$(cat "$CSS_FILE")" > "$CSS_FILE"
  echo "✓ Tailwind directives added to $CSS_FILE"
else
  echo "✓ Tailwind directives already present in $CSS_FILE"
fi

# Update postcss.config.mjs to use proper syntax
echo ""
echo "Configuring PostCSS..."
cat > postcss.config.mjs << 'EOF'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}

export default config
EOF

echo ""
echo "=========================================="
echo "✓ Tailwind CSS installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run your development server: $PKG_MANAGER dev"
echo "2. Start using Tailwind classes in your components"
echo "3. Consider installing shadcn/ui: npx shadcn@latest init"
echo ""
