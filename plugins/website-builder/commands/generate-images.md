---
description: Generate AI-powered images for hero sections, blog posts, and marketing using Google Imagen
argument-hint: image-type
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), TodoWrite(*), mcp__content-image-generation, mcp__context7
---

**Arguments**: $ARGUMENTS

Goal: Generate AI-powered images using Google Imagen 3/4 for hero sections, blog posts, and marketing materials

Core Principles:
- Use content-image-generation MCP for image generation
- Support multiple image types (hero, blog header, product, icon)
- Allow aspect ratio and quality customization
- Save images to project assets

Phase 1: Discovery & Requirements
Goal: Understand what images to generate

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for image type (hero, blog, product, icon)
- Use AskUserQuestion to gather:
  - What image type? (hero section, blog header, product image, icon, custom)
  - Image description/prompt?
  - Aspect ratio? (1:1, 16:9, 4:3, 9:16)
  - Quality? (SD or HD)
  - How many images? (single or batch)
  - Use Imagen 3 or Imagen 4?
- Summarize requirements

Phase 2: Project Analysis
Goal: Check project structure

Actions:
- Check if content-image-generation MCP configured
- Identify assets directory for saving images
- Check existing image patterns
- Update TodoWrite

Phase 3: Image Generation
Goal: Generate AI images

Actions:

Launch the website-ai-generator agent to generate images.

Provide the agent with:
- Image requirements from Phase 1
- Project structure from Phase 2
- MCP tools to use:
  - generate_image_imagen3 (for single image)
  - batch_generate_images (for multiple images)
- Image parameters:
  - Prompt (enhanced with image_prompt_enhancer if needed)
  - Negative prompt (optional)
  - Aspect ratio selection
  - Quality (SD or HD)
  - Output format (PNG, JPEG, WebP)
  - Seed (for reproducibility)
- Expected output: Images saved to assets directory

Phase 4: Validation
Goal: Verify images generated successfully

Actions:
- Check images saved to correct location
- Verify image quality and dimensions
- Display image paths and preview
- Update TodoWrite

Phase 5: Summary
Goal: Document generated images

Actions:
- Mark all todos complete
- Display image locations
- Show cost breakdown for generation
- Provide usage examples (how to reference in pages)
- Show next steps (optimize images, add to content)
