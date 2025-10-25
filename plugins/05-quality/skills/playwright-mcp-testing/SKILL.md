# Playwright MCP Testing

**Auto-invoked when**: user mentions "playwright testing", "frontend testing", "E2E testing", "browser testing", "MCP automation", "UI testing", "automated browser tests", or "test user journeys"

## Description

Automated browser testing using Playwright MCP server integration. Provides frontend E2E testing capabilities with MCP-powered browser automation for testing user journeys, validating deployments, and running automated test suites at key workflow moments.

## Features

- **Automated Test Runner** - Run test suites triggered by workflow events (commit, deploy, feature completion)
- **Playwright MCP Integration** - Direct integration with Playwright MCP server for browser automation
- **Test Scenarios** - Predefined test scenarios for common use cases (login, API, form validation)
- **Key Moments Triggers** - Scripts that trigger tests at critical moments (pre-commit, pre-push, deployment)
- **Real MCP Integration** - Validated integration with actual Playwright MCP functions

## Dependencies

This skill requires Node.js 18+ and the following packages:
- `@executeautomation/playwright-mcp-server` - Playwright MCP server
- `playwright` - Browser automation library

## Auto-Installation

The scripts will automatically check for and install dependencies on first run:
```bash
cd plugins/05-quality
npm install
```

## Scripts

### test-automation.js
Main test runner with multiple test scenarios:
- **Usage**: `node test-automation.js [trigger]`
- **Triggers**:
  - `commit` - Quick pre-commit tests
  - `deploy` - Deployment validation tests
  - `full` - Complete test suite
- **Test Scenarios**:
  - Login Flow Test
  - API Response Test
  - Form Validation Test

### test-real-mcp.js
Validates Playwright MCP server integration:
- **Usage**: `node test-real-mcp.js`
- **Purpose**: Verify MCP server is properly configured and responding
- **Tests**: Navigation, screenshot capture, page load verification

### playwright-mcp-wrapper.js
Reusable library for Playwright MCP integration:
- **Export**: `PlaywrightMCPClient`, `TEST_SCENARIOS`
- **Usage**: Import and use in custom test scripts
- **Features**:
  - User journey testing
  - Batch test execution
  - Predefined test scenarios (deployment, feature, smoke tests)

### key-moments.sh
Bash script to trigger tests at key workflow moments:
- **Usage**: `./key-moments.sh <moment> [additional_args]`
- **Moments**:
  - `pre-commit` - Run before git commit
  - `pre-push` - Run before git push
  - `deployment` - Run during deployment
  - `feature-complete` - Run when feature is complete
  - `nightly` - Run nightly regression tests
  - `manual` - Manual trigger with custom args

## Integration Examples

### Git Hooks
```bash
# .git/hooks/pre-commit
#!/bin/bash
./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh pre-commit

# .git/hooks/pre-push
#!/bin/bash
./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh pre-push
```

### CI/CD Pipeline
```yaml
# GitHub Actions example
- name: Run deployment validation
  run: |
    cd plugins/05-quality
    npm install
    ./skills/playwright-mcp-testing/scripts/key-moments.sh deployment
```

### Manual Testing
```bash
# From project root
cd plugins/05-quality
npm install
npm run test:full

# Or directly
./skills/playwright-mcp-testing/scripts/key-moments.sh manual
```

## MCP Server Setup

The Playwright MCP server must be running for tests to work:
```bash
# Install globally (one-time)
npm install -g @executeautomation/playwright-mcp-server

# Start server
npx @executeautomation/playwright-mcp-server

# Or let key-moments.sh auto-start it
```

## Test Scenarios

### Deployment Validation
- Health check endpoint
- Critical user flows
- API endpoint validation

### Feature Testing
- Login flow
- User registration
- Core feature workflows

### Smoke Tests
- Homepage load
- Navigation
- Critical paths

## Usage in Commands

This skill is referenced by:
- `/quality:test` - Run test suite
- `/quality:test-generate` - Generate test scaffolds
- `/quality:validate` - Validate test coverage

## Claude Code Integration

When user requests frontend testing:
1. Check if dependencies installed: `test -f plugins/05-quality/node_modules/@executeautomation/playwright-mcp-server`
2. If not installed: `cd plugins/05-quality && npm install`
3. Check if MCP server running: `curl -s http://localhost:3000/health`
4. If not running: Start server or use key-moments.sh which auto-starts
5. Run appropriate test script based on user request

## Output

All test scripts generate:
- Console output with colored status (✅ PASSED, ❌ FAILED)
- Test results summary with pass/fail counts
- Success rate percentage
- Timestamps for each test
- Detailed error messages on failures

## Best Practices

1. **Run quick tests on commit** - Use `commit` trigger for fast feedback
2. **Run full tests on push** - Use `pre-push` trigger for comprehensive validation
3. **Validate deployments** - Always run `deployment` trigger before production
4. **Nightly regression** - Set up cron job for `nightly` trigger
5. **Feature completion** - Run `feature-complete` when ready for review

## Troubleshooting

### MCP Server Not Running
```bash
# Check if server is running
curl http://localhost:3000/health

# Start manually
npx @executeautomation/playwright-mcp-server

# Or let key-moments.sh handle it
./key-moments.sh manual
```

### Dependencies Missing
```bash
cd plugins/05-quality
npm install
```

### Tests Failing
1. Verify MCP server is running
2. Check test URLs are accessible
3. Review test scenarios in test-automation.js
4. Check console output for specific errors

## Extending Test Scenarios

Add custom test scenarios in `test-automation.js`:
```javascript
const customScenario = {
  name: 'Custom Test',
  action: 'custom_action',
  url: 'https://your-app.com',
  steps: ['navigate', 'verify']
};
```

Or use the wrapper library:
```javascript
const { PlaywrightMCPClient, TEST_SCENARIOS } = require('./playwright-mcp-wrapper.js');

const client = new PlaywrightMCPClient();
await client.testUserJourney({
  name: 'My Custom Journey',
  startUrl: 'https://example.com',
  steps: [
    { type: 'click', selector: '#button' },
    { type: 'wait', condition: 'load' },
    { type: 'screenshot', filename: 'result.png' }
  ],
  expectedState: { loaded: true }
});
```
