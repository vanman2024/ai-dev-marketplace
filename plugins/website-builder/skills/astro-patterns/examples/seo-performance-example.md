# SEO and Performance Optimization Example

Complete guide to optimizing Astro sites for search engines and performance.

## SEO Component

```astro
---
// src/components/SEO.astro
import { ViewTransitions } from 'astro:transitions';

interface Props {
  title: string;
  description: string;
  image?: string;
  canonical?: string;
  noindex?: boolean;
}

const { title, description, image, canonical, noindex } = Astro.props;
const url = new URL(Astro.url.pathname, Astro.site);
const ogImage = image || new URL('/og-image.jpg', Astro.site);
---

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />

  <title>{title}</title>
  <meta name="description" content={description} />
  {canonical && <link rel="canonical" href={canonical} />}
  {noindex && <meta name="robots" content="noindex, nofollow" />}

  <!-- Open Graph -->
  <meta property="og:title" content={title} />
  <meta property="og:description" content={description} />
  <meta property="og:image" content={ogImage} />
  <meta property="og:url" content={url} />
  <meta property="og:type" content="website" />

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content={title} />
  <meta name="twitter:description" content={description} />
  <meta name="twitter:image" content={ogImage} />

  <!-- Sitemap -->
  <link rel="sitemap" href="/sitemap-index.xml" />

  <!-- View Transitions -->
  <ViewTransitions />
</head>
```

## Image Optimization

```astro
---
import { Image } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---

<!-- Optimized image with multiple formats -->
<Image
  src={heroImage}
  alt="Hero image"
  width={1200}
  height={600}
  format="webp"
  quality={80}
  loading="eager"
/>

<!-- Responsive images -->
<picture>
  <source
    srcset="/images/hero-1920.webp"
    type="image/webp"
    media="(min-width: 1200px)"
  />
  <source
    srcset="/images/hero-1024.webp"
    type="image/webp"
    media="(min-width: 768px)"
  />
  <img
    src="/images/hero-640.jpg"
    alt="Hero"
    loading="lazy"
    decoding="async"
  />
</picture>
```

## Sitemap Configuration

```typescript
// astro.config.mjs
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://example.com'
  integrations: [
    sitemap({
      filter: (page) => !page.includes('/admin/')
      customPages: [
        'https://example.com/external-page'
      ]
      changefreq: 'weekly'
      priority: 0.7
      lastmod: new Date()
    })
  ]
});
```

## RSS Feed

```typescript
// src/pages/rss.xml.ts
import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context) {
  const posts = await getCollection('blog');

  return rss({
    title: 'My Blog'
    description: 'A blog about web development'
    site: context.site
    items: posts.map(post => ({
      title: post.data.title
      pubDate: post.data.date
      description: post.data.description
      link: `/blog/${post.slug}/`
    }))
    customData: `<language>en-us</language>`
  });
}
```

## Performance Optimization

```typescript
// astro.config.mjs
export default defineConfig({
  build: {
    inlineStylesheets: 'auto'
    format: 'directory'
  }
  vite: {
    build: {
      cssCodeSplit: true
      rollupOptions: {
        output: {
          manualChunks: {
            'react-vendor': ['react', 'react-dom']
          }
        }
      }
    }
  }
  image: {
    service: {
      entrypoint: 'astro/assets/services/sharp'
    }
  }
  compressHTML: true
});
```

## Prefetch Strategy

```astro
---
// Prefetch links on hover
import { prefetch } from 'astro:prefetch';
---

<a href="/blog" data-astro-prefetch="hover">Blog</a>
<a href="/about" data-astro-prefetch="viewport">About</a>
<a href="/contact" data-astro-prefetch="load">Contact</a>
```

## Web Vitals Tracking

```astro
---
// src/components/Analytics.astro
---

<script>
  import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

  function sendToAnalytics(metric) {
    const body = JSON.stringify(metric);
    const url = '/api/analytics';

    if (navigator.sendBeacon) {
      navigator.sendBeacon(url, body);
    } else {
      fetch(url, { body, method: 'POST', keepalive: true });
    }
  }

  getCLS(sendToAnalytics);
  getFID(sendToAnalytics);
  getFCP(sendToAnalytics);
  getLCP(sendToAnalytics);
  getTTFB(sendToAnalytics);
</script>
```

## Structured Data

```astro
---
const schema = {
  "@context": "https://schema.org"
  "@type": "BlogPosting"
  "headline": post.data.title
  "datePublished": post.data.date
  "author": {
    "@type": "Person"
    "name": post.data.author
  }
};
---

<script type="application/ld+json" set:html={JSON.stringify(schema)} />
```
