// Astro Configuration - AI Tech Stack 1
// Complete configuration with React, MDX, Tailwind, and Sitemap integrations

import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import mdx from '@astrojs/mdx';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://example.com', // Replace with your actual domain

  integrations: [
    react(),
    mdx(),
    tailwind({
      applyBaseStyles: false, // Use custom Tailwind config
    }),
    sitemap(),
  ],

  // Output mode: 'static' for static site generation, 'server' for SSR
  output: 'static',

  // Markdown configuration
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      wrap: true,
    },
  },

  // Vite configuration for build optimizations
  vite: {
    optimizeDeps: {
      exclude: ['@astrojs/react'],
    },
  },
});
