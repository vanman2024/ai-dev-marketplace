# Astro Setup Skill

## Overview

Provides installation, prerequisite checking, and project initialization for Astro websites with AI Tech Stack 1 integration.

## Purpose

Automate the setup of Astro projects with proper Node.js version checking, dependency installation, integration configuration (React, MDX, Tailwind, Supabase), and MCP server setup.

## When to Use

- Initializing a new Astro website project
- Setting up prerequisites (Node.js 18.14.1+)
- Installing Astro CLI and project dependencies
- Configuring integrations for AI Tech Stack 1
- Setting up environment variables and MCP servers

## Components

### Scripts

1. **check-prerequisites.sh** - Verify Node.js version, package manager
2. **install-astro.sh** - Install Astro CLI globally if needed
3. **init-project.sh** - Initialize Astro project with proper configuration
4. **setup-integrations.sh** - Install and configure Astro integrations
5. **setup-env.sh** - Create .env file with API key placeholders

### Templates

1. **astro.config.mjs** - Complete Astro configuration with all integrations
2. **tsconfig.json** - TypeScript configuration for Astro
3. **tailwind.config.js** - Tailwind CSS configuration
4. **.env.example** - Environment variable template
5. **package.json.template** - Package.json with all dependencies

### Examples

1. **minimal-astro.config.mjs** - Minimal Astro configuration
2. **full-stack-astro.config.mjs** - Full AI Tech Stack 1 configuration
3. **blog-astro.config.mjs** - Blog-optimized configuration

## Integration with Website-Builder

This skill is invoked by:
- `/website-builder:init` command
- `website-setup` agent
- Any workflow requiring Astro project initialization

## Prerequisites

- Node.js 18.14.1 or higher
- npm, pnpm, yarn, or bun package manager
- Internet connection for package installation

## Documentation References

Uses Astro's LLM-optimized documentation:
- https://docs.astro.build/llms-full.txt - Complete Astro documentation
- https://docs.astro.build/_llms-txt/api-reference.txt - API reference
- https://docs.astro.build/en/install-and-setup/ - Installation guide

## Output

- Initialized Astro project with TypeScript
- Installed integrations: @astrojs/react, @astrojs/mdx, @astrojs/tailwind, @astrojs/sitemap
- Configured astro.config.mjs
- Created .env.example with required variables
- Ready-to-use project structure
