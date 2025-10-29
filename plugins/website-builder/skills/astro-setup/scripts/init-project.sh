#!/usr/bin/env bash
# init-project.sh - Initialize Astro project with AI Tech Stack 1 integrations
# Usage: bash init-project.sh <project-name> [--template=blog|marketing|docs]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
PROJECT_NAME="${1:-my-astro-site}"
TEMPLATE="${2:-blog}" # Default to blog template

# Extract template from --template= flag if provided
if [[ "$TEMPLATE" == --template=* ]]; then
    TEMPLATE="${TEMPLATE#*=}"
fi

echo -e "${BLUE}🚀 Initializing Astro Project: $PROJECT_NAME${NC}"
echo -e "${BLUE}📦 Template: $TEMPLATE${NC}"
echo ""

# Step 1: Run prerequisite checks
echo "[1/7] Checking prerequisites..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! bash "$SCRIPT_DIR/check-prerequisites.sh"; then
    echo -e "${RED}❌ Prerequisites check failed${NC}"
    exit 1
fi
echo ""

# Step 2: Create Astro project
echo "[2/7] Creating Astro project..."
echo -e "${YELLOW}Running: npm create astro@latest $PROJECT_NAME${NC}"

# Use npm create astro with non-interactive flags
npm create astro@latest "$PROJECT_NAME" -- \
    --template blog \
    --install \
    --git \
    --typescript strictest \
    --no-dry-run \
    --yes

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create Astro project${NC}"
    exit 1
fi

cd "$PROJECT_NAME"
echo -e "${GREEN}✅ Astro project created${NC}"
echo ""

# Step 3: Install AI Tech Stack 1 integrations
echo "[3/7] Installing Astro integrations..."
echo -e "${YELLOW}Installing: React, MDX, Tailwind, Sitemap${NC}"

npx astro add react mdx tailwind --yes
npm install @astrojs/sitemap

echo -e "${GREEN}✅ Integrations installed${NC}"
echo ""

# Step 4: Install additional dependencies
echo "[4/7] Installing AI Tech Stack dependencies..."
echo -e "${YELLOW}Installing: Supabase, Zod, date-fns${NC}"

npm install @supabase/supabase-js zod date-fns

echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 5: Create directory structure
echo "[5/7] Setting up project structure..."

# Create additional directories
mkdir -p src/lib
mkdir -p src/content/blog
mkdir -p src/content/config.ts
mkdir -p public/images

# Create lib files
cat > src/lib/utils.ts << 'EOF'
/**
 * Utility functions for the project
 */

export function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
EOF

# Create Supabase client
cat > src/lib/supabase.ts << 'EOF'
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY || '';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
EOF

# Create SEO component
cat > src/components/SEO.astro << 'EOF'
---
interface Props {
  title: string;
  description: string;
  image?: string;
  canonical?: string;
}

const { title, description, image, canonical } = Astro.props;
const siteUrl = Astro.site || 'https://example.com';
const ogImage = image || `${siteUrl}/og-image.png`;
const canonicalURL = canonical || new URL(Astro.url.pathname, siteUrl);
---

<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>{title}</title>
<meta name="description" content={description} />
<link rel="canonical" href={canonicalURL} />

<!-- Open Graph / Facebook -->
<meta property="og:type" content="website" />
<meta property="og:url" content={canonicalURL} />
<meta property="og:title" content={title} />
<meta property="og:description" content={description} />
<meta property="og:image" content={ogImage} />

<!-- Twitter -->
<meta property="twitter:card" content="summary_large_image" />
<meta property="twitter:url" content={canonicalURL} />
<meta property="twitter:title" content={title} />
<meta property="twitter:description" content={description} />
<meta property="twitter:image" content={ogImage} />
EOF

echo -e "${GREEN}✅ Project structure created${NC}"
echo ""

# Step 6: Setup environment variables
echo "[6/7] Creating environment files..."

cat > .env.example << 'EOF'
# Supabase Configuration
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here

# AI Services (for content generation)
GOOGLE_API_KEY=your-google-api-key
ANTHROPIC_API_KEY=your-anthropic-key

# Site Configuration
PUBLIC_SITE_URL=http://localhost:4321
EOF

# Create actual .env from .env.example
cp .env.example .env

# Add .env to .gitignore if not already there
if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
    echo ".env" >> .gitignore
fi

echo -e "${GREEN}✅ Environment files created${NC}"
echo ""

# Step 7: Update astro.config.mjs with sitemap
echo "[7/7] Updating Astro configuration..."

# Backup original config
cp astro.config.mjs astro.config.mjs.backup

# Update config to include sitemap
cat > astro.config.mjs << 'EOF'
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import mdx from '@astrojs/mdx';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://example.com', // Update with your actual domain
  integrations: [
    react(),
    mdx(),
    tailwind({
      applyBaseStyles: false,
    }),
    sitemap(),
  ],
  output: 'static',
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      wrap: true,
    },
  },
});
EOF

echo -e "${GREEN}✅ Configuration updated${NC}"
echo ""

# Success summary
echo "========================================="
echo -e "${GREEN}✅ Project initialized successfully!${NC}"
echo "========================================="
echo ""
echo "📁 Project: $PROJECT_NAME"
echo "📦 Template: $TEMPLATE"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. Update .env with your API keys"
echo "  3. npm run dev (start development server)"
echo "  4. npm run build (build for production)"
echo ""
echo "AI Tech Stack 1 integrations installed:"
echo "  ✓ Astro (static site generator)"
echo "  ✓ React (UI components)"
echo "  ✓ MDX (enhanced markdown)"
echo "  ✓ Tailwind CSS (styling)"
echo "  ✓ Sitemap (SEO)"
echo "  ✓ Supabase client (database)"
echo ""
echo -e "${BLUE}Happy building! 🚀${NC}"
echo ""

exit 0
