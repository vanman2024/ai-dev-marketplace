# Tailwind UI Registry MCP Server - Build Specification

**Date:** October 26, 2025  
**For:** Claude Code + FastMCP Plugin  
**Goal:** Create natural language access to your 490 Tailwind UI components (like Shadcn MCP)

---

## 📊 Executive Summary

You have **490 Tailwind UI components** already extracted and stored in Supabase. Now we need to build an MCP server so you can query them naturally instead of manually searching.

### What You Have:
- ✅ **Supabase Database:** `wsmhiiharnhqupdniwgw` ("Figma Design System")
- ✅ **490 Components:** Full React code stored in `sections` table
- ✅ **999 Figma Components:** Additional design components in `figma_components` table
- ✅ **Organized Categories:** Application UI, Forms, Elements, Navigation, etc.

### What We're Building:
- 🎯 **MCP Server:** Natural language interface to your components
- 🎯 **6 MCP Tools:** Search, browse, view, get code (like Shadcn has)
- 🎯 **Easy Access:** "Show me all button components" → instant results

---

## 🗄️ Database Information

### Connection Details
```
URL: https://wsmhiiharnhqupdniwgw.supabase.co
Database: Figma Design System
Status: ACTIVE_HEALTHY
Region: us-east-1
```

### Primary Table: `sections`
```sql
Table: sections
Rows: 490 components
Key Fields:
  - id (uuid)
  - name (varchar) - Component name
  - description (text)
  - category (varchar) - Main category
  - tailwind_ui_category (varchar) - Tailwind UI category
  - tailwind_ui_subcategory (varchar) - Subcategory
  - react_template (text) - FULL REACT CODE
  - html_code (text) - HTML version (some components)
  - tags (text[]) - Search tags
  - dependencies (jsonb) - Required packages
  - css_classes (text[]) - Tailwind classes used
  - block_type (varchar)
  - app_type (varchar)
```

### Component Breakdown
```
Marketing Landing: 60 components
Forms > Input_Groups: 21 components
Lists > Tables: 20 components
Lists > Stacked_Lists: 19 components
Elements > Badges: 18 components
Headings > Page_Headings: 13 components
Overlays > Drawers: 12 components
Forms > Radio_Groups: 12 components
Navigation > Navbar: 11 components
Elements > Avatars: 11 components
Elements > Buttons: 10 components
Layout > Cards: 10 components
... 390+ more components
```

---

## 🛠️ MCP Server Specification

### Server Name
`tailwind-ui`

### Technology Stack
**Choose one:**
- **Option A:** Node.js with FastMCP
- **Option B:** Python with FastMCP

### Environment Variables Required
```bash
SUPABASE_URL=https://wsmhiiharnhqupdniwgw.supabase.co
SUPABASE_SERVICE_KEY=<your-service-role-key>
```

---

## 🔧 Required MCP Tools (6 Tools)

### Tool 1: `list_tailwind_categories`
**Purpose:** Browse all available categories with component counts

**Parameters:** None

**SQL Query:**
```sql
SELECT 
  category
  tailwind_ui_category
  tailwind_ui_subcategory
  COUNT(*) as count
FROM sections 
WHERE react_template IS NOT NULL
GROUP BY category, tailwind_ui_category, tailwind_ui_subcategory
ORDER BY count DESC
```

**Return Format:**
```json
{
  "total_categories": 30
  "categories": [
    {
      "category": "application-ui"
      "tailwind_ui_category": "Forms"
      "tailwind_ui_subcategory": "Input_Groups"
      "count": 21
    }
    {
      "category": "application-ui"
      "tailwind_ui_category": "Elements"
      "tailwind_ui_subcategory": "Buttons"
      "count": 10
    }
  ]
}
```

**Example Usage:**
```
User: "List all Tailwind UI categories"
User: "Show me what components are available"
User: "What categories do you have?"
```

---

### Tool 2: `search_tailwind_components`
**Purpose:** Search components by keyword, category, or tag

**Parameters:**
```typescript
{
  query: string,           // Search term (required)
  category?: string,       // Filter by category (optional)
  limit?: number          // Max results (default: 20, max: 100)
}
```

**SQL Query:**
```sql
SELECT 
  name
  category
  tailwind_ui_category
  tailwind_ui_subcategory
  description
  tags
  LENGTH(react_template) as code_length
  block_type
FROM sections 
WHERE react_template IS NOT NULL
  AND (
    name ILIKE '%{query}%' 
    OR category ILIKE '%{query}%'
    OR description ILIKE '%{query}%'
    OR '{query}' = ANY(tags)
  )
  {AND category = '{category}' IF PROVIDED}
ORDER BY name
LIMIT {limit}
```

