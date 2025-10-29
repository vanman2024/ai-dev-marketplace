---
description: Generate AI-powered content for pages, blogs, and marketing copy using content-image-generation MCP
argument-hint: content-type
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), TodoWrite(*), mcp__content-image-generation, mcp__context7
---

**Arguments**: $ARGUMENTS

Goal: Generate AI-powered marketing content, blog posts, and page copy using Claude Sonnet 4 or Gemini 2.0 via content-image-generation MCP

Core Principles:
- Use content-image-generation MCP for AI content generation
- Support multiple content types (hero copy, blog posts, product descriptions)
- Allow customization of tone, style, and length
- Save generated content to project

Phase 1: Discovery & Requirements
Goal: Understand what content to generate

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for content type (hero, blog, product, custom)
- Use AskUserQuestion to gather:
  - What content type? (hero section, blog post, product description, landing page)
  - What's the topic/subject?
  - Tone and style? (professional, casual, technical, marketing)
  - Target audience?
  - Length preference? (short, medium, long)
  - Which AI model? (Claude Sonnet 4, Gemini 2.0 Pro)
- Summarize requirements

Phase 2: Project Analysis
Goal: Check project structure

Actions:
- Check if content-image-generation MCP configured
- Identify where to save generated content
- Check existing content patterns
- Update TodoWrite

Phase 3: Content Generation
Goal: Generate AI content

Actions:

Launch the website-ai-generator agent to generate content.

Provide the agent with:
- Content requirements from Phase 1
- Project structure from Phase 2
- MCP tool to use: generate_marketing_content
- Content parameters:
  - Topic and subject matter
  - Tone and style preferences
  - Target audience
  - Desired length
  - AI model selection
- Expected output: Generated content saved to appropriate location

Phase 4: Content Review
Goal: Review and refine generated content

Actions:

Launch the website-content agent to review and integrate content.

Provide the agent with:
- Generated content from Phase 3
- Integration requirements
- Format requirements (MDX, HTML, plain text)
- Expected output: Polished content ready for use

Phase 5: Summary
Goal: Document generated content

Actions:
- Mark all todos complete
- Display generated content preview
- Show file location
- Provide cost estimate for generation
- Show next steps (edit content, generate images, publish)
