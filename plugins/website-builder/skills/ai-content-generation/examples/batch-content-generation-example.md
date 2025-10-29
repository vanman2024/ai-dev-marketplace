# Batch AI Content Generation Example

Generate multiple pages, images, and content pieces at scale using content-image-generation MCP.

## Batch Page Generation Script

```typescript
// scripts/generate-product-pages.ts
import { generateMarketingContent, generateImageImagen3, calculateCostEstimate } from '../lib/ai-generation';

interface Product {
  id: string;
  name: string;
  category: string;
  features: string[];
}

const products: Product[] = [
  { id: 'p1', name: 'Product A', category: 'Electronics', features: ['Fast', 'Reliable'] },
  { id: 'p2', name: 'Product B', category: 'Home', features: ['Eco-friendly', 'Durable'] }
];

async function generateProductPages() {
  console.log('Generating content for', products.length, 'products...');

  for (const product of products) {
    // Generate marketing copy with Gemini 2.0
    const content = await generateMarketingContent({
      prompt: `Write compelling product description for ${product.name} in ${product.category} category. Highlight: ${product.features.join(', ')}`,
      model: 'gemini-2.0-flash-exp',
      max_tokens: 500
    });

    // Generate product image with Imagen 4
    const image = await generateImageImagen3({
      prompt: `Professional product photo of ${product.name}, ${product.category}, studio lighting, white background`,
      aspect_ratio: '16:9',
      safety_filter_level: 'block_some',
      person_generation: 'dont_allow',
      quality: 'hd'
    });

    // Save to content collection
    await writeFile(`src/content/products/${product.id}.mdx`, `---
title: "${product.name}"
description: "${content.substring(0, 160)}"
image: "${image.url}"
category: "${product.category}"
---

${content}
`);

    console.log(`✓ Generated ${product.name}`);
  }
}

generateProductPages();
```

## Batch Image Generation

```typescript
// scripts/generate-hero-images.ts
import { batchGenerateImages } from '../lib/ai-generation';

const pages = [
  { slug: 'home', prompt: 'Modern tech startup office, professional, bright' },
  { slug: 'about', prompt: 'Diverse team collaboration, modern workspace' },
  { slug: 'services', prompt: 'Technology services, abstract, futuristic' }
];

async function generateHeroImages() {
  const prompts = pages.map(p => ({
    prompt: `${p.prompt}, high quality, 16:9 aspect ratio, cinematic`,
    aspect_ratio: '16:9' as const,
    quality: 'hd' as const
  }));

  const results = await batchGenerateImages(prompts);

  for (let i = 0; i < results.length; i++) {
    console.log(`${pages[i].slug}: ${results[i].url}`);
    // Update page frontmatter with image URL
  }
}

generateHeroImages();
```

## Cost Estimation for Campaigns

```typescript
// scripts/estimate-campaign-cost.ts
import { calculateCostEstimate } from '../lib/ai-generation';

async function estimateCampaign() {
  const estimate = await calculateCostEstimate({
    num_images: 50,
    num_videos: 5,
    num_content_pieces: 100,
    image_quality: 'hd',
    video_duration_seconds: 30,
    content_model: 'gemini-2.0-flash-exp'
  });

  console.log('Campaign Cost Estimate:');
  console.log(`Total: $${estimate.total_cost}`);
  console.log(`Images: $${estimate.image_cost}`);
  console.log(`Videos: $${estimate.video_cost}`);
  console.log(`Content: $${estimate.content_cost}`);
}

estimateCampaign();
```
