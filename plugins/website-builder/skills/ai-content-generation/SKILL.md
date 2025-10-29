---
name: ai-content-generation
description: AI-powered content and image generation using content-image-generation MCP with Google Imagen 3/4, Veo 2/3, Claude Sonnet, and Gemini 2.0. Use when generating marketing content, creating hero images, building blog posts, generating product descriptions, creating videos, optimizing AI prompts, estimating generation costs, or when user mentions Imagen, Veo, AI content, AI images, content generation, image generation, video generation, marketing copy, or Google AI.
allowed-tools: Read(*), Write(*), Bash(*), Glob(*), Grep(*), mcp__content-image-generation(*)
---

# AI Content Generation

AI-powered content and image generation skill using the content-image-generation MCP server. This skill provides capabilities for generating marketing content with Claude Sonnet 4 or Gemini 2.0 Pro, creating images with Google Imagen 3/4, and generating videos with Google Veo 2/3.

## Core Capabilities

### Image Generation
- Generate images with Google Imagen 3 or Imagen 4
- Support multiple aspect ratios (1:1, 16:9, 4:3, 9:16, custom)
- Quality control (SD or HD)
- Batch generation for multiple images
- Prompt enhancement for better results
- Custom negative prompts for quality control
- Seed-based reproducibility

### Content Generation
- Marketing content with Claude Sonnet 4 or Gemini 2.0 Pro
- Hero section copy and landing page content
- Blog posts and articles
- Product descriptions and feature lists
- Email campaigns and ad copy
- SEO-optimized content
- Tone and style customization

### Video Generation
- Short-form videos with Google Veo 2 or Veo 3
- Multiple aspect ratios and durations
- Prompt-based video creation
- Quality and format options

### Cost Optimization
- Pre-generation cost estimation
- Batch optimization recommendations
- Quality vs cost tradeoffs
- Token usage tracking

## Instructions

### Setup and Validation

Before generating content, verify MCP integration:

```bash
# Validate MCP server configuration
bash scripts/validate-mcp-setup.sh

# Setup environment variables
bash scripts/setup-environment.sh
```

### Image Generation Workflow

1. **Enhance Prompt**: Use prompt enhancement for better results
   ```bash
   bash scripts/enhance-image-prompt.sh "your basic prompt"
   ```

2. **Estimate Cost**: Calculate generation costs
   ```bash
   bash scripts/calculate-cost.sh --type image --quality HD --count 5
   ```

3. **Generate Image**: Use MCP tool with enhanced parameters
   - Read template: `templates/typescript/image-generation.ts` or `templates/python/image-generation.py`
   - Call MCP tool: `generate_image_imagen3` or `batch_generate_images`
   - Save to assets directory

4. **Validate Output**: Check image quality and dimensions
   ```bash
   bash scripts/validate-output.sh --type image --path /path/to/image.png
   ```

### Content Generation Workflow

1. **Define Requirements**: Gather content parameters
   - Content type (hero, blog, product, email)
   - Topic and keywords
   - Tone and style (professional, casual, technical)
   - Target audience
   - Desired length

2. **Estimate Cost**: Calculate generation costs
   ```bash
   bash scripts/calculate-cost.sh --type content --model claude-sonnet-4 --length 1000
   ```

3. **Generate Content**: Use MCP tool
   - Read template: `templates/typescript/content-generation.ts` or `templates/python/content-generation.py`
   - Call MCP tool: `generate_marketing_content`
   - Save to content directory

4. **Review and Refine**: Validate content quality
   ```bash
   bash scripts/validate-output.sh --type content --path /path/to/content.md
   ```

### Video Generation Workflow

1. **Prepare Prompt**: Create detailed video description
   ```bash
   bash scripts/enhance-video-prompt.sh "your video description"
   ```

2. **Estimate Cost**: Calculate video generation costs
   ```bash
   bash scripts/calculate-cost.sh --type video --duration 5 --quality HD
   ```

3. **Generate Video**: Use MCP tool
   - Read template: `templates/typescript/video-generation.ts` or `templates/python/video-generation.py`
   - Call MCP tool: `generate_video_veo3`
   - Save to assets directory

### Batch Operations

For multiple assets, use batch generation:

