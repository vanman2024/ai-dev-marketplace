# Changelog - Claude Agent SDK Plugin

All notable changes to this plugin will be documented in this file.

## [Unreleased] - 2025-11-02

### Fixed  
- **CRITICAL**: Corrected package name from `anthropic-agent-sdk` to `claude-agent-sdk`
- **CRITICAL**: Fixed MCP transport type for FastMCP Cloud from `"sse"` to `"http"`
- Updated validator to check for correct package name and warn about SSE/HTTP
- Agent now uses sdk-config-validator skill for validation
- Agent references examples instead of containing code snippets

### Added
- Examples with working code in `examples/python/`
- FastMCP integration skill in `skills/fastmcp-integration/`
- Enhanced validator checks for new patterns
- AGENT_SDK_FIXES.md documentation
- FASTMCP_CLOUD_API_KEY to .env template

### Changed
- Agent uses validator skill, references examples
- Validator checks correct package, warns about transport type

### Migration Guide

**Fix wrong package:**
```bash
pip uninstall anthropic-agent-sdk
pip install claude-agent-sdk
```

**Fix imports:**
```python
from claude_agent_sdk import query  # Correct!
```

**Fix MCP config:**
```python
"type": "http"  # For FastMCP Cloud
```

**Validate:**
```bash
bash skills/sdk-config-validator/scripts/validate-python.sh .
```
