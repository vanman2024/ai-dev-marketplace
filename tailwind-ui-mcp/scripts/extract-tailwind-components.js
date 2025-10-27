#!/usr/bin/env node
/**
 * Tailwind UI Component Extractor
 * 
 * Extracts all components from Tailwind UI using authenticated session.
 * Based on the successful Figma MCP extraction pattern (1,054 components).
 * 
 * Usage:
 *   1. Get cookies: node extract-cookies.js
 *   2. Run extractor: node extract-tailwind-components.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs').promises;
const path = require('path');

// Tailwind UI component categories to extract
const TAILWIND_UI_STRUCTURE = {
  'application-ui': {
    name: 'Application UI',
    sections: [
      'application-shells',
      'headings',
      'forms',
      'lists',
      'navigation',
      'overlays',
      'page-examples',
      'layout',
      'elements',
      'data-display',
      'feedback'
    ]
  },
  'marketing': {
    name: 'Marketing',
    sections: [
      'page-examples',
      'heroes',
      'feature-sections',
      'cta-sections',
      'headers',
      'pricing',
      'testimonials',
      'newsletter-sections',
      'stats',
      'blog-sections',
      'team-sections',
      'contact-sections',
      'footers',
      'logo-clouds',
      'banners',
      'faq-sections'
    ]
  },
  'ecommerce': {
    name: 'Ecommerce',
    sections: [
      'page-examples',
      'storefront',
      'product-overviews',
      'category-filters',
      'product-lists',
      'product-quickviews',
      'shopping-carts',
      'category-previews',
      'store-navigation',
      'promo-sections',
      'checkout-forms',
      'reviews',
      'order-summaries',
      'order-history'
    ]
  }
};

class TailwindUIExtractor {
  constructor() {
    this.components = [];
    this.cookiesPath = path.join(__dirname, '..', 'data', 'tailwind-cookies.json');
    this.outputPath = path.join(__dirname, '..', 'data', 'tailwind-ui-components.json');
  }

  async loadCookies() {
    try {
      const cookiesData = await fs.readFile(this.cookiesPath, 'utf-8');
      return JSON.parse(cookiesData);
    } catch (error) {
      console.error('❌ Could not load cookies. Run extract-cookies.js first!');
      throw error;
    }
  }

  async extractComponent(page, componentElement) {
    try {
      // Get component name from heading
      const name = await componentElement.$eval(
        'h3, h4, [class*="heading"]',
        el => el.textContent.trim()
      ).catch(() => 'Unnamed Component');

      // Get description if available
      const description = await componentElement.$eval(
        'p, [class*="description"]',
        el => el.textContent.trim()
      ).catch(() => '');

      // Click "Show code" button
      const codeButton = await componentElement.$('button:has-text("Show code"), button:has-text("View code")');

      if (!codeButton) {
        console.log(`  ⚠️  No code button found for: ${name}`);
        return null;
      }

      await codeButton.click();
      await page.waitForTimeout(500); // Wait for code panel

      // Extract code from all available tabs (HTML, React, Vue)
      const codes = await page.evaluate(() => {
        const result = {};

        // Find code tabs
        const tabs = document.querySelectorAll('[role="tab"], [class*="code-tab"]');
        const codeBlocks = document.querySelectorAll('pre code, [class*="code-block"]');

        if (codeBlocks.length === 1) {
          // Single code block (usually HTML)
          result.html = codeBlocks[0].textContent;
        } else {
          // Multiple tabs - try to identify them
          tabs.forEach((tab, index) => {
            const tabName = tab.textContent.trim().toLowerCase();
            const code = codeBlocks[index]?.textContent || '';

            if (tabName.includes('html') || tabName.includes('template')) {
              result.html = code;
            } else if (tabName.includes('react') || tabName.includes('jsx')) {
              result.react = code;
            } else if (tabName.includes('vue')) {
              result.vue = code;
            }
          });
        }

        return result;
      });

      // Extract dependencies from code
      const dependencies = this.extractDependencies(codes);

      // Close code panel
      const closeButton = await page.$('button:has-text("Hide code"), [aria-label="Close"]');
      if (closeButton) await closeButton.click();

      return {
        name,
        description,
        ...codes,
        dependencies,
        extractedAt: new Date().toISOString()
      };

    } catch (error) {
      console.error(`  ❌ Error extracting component: ${error.message}`);
      return null;
    }
  }

  extractDependencies(codes) {
    const deps = new Set();
    const allCode = Object.values(codes).join('\n');

    // Common dependencies to look for
    const depPatterns = {
      '@headlessui/react': /@headlessui\/react/,
      '@heroicons/react': /@heroicons\/react/,
      'framer-motion': /framer-motion/,
      'react-transition-group': /react-transition/,
      'tailwindcss-forms': /form-/,
      'tailwindcss-typography': /prose/,
      'tailwindcss-aspect-ratio': /aspect-/
    };

    Object.entries(depPatterns).forEach(([dep, pattern]) => {
      if (pattern.test(allCode)) {
        deps.add(dep);
      }
    });

    return Array.from(deps);
  }

  async extractSection(browser, category, section) {
    const url = `https://tailwindui.com/components/${category}/${section}`;
    console.log(`\n📄 Extracting: ${category}/${section}`);
    console.log(`   URL: ${url}`);

    const page = await browser.newPage();

    try {
      await page.goto(url, {
        waitUntil: 'networkidle0',
        timeout: 30000
      });

      // Wait for components to load
      await page.waitForSelector('[class*="component"], [class*="preview"]', {
        timeout: 10000
      });

      // Get all component containers on the page
      const componentElements = await page.$$('[class*="component-container"], [class*="preview-container"]');

      console.log(`   Found ${componentElements.length} components`);

      for (const [index, element] of componentElements.entries()) {
        console.log(`   [${index + 1}/${componentElements.length}] Extracting...`);

        const component = await this.extractComponent(page, element);

        if (component) {
          this.components.push({
            ...component,
            category,
            section,
            url,
            index
          });
          console.log(`   ✅ ${component.name}`);
        }
      }

    } catch (error) {
      console.error(`   ❌ Error processing ${section}: ${error.message}`);
    } finally {
      await page.close();
    }
  }

  async extract() {
    console.log('🚀 Starting Tailwind UI Component Extraction');
    console.log('   (Using same pattern that extracted 1,054 Figma components)');

    const cookies = await this.loadCookies();

    const browser = await puppeteer.launch({
      headless: false, // Set to true for production
      defaultViewport: { width: 1920, height: 1080 },
      args: ['--no-sandbox']
    });

    const page = await browser.newPage();
    await page.setCookie(...cookies);

    // Verify authentication by visiting home page
    await page.goto('https://tailwindui.com', { waitUntil: 'networkidle0' });

    const isAuthenticated = await page.evaluate(() => {
      // Check for signed-in indicators
      return document.body.textContent.includes('Your account') ||
        document.querySelector('[href*="/account"]') !== null;
    });

    if (!isAuthenticated) {
      console.error('❌ Not authenticated! Please update your cookies.');
      await browser.close();
      return;
    }

    console.log('✅ Authenticated successfully\n');

    // Extract all sections
    for (const [categoryKey, categoryData] of Object.entries(TAILWIND_UI_STRUCTURE)) {
      console.log(`\n${'='.repeat(60)}`);
      console.log(`📦 ${categoryData.name} (${categoryData.sections.length} sections)`);
      console.log('='.repeat(60));

      for (const section of categoryData.sections) {
        await this.extractSection(browser, categoryKey, section);

        // Be respectful - wait between requests
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }

    await browser.close();

    // Save results
    await this.saveComponents();
    this.printSummary();
  }

  async saveComponents() {
    const outputDir = path.dirname(this.outputPath);
    await fs.mkdir(outputDir, { recursive: true });

    await fs.writeFile(
      this.outputPath,
      JSON.stringify(this.components, null, 2)
    );

    console.log(`\n💾 Saved to: ${this.outputPath}`);
  }

  printSummary() {
    console.log('\n' + '='.repeat(60));
    console.log('📊 EXTRACTION SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total components: ${this.components.length}`);

    const byCategory = this.components.reduce((acc, comp) => {
      acc[comp.category] = (acc[comp.category] || 0) + 1;
      return acc;
    }, {});

    console.log('\nBy category:');
    Object.entries(byCategory).forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count} components`);
    });

    const withReact = this.components.filter(c => c.react).length;
    const withVue = this.components.filter(c => c.vue).length;

    console.log(`\nCode variants:`);
    console.log(`  HTML: ${this.components.length}`);
    console.log(`  React: ${withReact}`);
    console.log(`  Vue: ${withVue}`);

    console.log('\n✨ Extraction complete!');
    console.log('\nNext steps:');
    console.log('  1. Review: less data/tailwind-ui-components.json');
    console.log('  2. Import: node scripts/import-to-supabase.js');
    console.log('  3. Use: Start the MCP server in VS Code');
  }
}

// Run the extractor
if (require.main === module) {
  const extractor = new TailwindUIExtractor();
  extractor.extract().catch(console.error);
}

module.exports = TailwindUIExtractor;
