# Changelog

All notable changes to the Domain Plugin Builder will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-24

### Added
- Universal plugin builder for domain-specific plugins
- Support for SDK plugins (Claude Agent SDK, Vercel AI SDK, etc.)
- Support for Framework plugins (Next.js, FastAPI, etc.)
- Support for Custom plugins (domain-specific tooling)
- Context7 MCP integration for fetching library documentation
- WebFetch integration for scraping documentation
- Comprehensive validation scripts
- Automatic root file creation (README, LICENSE, CHANGELOG, .mcp.json)
- Functional script generation for skills
- Agent template with Step 0 requirement

### Features
- Progressive context loading
- Interactive plugin type selection
- Documentation fetching from multiple sources
- Validation script execution in build process
- Project-agnostic design enforcement
- Hardcoded path detection and prevention

### Commands
- /domain-plugin-builder:plugin-create - Universal plugin builder
- /domain-plugin-builder:slash-commands-create - Create slash commands
- /domain-plugin-builder:skills-create - Create skills with functional scripts
- /domain-plugin-builder:agents-create - Create agents with proper structure
