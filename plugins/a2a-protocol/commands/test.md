---
description: Test and validate A2A implementations
argument-hint: [test-target]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Validate A2A protocol implementations through comprehensive testing

Core Principles:
- Verify protocol compliance before deployment
- Detect integration issues early
- Provide actionable feedback
- Validate against A2A specification

Phase 1: Discovery
Goal: Understand what needs to be tested

Actions:
- Parse $ARGUMENTS for test target (file, directory, or full project)
- If unclear, use AskUserQuestion to gather:
  - What should be tested? (specific files, features, or entire implementation)
  - What protocol aspects to focus on? (messaging, discovery, authentication)
  - Any specific test scenarios or edge cases?
- Detect project type and A2A implementation location
- Example: !{bash ls -la src/ 2>/dev/null | grep -i "a2a\|agent"}

Phase 2: Analysis
Goal: Understand existing A2A implementation

Actions:
- Locate A2A-related files
- Example: !{bash find . -type f \( -name "*a2a*" -o -name "*agent*" \) 2>/dev/null | head -20}
- Identify implementation patterns
- Check for test files
- Load relevant configuration files
- Example: @package.json

Phase 3: Planning
Goal: Design test approach

Actions:
- Determine test scope based on implementation
- Identify critical protocol components to validate
- Plan test scenarios (message handling, discovery, error cases)
- Confirm approach with user if significant gaps found

Phase 4: Implementation
Goal: Execute validation with agent

Actions:

Task(description="Validate A2A implementation", subagent_type="a2a-verifier", prompt="You are the a2a-verifier agent. Test and validate A2A protocol implementation for $ARGUMENTS.

Context: Testing A2A implementation to ensure protocol compliance

Requirements:
- Verify message format compliance
- Test discovery mechanisms
- Validate authentication flows
- Check error handling
- Test interoperability with reference implementations

Expected output: Comprehensive test report with pass/fail status, identified issues, and recommendations")

Phase 5: Review
Goal: Verify test results

Actions:
- Review agent's test report
- Check if any critical issues found
- Run additional validation if needed
- Example: !{bash npm test 2>/dev/null || echo "No test script available"}

Phase 6: Summary
Goal: Document test results

Actions:
- Summarize test outcomes
- Highlight any protocol violations or issues
- List recommendations for fixes
- Suggest next steps for addressing failures
