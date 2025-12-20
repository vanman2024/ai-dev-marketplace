---
description: Add agent discovery mechanisms to project
argument-hint: [discovery-type]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add A2A Protocol agent discovery mechanisms to enable agents to find and connect with each other in multi-agent systems.

Core Principles:
- Understand project architecture before implementing discovery
- Support multiple discovery patterns (static, dynamic, hybrid)
- Follow A2A Protocol discovery specifications
- Provide clear examples and documentation

Phase 1: Discovery
Goal: Understand project context and discovery requirements

Actions:
- Parse $ARGUMENTS to determine discovery type preference
- If $ARGUMENTS is empty or unclear, use AskUserQuestion to gather:
  - Which discovery pattern? (static registry, dynamic DNS-SD, hybrid)
  - What agent metadata should be discoverable? (capabilities, protocols, endpoints)
  - Any existing service discovery infrastructure?
- Detect project type and framework
- Example: @package.json or @pyproject.toml
- Load existing A2A Protocol configuration if present
- Example: @a2a-config.json or @.a2a/config.yaml

Phase 2: Analysis
Goal: Analyze project structure and identify integration points

Actions:
- Search for existing agent implementations
- Example: !{bash find . -name "*agent*" -type f 2>/dev/null | head -10}
- Identify service registration locations
- Check for existing discovery mechanisms
- Understand deployment environment (local, cloud, containerized)

Phase 3: Planning
Goal: Design discovery implementation approach

Actions:
- Determine discovery pattern based on requirements:
  - Static Registry: Simple JSON/YAML configuration files
  - Dynamic DNS-SD: mDNS/Bonjour for local network discovery
  - Hybrid: Combination of static config + dynamic announcements
- Identify files to create or modify
- Plan agent metadata schema
- Consider security and authentication requirements

Phase 4: Implementation
Goal: Implement discovery mechanism via specialized agent

Actions:

Task(description="Implement A2A discovery mechanism", subagent_type="a2a-discovery", prompt="You are the a2a-discovery agent. Implement A2A Protocol agent discovery for $ARGUMENTS.

Context from analysis:
- Project type and framework detected
- Existing agent implementations identified
- Discovery pattern selected based on requirements

Requirements:
- Implement chosen discovery pattern (static/dynamic/hybrid)
- Create agent registry with metadata schema
- Add discovery client for finding other agents
- Include announcement mechanism for agent availability
- Provide clear documentation and examples
- Follow A2A Protocol discovery specifications
- Ensure backward compatibility with existing code

Expected output:
- Discovery implementation files (registry, client, announcements)
- Agent metadata schema definition
- Configuration files
- Integration with existing agent code
- Documentation with usage examples
- Test cases for discovery functionality")

Phase 5: Review
Goal: Verify discovery implementation

Actions:
- Check that discovery files were created
- Verify agent metadata schema is complete
- Review discovery client implementation
- Test discovery mechanism if applicable
- Example: !{bash npm run test:discovery 2>/dev/null || echo "No discovery tests configured"}

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize discovery mechanism implemented:
  - Discovery pattern used (static/dynamic/hybrid)
  - Files created (registry, client, config)
  - Agent metadata schema defined
  - Integration points updated
- Highlight key implementation decisions
- Show example usage of discovery API
- Suggest next steps:
  - Test discovery with multiple agents
  - Add authentication/authorization if needed
  - Configure discovery for production deployment
  - Set up monitoring for agent registry
