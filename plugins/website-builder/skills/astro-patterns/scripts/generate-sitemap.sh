#!/bin/bash
# Generate sitemap configuration for Astro project

set -e

PROJECT_ROOT="${1:-.}"

echo "Setting up sitemap for Astro project..."

# Check if @astrojs/sitemap is installed
if [ -f "$PROJECT_ROOT/package.json" ]; then
  if ! grep -q '"@astrojs/sitemap"' "$PROJECT_ROOT/package.json"; then
    echo "Installing @astrojs/sitemap..."
    cd "$PROJECT_ROOT"
    npm install @astrojs/sitemap
    cd - > /dev/null
  else
    echo "✅ @astrojs/sitemap already installed"
  fi
else
  echo "❌ No package.json found"
  exit 1
fi

# Find Astro config file
CONFIG_FILE=""
if [ -f "$PROJECT_ROOT/astro.config.ts" ]; then
  CONFIG_FILE="$PROJECT_ROOT/astro.config.ts"
elif [ -f "$PROJECT_ROOT/astro.config.mjs" ]; then
  CONFIG_FILE="$PROJECT_ROOT/astro.config.mjs"
else
  echo "❌ No Astro config file found"
  exit 1
fi

# Check if sitemap is already configured
if grep -q "@astrojs/sitemap" "$CONFIG_FILE"; then
  echo "✅ Sitemap integration already configured in $CONFIG_FILE"
else
  echo "⚠️  Sitemap integration not found in config"
  echo ""
  echo "Add this to your $CONFIG_FILE:"
  echo ""
  cat <<'EOF'
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://your-domain.com', // Required for sitemap
  integrations: [
    sitemap({
      filter: (page) => !page.includes('/admin/'),
      customPages: ['https://your-domain.com/custom-page'],
    }),
  ],
});
EOF
  echo ""
fi

# Create robots.txt if it doesn't exist
if [ ! -f "$PROJECT_ROOT/public/robots.txt" ]; then
  mkdir -p "$PROJECT_ROOT/public"
  cat > "$PROJECT_ROOT/public/robots.txt" <<'EOF'
User-agent: *
Allow: /

Sitemap: https://your-domain.com/sitemap-index.xml
EOF
  echo "✅ Created public/robots.txt"
  echo "📝 TODO: Update domain in robots.txt"
else
  echo "✅ robots.txt already exists"

  # Check if sitemap is referenced
  if ! grep -q "Sitemap:" "$PROJECT_ROOT/public/robots.txt"; then
    echo "⚠️  No sitemap reference found in robots.txt"
    echo "   Add: Sitemap: https://your-domain.com/sitemap-index.xml"
  fi
fi

echo ""
echo "Sitemap setup complete!"
echo ""
echo "Next steps:"
echo "1. Set the 'site' field in astro.config to your domain"
echo "2. Add sitemap() to integrations array"
echo "3. Update robots.txt with your domain"
echo "4. Run 'npm run build' to generate sitemap"
echo "5. Submit sitemap to Google Search Console"
