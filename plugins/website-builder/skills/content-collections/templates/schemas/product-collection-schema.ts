// product-collection-schema.ts
// E-commerce product collection schema

import { defineCollection, z } from 'astro:content';

/**
 * Product collection schema
 * For e-commerce sites, product catalogs, and marketing pages
 */
export const products = defineCollection({
  schema: z.object({
    // Basic info
    name: z.string().min(1, "Product name required"),
    description: z.string().min(10, "Description required"),
    shortDescription: z.string().max(150).optional(),

    // Pricing
    price: z.number().positive("Price must be positive"),
    originalPrice: z.number().positive().optional(), // For showing discounts
    currency: z.string().default('USD'),

    // Inventory
    sku: z.string().optional(),
    inStock: z.boolean().default(true),
    stockQuantity: z.number().int().nonnegative().optional(),

    // Product details
    brand: z.string().optional(),
    category: z.string().min(1, "Category required"),
    subcategory: z.string().optional(),
    tags: z.array(z.string()).default([]),

    // Media
    images: z.array(z.object({
      url: z.string(),
      alt: z.string(),
      isPrimary: z.boolean().default(false),
    })).min(1, "At least one image required"),

    videos: z.array(z.object({
      url: z.string(),
      thumbnail: z.string().optional(),
      type: z.enum(['youtube', 'vimeo', 'direct']),
    })).optional(),

    // Features and specs
    features: z.array(z.string()).default([]),
    specifications: z.record(z.string()).optional(),

    // Variants (e.g., sizes, colors)
    variants: z.array(z.object({
      name: z.string(),
      options: z.array(z.string()),
    })).optional(),

    // Ratings
    rating: z.number().min(0).max(5).optional(),
    reviewCount: z.number().int().nonnegative().default(0),

    // Publishing
    featured: z.boolean().default(false),
    onSale: z.boolean().default(false),
    badge: z.string().optional(), // e.g., "New", "Bestseller"

    // SEO
    slug: z.string().optional(),
    metaTitle: z.string().max(60).optional(),
    metaDescription: z.string().max(160).optional(),

    // Dates
    releaseDate: z.date().optional(),
    createdAt: z.date(),
    updatedAt: z.date().optional(),

    // Related products
    relatedProducts: z.array(z.string()).default([]),
    upsellProducts: z.array(z.string()).default([]),
  }),
});

/**
 * Example product frontmatter:
 *
 * ---
 * name: "Premium Wireless Headphones"
 * description: "High-quality wireless headphones with noise cancellation"
 * price: 299.99
 * originalPrice: 399.99
 * category: "Electronics"
 * subcategory: "Audio"
 * tags: ["wireless", "noise-cancelling", "premium"]
 * inStock: true
 * images:
 *   - url: "/images/headphones-1.jpg"
 *     alt: "Front view of headphones"
 *     isPrimary: true
 *   - url: "/images/headphones-2.jpg"
 *     alt: "Side view"
 * features:
 *   - "Active Noise Cancellation"
 *   - "30-hour battery life"
 *   - "Premium sound quality"
 * rating: 4.5
 * reviewCount: 128
 * onSale: true
 * badge: "Bestseller"
 * ---
 */
