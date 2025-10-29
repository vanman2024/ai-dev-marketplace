# Dynamic Content Personalization Example

Personalize website content and images based on user context using AI generation.

## Personalized Landing Pages

```astro
---
// src/pages/landing/[audience].astro
import { generateMarketingContent } from '@/lib/ai-generation';

export async function getStaticPaths() {
  const audiences = ['developers', 'designers', 'marketers'];

  const pages = await Promise.all(
    audiences.map(async (audience) => {
      const content = await generateMarketingContent({
        prompt: `Write landing page hero copy for ${audience} audience. Professional, engaging, benefit-focused.`,
        model: 'gemini-2.0-flash-exp',
        max_tokens: 200
      });

      return {
        params: { audience },
        props: { content, audience }
      };
    })
  );

  return pages;
}

const { content, audience } = Astro.props;
---

<div class="hero">
  <h1>{audience}-specific Landing Page</h1>
  <p>{content}</p>
</div>
```

## A/B Testing with AI Variants

```typescript
// src/lib/ab-testing.ts
import { generateMarketingContent } from './ai-generation';

export async function generateVariants(basePrompt: string, count: number = 3) {
  const variants = await Promise.all(
    Array.from({ length: count }, (_, i) =>
      generateMarketingContent({
        prompt: `${basePrompt}. Variant ${i + 1}, different tone and approach.`,
        model: 'gemini-2.0-flash-exp',
        max_tokens: 150,
        temperature: 0.8 + (i * 0.1)
      })
    )
  );

  return variants.map((content, i) => ({
    id: `variant-${i}`,
    content
  }));
}
```

## User-Specific Image Generation

```typescript
// src/pages/api/personalized-image.ts
import { generateImageImagen3 } from '@/lib/ai-generation';
import type { APIRoute } from 'astro';

export const POST: APIRoute = async ({ request }) => {
  const { userPreferences } = await request.json();

  const prompt = `Professional illustration featuring: ${userPreferences.industry}, ${userPreferences.style} style, ${userPreferences.colors} color palette`;

  const image = await generateImageImagen3({
    prompt,
    aspect_ratio: '1:1',
    quality: 'sd'
  });

  return new Response(JSON.stringify({ imageUrl: image.url }), {
    headers: { 'Content-Type': 'application/json' }
  });
};
```
