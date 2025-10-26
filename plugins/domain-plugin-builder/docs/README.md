# Domain Plugin Builder Documentation

Central documentation for building domain-specific plugins for Claude Code.

## 📚 Documentation Structure

### 🏗️ Architecture
High-level concepts and marketplace organization strategies.

- **[04-plugin-marketplaces.md](architecture/04-plugin-marketplaces.md)** - Plugin marketplace fundamentals
- **[06-tech-stack-marketplaces.md](architecture/06-tech-stack-marketplaces.md)** - Tech stack marketplace architecture
  - Three-tier marketplace organization
  - Hybrid documentation pattern (static + Context7)
  - Plugin initialization patterns
  - Version pinning strategies

### 🔧 Frameworks
Claude Code framework-specific documentation.

- **[03-claude-code-plugins.md](frameworks/03-claude-code-plugins.md)** - Claude Code plugin development guide

### 🚀 SDKs
AI/ML SDK integration documentation with curated links.

- **[claude-agent-sdk-documentation.md](sdks/claude-agent-sdk-documentation.md)** - Claude Agent SDK reference
- **[claude-api-documentation.md](sdks/claude-api-documentation.md)** - Claude API reference
- **[mem0-documentation.md](sdks/mem0-documentation.md)** - Mem0 memory management reference

### 📖 Reference
Comprehensive documentation link collections.

- **[ai-development-documentation-links.md](reference/ai-development-documentation-links.md)** - Master collection of AI development resources
  - Vercel AI SDK
  - OpenAI
  - Anthropic Claude
  - LangChain
  - Vector databases
  - And more...

---

## 🎯 Quick Start Guides

### Building a New SDK Plugin

1. **Read architecture docs** to understand marketplace organization
2. **Review SDK documentation** for the target SDK
3. **Use domain-plugin-builder commands**:
   ```bash
   /domain-plugin-builder:plugin-create my-sdk-plugin
   ```

### Building a Tech Stack Marketplace

1. **Read** `architecture/06-tech-stack-marketplaces.md`
2. **Understand** the three-tier architecture
3. **Design** your plugin combination
4. **Implement** using the hybrid documentation pattern

---

## 📋 Documentation Categories Explained

### Architecture Docs
**Purpose:** Understand HOW to organize plugins and marketplaces

**When to use:**
- Planning a new marketplace
- Understanding plugin organization
- Learning version management
- Designing multi-plugin systems

### Framework Docs
**Purpose:** Learn framework-specific implementation details

**When to use:**
- Building Claude Code plugins
- Understanding framework constraints
- Implementing framework patterns

### SDK Docs
**Purpose:** Quick reference for specific SDKs with curated links

**When to use:**
- Implementing features from a specific SDK
- Finding SDK documentation quickly
- Understanding SDK capabilities

### Reference Docs
**Purpose:** Comprehensive link collections for research

**When to use:**
- Exploring available SDKs/tools
- Finding official documentation
- Researching best practices
- Discovering new technologies

---

## 🔄 Documentation Patterns

### Static Documentation (These Files)
- **Use for:** Concepts, architecture, patterns, guides
- **Benefits:** Offline access, version controlled, curated
- **Location:** This docs/ directory

### Dynamic Documentation (Context7 MCP)
- **Use for:** Latest API reference, up-to-date examples
- **Benefits:** Always current, official sources
- **Access via:** Commands that invoke agents with WebFetch

### Hybrid Approach
Most effective: Use BOTH
- Static docs for initialization and concepts
- Context7 for implementing features and checking latest API

---

## 🛠️ Maintaining Documentation

### Adding New SDK Documentation

1. Create file in `sdks/` directory
2. Include curated documentation links
3. Organize by feature area
4. Add examples and common patterns
5. Update this README

### Adding Architecture Documentation

1. Create file in `architecture/` directory
2. Focus on patterns and organization
3. Include diagrams and examples
4. Explain trade-offs
5. Update this README

### Updating Reference Links

1. Edit files in `reference/` directory
2. Group by category
3. Include brief descriptions
4. Verify links work
5. Keep current with SDK updates

---

## 📌 Key Concepts

### Three-Tier Marketplace Architecture

```
dev-lifecycle-marketplace (HOW you develop)
         ↓
ai-dev-marketplace (WHAT you develop with)
         ↓
tech-stack-marketplaces (Curated combinations)
```

### Plugin Types

- **Lifecycle plugins:** Tech-agnostic workflow (01-core, 02-develop, etc.)
- **Tech plugins:** SDK/framework-specific (vercel-ai-sdk, mem0, etc.)
- **Builder plugins:** Meta-tools for building other plugins (domain-plugin-builder)

### Documentation Strategy

- **Init phase:** Use static docs from this directory
- **Feature phase:** Use Context7 MCP for latest API
- **Reference phase:** Combine both for comprehensive understanding

---

## 🔗 External Resources

- **Claude Code Documentation:** https://docs.claude.com/en/docs/claude-code
- **Plugin Development:** https://docs.claude.com/en/docs/claude-code/plugins
- **MCP Protocol:** https://modelcontextprotocol.io

---

## 📝 Contributing

When adding documentation:

1. **Choose the right category** (architecture, frameworks, sdks, reference)
2. **Follow existing patterns** in similar docs
3. **Include practical examples**
4. **Keep links current**
5. **Update this README**

---

**Last Updated:** 2025-10-25
**Maintained by:** domain-plugin-builder team
