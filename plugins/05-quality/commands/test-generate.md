---
allowed-tools: Task(*), Read(*), Bash(*), Glob(*), Write(*)
description: Generate test scaffolds (unit tests, E2E, Playwright MCP)
argument-hint: <target-file|--playwright|--e2e>
---

**Arguments**: $ARGUMENTS

## Overview

Generates test scaffolds and boilerplate for the target file or directory. Supports unit tests, integration tests, and Playwright MCP E2E browser tests.

## Step 1: Determine Test Type

**Check arguments:**
- If `--playwright` or `--e2e`: Setup Playwright MCP browser testing
- Otherwise: Generate unit/integration test scaffolds for target file

## Step 2: Playwright MCP Setup (if --playwright or --e2e)

**If $ARGUMENTS contains --playwright or --e2e:**

### Initialize Playwright MCP Testing

Use Bash tool:
```bash
PLUGIN_ROOT="plugins/05-quality"
PLAYWRIGHT_SKILL="$PLUGIN_ROOT/skills/playwright-mcp-testing"

if [ ! -d "$PLAYWRIGHT_SKILL" ]; then
  echo "❌ Playwright MCP skill not found"
  echo "This should not happen - playwright-mcp-testing skill is part of 05-quality plugin"
  exit 1
fi

echo "✅ Playwright MCP testing available"
echo "📍 Location: $PLAYWRIGHT_SKILL"
```

### Initialize Dependencies

Use Bash tool:
```bash
PLAYWRIGHT_SKILL="plugins/05-quality/skills/playwright-mcp-testing"

cd "$PLAYWRIGHT_SKILL"

echo "🚀 Initializing Playwright MCP dependencies..."
./scripts/init-playwright-deps.sh ../..

echo "✅ Dependencies initialized"
```

### Verify MCP Integration

Use Bash tool:
```bash
PLAYWRIGHT_SKILL="plugins/05-quality/skills/playwright-mcp-testing"

cd "$PLAYWRIGHT_SKILL"

echo "🔍 Verifying Playwright MCP integration..."
node scripts/test-real-mcp.js
```

### Setup Git Hooks (Optional)

Use Bash tool:
```bash
PLAYWRIGHT_SKILL="plugins/05-quality/skills/playwright-mcp-testing"

if [ -d ".git" ]; then
  echo "🔗 Setting up git hooks for automated testing..."

  # Create pre-commit hook
  cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
exec ./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh pre-commit
EOF
  chmod +x .git/hooks/pre-commit

  # Create pre-push hook
  cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
exec ./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh pre-push
EOF
  chmod +x .git/hooks/pre-push

  echo "✅ Git hooks created"
else
  echo "ℹ️  Not a git repository - skipping hook setup"
fi
```

### Display Usage Instructions

Output to user:
```
🎉 Playwright MCP Testing is ready!

📋 Available Scripts:
- npm run pw:test           - Run test suite
- npm run pw:test:full      - Run full test suite
- npm run pw:test:commit    - Quick pre-commit tests
- npm run pw:test:deploy    - Deployment validation

🔧 Direct Script Usage:
- ./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh <moment>
- node plugins/05-quality/skills/playwright-mcp-testing/scripts/test-automation.js <trigger>

📚 Documentation:
- SKILL.md: plugins/05-quality/skills/playwright-mcp-testing/SKILL.md
- Scripts README: plugins/05-quality/skills/playwright-mcp-testing/scripts/README.md

🚀 Next Steps:
1. Customize test scenarios in test-automation.js
2. Run: /quality:test --playwright
3. Integrate with CI/CD pipeline
```

**Then STOP - Playwright MCP setup complete**

## Step 3: Unit/Integration Test Generation (if not --playwright)

**If NOT --playwright or --e2e:**

### Validate Target

Use Bash tool:
```bash
if [ -z "$ARGUMENTS" ]; then
  echo "❌ No target specified"
  echo "Usage: /quality:test-generate <target-file>"
  echo "       /quality:test-generate --playwright"
  exit 1
fi

if [[ "$ARGUMENTS" == --* ]]; then
  # This is a flag, not a file
  echo "ℹ️  Flag detected: $ARGUMENTS"
else
  # This should be a file
  if [ -e "$ARGUMENTS" ]; then
    echo "✅ Target found: $ARGUMENTS"
  else
    echo "❌ Target not found: $ARGUMENTS"
    exit 1
  fi
fi
```

