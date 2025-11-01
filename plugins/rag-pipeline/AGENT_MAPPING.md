# Agent Mapping - Corrections Needed

## Incorrect References → Correct Agent Names

| Command Reference | Should Be | Purpose |
|------------------|-----------|---------|
| `rag-initializer` | `rag-architect` | Initialize RAG projects and make framework choices |
| `rag-specialist` | `llamaindex-specialist` or `langchain-specialist` | RAG implementation (context-dependent) |
| `parser-integration-specialist` | `document-processor` | Document parsing and chunking |
| `rag-embedding-configurator` | `embedding-specialist` | Embedding configuration |
| `rag-embedding-tester` | `embedding-specialist` | Embedding testing |
| `scraper-specialist` | `web-scraper-agent` | Web scraping |
| `deployment-engineer` | `rag-deployment-agent` | Deployment |
| `general-purpose` (many uses) | Specific agents | Replace with appropriate specialist |

## Files Needing Updates

Need to update all commands/*.md files to use correct agent names in Task() calls.
