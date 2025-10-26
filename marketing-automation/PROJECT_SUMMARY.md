# Marketing Automation MCP Server - Project Summary

## Overview

Production-ready FastMCP server for AI-powered marketing automation, featuring:
- Google Imagen 3/4 for high-quality image generation
- Google Veo 2/3 for video content creation
- Claude Sonnet 4 and Gemini 2.0 Flash for content generation
- Comprehensive cost estimation and tracking
- Ready for HTTP deployment or Claude Desktop integration

## Project Structure

```
marketing-automation/
├── server.py                          # Main FastMCP server implementation
├── test_server.py                     # Server validation and demo script
├── pyproject.toml                     # Python project configuration
├── requirements.txt                   # Dependencies (pip format)
├── fastmcp.json                       # FastMCP server configuration
├── .env.example                       # Environment variables template
├── .gitignore                         # Git ignore rules (includes .env)
├── README.md                          # Complete documentation
├── QUICKSTART.md                      # 5-minute setup guide
├── claude_desktop_config.example.json # Claude Desktop integration example
├── .venv/                            # Virtual environment (not committed)
└── output/                           # Generated content directory
```

## Features Implemented

### Tools (5)
1. **generate_image_imagen3** - Image generation with Imagen 3/4
2. **batch_generate_images** - Batch image processing
3. **generate_video_veo3** - Video generation with Veo 2/3
4. **generate_marketing_content** - AI copywriting (Claude/Gemini)
5. **calculate_cost_estimate** - Campaign budget planning

### Resources (2)
1. **config://pricing** - Current API pricing information
2. **config://models** - Available AI models and capabilities

### Prompts (2)
1. **campaign_planner** - Interactive campaign planning assistant
2. **image_prompt_enhancer** - Optimize image generation prompts

## Technology Stack

- **Framework**: FastMCP 2.13.0
- **Python**: 3.10+ required
- **Google Cloud**: Vertex AI Platform SDK
- **Anthropic**: Claude API SDK
- **Google AI**: Generative AI SDK
- **Environment**: python-dotenv
- **Validation**: Pydantic 2.x

## Security Features

- Environment variable configuration (no hardcoded credentials)
- .env excluded from git
- Service account authentication for Google Cloud
- API key rotation support
- Secure credential handling patterns

## Deployment Options

### 1. Local Development (STDIO)
```bash
python server.py
```
Use with Claude Desktop for interactive testing.

### 2. HTTP Server
```bash
python server.py --http
```
Accessible at http://0.0.0.0:8000 for web integration.

### 3. Claude Desktop Integration
Add to claude_desktop_config.json (see example file).

### 4. Cloud Deployment
- Docker support ready
- Vercel compatible
- FastMCP Cloud ready
- Environment variable injection supported

## Configuration Requirements

### Required Environment Variables
```env
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
ANTHROPIC_API_KEY=sk-ant-api03-xxx
GOOGLE_API_KEY=your-google-key
```

### Optional Variables
```env
MCP_SERVER_NAME=Marketing Automation
MCP_SERVER_PORT=8000
ENABLE_COST_TRACKING=true
COST_ALERT_THRESHOLD=100.00
```

## API Pricing (Approximate)

| Service | Unit | Cost (USD) |
|---------|------|------------|
| Imagen 3 SD | per image | $0.020 |
| Imagen 3 HD | per image | $0.040 |
| Imagen 4 SD | per image | $0.025 |
| Imagen 4 HD | per image | $0.050 |
| Veo 2 | per second | $0.15 |
| Veo 3 | per second | $0.20 |
| Claude Sonnet | per 1K tokens | $0.003 |
| Gemini Pro | per 1K tokens | $0.0005 |

## Testing

### Verify Installation
```bash
source .venv/bin/activate
python test_server.py
```

Expected output:
- Server name and version
- List of 5 tools
- List of 2 resources
- List of 2 prompts
- Usage examples

### Test Server Import
```bash
python -c "from server import mcp; print(f'Server: {mcp.name}')"
```

### Validate FastMCP Version
```bash
python -c "import fastmcp; print(fastmcp.__version__)"
```

## Error Handling

All tools return structured responses with:
```python
{
    "success": bool,
    "result": Any,  # on success
    "error": str,   # on failure
    "metadata": dict  # additional info
}
```

## Best Practices

1. **Always use environment variables** - Never hardcode API keys
2. **Monitor costs** - Use calculate_cost_estimate before generating content
3. **Test locally first** - Verify API credentials before deployment
4. **Use seed parameter** - For reproducible image generation
5. **Batch operations** - Use batch_generate_images for efficiency
6. **Set cost alerts** - Configure Google Cloud billing alerts

## Future Enhancements

Planned features for future versions:
- [ ] OAuth 2.1 authentication
- [ ] Image style templates library
- [ ] Video editing capabilities
- [ ] Multi-language content generation
- [ ] A/B testing support
- [ ] Campaign analytics integration
- [ ] Template management system
- [ ] Automated social media posting

## Documentation

- **README.md** - Complete documentation with all features
- **QUICKSTART.md** - 5-minute setup guide
- **PROJECT_SUMMARY.md** - This file, project overview
- **claude_desktop_config.example.json** - Integration example
- **.env.example** - Environment configuration template

## Dependencies

Core dependencies (auto-installed):
- fastmcp >= 2.13.0
- google-cloud-aiplatform >= 1.40.0
- anthropic >= 0.40.0
- google-generativeai >= 0.3.0
- python-dotenv >= 1.0.0
- pydantic >= 2.0.0

## Installation Success Criteria

- ✅ Virtual environment created
- ✅ All dependencies installed
- ✅ Server imports without errors
- ✅ Test script runs successfully
- ✅ Configuration files present
- ✅ Documentation complete
- ✅ Security best practices followed

## Quick Commands Reference

```bash
# Setup
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env

# Test
python test_server.py

# Run (STDIO)
python server.py

# Run (HTTP)
python server.py --http

# Verify
python -c "from server import mcp; print(mcp.name)"
```

## Support

For issues or questions:
1. Check QUICKSTART.md for common issues
2. Review README.md for detailed documentation
3. Verify API credentials and quotas
4. Check FastMCP documentation: https://gofastmcp.com
5. Review Google Cloud Vertex AI docs
6. Validate Python version (3.10+)

## Version History

**v0.1.0** - October 25, 2025
- Initial release
- FastMCP 2.13.0 integration
- 5 tools, 2 resources, 2 prompts
- Imagen 3/4 support
- Veo 2/3 support (preview)
- Claude Sonnet 4 integration
- Gemini 2.0 Flash integration
- Cost estimation
- HTTP and STDIO transport
- Complete documentation

---

**Project Status**: Production Ready
**License**: Apache 2.0
**Python Version**: 3.10+
**FastMCP Version**: 2.13.0

Built with FastMCP - The fast, Pythonic way to build MCP servers.