### Detect Project Type

Use Bash tool:
```bash
if test -f package.json; then
  echo "📦 Project Type: Node.js"
  if grep -q "jest" package.json 2>/dev/null; then echo "🧪 Test Framework: Jest"
  elif grep -q "vitest" package.json 2>/dev/null; then echo "🧪 Test Framework: Vitest"
  elif grep -q "mocha" package.json 2>/dev/null; then echo "🧪 Test Framework: Mocha"
  else echo "⚠️  No test framework detected"; fi
elif test -f requirements.txt || test -f pyproject.toml; then
  echo "📦 Project Type: Python"
  if grep -q "pytest" requirements.txt 2>/dev/null || grep -q "pytest" pyproject.toml 2>/dev/null; then
    echo "🧪 Test Framework: Pytest"
  else
    echo "🧪 Test Framework: Unittest"
  fi
elif test -f Cargo.toml; then
  echo "📦 Project Type: Rust"
elif test -f pom.xml; then
  echo "📦 Project Type: Java"
else
  echo "❓ Project Type: Unknown"
fi
```

### Create Test Directory Structure

Use Bash tool:
```bash
if test -f package.json; then
  mkdir -p tests __tests__
  echo "✅ Created: tests/ and __tests__/"
elif test -f requirements.txt || test -f pyproject.toml; then
  mkdir -p tests
  echo "✅ Created: tests/"
elif test -f Cargo.toml; then
  mkdir -p tests
  echo "✅ Created: tests/"
elif test -f pom.xml; then
  mkdir -p src/test/java
  echo "✅ Created: src/test/java/"
else
  mkdir -p tests
  echo "✅ Created: tests/"
fi
```

### Invoke Test Generator Agent

Use Task tool with test-generator agent:
```
Task(
  description="Generate test scaffolds",
  subagent_type="test-generator",
  prompt="Generate comprehensive test scaffolds for $ARGUMENTS.

**Context:**
- Target file/directory: $ARGUMENTS
- Project type: (detected from Step 3)
- Test framework: (detected from Step 3)

**Analysis:**
- Read the target file/directory
- Identify functions, classes, and methods to test
- Determine appropriate test patterns for the detected framework
- Identify edge cases and error scenarios

**Test Generation:**
- Create test file(s) following framework conventions
- Generate test cases for each function/method
- Include:
  - Happy path tests
  - Edge cases
  - Error scenarios
  - Setup and teardown if needed
- Use appropriate assertions for the framework
- Add clear comments and TODOs

**Deliverables:**
- Complete test file(s) with scaffolded test cases
- Clear TODOs for implementation details
- Test coverage targeting critical paths
- Follow best practices for the detected framework"
)
```

## Step 4: Report Results

**For Playwright MCP setup:**
- Display setup completion message
- Show available commands
- List next steps

**For unit/integration tests:**
- List test files created
- Count test cases scaffolded
- Provide next steps for implementation
- Suggest running tests with `/quality:test`

## Usage Examples

### Generate Unit Tests
```bash
/quality:test-generate src/utils/helper.js
```

### Setup Playwright MCP E2E Testing
```bash
/quality:test-generate --playwright
```

### Setup E2E Testing (alias)
```bash
/quality:test-generate --e2e
```

### Generate Tests for Directory
```bash
/quality:test-generate src/components/
```

## Integration with Other Commands

- After generation, use `/quality:test` to run tests
- Use `/quality:validate` to check test coverage
- Use `/quality:test --playwright` to run E2E tests

## Notes

- **Playwright MCP**: Requires Node.js 18+, auto-installs dependencies
- **Git hooks**: Optional, auto-configured during Playwright setup
- **Test frameworks**: Auto-detected from project configuration
- **File locations**: Playwright scripts in `plugins/05-quality/skills/playwright-mcp-testing/`
