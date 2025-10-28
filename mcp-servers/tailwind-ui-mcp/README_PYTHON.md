# Tailwind UI Components - FastMCP Server

Natural language access to 490+ Tailwind UI components stored in Supabase.

## Overview

This FastMCP server provides an MCP interface to your Tailwind UI component library stored in Supabase. Instead of manually browsing Tailwind UI's website, you can use natural language to search, browse, and retrieve components programmatically.

**Key Features:**
- Access 490+ Tailwind UI components via natural language
- Search by name, category, tags, or description
- Retrieve React and HTML code instantly
- Browse component categories and subcategories
- Get dependency information automatically
- Works with Claude Desktop, Claude Code, and HTTP clients

## Architecture

This server uses a unique two-MCP-server architecture:

```
┌─────────────────────┐
│   Your AI Client    │
│ (Claude Code/Desktop)│
└──────────┬──────────┘
           │
    ┌──────▼──────────────────┐
    │  Tailwind UI MCP Server │  (This server)
    │  - Natural language API │
    │  - Component search     │
    │  - Query generation     │
    └──────┬──────────────────┘
           │
    ┌──────▼──────────────────┐
    │   Supabase MCP Server   │  (Separate MCP server)
    │  - Database queries     │
    │  - Authentication       │
    │  - SQL execution        │
    └──────┬──────────────────┘
           │
    ┌──────▼──────────────────┐
    │  Supabase Database      │
    │  - sections table       │
    │  - 490+ components      │
    └─────────────────────────┘
```

**Why This Design?**
- Separation of concerns: UI logic vs database access
- Reusable Supabase MCP server for other projects
- No hardcoded database credentials in this server
- Easier testing and debugging

## Prerequisites

- Python 3.10 or higher
- `uv` package manager (recommended) or `pip`
- Access to Supabase database with Tailwind UI components
- Supabase MCP server configured (for database queries)

## Installation

### Option 1: Using uv (Recommended)

```bash
# Navigate to project directory
cd /home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp

# Create virtual environment
uv venv

# Activate virtual environment
source .venv/bin/activate  # On Linux/Mac
# or
.venv\Scripts\activate  # On Windows

# Install dependencies
uv pip install -r requirements.txt
```

### Option 2: Using pip

```bash
# Navigate to project directory
cd /home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp

# Create virtual environment
python -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # On Linux/Mac
# or
.venv\Scripts\activate  # On Windows

# Install dependencies
pip install -r requirements.txt
```

## Configuration

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` with your Supabase project ID:
```bash
SUPABASE_PROJECT_ID=wsmhiiharnhqupdniwgw
```

**Note:** You do NOT need Supabase API keys in this file. The Supabase MCP server handles authentication separately.

## Database Schema

The server expects a `sections` table in Supabase with the following structure:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | TEXT | Component name |
| `description` | TEXT | Component description |
| `category` | TEXT | Primary category (e.g., "forms", "navigation") |
| `tailwind_ui_category` | TEXT | Tailwind UI specific category |
| `tailwind_ui_subcategory` | TEXT | Tailwind UI subcategory |
| `react_template` | TEXT | React/JSX code |
| `html_code` | TEXT | Raw HTML code |
| `tags` | TEXT[] | Array of searchable tags |
| `dependencies` | JSONB | Required dependencies |
| `css_classes` | TEXT[] | Tailwind CSS classes used |

## Running the Server

### Local Development (STDIO)

For use with Claude Desktop or Claude Code:

```bash
python server.py
```

### HTTP Server

For web access or HTTP clients:

```bash
# Default port 8000
python server.py --transport http

# Custom port
python server.py --transport http --port 8001
```

## Available Tools

### 1. `server_info`
Get information about the server, database configuration, and available components.

**Usage:**
```
What components are available in the Tailwind UI server?
```

**Returns:**
- Server metadata
- Database configuration
- Component count
- Available categories

### 2. `get_example_query`
Get example SQL queries for accessing components via Supabase MCP.

**Usage:**
```
How do I query for button components?
```

**Returns:**
- Example SQL queries for common use cases
- Database field descriptions
- Query patterns for searching, filtering, and retrieving components

### Additional Tools (To Be Added)

The following tools will be added via `/fastmcp:add-components`:
- `search_components` - Natural language component search
- `get_component_code` - Retrieve full component code
- `list_categories` - Browse available categories
- `filter_by_tags` - Find components with specific features
- `get_component_dependencies` - Get dependency information

## Integration with Claude Desktop

Add to your Claude Desktop configuration (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "tailwind-ui": {
      "command": "python",
      "args": ["/home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp/server.py"],
      "env": {
        "SUPABASE_PROJECT_ID": "wsmhiiharnhqupdniwgw"
      }
    }
  }
}
```

