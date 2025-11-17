---
description: Add code execution with MCP pattern for 98.7% token reduction - generates typed tool wrappers and enables efficient tool usage via code
argument-hint: [mcp-server-name]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---


**Arguments**: $ARGUMENTS

**Reference**: https://www.anthropic.com/engineering/code-execution-with-mcp

Goal: Implement code execution with MCP pattern in Claude Agent SDK application - transforms MCP servers into code APIs for 98.7% token reduction through progressive disclosure, context-efficient filtering, and familiar programming patterns.

Core Principles:
- Present MCP servers as filesystem APIs (servers/ directory tree)
- Generate typed wrappers for on-demand tool loading
- Filter data in execution environment before returning to model
- Use familiar programming patterns for control flow
- Enable state persistence across executions

Phase 1: Discovery
Goal: Understand project structure and MCP configuration

Actions:
- Check if this is a Claude Agent SDK project: !{bash test -f package.json -o -f main.py && echo "FOUND" || echo "NOT_FOUND"}
- Parse $ARGUMENTS for MCP server name (optional - if not provided, will prompt)
- Detect language (TypeScript or Python): !{bash test -f package.json && echo "TypeScript" || echo "Python"}
- Check for existing MCP configuration: !{bash test -f .mcp.json && cat .mcp.json || echo "No .mcp.json found"}
- If no server specified in $ARGUMENTS, use AskUserQuestion to gather:
  - Which MCP server(s) to generate code wrappers for?
  - Use filesystem pattern (recommended) or custom structure?
  - Include automatic PII tokenization?

Phase 2: Generate MCP Tool Wrappers
Goal: Create typed code APIs for MCP server tools in servers/ directory

Actions:

Create servers/ directory structure:
!{bash mkdir -p servers/$MCP_SERVER_NAME}

**For TypeScript Projects:**

Generate typed wrapper files for each tool:
- Create servers/$MCP_SERVER_NAME/toolName.ts with:
  - Typed input/output interfaces
  - Async function calling callMCPTool helper
  - JSDoc comments from MCP tool schema
- Create servers/$MCP_SERVER_NAME/index.ts that exports all tools

**For Python Projects:**

Generate typed wrapper files for each tool:
- Create servers/$MCP_SERVER_NAME/tool_name.py with:
  - Type hints using TypedDict
  - Async function calling call_mcp_tool helper
  - Docstrings from MCP tool schema
- Create servers/$MCP_SERVER_NAME/__init__.py that exports all tools

Phase 3: Create Helper Functions
Goal: Implement core utilities for MCP tool execution

Actions:

**For TypeScript:**
Create lib/mcp-helpers.ts with:
- callMCPTool<T> generic function
- Handles MCP tool invocation via SDK
- Serialization/deserialization
- Error handling and logging

**For Python:**
Create lib/mcp_helpers.py with:
- call_mcp_tool async function
- Handles MCP tool invocation via SDK
- Type conversion
- Error handling and logging

Optional: Create search_tools helper for keyword-based tool discovery

Phase 4: Update Agent Configuration
Goal: Enable code execution environment and tool access

Actions:

Update agent configuration to:
- Provide filesystem access to servers/ directory for tool discovery
- Enable code execution with proper sandboxing
- Add resource limits (memory, CPU, timeout) for safety
- Configure PII tokenization if requested
- Add workspace/ directory for persistent state

**TypeScript:**
- Update package.json with execution dependencies
- Configure TypeScript for module resolution
- Add filesystem permissions

**Python:**
- Update requirements.txt with execution dependencies
- Configure virtual environment
- Add filesystem permissions

Phase 5: Create Example Usage
Goal: Demonstrate code execution pattern

Actions:

Create example file showing:
- Progressive disclosure: List servers/, load tools on-demand
- Context-efficient filtering: Process data in code before returning
- Control flow: Loops, conditionals, error handling
- State persistence: Save to workspace/ for reuse

Phase 6: Validation & Documentation
Goal: Verify implementation and document usage

Actions:

Test generated code:
- Import tool wrappers and verify functionality
- Test tool discovery and filtering

Add README section:
- Explain code execution pattern (98.7% token reduction)
- Show tool discovery (list servers/)
- Document filtering and control flow patterns
- Link to https://www.anthropic.com/engineering/code-execution-with-mcp

Phase 7: Summary
Goal: Present results and usage instructions

Actions:

Display comprehensive summary:

**Code Execution with MCP Added**: $MCP_SERVER_NAME

**Files Created**:
- servers/$MCP_SERVER_NAME/*.ts|py - Typed tool wrappers
- lib/mcp-helpers.ts|py - Core execution utilities
- examples/code-execution-demo - Usage examples
- workspace/ - Persistent state directory

**Benefits**:
- 98.7% reduction in token usage vs direct tool calls
- On-demand tool loading via filesystem navigation
- Context-efficient result filtering in code
- Familiar programming patterns for control flow
- State persistence across executions
- Automatic PII tokenization (if enabled)

**Usage**:

Discover tools:
List servers/ directory: `ls servers/`

Call tools via code:
Import and call like regular async functions

Filter results:
Process data in code before returning to model

**Next Steps**:
- Add more MCP servers to servers/ directory
- Create reusable skills in workspace/
- Implement complex workflows with control flow
- Review: https://www.anthropic.com/engineering/code-execution-with-mcp
