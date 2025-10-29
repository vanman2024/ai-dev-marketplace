#!/bin/bash
# Apply build optimization configurations to Astro project

set -e

PROJECT_ROOT="${1:-.}"

echo "Applying Astro build optimizations..."

# Check for Astro config
CONFIG_FILE=""
if [ -f "$PROJECT_ROOT/astro.config.ts" ]; then
  CONFIG_FILE="$PROJECT_ROOT/astro.config.ts"
elif [ -f "$PROJECT_ROOT/astro.config.mjs" ]; then
  CONFIG_FILE="$PROJECT_ROOT/astro.config.mjs"
else
  echo "❌ No Astro config file found"
  exit 1
fi

echo "Found config: $CONFIG_FILE"

# Check if optimizations are already applied
if grep -q "vite.*build.*rollupOptions" "$CONFIG_FILE"; then
  echo "⚠️  Build optimizations appear to be already configured"
  echo "Review $CONFIG_FILE manually to ensure proper configuration"
else
  echo "💡 To optimize builds, consider adding to your Astro config:"
  echo ""
  cat <<'EOF'
export default defineConfig({
  // ... your existing config

  vite: {
    build: {
      rollupOptions: {
        output: {
          manualChunks: {
            // Split vendor chunks
            'react-vendor': ['react', 'react-dom'],
          },
        },
      },
    },
  },

  // Enable compression
  compressHTML: true,

  // Build settings
  build: {
    inlineStylesheets: 'auto',
  },
});
EOF
fi

# Check for image optimization
if [ -f "$PROJECT_ROOT/package.json" ]; then
  if grep -q '"@astrojs/image"' "$PROJECT_ROOT/package.json" || grep -q '"astro:assets"' "$CONFIG_FILE"; then
    echo "✅ Image optimization configured"
  else
    echo "💡 Consider enabling Astro's built-in image optimization"
    echo "   Use the <Image> component from 'astro:assets'"
  fi
fi

# Check for sitemap integration
if grep -q "@astrojs/sitemap" "$CONFIG_FILE"; then
  echo "✅ Sitemap integration enabled"
else
  echo "💡 Consider adding @astrojs/sitemap for SEO"
  echo "   npm install @astrojs/sitemap"
fi

# Create .env.example if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.env.example" ]; then
  cat > "$PROJECT_ROOT/.env.example" <<'EOF'
# Public environment variables (accessible in browser)
PUBLIC_SITE_URL=https://example.com

# Private environment variables (server-side only)
# API_KEY=your_api_key_here
EOF
  echo "✅ Created .env.example"
fi

# Create or update .gitignore
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
  if ! grep -q "^dist/$" "$PROJECT_ROOT/.gitignore"; then
    echo "dist/" >> "$PROJECT_ROOT/.gitignore"
    echo ".env" >> "$PROJECT_ROOT/.gitignore"
    echo "✅ Updated .gitignore"
  fi
else
  cat > "$PROJECT_ROOT/.gitignore" <<'EOF'
# Build output
dist/
.astro/

# Dependencies
node_modules/

# Environment
.env
.env.local

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
EOF
  echo "✅ Created .gitignore"
fi

echo ""
echo "Build optimization check complete!"
echo ""
echo "Recommended next steps:"
echo "1. Review and update astro.config with optimization settings"
echo "2. Run 'npm run build' to test build process"
echo "3. Analyze bundle sizes with build output"
echo "4. Consider adding @astrojs/sitemap for SEO"
