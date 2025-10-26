# CATS MCP Server

FastMCP server for CATS (Complete Applicant Tracking System) API v3 with dynamic toolset loading.

## Overview

This MCP server provides access to **163 tools** across **17 toolsets** covering the complete CATS API v3. The toolset architecture allows agents to load only what they need, optimizing token usage and performance.

**Key Features:**
- 🎯 **163 MCP tools** covering all CATS API v3 endpoints
- 📦 **17 toolsets** organized by resource type
- ⚡ **Dynamic loading** - load only what you need
- 🔐 **Secure** - token-based authentication, no hardcoded credentials
- 📝 **Type-safe** - full type hints on all tools
- 📚 **Well-documented** - comprehensive docstrings with examples
- 🚀 **Production-ready** - error handling, async/await, tested

## Quick Start

```bash
# 1. Install dependencies
pip install fastmcp httpx python-dotenv

# 2. Configure
cp .env.example .env
# Edit .env with your CATS_API_KEY

# 3. Run
python server.py --list-toolsets  # See available toolsets
python server.py                  # Load default toolsets (77 tools)
python server.py --toolsets all   # Load all 163 tools
```

## Architecture

### Toolset Organization

**DEFAULT Toolsets (77 tools)** - Loaded by default:
- **candidates** (28 tools) - Candidate management + sub-resources
- **jobs** (29 tools) - Job management, lists, applications
- **pipelines** (12 tools) - Pipeline workflows and status management
- **context** (3 tools) - Site info, user info, authorization
- **tasks** (5 tools) - Task management

**RECRUITING Toolsets (64 tools)** - Optional:
- **companies** (22 tools) - Company management + departments
- **contacts** (25 tools) - Contact management + communications
- **activities** (6 tools) - Activity tracking (calls, meetings, emails)
- **portals** (8 tools) - Career portals and applications
- **work_history** (3 tools) - Employment history management

**DATA & CONFIG Toolsets (22 tools)** - Optional:
- **tags** (2 tools) - Global tag management
- **webhooks** (4 tools) - Webhook subscriptions with 24+ event types
- **users** (2 tools) - User and permissions management
- **triggers** (2 tools) - Automated trigger information
- **attachments** (4 tools) - File management + AI resume parsing
- **backups** (3 tools) - Database backup management
- **events** (5 tools) - Calendar events and scheduling

### Token Efficiency

Agents load only needed toolsets, dramatically reducing token usage:

| Toolsets | Tools Loaded | Use Case |
|----------|--------------|----------|
| Default | 77 (~47%) | Core recruiting |
| candidates,companies | 50 (~31%) | Candidate sourcing |
| all | 163 (100%) | Full API access |

## Installation

### 1. Setup

```bash
# Clone repository
cd cats-mcp-server

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install fastmcp httpx python-dotenv
```

### 2. Configure

Create `.env` file:

```bash
CATS_API_BASE_URL=https://api.catsone.com/v3
CATS_API_KEY=your_cats_api_key_here

# Optional: Default toolsets
CATS_TOOLSETS=candidates,jobs,companies
```

### 3. Add to Claude Desktop

Edit `~/.claude/config.json`:

```json
{
  "mcpServers": {
    "cats": {
      "command": "python",
      "args": ["/path/to/cats-mcp-server/server.py"],
      "env": {
        "CATS_API_BASE_URL": "https://api.catsone.com/v3",
        "CATS_API_KEY": "your_api_key",
        "CATS_TOOLSETS": "candidates,jobs,companies"
      }
    }
  }
}
```

## Usage

### Command Line

```bash
# List toolsets
python server.py --list-toolsets

# Default (77 tools)
python server.py

# Specific toolsets
python server.py --toolsets candidates,jobs,companies

# Everything (163 tools)
python server.py --toolsets all

# Environment variable
export CATS_TOOLSETS='candidates,pipelines'
python server.py
```

### Common Combinations

```bash
# Recruiting team
--toolsets candidates,jobs,pipelines,companies,activities

# Hiring manager
--toolsets candidates,jobs,pipelines,events

# Administrator
--toolsets users,webhooks,backups,triggers,tags

# Full access
--toolsets all
```

## API Coverage

### Complete Tool List

**Candidates (28 tools)**
- Main: list, get, create, update, delete, search, filter, authorize
- Sub-resources: pipelines, activities, attachments, custom fields, emails, phones, tags, work history

**Jobs (29 tools)**
- Main: list, get, create, update, delete, search, filter
- Sub-resources: activities, attachments, custom fields, tags
- Job lists: full CRUD + item management
- Applications: list, get details, get fields

**Pipelines (12 tools)**
- Main: list, get, create, update, delete, filter
- Workflows: list workflows/statuses
- Status management: get history, change status

**Companies (22 tools)**
- Main: list, get, create, update, delete, search, filter
- Sub-resources: activities, attachments, contacts, custom fields, departments, pipelines, tags

**Contacts (25 tools)**
- Main: list, get, create, update, delete, search, filter
- Sub-resources: activities, attachments, custom fields, emails, phones, pipelines, tags

**Activities (6 tools)**
- list, get, update, delete, search, filter
- Types: email, meeting, call_talked, call_lvm, call_missed, text_message, other

**Portals (8 tools)**
- list, get, list jobs
- submit application, publish/unpublish jobs
- registration forms

**Work History (3 tools)**
- get, update, delete

**Tags (2 tools)**
- list, get

**Webhooks (4 tools)**
- list, get, create, delete
- 24+ event types with HMAC-SHA256 verification

**Users (2 tools)**
- list, get
- Access levels: read_only, edit, admin

**Triggers (2 tools)**
- list, get

**Attachments (4 tools)**
- get, delete, download
- **parse_resume** - AI-powered resume parsing

**Backups (3 tools)**
- list, get, create
- Options: attachments, emails

**Events (5 tools)**
- Full CRUD: list, get, create, update, delete
- Attendees, virtual meeting URLs, calendar integration

**Context (3 tools)**
- get_site, get_me, authorize_user

**Tasks (5 tools)**
- Full CRUD with priority, assignments, due dates

## Development

### File Structure

```
cats-mcp-server/
├── server.py                  # Core (242 lines)
├── toolsets_default.py        # Default (1,611 lines, 77 tools)
├── toolsets_recruiting.py     # Recruiting (1,364 lines, 64 tools)
├── toolsets_data.py           # Data (1,017 lines, 22 tools)
├── .env                       # Config (not in git)
├── .env.example               # Template
├── README.md                  # This file
└── cats-v3-api-endpoints.md   # API reference
```

### Testing

```bash
# Syntax check
python -m py_compile server.py toolsets_*.py

# List toolsets
python server.py --list-toolsets

# Test loading
python server.py --toolsets candidates
```

## Troubleshooting

### Common Issues

**"CATS_API_KEY not configured"**
- Set in `.env` or export as environment variable

**"Module not found: toolsets_*"**
- Ensure all three toolset files exist

**Rate Limiting (500 req/hour)**
- Monitor `X-Rate-Limit-Remaining` header
- Implement backoff on 429 errors

**401 Unauthorized**
- Verify API v3 key (not v2)
- Check key permissions

## Resources

- **CATS API:** https://docs.catsone.com/api/v3/
- **FastMCP:** https://gofastmcp.com/
- **MCP Protocol:** https://modelcontextprotocol.io/

## License

Provided as-is for CATS API v3 integration. Follow CATS API terms of service.

## Changelog

### 2025-01-26 - v1.0.0
- Initial release with toolset architecture
- 163 tools across 17 toolsets
- Dynamic loading via CLI/environment
- Complete CATS API v3 coverage
- Production-ready
