# SDK Configuration Validator Skill

A focused skill for validating Claude Agent SDK project configuration, dependencies, and environment setup.

## Purpose

This skill provides reusable validation capabilities that ensure Claude Agent SDK projects are properly configured before development begins. It detects common configuration issues and provides actionable fixes.

## Structure

```
sdk-config-validator/
├── SKILL.md                           # Main skill manifest (84 lines)
├── README.md                          # This file
├── scripts/                           # Validation scripts
│   ├── validate-typescript.sh         # TypeScript project validation
│   ├── validate-python.sh             # Python project validation
│   ├── check-sdk-version.sh           # SDK version compatibility check
│   └── validate-env-setup.sh          # Environment variable validation
├── templates/                         # Configuration templates
│   ├── .env.example.template          # Environment variable template
│   ├── tsconfig-sdk.json              # TypeScript config for SDK
│   └── pyproject-sdk.toml             # Python config for SDK
└── examples/                          # Usage examples
    ├── validation-report-example.md   # Sample validation report
    └── common-fixes.md                # Common issues and solutions
```

## Invocation Triggers

The skill is automatically invoked when users mention:
- "validate SDK setup"
- "check SDK configuration"
- "SDK not working"
- "troubleshoot SDK issues"
- "is my SDK project configured correctly?"

## Validation Capabilities

### TypeScript Projects
- ✅ Checks for @claude-ai/sdk dependency
- ✅ Validates tsconfig.json settings
- ✅ Verifies Node.js version compatibility (18+)
- ✅ Checks module resolution settings

### Python Projects
- ✅ Checks for claude-ai-sdk dependency
- ✅ Validates pyproject.toml/requirements.txt
- ✅ Verifies Python version compatibility (3.8+)
- ✅ Checks virtual environment setup

### Environment Setup
- ✅ Validates .env file existence and configuration
- ✅ Checks for required variables (ANTHROPIC_API_KEY)
- ✅ Verifies .env is in .gitignore (security check)
- ✅ Validates optional configuration variables

### SDK Version
- ✅ Checks declared SDK version in package.json/pyproject.toml
- ✅ Verifies installed SDK version matches requirements
- ✅ Detects version compatibility issues

## Usage Examples

### Quick Validation
```bash
# TypeScript project
bash scripts/validate-typescript.sh /path/to/project

# Python project
bash scripts/validate-python.sh /path/to/project
```

### Complete Validation
```bash
# Run all validations
bash scripts/validate-typescript.sh .
bash scripts/validate-env-setup.sh .
bash scripts/check-sdk-version.sh .
```

### Setup New Project
```bash
# Copy configuration templates
cp templates/.env.example.template .env.example
cp templates/tsconfig-sdk.json tsconfig.json
```

## Exit Codes

- `0`: All validations passed
- `1`: Configuration errors found (check output)
- `2`: Critical errors (missing SDK, invalid project structure)

## Integration with Agents

This skill is designed to be used by:
- **sdk-setup-agent**: For initial project setup validation
- **sdk-troubleshooter-agent**: For diagnosing configuration issues
- **general-purpose agents**: When SDK configuration questions arise

## Design Principles

1. **Focused**: Only handles configuration validation, not SDK functionality
2. **Reusable**: Can be invoked across multiple agents
3. **Actionable**: Provides specific fixes for every issue detected
4. **Portable**: Scripts work across Linux, macOS, and WSL
5. **Secure**: Checks for security issues (.env in .gitignore)

## Validation Workflow

```
1. Detect Project Type (TS/Python)
       ↓
2. Run Configuration Validation
       ↓
3. Check SDK Dependencies
       ↓
4. Validate Environment Setup
       ↓
5. Generate Validation Report
       ↓
6. Offer Actionable Fixes
```

## Common Issues Detected

- Missing SDK dependency
- Incorrect TypeScript compiler options
- Missing ANTHROPIC_API_KEY
- .env file not in .gitignore (security risk)
- SDK version incompatibility
- Python/Node version mismatch
- Missing configuration files

## Resources

- **Templates**: Ready-to-use configuration files
- **Examples**: Sample reports and fix patterns
- **Scripts**: Automated validation tools

## Maintenance

When updating this skill:
1. Keep SKILL.md under 150 lines
2. Ensure scripts remain portable
3. Update templates with SDK best practices
4. Add new validation checks as scripts
5. Document common fixes in examples/

## Testing

Test the skill with various project states:
```bash
# Test with missing SDK
# Test with invalid .env
# Test with outdated Node/Python
# Test with correct setup
```

## Contributing

To add new validation checks:
1. Add check to appropriate script
2. Update SKILL.md if new capability
3. Add fix pattern to examples/common-fixes.md
4. Test across TypeScript and Python projects
