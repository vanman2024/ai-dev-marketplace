#!/bin/bash
# setup-react.sh - Initialize React integration in Astro project

set -e

echo "🚀 Setting up React integration for Astro..."

# Check if we're in an Astro project
if [ ! -f "astro.config.mjs" ] && [ ! -f "astro.config.ts" ]; then
  echo "❌ Error: Not in an Astro project directory"
  echo "   astro.config.mjs or astro.config.ts not found"
  exit 1
fi

# Check if package.json exists
if [ ! -f "package.json" ]; then
  echo "❌ Error: package.json not found"
  exit 1
fi

# Install React and Astro React integration
echo "📦 Installing React dependencies..."
npm install react react-dom
npm install --save-dev @astrojs/react @types/react @types/react-dom

# Check if @astrojs/react is already in astro config
CONFIG_FILE="astro.config.mjs"
if [ -f "astro.config.ts" ]; then
  CONFIG_FILE="astro.config.ts"
fi

if grep -q "@astrojs/react" "$CONFIG_FILE"; then
  echo "✅ React integration already configured in $CONFIG_FILE"
else
  echo "⚙️  Adding React integration to $CONFIG_FILE..."
  echo ""
  echo "⚠️  Manual step required:"
  echo "   Add '@astrojs/react' to integrations array in $CONFIG_FILE"
  echo ""
  echo "   Example:"
  echo "   import react from '@astrojs/react';"
  echo "   export default defineConfig({"
  echo "     integrations: [react()]"
  echo "   });"
fi

# Create components directory if it doesn't exist
if [ ! -d "src/components" ]; then
  mkdir -p src/components
  echo "📁 Created src/components directory"
fi

# Create React components subdirectory
if [ ! -d "src/components/react" ]; then
  mkdir -p src/components/react
  echo "📁 Created src/components/react directory"
fi

# Update tsconfig.json for JSX support
if [ -f "tsconfig.json" ]; then
  if ! grep -q '"jsx"' tsconfig.json; then
    echo "⚙️  Updating tsconfig.json for JSX support..."
    echo ""
    echo "⚠️  Manual step required:"
    echo "   Add JSX compiler options to tsconfig.json:"
    echo '   "compilerOptions": {'
    echo '     "jsx": "react-jsx",'
    echo '     "jsxImportSource": "react"'
    echo '   }'
  else
    echo "✅ tsconfig.json already configured for JSX"
  fi
fi

echo ""
echo "✅ React integration setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Verify @astrojs/react is in integrations array"
echo "   2. Run 'npm run dev' to test the setup"
echo "   3. Create React components in src/components/react/"
echo "   4. Use client:* directives for hydration"
echo ""
echo "Example usage in .astro file:"
echo "   import MyComponent from '@/components/react/MyComponent';"
echo "   <MyComponent client:load />"
