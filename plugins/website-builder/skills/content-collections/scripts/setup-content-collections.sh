#!/bin/bash
# setup-content-collections.sh
# Initialize Astro content collections structure

set -e

PROJECT_PATH="${1:-.}"
CONTENT_DIR="$PROJECT_PATH/src/content"
CONFIG_FILE="$CONTENT_DIR/config.ts"

echo "Setting up content collections for Astro project: $PROJECT_PATH"

# Check if we're in an Astro project
if [ ! -f "$PROJECT_PATH/astro.config.mjs" ] && [ ! -f "$PROJECT_PATH/astro.config.ts" ]; then
  echo "Error: Not an Astro project (no astro.config found)"
  exit 1
fi

# Create content directory structure
echo "Creating content directory structure..."
mkdir -p "$CONTENT_DIR"/{blog,docs,authors,products}

# Create config.ts if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Creating content config.ts..."
  cat > "$CONFIG_FILE" << 'EOF'
import { defineCollection, z } from 'astro:content';

// Blog collection schema
const blog = defineCollection({
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date(),
    updatedDate: z.date().optional(),
    heroImage: z.string().optional(),
    tags: z.array(z.string()).default([]),
    author: z.string(),
    draft: z.boolean().default(false),
  }),
});

// Documentation collection schema
const docs = defineCollection({
  schema: z.object({
    title: z.string(),
    description: z.string(),
    order: z.number().optional(),
    category: z.string(),
    tags: z.array(z.string()).default([]),
    lastUpdated: z.date().optional(),
  }),
});

// Author collection schema
const authors = defineCollection({
  schema: z.object({
    name: z.string(),
    bio: z.string(),
    avatar: z.string().optional(),
    email: z.string().email().optional(),
    twitter: z.string().optional(),
    github: z.string().optional(),
  }),
});

export const collections = { blog, docs, authors };
EOF
  echo "Created: $CONFIG_FILE"
else
  echo "Content config already exists: $CONFIG_FILE"
fi

# Add example content if directories are empty
if [ -z "$(ls -A $CONTENT_DIR/blog 2>/dev/null)" ]; then
  echo "Creating example blog post..."
  cat > "$CONTENT_DIR/blog/example-post.md" << 'EOF'
---
title: "Example Blog Post"
description: "This is an example blog post to demonstrate content collections"
pubDate: 2025-01-01
author: "Example Author"
tags: ["astro", "content-collections"]
draft: false
---

This is an example blog post. Replace this with your own content.

## Features

- Type-safe frontmatter
- Auto-completion in IDE
- Build-time validation
EOF
fi

# Create TypeScript declaration file
TYPES_DIR="$PROJECT_PATH/.astro"
mkdir -p "$TYPES_DIR"

# Check package.json for dependencies
PACKAGE_JSON="$PROJECT_PATH/package.json"
if [ -f "$PACKAGE_JSON" ]; then
  echo "Checking dependencies..."

  # Check for zod
  if ! grep -q '"zod"' "$PACKAGE_JSON"; then
    echo "Warning: zod not found in package.json"
    echo "Install with: npm install zod"
  fi

  # Check for astro content
  if ! grep -q '"astro"' "$PACKAGE_JSON"; then
    echo "Warning: astro not found in package.json"
  fi
fi

# Create .gitignore entries
GITIGNORE="$PROJECT_PATH/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q ".astro/" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo "# Astro generated types" >> "$GITIGNORE"
    echo ".astro/" >> "$GITIGNORE"
    echo "Added .astro/ to .gitignore"
  fi
fi

echo ""
echo "Content collections setup complete!"
echo ""
echo "Next steps:"
echo "1. Run 'npm install zod' if not already installed"
echo "2. Run 'npm run dev' to generate types"
echo "3. Edit $CONFIG_FILE to customize schemas"
echo "4. Add content to collections in $CONTENT_DIR"
echo ""
echo "Collection directories created:"
ls -d "$CONTENT_DIR"/*/ 2>/dev/null || echo "  (none yet)"
