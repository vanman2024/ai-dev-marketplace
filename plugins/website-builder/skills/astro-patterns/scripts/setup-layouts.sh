#!/bin/bash
# Create layout hierarchy for Astro project

set -e

PROJECT_ROOT="${1:-.}"

echo "Setting up Astro layout system..."

# Create layouts directory
mkdir -p "$PROJECT_ROOT/src/layouts"

# Create base layout
if [ ! -f "$PROJECT_ROOT/src/layouts/Layout.astro" ]; then
  cat > "$PROJECT_ROOT/src/layouts/Layout.astro" <<'EOF'
---
import Header from '@/components/layout/Header.astro';
import Footer from '@/components/layout/Footer.astro';

export interface Props {
  title: string;
  description?: string;
  image?: string;
}

const {
  title,
  description = 'Default site description',
  image = '/og-image.jpg'
} = Astro.props;

const canonicalURL = new URL(Astro.url.pathname, Astro.site);
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="canonical" href={canonicalURL} />

    <!-- Primary Meta Tags -->
    <title>{title}</title>
    <meta name="title" content={title} />
    <meta name="description" content={description} />

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website" />
    <meta property="og:url" content={canonicalURL} />
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={new URL(image, Astro.site)} />

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image" />
    <meta property="twitter:url" content={canonicalURL} />
    <meta property="twitter:title" content={title} />
    <meta property="twitter:description" content={description} />
    <meta property="twitter:image" content={new URL(image, Astro.site)} />

    <slot name="head" />
  </head>
  <body>
    <Header />
    <main>
      <slot />
    </main>
    <Footer />
  </body>
</html>

<style is:global>
  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  html {
    font-family: system-ui, sans-serif;
    font-size: 16px;
    line-height: 1.6;
    color: #0f172a;
  }

  body {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }

  main {
    flex: 1;
    max-width: 1200px;
    width: 100%;
    margin: 0 auto;
    padding: 2rem 1rem;
  }

  a {
    color: #3b82f6;
    text-decoration: none;
  }

  a:hover {
    text-decoration: underline;
  }

  img {
    max-width: 100%;
    height: auto;
  }
</style>
EOF
  echo "Created: src/layouts/Layout.astro"
fi

# Create blog layout
if [ ! -f "$PROJECT_ROOT/src/layouts/BlogLayout.astro" ]; then
  cat > "$PROJECT_ROOT/src/layouts/BlogLayout.astro" <<'EOF'
---
import Layout from './Layout.astro';

export interface Props {
  title: string;
  description: string;
  publishDate: Date;
  author?: string;
  image?: string;
}

const {
  title,
  description,
  publishDate,
  author = 'Anonymous',
  image
} = Astro.props;

const formattedDate = publishDate.toLocaleDateString('en-US', {
  year: 'numeric',
  month: 'long',
  day: 'numeric'
});
---

<Layout title={title} description={description} image={image}>
  <article class="blog-post">
    <header class="post-header">
      <h1>{title}</h1>
      <div class="post-meta">
        <time datetime={publishDate.toISOString()}>{formattedDate}</time>
        <span class="separator">•</span>
        <span class="author">{author}</span>
      </div>
    </header>

    <div class="post-content">
      <slot />
    </div>
  </article>
</Layout>

<style>
  .blog-post {
    max-width: 720px;
    margin: 0 auto;
  }

  .post-header {
    margin-bottom: 2rem;
    padding-bottom: 2rem;
    border-bottom: 1px solid #e2e8f0;
  }

  .post-header h1 {
    font-size: 2.5rem;
    line-height: 1.2;
    margin-bottom: 1rem;
  }

  .post-meta {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #64748b;
    font-size: 0.875rem;
  }

  .separator {
    color: #cbd5e1;
  }

  .post-content {
    font-size: 1.125rem;
    line-height: 1.8;
  }

  .post-content :global(h2) {
    font-size: 1.875rem;
    margin-top: 2.5rem;
    margin-bottom: 1rem;
  }

  .post-content :global(h3) {
    font-size: 1.5rem;
    margin-top: 2rem;
    margin-bottom: 0.75rem;
  }

  .post-content :global(p) {
    margin-bottom: 1.5rem;
  }

  .post-content :global(ul),
  .post-content :global(ol) {
    margin-bottom: 1.5rem;
    padding-left: 1.5rem;
  }

  .post-content :global(li) {
    margin-bottom: 0.5rem;
  }

  .post-content :global(code) {
    background: #f1f5f9;
    padding: 0.2rem 0.4rem;
    border-radius: 0.25rem;
    font-size: 0.9em;
    font-family: 'Courier New', monospace;
  }

  .post-content :global(pre) {
    background: #0f172a;
    color: #e2e8f0;
    padding: 1rem;
    border-radius: 0.5rem;
    overflow-x: auto;
    margin-bottom: 1.5rem;
  }

  .post-content :global(pre code) {
    background: transparent;
    padding: 0;
  }
</style>
EOF
  echo "Created: src/layouts/BlogLayout.astro"
fi

# Create docs layout
if [ ! -f "$PROJECT_ROOT/src/layouts/DocsLayout.astro" ]; then
  cat > "$PROJECT_ROOT/src/layouts/DocsLayout.astro" <<'EOF'
---
import Layout from './Layout.astro';

export interface Props {
  title: string;
  description: string;
}

const { title, description } = Astro.props;
---

<Layout title={title} description={description}>
  <div class="docs-layout">
    <aside class="docs-sidebar">
      <nav>
        <slot name="sidebar" />
      </nav>
    </aside>

    <div class="docs-content">
      <article>
        <h1>{title}</h1>
        <slot />
      </article>

      <slot name="toc" />
    </div>
  </div>
</Layout>

<style>
  .docs-layout {
    display: grid;
    grid-template-columns: 250px 1fr;
    gap: 3rem;
    max-width: 1400px;
  }

  .docs-sidebar {
    position: sticky;
    top: 1rem;
    height: fit-content;
  }

  .docs-content {
    min-width: 0;
  }

  .docs-content article {
    max-width: 800px;
  }

  .docs-content h1 {
    font-size: 2.5rem;
    margin-bottom: 1.5rem;
  }

  @media (max-width: 768px) {
    .docs-layout {
      grid-template-columns: 1fr;
    }

    .docs-sidebar {
      position: static;
    }
  }
</style>
EOF
  echo "Created: src/layouts/DocsLayout.astro"
fi

echo "Layout system setup complete!"
echo ""
echo "Created layouts:"
echo "  - Layout.astro (Base layout with SEO)"
echo "  - BlogLayout.astro (Blog post layout)"
echo "  - DocsLayout.astro (Documentation layout)"