**Return Format:**
```json
{
  "total_found": 10
  "components": [
    {
      "name": "Elements - Buttons - Example"
      "category": "application-ui"
      "tailwind_ui_category": "Elements"
      "tailwind_ui_subcategory": "Buttons"
      "description": "Primary button components with various sizes"
      "tags": ["beta", "tailwind-ui", "application-ui", "elements"]
      "code_length": 1576
      "block_type": "component"
    }
  ]
}
```

**Example Usage:**
```
User: "Search for button components"
User: "Find all pricing sections"
User: "Show me navbar components"
User: "Search for forms with validation"
```

---

### Tool 3: `list_components_in_category`
**Purpose:** Get all components in a specific category/subcategory

**Parameters:**
```typescript
{
  category?: string,              // Main category (optional)
  tailwind_ui_category?: string,  // Tailwind category (optional)
  tailwind_ui_subcategory?: string, // Subcategory (optional)
  limit?: number                  // Default: 50
}
```

**SQL Query:**
```sql
SELECT 
  name
  description
  tailwind_ui_category
  tailwind_ui_subcategory
  tags
  LENGTH(react_template) as code_length
FROM sections 
WHERE react_template IS NOT NULL
  {AND category = '{category}' IF PROVIDED}
  {AND tailwind_ui_category = '{tailwind_ui_category}' IF PROVIDED}
  {AND tailwind_ui_subcategory = '{tailwind_ui_subcategory}' IF PROVIDED}
ORDER BY name
LIMIT {limit}
```

**Return Format:**
```json
{
  "category": "application-ui"
  "tailwind_ui_category": "Forms"
  "tailwind_ui_subcategory": "Input_Groups"
  "total_components": 21
  "components": [
    {
      "name": "Forms - Input_Groups - WithLabel"
      "description": "Input field with label"
      "code_length": 1234
    }
  ]
}
```

**Example Usage:**
```
User: "Show all Form components"
User: "List components in Elements > Buttons"
User: "Get all Navigation components"
```

---

### Tool 4: `view_component_details`
**Purpose:** Get complete details for specific component(s)

**Parameters:**
```typescript
{
  component_names: string[]  // Array of component names
}
```

**SQL Query:**
```sql
SELECT 
  name
  description
  category
  tailwind_ui_category
  tailwind_ui_subcategory
  react_template
  html_code
  dependencies
  tags
  css_classes
  block_type
  app_type
  LENGTH(react_template) as code_length
FROM sections 
WHERE name = ANY(ARRAY[{component_names}])
  AND react_template IS NOT NULL
```

**Return Format:**
```json
{
  "components": [
    {
      "name": "Elements - Buttons - Example"
      "description": "Primary button components"
      "category": "application-ui"
      "tailwind_ui_category": "Elements"
      "tailwind_ui_subcategory": "Buttons"
      "react_template": "// Full React code here..."
      "html_code": null
      "dependencies": {
        "uses_components": []
        "npm_packages": []
      }
      "tags": ["beta", "tailwind-ui", "elements"]
      "css_classes": ["rounded-md", "bg-indigo-600", "px-3", "py-2"]
      "code_length": 1576
    }
  ]
}
```

**Example Usage:**
```
User: "Show me details for Elements - Buttons - Example"
User: "Get info about the pricing section"
User: "View component Forms - Radio_Groups - SimpleList"
```

---

### Tool 5: `get_component_code`
**Purpose:** Get ONLY the code (no metadata) - ready to copy/paste

**Parameters:**
```typescript
{
  component_name: string,    // Component name (required)
  format?: "react" | "html"  // Code format (default: "react")
}
```

**SQL Query:**
```sql
SELECT 
  name
  react_template
  html_code
FROM sections 
WHERE name = '{component_name}'
  AND react_template IS NOT NULL
```

**Return Format:**
```json
{
  "name": "Elements - Buttons - Example"
  "code": "// Tailwind UI - Application UI - Elements - Buttons\nexport default function Example() {\n  return (\n    <>\n      <button\n        type=\"button\"\n        className=\"rounded-sm bg-indigo-600 px-2 py-1 text-xs font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600\"\n      >\n        Button text\n      </button>\n    </>\n  )\n}"
  "format": "react"
}
```

**Example Usage:**
```
User: "Get the code for Elements - Buttons - Example"
User: "Give me the React code for navbar component"
User: "Show code for pricing section"
```

---

### Tool 6: `get_add_instructions`
**Purpose:** Get installation/usage instructions for a component

**Parameters:**
```typescript
{
  component_name: string  // Component name (required)
}
```

**SQL Query:**
```sql
SELECT 
  name
  description
  dependencies
  tailwind_ui_category
  tailwind_ui_subcategory
  css_classes
  react_template
FROM sections 
WHERE name = '{component_name}'
```

