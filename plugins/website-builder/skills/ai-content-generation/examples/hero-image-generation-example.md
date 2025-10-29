# Hero Image Generation Example

Complete example of generating hero images for a landing page using Google Imagen.

## Setup

### 1. Configure MCP Server

```json
// .mcp.json
{
  "mcpServers": {
    "content-image-generation": {
      "command": "uv",
      "args": ["--directory", "../../mcp-servers/content-image-generation-mcp", "run", "content-image-generation"],
      "env": {
        "GOOGLE_CLOUD_PROJECT": "your-project-id",
        "ANTHROPIC_API_KEY": "sk-ant-..."
      }
    }
  }
}
```

### 2. Generate Hero Image

```typescript
// Using MCP tool: generate_image_imagen3
const heroImage = await generate_image_imagen3({
  prompt: "Modern, clean tech workspace with laptop displaying elegant web dashboard, soft natural lighting, professional photography style, blue and white color scheme, minimalist aesthetic",
  negative_prompt: "cluttered, messy, dark, unprofessional, cartoon",
  aspect_ratio: "16:9",
  quality: "hd",
  output_format: "webp",
  model: "imagen-4"
});

// Image saved to: output/imagen3_[timestamp].webp
```

### 3. Cost Estimate

```typescript
// Calculate cost before generating
const estimate = await calculate_cost_estimate({
  images: {
    imagen4_hd: 1  // 1 HD image with Imagen 4
  }
});

console.log(`Estimated cost: $${estimate.total_cost}`);
// Output: Estimated cost: $0.05
```

### 4. Batch Generate Multiple Variations

```typescript
// Generate 3 variations of hero image
const variations = await batch_generate_images({
  base_prompt: "Tech startup office space, modern design",
  variations: [
    "morning light, team collaboration",
    "afternoon, focused individual work",
    "evening, presentation on large screen"
  ],
  aspect_ratio: "16:9",
  quality: "sd",  // Use SD for prototyping
  output_format: "webp"
});

// 3 images generated at $0.025 each = $0.075 total
```

### 5. Integrate with Astro

```astro
---
// src/pages/index.astro
import { Image } from 'astro:assets';
import heroImage from '../assets/hero-imagen4.webp';
---

<section class="hero">
  <div class="hero-content">
    <h1>Transform Your Workflow</h1>
    <p>AI-powered tools for modern teams</p>
  </div>
  <Image
    src={heroImage}
    alt="Modern workspace"
    width={1920}
    height={1080}
    format="webp"
  />
</section>
```

## Results

- ✅ High-quality hero image generated in seconds
- ✅ Cost: $0.05 for HD Imagen 4
- ✅ WebP format for optimal web performance
- ✅ 16:9 aspect ratio perfect for hero sections
- ✅ Multiple variations for A/B testing

## Best Practices

1. **Start with SD for prototyping** - Cost $0.020 vs $0.050 for HD
2. **Use detailed prompts** - More specific = better results
3. **Include style keywords** - "professional photography", "minimalist", "modern"
4. **Specify negative prompts** - What to avoid
5. **Batch generate variations** - More efficient than individual requests
