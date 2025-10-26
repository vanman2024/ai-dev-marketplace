# Quick Start Guide

Get your Marketing Automation MCP server running in 5 minutes.

## Prerequisites

- Python 3.10 or higher
- Google Cloud account (for Imagen/Veo)
- Anthropic API key (for Claude)
- Google AI API key (for Gemini)

## Step 1: Setup Environment

```bash
# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

## Step 2: Configure API Keys

```bash
# Copy environment template
cp .env.example .env

# Edit .env and add your credentials:
# - GOOGLE_CLOUD_PROJECT
# - GOOGLE_APPLICATION_CREDENTIALS
# - ANTHROPIC_API_KEY
# - GOOGLE_API_KEY
```

### Get API Keys

1. **Google Cloud** (Imagen/Veo):
   - Go to https://console.cloud.google.com
   - Enable Vertex AI API
   - Create service account and download JSON key
   - Set `GOOGLE_APPLICATION_CREDENTIALS` to the key path

2. **Anthropic** (Claude):
   - Go to https://console.anthropic.com
   - Copy your API key
   - Set `ANTHROPIC_API_KEY` in .env

3. **Google AI** (Gemini):
   - Go to https://makersuite.google.com/app/apikey
   - Generate API key
   - Set `GOOGLE_API_KEY` in .env

## Step 3: Test the Server

```bash
# Verify installation
python test_server.py
```

You should see all available tools, resources, and prompts listed.

## Step 4: Run the Server

### Option A: Local Development (STDIO)

For use with Claude Desktop:

```bash
python server.py
```

### Option B: HTTP Server

For deployment or testing via HTTP:

```bash
python server.py --http
```

Server will start on http://0.0.0.0:8000

## Step 5: Add to Claude Desktop

1. Open Claude Desktop configuration file:
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

2. Add the server configuration:

```json
{
  "mcpServers": {
    "marketing-automation": {
      "command": "python",
      "args": [
        "/absolute/path/to/marketing-automation/server.py"
      ],
      "env": {
        "GOOGLE_CLOUD_PROJECT": "your-project-id",
        "GOOGLE_CLOUD_LOCATION": "us-central1",
        "GOOGLE_APPLICATION_CREDENTIALS": "/path/to/service-account-key.json",
        "ANTHROPIC_API_KEY": "sk-ant-api03-your-key",
        "GOOGLE_API_KEY": "your-google-ai-key"
      }
    }
  }
}
```

3. Restart Claude Desktop

## Using the Server

Once connected, you can ask Claude to:

### Generate Images
```
"Create a professional product image of a laptop using Imagen 3 in HD quality"
```

### Create Marketing Copy
```
"Generate an enthusiastic social media post about our new AI analytics platform"
```

### Estimate Campaign Costs
```
"Calculate the cost for a campaign with 10 HD images, 20 SD images, and 30 seconds of video"
```

### Generate Videos
```
"Create a 5-second marketing video showcasing our product with Veo 3"
```

## Troubleshooting

### Import Errors

```bash
pip install --force-reinstall -r requirements.txt
```

### Authentication Issues

```bash
# Test Google Cloud auth
gcloud auth application-default login

# Verify credentials are loaded
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print('API keys loaded')"
```

### Server Won't Start

1. Check Python version: `python --version` (must be 3.10+)
2. Verify virtual environment is activated
3. Check .env file exists and has correct values
4. Look for error messages in console

## Next Steps

1. Review the full README.md for detailed documentation
2. Explore all available tools with `python test_server.py`
3. Check pricing information before generating content
4. Set up cost tracking and alerts in Google Cloud Console

## Support Resources

- FastMCP Documentation: https://gofastmcp.com
- Google Vertex AI Docs: https://cloud.google.com/vertex-ai/docs
- Anthropic API Docs: https://docs.anthropic.com
- Google Gemini Docs: https://ai.google.dev

---

**Ready to automate your marketing with AI!**