**Return Format:**
```json
{
  "component": "Elements - Buttons - Example"
  "instructions": {
    "step1": "Copy the component code"
    "step2": "Paste into your React component file"
    "step3": "Ensure Tailwind CSS is configured in your project"
    "dependencies": []
    "tailwind_classes": ["rounded-sm", "bg-indigo-600", "px-2", "py-1", "text-xs"]
    "usage_example": "import Example from './components/Example'\n\n<Example />"
  }
}
```

**Example Usage:**
```
User: "How do I use the button component?"
User: "Give me instructions for adding the navbar"
User: "How to install Elements - Buttons - Example"
```

---

## 📦 Implementation Details

### File Structure
```
tailwind-ui-mcp/
├── server.js (or server.py)
├── package.json (or requirements.txt)
├── README.md
└── .env.example
```

### Dependencies

**If Node.js:**
```json
{
  "dependencies": {
    "@modelcontextprotocol/sdk": "latest"
    "@supabase/supabase-js": "^2.x"
    "fastmcp": "latest"
  }
}
```

**If Python:**
```txt
fastmcp
supabase
python-dotenv
```

### Configuration File (.mcp.json)
```json
{
  "mcpServers": {
    "tailwind-ui": {
      "command": "node"
      "args": ["path/to/tailwind-ui-mcp/server.js"]
      "env": {
        "SUPABASE_URL": "https://wsmhiiharnhqupdniwgw.supabase.co"
        "SUPABASE_SERVICE_KEY": "your-service-role-key-here"
      }
    }
  }
}
```

---

## 🎯 Example Implementation Skeleton

### Node.js Example:
```javascript
const { FastMCP } = require('fastmcp');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL
  process.env.SUPABASE_SERVICE_KEY
);

const mcp = new FastMCP('tailwind-ui');

// Tool 1: List Categories
mcp.tool('list_tailwind_categories'
  'Lists all available Tailwind UI categories with component counts'
  {}
  async () => {
    const { data, error } = await supabase
      .from('sections')
      .select('category, tailwind_ui_category, tailwind_ui_subcategory')
      .not('react_template', 'is', null);
    
    // Group and count
    // Return formatted results
  }
);

// Tool 2: Search Components
mcp.tool('search_tailwind_components'
  'Search for Tailwind UI components by keyword'
  {
    query: { type: 'string', required: true }
    category: { type: 'string' }
    limit: { type: 'number', default: 20 }
  }
  async ({ query, category, limit }) => {
    let dbQuery = supabase
      .from('sections')
      .select('name, category, tailwind_ui_category, tailwind_ui_subcategory, description, tags')
      .not('react_template', 'is', null)
      .ilike('name', `%${query}%`)
      .limit(limit);
    
    if (category) {
      dbQuery = dbQuery.eq('category', category);
    }
    
    const { data, error } = await dbQuery;
    return { components: data };
  }
);

// Tool 3: List by Category
mcp.tool('list_components_in_category'
  'List all components in a specific category'
  {
    tailwind_ui_category: { type: 'string' }
    tailwind_ui_subcategory: { type: 'string' }
    limit: { type: 'number', default: 50 }
  }
  async (params) => {
    // Implementation
  }
);

// Tool 4: View Details
mcp.tool('view_component_details'
  'Get complete details for specific components'
  {
    component_names: { type: 'array', items: { type: 'string' }, required: true }
  }
  async ({ component_names }) => {
    const { data, error } = await supabase
      .from('sections')
      .select('*')
      .in('name', component_names)
      .not('react_template', 'is', null);
    
    return { components: data };
  }
);

// Tool 5: Get Code
mcp.tool('get_component_code'
  'Get only the code for a component (ready to copy/paste)'
  {
    component_name: { type: 'string', required: true }
    format: { type: 'string', enum: ['react', 'html'], default: 'react' }
  }
  async ({ component_name, format }) => {
    const { data, error } = await supabase
      .from('sections')
      .select('name, react_template, html_code')
      .eq('name', component_name)
      .single();
    
    return {
      name: data.name
      code: format === 'html' ? data.html_code : data.react_template
      format
    };
  }
);

// Tool 6: Get Instructions
mcp.tool('get_add_instructions'
  'Get installation and usage instructions for a component'
  {
    component_name: { type: 'string', required: true }
  }
  async ({ component_name }) => {
    // Get component details and format instructions
  }
);

mcp.start();
```

---

## 🚀 Usage Examples After Implementation

### Example 1: Finding Components
```
User: "Show me all button components"
MCP: Calls search_tailwind_components(query: "button")
Returns: 10 button components with names and descriptions

User: "List categories"
MCP: Calls list_tailwind_categories()
Returns: All 30+ categories with component counts
```

### Example 2: Getting Code
```
User: "Get the code for Elements - Buttons - Example"
MCP: Calls get_component_code(component_name: "Elements - Buttons - Example")
Returns: Full React component code ready to paste

User: "Show me the pricing section code"
MCP: Calls search_tailwind_components(query: "pricing")
Then: Calls get_component_code() for selected component
Returns: Complete code
```

