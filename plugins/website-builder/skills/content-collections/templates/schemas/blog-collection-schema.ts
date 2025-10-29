// blog-collection-schema.ts
// Complete blog collection schema with Zod validation

import { defineCollection, z } from 'astro:content';

/**
 * Blog post collection schema
 * Comprehensive schema for blog posts with SEO, social, and metadata fields
 */
export const blog = defineCollection({
  schema: z.object({
    // Core content fields
    title: z.string().min(1, "Title is required").max(100, "Title too long"),
    description: z.string().min(10, "Description too short").max(160, "Description too long for SEO"),

    // Date fields
    pubDate: z.date({
      required_error: "Publication date is required",
      invalid_type_error: "Invalid date format",
    }),
    updatedDate: z.date().optional(),

    // Content metadata
    author: z.string().min(1, "Author is required"),
    tags: z.array(z.string()).default([]),
    categories: z.array(z.string()).default([]),

    // Media
    heroImage: z.string().optional(),
    heroImageAlt: z.string().optional(),

    // Publishing control
    draft: z.boolean().default(false),
    featured: z.boolean().default(false),

    // SEO fields (optional but recommended)
    seo: z.object({
      metaTitle: z.string().max(60).optional(),
      metaDescription: z.string().max(160).optional(),
      canonicalUrl: z.string().url().optional(),
      noindex: z.boolean().default(false),
      nofollow: z.boolean().default(false),
    }).optional(),

    // Social sharing (optional)
    social: z.object({
      ogImage: z.string().optional(),
      ogImageAlt: z.string().optional(),
      twitterCard: z.enum(['summary', 'summary_large_image', 'app', 'player']).default('summary_large_image'),
      twitterImage: z.string().optional(),
    }).optional(),

    // Reading metadata
    readingTime: z.number().optional(), // minutes
    excerpt: z.string().max(300).optional(),

    // Advanced options
    series: z.string().optional(), // Part of a post series
    seriesOrder: z.number().optional(),
    relatedPosts: z.array(z.string()).default([]), // Slugs of related posts

    // Table of contents
    toc: z.boolean().default(true),
    tocDepth: z.number().min(1).max(6).default(3),
  }),
});

/**
 * Example usage in src/content/config.ts:
 *
 * import { blog } from './schemas/blog-collection-schema';
 * export const collections = { blog };
 *
 * Then in your .astro files:
 *
 * import { getCollection } from 'astro:content';
 * const posts = await getCollection('blog');
 */
