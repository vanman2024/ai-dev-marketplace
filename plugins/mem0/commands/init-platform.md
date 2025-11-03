---
description: Setup hosted Mem0 Platform with API keys and quick configuration
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Setup Mem0 Platform (hosted mode) with API key configuration and quick start code.

Core Principles:
- Quick setup with minimal configuration
- Platform handles infrastructure
- Enterprise features ready to use
- Provide usage examples

Phase 1: Package Installation
Goal: Install Mem0 Platform client

Actions:
- Detect language (Python or JavaScript/TypeScript)
- Install correct package:
  - Python: pip install mem0ai
  - JavaScript/TypeScript: npm install mem0ai
- Verify installation successful
- Check package versions

Phase 2: API Key Configuration
Goal: Setup environment variables

Actions:
- Create or update .env file with MEM0_API_KEY placeholder
- Add .env to .gitignore if not already present
- Create .env.example for documentation
- Explain how to get API key from https://app.mem0.ai

Phase 3: Client Code Generation
Goal: Create memory client initialization code

Actions:

Launch the mem0-integrator agent to generate Platform client code.

Provide the agent with:
- Mode: Platform (hosted)
- Language: [Detected from Phase 1]
- Requirements:
  - Generate MemoryClient initialization code
  - Add example memory operations (add, search, get, update, delete)
  - Include error handling
  - Add TypeScript types (if applicable)
- Expected output: Working memory client code with examples

Phase 4: Verification
Goal: Test Platform connection

Actions:
- Test client initialization (will fail without API key, but validates code)
- Show sample usage code
- Verify environment setup is correct

Phase 5: Summary
Goal: Show setup results and instructions

Actions:
- Display what was configured:
  - Package installed: mem0ai@version
  - Client code created: [file path]
  - Environment template: .env.example
- Show next steps:
  1. Get API key from https://app.mem0.ai
  2. Add key to .env file: MEM0_API_KEY=your-key-here
  3. Test with sample code
  4. Use /mem0:add-conversation-memory to integrate with chat
  5. Use /mem0:configure for advanced settings
- Provide documentation link: https://docs.mem0.ai/platform/quickstart