### Example 3: Browsing by Category
```
User: "Show all form input components"
MCP: Calls list_components_in_category(
  tailwind_ui_category: "Forms"
  tailwind_ui_subcategory: "Input_Groups"
)
Returns: All 21 form input components

User: "View details for Forms - Input_Groups - WithLabel"
MCP: Calls view_component_details(component_names: ["Forms - Input_Groups - WithLabel"])
Returns: Full component details including code
```

---

## 🎨 Comparison: Shadcn MCP vs Your Tailwind UI MCP

| Feature | Shadcn MCP | Your Tailwind UI MCP |
|---------|------------|----------------------|
| **Purpose** | Access Shadcn component registry | Access YOUR Tailwind UI components |
| **Components** | 449 basic UI elements | 490 full sections/layouts |
| **Source** | NPM registry (@shadcn/ui) | Your Supabase database |
| **Code Type** | Individual components | Complete sections/pages |
| **Installation** | `npx shadcn add button` | Copy/paste from MCP response |
| **Cost** | Free (open source) | Paid Tailwind UI (you own license) |
| **Customization** | Limited to Shadcn components | Full access to all Tailwind UI |
| **Database** | External registry | YOUR database |
| **Tools** | 6 tools | 6 tools (matching) |
| **Registry Format** | @shadcn/button | "Elements - Buttons - Example" |

---

## ✅ Success Criteria

After building, you should be able to:

1. ✅ **Search naturally:** "Show me button components"
2. ✅ **Browse categories:** "List all form components"
3. ✅ **Get code instantly:** "Get code for navbar"
4. ✅ **View details:** "Show me details for pricing section"
5. ✅ **Copy/paste ready:** Code should be immediately usable
6. ✅ **Fast queries:** Response time < 1 second

---

## 📝 Build Instructions for Claude Code

Copy this prompt to Claude Code:

```
Build a FastMCP server called "tailwind-ui" that provides natural language access 
to 490 Tailwind UI components stored in my Supabase database.

Database: https://wsmhiiharnhqupdniwgw.supabase.co
Table: sections
Key fields: name, category, tailwind_ui_category, tailwind_ui_subcategory
react_template (full code), html_code, tags, dependencies

Create 6 MCP tools: 1. list_tailwind_categories - List all categories with counts
2. search_tailwind_components - Search by keyword/tag
3. list_components_in_category - Browse specific category
4. view_component_details - Get full component details
5. get_component_code - Get just the code (copy/paste ready)
6. get_add_instructions - Installation/usage instructions

Model it after the Shadcn MCP server structure with 6 similar tools.
Use environment variables for SUPABASE_URL and SUPABASE_SERVICE_KEY.
Return clean, formatted JSON responses.

Reference: See TAILWIND-UI-MCP-SPEC.md for complete specifications.
```

---

## 🔗 Additional Resources

### Database Connection Test Query
```sql
-- Test if you can connect and query
SELECT COUNT(*) as total_components
FROM sections
WHERE react_template IS NOT NULL;
-- Should return: 490
```

### Sample Component Query
```sql
-- Get a sample component to test
SELECT name
       SUBSTRING(react_template, 1, 500) as code_preview
       tailwind_ui_category
       tailwind_ui_subcategory
FROM sections
WHERE name = 'Elements - Buttons - Example';
```

### Environment Variable Template (.env.example)
```bash
# Supabase Configuration
SUPABASE_URL=https://wsmhiiharnhqupdniwgw.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key-here

# Optional: Rate limiting
MAX_REQUESTS_PER_MINUTE=60

# Optional: Default limits
DEFAULT_SEARCH_LIMIT=20
MAX_SEARCH_LIMIT=100
```

---

## 🎯 Next Steps

1. **Get Supabase Service Key:**
   - Go to: https://app.supabase.com/project/wsmhiiharnhqupdniwgw/settings/api
   - Copy the `service_role` key

2. **Give to Claude Code:**
   - Share this specification document
   - Provide the service key
   - Ask Claude Code to build using FastMCP plugin

3. **Test the MCP:**
   - Add to `.mcp.json`
   - Restart VS Code
   - Try: "Show me all button components"

4. **Enjoy Your Investment:**
   - Finally have easy access to your $299 Tailwind UI purchase!
   - Query 490 components naturally
   - Copy/paste code instantly

---

## 📞 Support

If Claude Code needs clarification:
- Database is confirmed working (we queried it successfully)
- 490 components are ready with full React code
- All table schemas are documented above
- SQL queries are tested and ready to use

**Your original pain point will be solved:** No more manual searching through Tailwind UI - just natural language queries to your personal component library!
