#!/bin/bash
# setup-mdx.sh - Configure MDX support with plugins

set -e

echo "📝 Setting up MDX integration for Astro..."

# Check if we're in an Astro project
if [ ! -f "astro.config.mjs" ] && [ ! -f "astro.config.ts" ]; then
  echo "❌ Error: Not in an Astro project directory"
  exit 1
fi

# Install MDX and Astro MDX integration
echo "📦 Installing MDX dependencies..."
npm install @astrojs/mdx
npm install --save-dev remark-gfm rehype-slug rehype-autolink-headings

# Optional plugins
echo "📦 Installing optional MDX plugins..."
npm install --save-dev remark-toc rehype-external-links remark-smartypants

# Check if @astrojs/mdx is already in config
CONFIG_FILE="astro.config.mjs"
if [ -f "astro.config.ts" ]; then
  CONFIG_FILE="astro.config.ts"
fi

if grep -q "@astrojs/mdx" "$CONFIG_FILE"; then
  echo "✅ MDX integration already configured in $CONFIG_FILE"
else
  echo "⚙️  Adding MDX integration to $CONFIG_FILE..."
  echo ""
  echo "⚠️  Manual step required:"
  echo "   Add '@astrojs/mdx' to integrations array in $CONFIG_FILE"
  echo ""
  echo "   Example:"
  echo "   import mdx from '@astrojs/mdx';"
  echo "   import remarkGfm from 'remark-gfm';"
  echo "   import rehypeSlug from 'rehype-slug';"
  echo "   import rehypeAutolinkHeadings from 'rehype-autolink-headings';"
  echo ""
  echo "   export default defineConfig({"
  echo "     integrations: ["
  echo "       mdx({"
  echo "         remarkPlugins: [remarkGfm],"
  echo "         rehypePlugins: [rehypeSlug, rehypeAutolinkHeadings],"
  echo "         extendMarkdownConfig: true,"
  echo "       })"
  echo "     ]"
  echo "   });"
fi

# Create content directory structure
if [ ! -d "src/content" ]; then
  mkdir -p src/content
  echo "📁 Created src/content directory"
fi

# Create blog directory for MDX posts
if [ ! -d "src/content/blog" ]; then
  mkdir -p src/content/blog
  echo "📁 Created src/content/blog directory"
fi

# Create layouts directory for MDX layouts
if [ ! -d "src/layouts" ]; then
  mkdir -p src/layouts
  echo "📁 Created src/layouts directory"
fi

# Create a basic MDX layout template
cat > src/layouts/MdxLayout.astro << 'EOF'
---
interface Props {
  frontmatter: {
    title: string;
    description?: string;
    date?: string;
    author?: string;
  };
}

const { frontmatter } = Astro.props;
---

<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{frontmatter.title}</title>
    {frontmatter.description && (
      <meta name="description" content={frontmatter.description} />
    )}
  </head>
  <body>
    <article>
      <header>
        <h1>{frontmatter.title}</h1>
        {frontmatter.date && (
          <time datetime={frontmatter.date}>{frontmatter.date}</time>
        )}
        {frontmatter.author && <p>By {frontmatter.author}</p>}
      </header>
      <main>
        <slot />
      </main>
    </article>
  </body>
</html>
EOF

echo "📄 Created basic MDX layout: src/layouts/MdxLayout.astro"

# Create a sample MDX file
cat > src/content/blog/example.mdx << 'EOF'
---
title: "Example MDX Post"
description: "This is an example MDX post with React components"
date: "2024-01-01"
author: "Your Name"
layout: "@/layouts/MdxLayout.astro"
---

# Welcome to MDX

This is a sample MDX file that combines Markdown with React components.

## Features

- **GitHub Flavored Markdown** support
- Custom React components
- Syntax highlighting
- Auto-linked headings

## Using Components

You can import and use React components directly in MDX:

```tsx
import { Alert } from '@/components/Alert';

<Alert type="info">
  This is an alert component!
</Alert>
```

## Code Examples

```javascript
const greeting = "Hello, MDX!";
console.log(greeting);
```

---

Learn more about [MDX](https://mdxjs.com/).
EOF

echo "📄 Created example MDX file: src/content/blog/example.mdx"

echo ""
echo "✅ MDX integration setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Verify @astrojs/mdx is in integrations array"
echo "   2. Configure remark and rehype plugins"
echo "   3. Create MDX files in src/content/"
echo "   4. Import and use React components in MDX"
echo ""
echo "Example MDX file structure:"
echo "   src/content/blog/post.mdx"
echo "   src/layouts/MdxLayout.astro"
