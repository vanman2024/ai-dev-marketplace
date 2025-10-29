// author-collection-schema.ts
// Author/contributor collection schema

import { defineCollection, z } from 'astro:content';

/**
 * Author collection schema
 * For blog authors, contributors, team members
 */
export const authors = defineCollection({
  schema: z.object({
    // Basic info
    name: z.string().min(1, "Name is required"),
    bio: z.string().min(10, "Bio is required"),
    title: z.string().optional(), // Job title

    // Contact
    email: z.string().email().optional(),
    website: z.string().url().optional(),

    // Social links
    social: z.object({
      twitter: z.string().optional(),
      github: z.string().optional(),
      linkedin: z.string().optional(),
      youtube: z.string().optional(),
      instagram: z.string().optional(),
      mastodon: z.string().optional(),
    }).optional(),

    // Media
    avatar: z.string().optional(),
    coverImage: z.string().optional(),

    // Author metadata
    role: z.enum(['author', 'editor', 'contributor', 'guest']).default('author'),
    featured: z.boolean().default(false),

    // Stats (optional, can be computed)
    postCount: z.number().int().nonnegative().optional(),
    joinDate: z.date().optional(),

    // Display preferences
    showInTeamPage: z.boolean().default(true),
    showInAuthorList: z.boolean().default(true),
  }),
});

/**
 * Example author frontmatter:
 *
 * ---
 * name: "Jane Doe"
 * bio: "Senior developer and technical writer with 10+ years experience"
 * title: "Lead Developer"
 * email: "jane@example.com"
 * social:
 *   twitter: "@janedoe"
 *   github: "janedoe"
 *   linkedin: "janedoe"
 * avatar: "/images/authors/jane.jpg"
 * role: "author"
 * featured: true
 * ---
 */
