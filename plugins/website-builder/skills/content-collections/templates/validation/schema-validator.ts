// Zod schema validators for content collections
import { z } from 'zod';

// Blog post schema with comprehensive validation
export const blogSchema = z.object({
  title: z.string().min(1, 'Title is required').max(100, 'Title too long'),
  description: z.string().min(10, 'Description too short').max(300, 'Description too long'),
  date: z.date(),
  author: z.string().min(1, 'Author is required'),
  tags: z.array(z.string()).min(1, 'At least one tag required').max(10, 'Too many tags'),
  draft: z.boolean().default(false),
  image: z.string().url().optional(),
  category: z.enum(['tutorial', 'guide', 'news', 'case-study']).optional(),
});

// Documentation schema
export const docsSchema = z.object({
  title: z.string().min(1).max(100),
  description: z.string().min(10).max(300),
  category: z.enum(['guide', 'reference', 'tutorial', 'api']),
  order: z.number().int().min(0),
  version: z.string().regex(/^\d+\.\d+(\.\d+)?$/, 'Invalid version format'),
  lastUpdated: z.date(),
  tags: z.array(z.string()).default([]),
  related: z.array(z.string()).default([]),
});

// Project schema with image validation
export const projectSchema = z.object({
  title: z.string().min(1).max(100),
  description: z.string().min(10).max(500),
  category: z.enum(['web', 'mobile', 'design', 'other']),
  tags: z.array(z.string()).min(1).max(15),
  featured: z.boolean().default(false),
  link: z.string().url().optional(),
  github: z.string().url().optional(),
  date: z.date(),
  client: z.string().optional(),
  role: z.string().min(1, 'Role is required'),
});
