# Next.js Frontend Plugin Scripts

Utility scripts for the nextjs-frontend plugin.

## Available Scripts

### `setup-hooks.sh`

Install lifecycle hooks into a Next.js project.

**Usage:**
```bash
# Install in current directory
bash scripts/setup-hooks.sh

# Install in specific project
bash scripts/setup-hooks.sh /path/to/project
```

**What it does:**
- Installs pre-commit hook for design system validation
- Makes hooks executable
- Validates git repository exists

## Future Scripts

Additional utility scripts will be added here for:
- Project validation
- Build optimization
- Component generation
- Testing automation