```bash
# Optimize batch parameters
bash scripts/optimize-batch.sh --type image --count 10 --budget 50

# Generate batch with optimized settings
# Use batch_generate_images MCP tool
```

## MCP Tools Reference

### Image Generation
- `generate_image_imagen3`: Generate single image with Imagen 3/4
  - Parameters: prompt, negative_prompt, aspect_ratio, quality, model, seed
  - Returns: Base64 image data, metadata, cost

- `batch_generate_images`: Generate multiple images efficiently
  - Parameters: prompts array, shared settings, batch_size
  - Returns: Array of images with metadata

### Content Generation
- `generate_marketing_content`: Generate marketing copy
  - Parameters: topic, content_type, tone, style, length, model, keywords
  - Returns: Generated content, metadata, cost

### Video Generation
- `generate_video_veo3`: Generate video with Veo 2/3
  - Parameters: prompt, duration, aspect_ratio, quality, model
  - Returns: Video data, metadata, cost

### Utilities
- `calculate_cost_estimate`: Estimate generation costs
  - Parameters: operation_type, parameters, quantity
  - Returns: Cost breakdown, recommendations

- `image_prompt_enhancer`: Enhance image prompts
  - Parameters: basic_prompt, style, quality_level
  - Returns: Enhanced prompt, suggestions

## Scripts Reference

All scripts are located in `skills/ai-content-generation/scripts/`:

- `setup-environment.sh`: Configure environment variables and credentials
- `validate-mcp-setup.sh`: Verify MCP server connection and tools
- `enhance-image-prompt.sh`: Improve image generation prompts
- `calculate-cost.sh`: Estimate generation costs before execution
- `validate-output.sh`: Check quality of generated assets
- `optimize-batch.sh`: Optimize batch generation parameters
- `test-generation.sh`: Run test generation to verify setup

## Templates Reference

### TypeScript Templates (`templates/typescript/`)
- `image-generation.ts`: Complete image generation implementation
- `content-generation.ts`: Marketing content generation
- `video-generation.ts`: Video generation workflow

### Python Templates (`templates/python/`)
- `image-generation.py`: Complete image generation implementation
- `content-generation.py`: Marketing content generation
- `video-generation.py`: Video generation workflow

## Examples

See `examples/` directory for comprehensive usage examples:

- `basic-usage.md`: Simple image and content generation
- `advanced-usage.md`: Batch operations, cost optimization, custom parameters
- `common-patterns.md`: Hero images, blog headers, product galleries
- `error-handling.md`: Retry logic, fallbacks, validation
- `integration.md`: Astro integration, asset management, workflow automation

## Best Practices

### Image Generation
- Always enhance prompts for better quality
- Use HD quality for hero sections and key visuals
- Use SD quality for thumbnails and secondary images
- Specify negative prompts to avoid unwanted elements
- Use consistent seeds for reproducible results
- Batch similar images to optimize costs

### Content Generation
- Provide clear topic and keywords
- Specify target audience for better relevance
- Choose appropriate tone and style
- Review and customize generated content
- Use Claude for technical/detailed content
- Use Gemini for creative/marketing content

### Cost Optimization
- Estimate costs before generation
- Use batch operations for multiple assets
- Choose SD quality when HD is not required
- Optimize prompt length for content generation
- Cache and reuse similar assets
- Monitor token usage and costs

### Error Handling
- Validate MCP setup before operations
- Check API quotas and limits
- Implement retry logic for transient failures
- Validate output quality after generation
- Log costs and metadata for tracking

## Requirements

### Environment Variables
- `GOOGLE_CLOUD_PROJECT`: Google Cloud project ID for Vertex AI
- `ANTHROPIC_API_KEY`: API key for Claude Sonnet content generation
- `GOOGLE_AI_API_KEY`: (Optional) API key for Gemini content generation

### MCP Configuration
- content-image-generation MCP server must be configured in `.mcp.json`
- Google Cloud credentials must be set up for Vertex AI
- Appropriate APIs must be enabled (Vertex AI, Imagen, Veo)

### Project Structure
- Assets directory for storing generated images/videos
- Content directory for storing generated text
- Environment file for API credentials

---

**Skill Version**: 1.0.0
**Plugin**: website-builder
**MCP Server**: content-image-generation