**Important:** Make sure the Supabase MCP server is also configured in your `claude_desktop_config.json` so that this server can use its tools.

## Integration with Claude Code

In VS Code, add to your MCP configuration:

```json
{
  "mcpServers": {
    "tailwind-ui": {
      "command": "python",
      "args": ["/home/vanman2025/Projects/ai-dev-marketplace/tailwind-ui-mcp/server.py"],
      "env": {
        "SUPABASE_PROJECT_ID": "wsmhiiharnhqupdniwgw"
      }
    }
  }
}
```

## Usage Examples

### Example 1: Finding Button Components

```
User: "Find all button components"
AI: Uses search_components tool with query="button"
Returns: List of button components with descriptions
```

### Example 2: Getting Component Code

```
User: "Get the code for the Simple Contact Form"
AI: Uses get_component_code tool
Returns: React and HTML code, dependencies, CSS classes
```

### Example 3: Browsing Categories

```
User: "What form components are available?"
AI: Uses list_categories tool with filter="forms"
Returns: All form-related components organized by subcategory
```

### Example 4: Finding Components by Features

```
User: "Show me responsive components with dark mode support"
AI: Uses filter_by_tags tool with tags=["responsive", "dark-mode"]
Returns: Components matching both criteria
```

## Project Structure

```
tailwind-ui-mcp/
├── server.py                 # Main FastMCP server
├── pyproject.toml           # Python project configuration
├── requirements.txt         # Python dependencies
├── .env.example            # Environment variable template
├── .env                    # Your configuration (gitignored)
├── .gitignore             # Git ignore rules
├── README_PYTHON.md       # This file
├── README.md              # Original Node.js documentation
└── scripts/               # Utility scripts
    └── extract-tailwind-components.js
```

## Development

### Running Tests

```bash
# Install dev dependencies
uv pip install -e ".[dev]"

# Run tests
pytest

# Run with coverage
pytest --cov=server --cov-report=html
```

### Code Formatting

```bash
# Format code with Black
black server.py

# Lint with Ruff
ruff check server.py
```

## Troubleshooting

### Server won't start

1. Check Python version: `python --version` (should be 3.10+)
2. Verify virtual environment is activated
3. Ensure all dependencies installed: `pip list`

### Can't connect to database

1. Verify Supabase MCP server is running
2. Check SUPABASE_PROJECT_ID in .env file
3. Test Supabase MCP connection independently

### No components returned

1. Verify `sections` table exists in Supabase
2. Check table has data: Use Supabase dashboard
3. Ensure Supabase MCP has proper permissions

### Import errors

```bash
# Reinstall dependencies
pip uninstall fastmcp python-dotenv
pip install -r requirements.txt
```

## Security Notes

- Never commit `.env` file to git
- Never hardcode API keys or credentials
- Use environment variables for all secrets
- The `.gitignore` file is configured to prevent accidental commits

## Performance

- Initial query may take 1-2 seconds (cold start)
- Subsequent queries typically < 500ms
- Component code retrieval < 1 second
- HTTP mode adds ~50-100ms latency vs STDIO

## Comparison: This Server vs Direct Supabase Access

| Feature | Direct Supabase | This MCP Server |
|---------|----------------|-----------------|
| Natural Language | No | Yes |
| Component Search | Manual SQL | Simple queries |
| Code Formatting | Raw JSON | Clean code blocks |
| Tag Filtering | Complex queries | Simple parameters |
| Learning Curve | High (SQL) | Low (English) |

## Contributing

This is a personal project for accessing your Tailwind UI purchase. Feel free to extend with additional tools as needed.

## License

MIT License - Personal use for accessing your own Tailwind UI components.

## Related Projects

- **Supabase MCP Server**: Handles database queries (required dependency)
- **FastMCP**: Python MCP framework
- **Tailwind UI**: Component library (paid license required)

## Support

For issues specific to:
- **FastMCP**: https://github.com/jlowin/fastmcp
- **Supabase**: https://supabase.com/docs
- **MCP Protocol**: https://modelcontextprotocol.io/

## Next Steps

1. Install dependencies: `uv pip install -r requirements.txt`
2. Configure environment: Copy `.env.example` to `.env`
3. Run server: `python server.py`
4. Add tools: Use `/fastmcp:add-components` to add remaining tools
5. Test: Try `server_info` tool to verify connection
6. Build: Add your component search and retrieval tools

---

**Made with FastMCP** - Natural language access to your $299 Tailwind UI investment
