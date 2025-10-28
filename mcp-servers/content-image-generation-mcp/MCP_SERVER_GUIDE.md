# MCP Server Reference for Marketing Automation

**Quick guide on which MCP servers to use and when**

---

## 🔍 Available Supabase MCP Servers

### From Context7 Research

| MCP Server | Purpose | Use Case | Recommendation |
|-----------|---------|----------|----------------|
| **[alexander-zuev/supabase-mcp-server](https://github.com/alexander-zuev/supabase-mcp-server)** | Full Supabase operations | Safe SQL execution, schema management, API interaction | ✅ **RECOMMENDED for development** |
| **[coleam00/supabase-mcp](https://github.com/coleam00/supabase-mcp)** | Database operations via MCP | AI assistant database queries | ✅ Alternative option |
| **[supabase-community/supabase-mcp](https://github.com/supabase-community/supabase-mcp)** | Connect projects to AI assistants | Cursor/Claude integration | ✅ Good for IDE integration |

---

## 📋 Usage Recommendations

### For Development (Local)

**Use: SQLite + MCP Server (Local)**

```bash
# Run marketing automation MCP server in dev mode
cd mcp-servers/marketing-automation
export DATABASE_MODE=development
export DB_PATH=./marketing_automation.db
python server.py
```

**Characteristics:**
- ✅ Direct SQLite file access
- ✅ No network latency
- ✅ Fast iteration
- ✅ Easy to reset database
- ✅ MCP server has direct database access

### For Production (Remote)

**Use: Supabase Python Client + FastAPI + MCP Server**

```bash
# FastAPI server connects to Supabase
cd mcp-servers/marketing-automation
export DATABASE_MODE=production
export SUPABASE_URL=your_url
export SUPABASE_ANON_KEY=your_key
uvicorn production_server:app --host 0.0.0.0 --port 8000

# MCP server connects to FastAPI (not directly to Supabase)
export API_URL=http://localhost:8000
python mcp_server_prod.py
```

**Characteristics:**
- ✅ Supabase Python client for database access
- ✅ FastAPI provides REST API
- ✅ MCP server calls FastAPI (not Supabase directly)
- ✅ Better separation of concerns
- ✅ Authentication/authorization in FastAPI layer

---

## 🚫 What NOT to Use

### ❌ Supabase MCP Server for Production Client Access

**Why?**
- MCP servers from Context7 are designed for **local IDE/Claude Desktop integration**
- They typically use **STDIO transport** (not HTTP)
- Not designed for **remote client connections**
- No built-in authentication/rate limiting
- Not optimized for production workloads

### ❌ Direct Supabase Access from MCP Server in Production

**Why?**
- Bypasses application logic layer
- No centralized authentication
- Harder to implement business rules
- Difficult to audit access
- No caching layer

---

## ✅ Recommended Architecture

```
Development:
┌─────────────┐
│ Claude Code │
└──────┬──────┘
       │ STDIO
       ▼
┌──────────────────┐     Direct Access     ┌─────────────┐
│ MCP Server (Dev) │────────────────────────▶│   SQLite    │
└──────────────────┘                        └─────────────┘

Production:
┌─────────────┐
│ Claude Code │
└──────┬──────┘
       │ HTTP
       ▼
┌───────────────────┐     HTTP API      ┌──────────────┐
│ MCP Server (Prod) │──────────────────▶│   FastAPI    │
└───────────────────┘                   └──────┬───────┘
                                               │ Supabase
                                               │ Python
                                               │ Client
                                               ▼
                                        ┌──────────────┐
                                        │   Supabase   │
                                        │ (PostgreSQL) │
                                        └──────────────┘
```

---

## 🛠️ Setup Guide

### 1. Development Setup (SQLite)

```bash
# Install dependencies
cd mcp-servers/marketing-automation
pip install fastmcp sqlite3 anthropic google-generativeai

# Initialize database
python scripts/init_dev_db.py

# Run MCP server
export DATABASE_MODE=development
python server.py
```

### 2. Production Setup (Supabase + FastAPI)

**Step 1: Create Supabase Project**
```bash
# Install Supabase CLI
npm install -g supabase

# Initialize Supabase
supabase init

# Start local Supabase (for testing)
supabase start

# Apply migrations
supabase db push
```

**Step 2: Install Production Dependencies**
```bash
pip install fastmcp fastapi uvicorn supabase httpx redis
```

**Step 3: Configure Environment**
```bash
# .env.production
DATABASE_MODE=production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_key
REDIS_URL=redis://localhost:6379
API_URL=http://localhost:8000
```

**Step 4: Run FastAPI Server**
```bash
uvicorn production_server:app --reload
```

**Step 5: Run MCP Server (Production Mode)**
```bash
python mcp_server_prod.py
```

---

## 🔐 Security Considerations

### Development (SQLite)
- ✅ Local file access only
- ✅ No network exposure
- ✅ No authentication needed
- ✅ Safe for testing

### Production (Supabase)
- ✅ Row-Level Security (RLS) enabled
- ✅ API keys in environment variables
- ✅ FastAPI authentication middleware
- ✅ Rate limiting on FastAPI endpoints
- ✅ Supabase service role key for admin operations only
- ✅ Anon key for public operations

---

## 📊 Performance Comparison

| Aspect | SQLite (Dev) | Supabase (Prod) |
|--------|-------------|-----------------|
| **Latency** | <1ms | 50-100ms |
| **Throughput** | 10k+ ops/sec | 1k+ ops/sec |
| **Scalability** | Single process | Unlimited |
| **Concurrent Users** | 1 | Thousands |
| **Vector Search** | Basic | Optimized (pgvector) |
| **Real-time** | Not available | Built-in |
| **Backup** | Manual | Automatic |

---

## 🎯 Decision Matrix

**Use SQLite (Development) if:**
- ✅ Local development only
- ✅ Single developer
- ✅ Fast iteration needed
- ✅ No real-time requirements
- ✅ Simple queries

**Use Supabase (Production) if:**
- ✅ Multi-user access
- ✅ Remote access needed
- ✅ Vector search required
- ✅ Real-time updates needed
- ✅ Automatic backups important
- ✅ Scalability required

---

## 🚀 Migration Path

### SQLite → Supabase

```python
"""
migrate_to_supabase.py - Migrate from SQLite to Supabase
"""

import sqlite3
from supabase import create_client
import os

# Connect to SQLite
sqlite_conn = sqlite3.connect("marketing_automation.db")
sqlite_cursor = sqlite_conn.cursor()

# Connect to Supabase
supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_ROLE_KEY")  # Admin access for migration
)

# Migrate campaigns
print("Migrating campaigns...")
campaigns = sqlite_cursor.execute("SELECT * FROM campaigns").fetchall()
for campaign in campaigns:
    supabase.table("campaigns").insert({
        "id": campaign[0],
        "name": campaign[1],
        "campaign_type": campaign[2],
        # ... map all fields
    }).execute()

# Migrate content_assets
print("Migrating content assets...")
content = sqlite_cursor.execute("SELECT * FROM content_assets").fetchall()
for asset in content:
    supabase.table("content_assets").insert({
        # ... map all fields
    }).execute()

# Migrate social_posts
print("Migrating social posts...")
posts = sqlite_cursor.execute("SELECT * FROM social_posts").fetchall()
for post in posts:
    supabase.table("social_posts").insert({
        # ... map all fields
    }).execute()

print("Migration complete!")
```

---

## 📚 Additional Resources

### Supabase Python Client
- **Docs:** https://supabase.com/docs/reference/python/introduction
- **GitHub:** https://github.com/supabase/supabase-py
- **Examples:** https://supabase.com/docs/guides/database/python

### Supabase MCP Servers (for IDE integration)
- **alexander-zuev/supabase-mcp-server:** https://github.com/alexander-zuev/supabase-mcp-server
- **coleam00/supabase-mcp:** https://github.com/coleam00/supabase-mcp

### FastMCP
- **Docs:** https://gofastmcp.com
- **GitHub:** https://github.com/jlowin/fastmcp

---

**Remember:**
- Use **SQLite + MCP Server** for development
- Use **Supabase Python Client + FastAPI + MCP Server** for production
- Don't use Supabase MCP servers for production client access
- Agents will manage database schema across both environments
