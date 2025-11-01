# Changelog

All notable changes to the OpenRouter plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-31

### Added
- Initial release of OpenRouter plugin
- 5 commands for SDK integration and configuration:
  - `/openrouter:init` - Initialize OpenRouter SDK with API key configuration
  - `/openrouter:add-vercel-ai-sdk` - Add Vercel AI SDK integration
  - `/openrouter:add-langchain` - Add LangChain integration for chains, agents, and RAG
  - `/openrouter:add-model-routing` - Configure intelligent model routing and cost optimization
  - `/openrouter:configure` - Manage OpenRouter settings and preferences
- 4 specialized agents:
  - `openrouter-setup-agent` - SDK initialization with framework detection
  - `openrouter-vercel-integration-agent` - Vercel AI SDK integration
  - `openrouter-langchain-agent` - LangChain integration
  - `openrouter-routing-agent` - Model routing configuration
- 3 comprehensive skills with scripts, templates, and examples:
  - `model-routing-patterns` - 5 routing strategies, 4 scripts, 7 templates, 4 examples
  - `provider-integration-templates` - Vercel AI SDK, LangChain, OpenAI SDK templates
  - `openrouter-config-validator` - 8 validation scripts, 5 config templates, 6 troubleshooting guides
- Complete documentation with README, usage examples, and API references
- Support for 500+ models from 60+ providers
- Intelligent routing with cost optimization
- Framework integrations (Vercel AI SDK, LangChain, OpenAI SDK, PydanticAI)
