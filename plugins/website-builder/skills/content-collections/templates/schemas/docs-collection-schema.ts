// docs-collection-schema.ts
// Documentation collection schema with hierarchical navigation support

import { defineCollection, z } from 'astro:content';

/**
 * Documentation collection schema
 * Optimized for technical documentation with navigation, versioning, and search
 */
export const docs = defineCollection({
  schema: z.object({
    // Core content
    title: z.string().min(1, "Title is required"),
    description: z.string().min(10, "Description required for search"),

    // Navigation and organization
    category: z.string().min(1, "Category is required"),
    order: z.number().default(999), // Display order in sidebar
    sidebar_label: z.string().optional(), // Override title in sidebar

    // Hierarchy
    parent: z.string().optional(), // Slug of parent doc
    children: z.array(z.string()).default([]), // Slugs of child docs

    // Metadata
    tags: z.array(z.string()).default([]),
    keywords: z.array(z.string()).default([]), // For search

    // Dates
    createdDate: z.date().optional(),
    lastUpdated: z.date().optional(),

    // Publishing
    draft: z.boolean().default(false),
    deprecated: z.boolean().default(false),
    deprecationMessage: z.string().optional(),

    // Navigation hints
    prev: z.object({
      label: z.string(),
      link: z.string(),
    }).optional(),
    next: z.object({
      label: z.string(),
      link: z.string(),
    }).optional(),

    // Content features
    toc: z.boolean().default(true),
    tocDepth: z.number().min(1).max(6).default(3),
    showLastUpdated: z.boolean().default(true),
    editUrl: z.string().url().optional(), // Link to edit on GitHub

    // Code examples
    examples: z.array(z.object({
      title: z.string(),
      language: z.string(),
      code: z.string(),
    })).optional(),

    // API reference
    apiRef: z.object({
      endpoint: z.string().optional(),
      method: z.enum(['GET', 'POST', 'PUT', 'PATCH', 'DELETE']).optional(),
      parameters: z.array(z.object({
        name: z.string(),
        type: z.string(),
        required: z.boolean().default(false),
        description: z.string(),
      })).optional(),
    }).optional(),

    // Versioning
    version: z.string().optional(), // e.g., "1.0", "2.0"
    versionStatus: z.enum(['current', 'legacy', 'beta', 'alpha']).default('current'),

    // Related content
    relatedDocs: z.array(z.string()).default([]),
    prerequisites: z.array(z.string()).default([]), // Docs to read first

    // Feedback
    feedback: z.boolean().default(true), // Show feedback widget
    contributors: z.array(z.string()).default([]), // Usernames
  }),
});

/**
 * Example directory structure:
 *
 * src/content/docs/
 *   getting-started/
 *     introduction.md
 *     installation.md
 *   guides/
 *     authentication.md
 *     deployment.md
 *   api-reference/
 *     endpoints.md
 *     types.md
 *
 * Example frontmatter:
 *
 * ---
 * title: "Installation Guide"
 * description: "Step-by-step installation instructions"
 * category: "Getting Started"
 * order: 2
 * tags: ["setup", "installation"]
 * lastUpdated: 2025-01-15
 * next:
 *   label: "Configuration"
 *   link: "/docs/getting-started/configuration"
 * ---
 */
