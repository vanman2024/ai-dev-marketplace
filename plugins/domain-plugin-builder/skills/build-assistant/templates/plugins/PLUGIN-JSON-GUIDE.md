# Plugin.json Configuration Guide

## Critical Rule: Auto-Discovery vs Custom Paths

**Auto-Discovered (DO NOT list in plugin.json):**
- `commands/` directory → All `.md` files auto-discovered
- `agents/` directory → All `.md` files auto-discovered
- `skills/` directory → All `SKILL.md` files auto-discovered

**Only List in plugin.json IF using custom/non-standard locations**

---

## Example 1: Standard Structure (Most Common)

**Directory structure:**
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── deploy.md
│   └── validate.md
├── agents/
│   ├── orchestrator.md
│   └── validator.md
└── skills/
    └── deployment-skill/
        └── SKILL.md
```

**plugin.json (NO commands/agents/skills fields):**
```json
{
  "name": "my-plugin"
  "version": "1.0.0"
  "description": "Deployment automation"
  "author": {
    "name": "Dev Team"
    "email": "dev@example.com"
  }
  "license": "MIT"
  "keywords": ["deployment"]
}
```

**Why:** Everything is in default directories - auto-discovered automatically.

---

## Example 2: Custom Locations (Rare)

**Directory structure:**
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/              ← Auto-discovered (default)
│   └── deploy.md
├── specialized/           ← Custom location
│   └── advanced-deploy.md
└── custom-agents/         ← Custom location
    └── reviewer.md
```

**plugin.json (List ONLY custom paths):**
```json
{
  "name": "my-plugin"
  "version": "1.0.0"
  "description": "Deployment automation"
  "author": {
    "name": "Dev Team"
    "email": "dev@example.com"
  }
  "license": "MIT"
  "keywords": ["deployment"]
  "commands": ["./specialized/advanced-deploy.md"]
  "agents": ["./custom-agents/reviewer.md"]
}
```

**Result:**
- `commands/deploy.md` loaded (auto-discovered)
- `specialized/advanced-deploy.md` loaded (from plugin.json)
- `custom-agents/reviewer.md` loaded (from plugin.json)

---

## ❌ WRONG: Duplication Error

**Directory structure:**
```
my-plugin/
├── commands/
│   └── deploy.md
└── agents/
    └── orchestrator.md
```

**plugin.json (CAUSES DUPLICATION):**
```json
{
  "name": "my-plugin"
  "commands": ["./commands/deploy.md"],     ❌ WRONG
  "agents": ["./agents/orchestrator.md"]    ❌ WRONG
}
```

**Why wrong:**
- `deploy.md` loaded from auto-discovery
- `deploy.md` loaded AGAIN from plugin.json listing
- **Result: Command appears TWICE**

---

## Template Default

Our `plugin.json.template` defaults to:
```json
{
  "name": "{{PLUGIN_NAME}}"
  "version": "{{VERSION}}"
  "description": "{{DESCRIPTION}}"
  "author": {
    "name": "{{AUTHOR_NAME}}"
    "email": "{{AUTHOR_EMAIL}}"
  }
  "homepage": "{{HOMEPAGE_URL}}"
  "repository": "{{REPOSITORY_URL}}"
  "license": "{{LICENSE}}"
  "keywords": {{KEYWORDS}}
}
```

**No `commands`, `agents`, or `skills` fields** - assumes standard structure.

---

## When Building Plugins

**For /build-lifecycle-plugin:**
1. Creates standard structure (commands/, agents/, skills/)
2. Generates plugin.json WITHOUT component fields
3. Everything auto-discovered
4. No duplication issues

**Only add component fields manually if:**
- You have scripts in non-standard locations
- You're organizing differently for a specific reason
- You understand the supplemental (not replacement) behavior

---

## Quick Reference

| Scenario | Include in plugin.json? |
|:---------|:------------------------|
| Component in `commands/` | ❌ No (auto-discovered) |
| Component in `agents/` | ❌ No (auto-discovered) |
| Component in `skills/` | ❌ No (auto-discovered) |
| Component in `custom-dir/` | ✅ Yes (must specify path) |
| Both default AND custom | ✅ List only custom paths |

---

**Rule of thumb:** If you're using standard directories, leave `commands`, `agents`, `skills` out of plugin.json entirely.
