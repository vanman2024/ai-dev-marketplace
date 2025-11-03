---
description: Setup content-image-generation MCP server for AI-powered content and image generation
argument-hint: none
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__content-image-generation, mcp__context7, Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Setup and configure content-image-generation MCP server for AI-powered content generation (Claude/Gemini) and image generation (Google Imagen 3/4)

Core Principles:
- Configure content-image-generation MCP server
- Setup Google Cloud credentials for Imagen
- Configure Anthropic/Google AI API keys
- Integrate with Astro project

Phase 1: Discovery & Requirements
Goal: Understand MCP integration needs

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - Have Google Cloud project with Vertex AI enabled?
  - Have Anthropic API key for content generation?
  - Have Google AI API key (optional alternative)?
  - Where to store MCP configuration? (.mcp.json in project root)
  - Need to generate sample content now?
- Load content-image-generation MCP documentation
- Summarize requirements

Phase 2: Project Analysis
Goal: Check existing setup

Actions:
- Check if .mcp.json already exists
- Check for existing MCP servers configured
- Verify Astro project structure
- Check for environment variable files
- Update TodoWrite

Phase 3: Implementation
Goal: Configure MCP server

Actions:

Launch the website-setup agent to configure content-image-generation MCP.

Provide the agent with:
- MCP server location: mcp-servers/content-image-generation-mcp
- Configuration requirements from Phase 1
- Project structure from Phase 2
- Environment variables needed:
  - GOOGLE_CLOUD_PROJECT
  - ANTHROPIC_API_KEY
  - GOOGLE_AI_API_KEY (optional)
- Expected output: .mcp.json configuration, .env.example template, integration guide

Phase 4: Validation
Goal: Verify MCP integration works

Actions:
- Check .mcp.json created and valid
- Verify MCP server can be loaded
- Test basic MCP connection
- Update TodoWrite

Phase 5: Summary
Goal: Document integration

Actions:
- Mark all todos complete
- Display MCP configuration
- Show available MCP tools: - generate_image_imagen3 (Google Imagen 3/4 image generation)
  - batch_generate_images (batch image generation)
  - generate_video_veo3 (Google Veo 2/3 video generation)
  - generate_marketing_content (Claude/Gemini content generation)
  - calculate_cost_estimate (campaign cost estimation)
- Provide usage examples
- Show next steps (generate content, generate images)
