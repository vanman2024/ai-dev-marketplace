# RAG Pipeline Agent Mapping

## Agents

| Agent                            | Model  | Purpose                                                              |
| -------------------------------- | ------ | -------------------------------------------------------------------- |
| `@google-file-search-specialist` | Sonnet | Google File Search API implementation - stores, uploads, search, RAG |
| `@document-processor`            | Haiku  | Document parsing - PDF, DOCX, HTML, Markdown extraction              |

## Usage

### Google File Search Specialist

```
@google-file-search-specialist Build a RAG system for technical documentation
```

- Creates File Search stores
- Uploads and processes documents
- Implements semantic search
- Builds RAG endpoints with citations
- Integrates with Gemini models

### Document Processor

```
@document-processor Parse and prepare documents from /docs folder
```

- Extracts text from PDFs
- Processes Word documents
- Cleans HTML content
- Handles Markdown files
- Creates batch processing scripts

## Workflow

1. **Prepare Documents**: Use `@document-processor` to parse and clean source documents
2. **Build RAG System**: Use `@google-file-search-specialist` to create stores, upload, and implement search
3. **Generate**: Query with Gemini for RAG responses with citations

## Skills Auto-Loading

Agents automatically access relevant skills:

- `google-file-search` - File Search API patterns
- `document-parsers` - Document parsing utilities
- `chunking-strategies` - Chunking configuration
