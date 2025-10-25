# Playwright MCP Testing Scripts

Automated browser testing scripts using Playwright MCP server integration.

## Scripts Overview

### init-playwright-deps.sh

**Purpose**: Initialize or merge Playwright MCP dependencies into project package.json

**Usage**:
```bash
./init-playwright-deps.sh [project_root]
```

**What it does**:
1. Checks if Node.js 18+ is installed
2. Creates package.json from template if none exists
3. Merges required dependencies into existing package.json
4. Installs dependencies via npm
5. Verifies Playwright MCP server installation

**When to use**:
- First-time setup of Playwright testing in a project
- Adding Playwright MCP to an existing project
- Ensuring all required dependencies are installed

### test-automation.js

**Purpose**: Main test runner with multiple test scenarios

**Usage**:
```bash
node test-automation.js [trigger]
```

**Triggers**:
- `commit` - Quick pre-commit tests
- `deploy` - Deployment validation tests
- `full` - Complete test suite (default)

**Test Scenarios**:
- Login Flow Test
- API Response Test
- Form Validation Test

**When to use**:
- Running automated tests at different workflow stages
- Validating deployments before production
- Pre-commit/pre-push validation

### test-real-mcp.js

**Purpose**: Validate Playwright MCP server integration

**Usage**:
```bash
node test-real-mcp.js
```

**What it does**:
- Tests navigation to httpbin.org
- Takes a screenshot
- Verifies MCP functions are working

**When to use**:
- First-time setup verification
- Debugging MCP server issues
- Confirming MCP server is responding

### playwright-mcp-wrapper.js

**Purpose**: Reusable library for Playwright MCP integration

**Usage** (as a module):
```javascript
const { PlaywrightMCPClient, TEST_SCENARIOS } = require('./playwright-mcp-wrapper.js');

const client = new PlaywrightMCPClient();
await client.testUserJourney({
  name: 'My Test',
  startUrl: 'https://example.com',
  steps: [
    { type: 'click', selector: '#button' },
    { type: 'wait', condition: 'load' }
  ],
  expectedState: { loaded: true }
});
```

**Features**:
- User journey testing
- Batch test execution
- Predefined test scenarios
- MCP function wrappers

**When to use**:
- Building custom test scripts
- Creating project-specific test scenarios
- Extending test automation

### key-moments.sh

**Purpose**: Trigger tests at critical workflow moments

**Usage**:
```bash
./key-moments.sh <moment> [additional_args]
```

**Moments**:
- `pre-commit` - Before git commit
- `pre-push` - Before git push
- `deployment` - During deployment
- `feature-complete` - When feature is done
- `nightly` - Nightly regression tests
- `manual` - Manual trigger

**What it does**:
- Checks if MCP server is running
- Auto-starts MCP server if needed
- Runs appropriate tests for the moment
- Reports test results

**When to use**:
- Integrating with git hooks
- CI/CD pipeline integration
- Scheduled test runs
- Manual test execution

## Typical Workflow

### Initial Setup

```bash
# 1. Initialize dependencies
./init-playwright-deps.sh

# 2. Verify MCP integration
node test-real-mcp.js

# 3. Run full test suite
node test-automation.js full
```

### Daily Development

```bash
# Before committing code
./key-moments.sh pre-commit

# Before pushing to remote
./key-moments.sh pre-push

# When feature is complete
./key-moments.sh feature-complete
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Setup Playwright MCP
  run: ./plugins/05-quality/skills/playwright-mcp-testing/scripts/init-playwright-deps.sh

- name: Run deployment tests
  run: ./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh deployment
```

### Git Hooks Integration

```bash
# .git/hooks/pre-commit
#!/bin/bash
exec ./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh pre-commit

# .git/hooks/pre-push
#!/bin/bash
exec ./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh pre-push
```

## Dependencies

All scripts require:
- **Node.js 18+**
- **npm**
- **@executeautomation/playwright-mcp-server**
- **playwright**

Dependencies are automatically installed when running `init-playwright-deps.sh`.

## MCP Server

The Playwright MCP server must be running for tests to execute:

```bash
# Install globally (recommended)
npm install -g @executeautomation/playwright-mcp-server

# Start server
npx @executeautomation/playwright-mcp-server

# Or let key-moments.sh auto-start it
```

## Environment Variables

None required by default. The scripts use sensible defaults.

## Troubleshooting

### MCP Server Not Running

```bash
# Check if running
curl http://localhost:3000/health

# Start manually
npx @executeautomation/playwright-mcp-server
```

### Dependencies Missing

```bash
# Re-run initialization
./init-playwright-deps.sh

# Or install manually
npm install
```

### Tests Failing

1. Verify MCP server is running
2. Check test URLs are accessible
3. Review test scenarios
4. Check console output for errors

## Extending Tests

### Add Custom Scenario to test-automation.js

```javascript
const customScenario = {
  name: 'My Custom Test',
  action: 'custom_action',
  url: 'https://my-app.com',
  steps: ['navigate', 'verify']
};

testScenarios.push(customScenario);
```

### Create Custom Test Script

```javascript
const { PlaywrightMCPClient } = require('./playwright-mcp-wrapper.js');

const client = new PlaywrightMCPClient();

await client.testUserJourney({
  name: 'My Journey',
  startUrl: 'https://example.com',
  steps: [
    { type: 'type', selector: '#input', text: 'test' },
    { type: 'click', selector: '#submit' },
    { type: 'screenshot', filename: 'result.png' }
  ],
  expectedState: { success: true }
});
```

## Output Format

All scripts provide colored console output:
- ✅ Green for success
- ❌ Red for failures
- ⚠️ Yellow for warnings
- 📊 Blue for informational messages

## Performance

- **Quick tests** (pre-commit): ~5-10 seconds
- **Smoke tests** (pre-push): ~15-30 seconds
- **Full suite**: ~1-3 minutes
- **Nightly regression**: ~5-10 minutes

## Best Practices

1. Run quick tests locally before committing
2. Run full tests in CI/CD pipeline
3. Use nightly tests for regression
4. Keep test scenarios focused and fast
5. Update test scenarios when features change
6. Monitor test execution time
7. Fix failing tests immediately
