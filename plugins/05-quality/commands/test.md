---
allowed-tools: Bash(*), Read(*), Grep(*), SlashCommand(*)
description: Run test suite for project (unit, integration, E2E, playwright MCP)
argument-hint: [--coverage|--e2e|--playwright|--full]
---

**Arguments**: $ARGUMENTS

## Overview

Runs the test suite for the current project, detecting the test framework and executing appropriately. Supports unit tests, integration tests, E2E tests, and Playwright MCP browser automation.

## Step 1: Determine Test Type

**Check arguments**:
- If `--playwright` or `--e2e`: Run Playwright MCP browser tests
- If `--full`: Run all test types
- Otherwise: Run standard unit/integration tests

## Step 2: Detect Project Type and Test Framework

Use Bash tool to detect project type:
```bash
if test -f package.json; then
  echo "Node.js project detected"
  if grep -q "jest" package.json 2>/dev/null; then echo "Test framework: Jest"
  elif grep -q "vitest" package.json 2>/dev/null; then echo "Test framework: Vitest"
  elif grep -q "mocha" package.json 2>/dev/null; then echo "Test framework: Mocha"
  else echo "No test framework detected"; fi
elif test -f requirements.txt || test -f pyproject.toml; then
  echo "Python project detected"
  if grep -q "pytest" requirements.txt 2>/dev/null || grep -q "pytest" pyproject.toml 2>/dev/null; then
    echo "Test framework: Pytest"
  else echo "Test framework: Unittest"; fi
elif test -f Cargo.toml; then echo "Rust project detected"
elif test -f pom.xml; then echo "Java project detected"
else echo "Unknown project type"; fi
```

## Step 3: Run Standard Tests (Unit/Integration)

**If not --playwright or --e2e**, run standard tests using Bash tool:

For Node.js:
```bash
if test -f package.json; then
  npm test
fi
```

For Python:
```bash
if test -f requirements.txt || test -f pyproject.toml; then
  python -m pytest
fi
```

For Rust:
```bash
if test -f Cargo.toml; then
  cargo test
fi
```

For Java:
```bash
if test -f pom.xml; then
  mvn test
fi
```

## Step 4: Run Playwright MCP Tests (E2E/Browser)

**If $ARGUMENTS contains --playwright, --e2e, or --full**:

### Check Playwright MCP Setup

Use Bash tool:
```bash
PLAYWRIGHT_SKILL_DIR="plugins/05-quality/skills/playwright-mcp-testing"

if [ -d "$PLAYWRIGHT_SKILL_DIR" ]; then
  echo "✅ Playwright MCP testing available"
else
  echo "❌ Playwright MCP not installed"
  echo "Install with: /quality:test-generate --playwright"
  exit 1
fi
```

### Initialize Dependencies (if needed)

Use Bash tool:
```bash
PLAYWRIGHT_SKILL_DIR="plugins/05-quality/skills/playwright-mcp-testing"

cd "$PLAYWRIGHT_SKILL_DIR"

# Check if dependencies installed
if [ ! -d "../../node_modules/@executeautomation/playwright-mcp-server" ]; then
  echo "📦 Installing Playwright MCP dependencies..."
  ./scripts/init-playwright-deps.sh ../..
else
  echo "✅ Playwright MCP dependencies already installed"
fi
```

### Run Playwright Tests

Use Bash tool:
```bash
PLAYWRIGHT_SKILL_DIR="plugins/05-quality/skills/playwright-mcp-testing"

cd "$PLAYWRIGHT_SKILL_DIR"

# Determine test type
if [[ "$ARGUMENTS" == *"--full"* ]]; then
  echo "🔥 Running full Playwright test suite..."
  ./scripts/key-moments.sh manual full
elif [[ "$ARGUMENTS" == *"--deploy"* ]]; then
  echo "🚀 Running deployment validation tests..."
  ./scripts/key-moments.sh deployment
else
  echo "🧪 Running Playwright browser tests..."
  node scripts/test-automation.js full
fi
```

## Step 5: Generate Coverage (if requested)

**If $ARGUMENTS contains --coverage**:

Use Bash tool:
```bash
if test -f package.json; then
  # Try npm script first, fallback to jest
  npm run test:coverage 2>/dev/null || npx jest --coverage 2>/dev/null || echo "Coverage not available for this framework"
elif test -f requirements.txt || test -f pyproject.toml; then
  pytest --cov 2>/dev/null || echo "Coverage not available"
else
  echo "Coverage not available for this project type"
fi
```

## Step 6: Report Results

Display test results summary:
- Total tests run
- Passed/Failed counts
- Success rate
- Coverage percentage (if available)
- Failing test locations (if any)
- Recommendations for improvements

## Usage Examples

### Standard Unit Tests
```bash
/quality:test
```

### With Coverage
```bash
/quality:test --coverage
```

### Playwright E2E Tests
```bash
/quality:test --playwright
```

### Full Test Suite (Unit + E2E)
```bash
/quality:test --full
```

### Deployment Validation
```bash
/quality:test --deploy
```

## Integration with Other Commands

- Use `/quality:test-generate` to scaffold Playwright MCP tests
- Use `/quality:validate` to validate test coverage
- Use SlashCommand to trigger other quality commands if needed

## Notes

- **Playwright MCP tests require**: Node.js 18+, MCP server running
- **First-time setup**: Will auto-initialize dependencies
- **MCP server**: Will auto-start if not running (via key-moments.sh)
- **Test output**: Colored console output with pass/fail indicators
