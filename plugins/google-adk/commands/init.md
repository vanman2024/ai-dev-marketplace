---
description: Initialize Google ADK project with Python/TypeScript/Go/Java support
argument-hint: [language] [project-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Initialize a Google ADK (Agent Development Kit) project with the specified language runtime (Python, TypeScript, Go, or Java) and project structure.

Core Principles:
- Detect language from arguments or ask user
- Validate environment and prerequisites
- Follow Google ADK best practices for project structure
- Provide clear setup instructions

Phase 1: Discovery
Goal: Parse arguments and determine project requirements

Actions:
- Parse $ARGUMENTS to extract language and project name
- Check if running in existing directory or need to create new one
- Example: !{bash pwd}
- If language or project name unclear, use AskUserQuestion to gather:
  - Which language runtime? (Python, TypeScript, Go, or Java)
  - What is the project name?
  - Any specific ADK features needed? (LangChain, LangGraph, streaming)

Phase 2: Environment Check
Goal: Verify prerequisites for chosen language

Actions:
- Check if required tools are installed based on language:
  - Python: !{bash python3 --version 2>/dev/null || echo "Not installed"}
  - TypeScript: !{bash node --version 2>/dev/null || echo "Not installed"}
  - Go: !{bash go version 2>/dev/null || echo "Not installed"}
  - Java: !{bash java -version 2>/dev/null || echo "Not installed"}
- Check for existing Google ADK configuration
- Verify if directory is empty or has existing files: !{bash ls -la}

Phase 3: Project Setup
Goal: Initialize ADK project with proper structure

Actions:

Task(description="Initialize Google ADK project", subagent_type="google-adk-setup-agent", prompt="You are the google-adk-setup-agent. Initialize a Google ADK project for $ARGUMENTS.

Language: [Extracted from arguments]
Project Name: [Extracted from arguments]

Requirements:
- Create proper directory structure for the language runtime
- Set up ADK configuration files (.mcp.json, package.json/pyproject.toml/go.mod/pom.xml)
- Configure environment variables template (.env.example)
- Add sample agent implementation
- Include README with setup and usage instructions
- Follow Google ADK documentation standards

**Security**: Use placeholders for all API keys (GOOGLE_ADK_API_KEY=your_google_adk_key_here)

Deliverable: Complete project structure with all configuration files")

Phase 4: Post-Setup Verification
Goal: Verify initialization and provide next steps

Actions:
- Check created files exist: !{bash ls -la}
- Verify configuration files are valid
- Display project structure: !{bash tree -L 2 2>/dev/null || find . -maxdepth 2 -type f}

Phase 5: Summary
Goal: Report what was created and next steps

Actions:
- Summarize initialized project:
  - Language runtime configured
  - Files created
  - Configuration completed
- Provide clear next steps:
  - How to install dependencies
  - How to configure API keys
  - How to run the first agent
  - Link to Google ADK documentation
