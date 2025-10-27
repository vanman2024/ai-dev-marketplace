# Tailwind UI MCP Server

Make your Tailwind UI purchase actually accessible! This MCP server provides natural language access to all your Tailwind UI components.

## The Problem This Solves

You paid $299 for Tailwind UI but accessing components is painful:
- ❌ Manual copy/paste from website
- ❌ No search functionality
- ❌ Hard to organize and reuse
- ❌ Can't browse offline

## The Solution

Natural language interface to your Tailwind UI library:
- ✅ "Show me all button components"
- ✅ "Find form layouts with validation"
- ✅ "Get the e-commerce product card"
- ✅ Search 500+ components instantly

## Quick Start

### Prerequisites

1. **Valid Tailwind UI license** (already purchased ✓)
2. **One-time component extraction** using authenticated browser
3. **Supabase project** (free tier works)

### Installation

```bash
cd tailwind-ui-mcp
npm install
```

### Step 1: Extract Your Tailwind UI Components

We'll use your existing cookie-based authentication approach:

```bash
# 1. Get your Tailwind UI session cookies
node scripts/extract-cookies.js

# 2. Run the component extractor (one-time)
node scripts/extract-tailwind-components.js

# This creates: data/tailwind-ui-components.json (~2MB)
```

### Step 2: Import to Supabase

```bash
# Run the database migration
psql -h db.xxx.supabase.co -U postgres -d postgres < migrations/001_tailwind_ui_schema.sql

# Import extracted components
node scripts/import-to-supabase.js
```

### Step 3: Add MCP Server to VS Code

Add to `.vscode/mcp.json`:

```json
{
  "mcpServers": {
    "tailwind-ui": {
      "command": "node",
      "args": ["/path/to/tailwind-ui-mcp/src/server.js"],
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_SERVICE_KEY": "your-service-key"
      }
    }
  }
}
```

## MCP Tools

### `search_tailwind_components`
Search your Tailwind UI library naturally:
```
"Find all button variants"
"Show me e-commerce product cards"
"Get form layouts with inline validation"
```

### `get_component_code`
Get the full HTML/React code for a component:
```
Component: "Simple Newsletter Sign Up"
Category: "Marketing → Newsletter Sections"
→ Returns full code ready to use
```

### `list_categories`
Browse all available Tailwind UI categories:
- Application UI (Shell, Navigation, Forms, Lists, etc.)
- Marketing (Heroes, Features, CTAs, Pricing, etc.)
- Ecommerce (Product Lists, Carts, Checkout, etc.)

### `get_component_preview`
Get component metadata and preview URL

### `install_component`
Copy component directly into your project:
```
install_component(
    name="Stacked Layout",
    destination="src/components/layouts/"
)
```

## Component Extraction Details

### What Gets Extracted

For each Tailwind UI component:
- **HTML Code**: Full component markup
- **React Code**: React version (if available)
- **Vue Code**: Vue version (if available)
- **Metadata**: Category, name, description
- **Dependencies**: Required JS libraries
- **Variants**: All color/size variations

### Extraction Strategy

Since Playwright can't access logged-in pages easily, we use:

**Method 1: Browser Extension (Recommended)**
- Install our Chrome extension
- Browse Tailwind UI normally
- Extension captures components as you view them
- Auto-syncs to local database

**Method 2: Manual Session Transfer**
- Export session from authenticated browser
- Use Puppeteer with session cookies
- Automated scraping of all pages
- One-time extraction (~30 minutes)

**Method 3: Import Pre-Extracted**
- If you already manually copied components
- Import existing HTML files
- Parse and categorize automatically

## Database Schema

```sql
CREATE TABLE tailwind_ui_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT,
    description TEXT,
    html_code TEXT,
    react_code TEXT,
    vue_code TEXT,
    preview_url TEXT,
    tags TEXT[],
    dependencies JSONB,
    complexity TEXT, -- 'simple' | 'intermediate' | 'complex'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_components_category ON tailwind_ui_components(category);
CREATE INDEX idx_components_tags ON tailwind_ui_components USING GIN(tags);
CREATE INDEX idx_components_search ON tailwind_ui_components USING GIN(
    to_tsvector('english', name || ' ' || description || ' ' || category)
);
```

## Usage Examples

### Example 1: Building a Dashboard

```javascript
// Ask the MCP
"Show me application shell layouts with sidebar navigation"

// Returns:
- Stacked Layout (simple sidebar)
- Multi-Column Layout (complex dashboard)
- Sidebar with Header (modern app layout)

// Get the code:
get_component_code("Multi-Column Layout")

// Install it:
install_component("Multi-Column Layout", "src/layouts/")
```

### Example 2: E-commerce Product Page

```javascript
// Search for what you need
"Find e-commerce product detail layouts with image gallery"

// Browse results
list_components({ category: "ecommerce", subcategory: "product-pages" })

// Get the code
get_component_code("Product Detail with Image Carousel")
```

### Example 3: Marketing Landing Page

```javascript
// Build a landing page from components
"Show me hero sections with background images"
"Find feature sections with 3 columns"
"Get newsletter signup forms"
"Find footer navigation sections"

// Assemble into your page
```

## Project Structure

```
tailwind-ui-mcp/
├── src/
│   ├── server.js              # Main MCP server
│   ├── supabase-client.js     # Database operations
│   ├── component-search.js    # Search & filtering
│   └── code-extractor.js      # Component extraction
├── scripts/
│   ├── extract-cookies.js           # Get auth cookies
│   ├── extract-tailwind-components.js  # Scrape components
│   └── import-to-supabase.js        # Database import
├── migrations/
│   └── 001_tailwind_ui_schema.sql   # Database schema
├── data/
│   └── tailwind-ui-components.json  # Extracted components
└── README.md
```

## Comparison: Tailwind UI vs Shadcn

| Feature | Tailwind UI (your purchase) | Shadcn (free) |
|---------|---------------------------|---------------|
| **Cost** | $299 | Free |
| **Components** | 500+ production-ready | 449 basic components |
| **Complexity** | Full page layouts, dashboards | Individual UI elements |
| **Accessibility** | Hard (manual copy/paste) | Easy (CLI) |
| **With This MCP** | ✅ Easy (natural language) | ✅ Already easy |

**Your Advantage**: You have BOTH!
- Use Shadcn for basic UI elements (buttons, inputs)
- Use Tailwind UI for complex layouts (dashboards, product pages)
- This MCP makes Tailwind UI as accessible as Shadcn

## Next Steps

1. **Run the extractor** (one-time setup)
2. **Import to Supabase** (stores your components)
3. **Add MCP to VS Code** (enables natural language access)
4. **Start building** with your $299 investment finally accessible!

## Troubleshooting

### "Can't access Tailwind UI pages"
- Use the browser extension method
- Or manually export your session cookies

### "Extraction takes too long"
- Extract category by category
- Cache results as you go
- Only extract what you need

### "Missing React/Vue code"
- Tailwind UI shows React/Vue tabs - make sure to capture all tabs
- The extractor auto-switches between code views

## Legal Note

This tool is for **personal use** with your valid Tailwind UI license. The components remain Tailwind's intellectual property - this just makes YOUR purchased components more accessible to YOU.

## Support

Based on your successful Figma MCP extraction of 1,054 components, this should extract your full Tailwind UI library (~500-600 components) in a similar way.
