# Deployment Configuration Skill

Comprehensive Vercel deployment configuration and optimization for Next.js applications.

## Overview

This skill provides automated validation, configuration, and optimization tools for deploying Next.js applications to Vercel. It includes scripts for pre-deployment validation, environment variable management, build optimization, and edge function testing.

## Contents

### SKILL.md

Main skill manifest with:
- Deployment workflow and validation
- Configuration guidelines
- Environment variable best practices
- Build optimization strategies
- Edge function setup
- Troubleshooting guide

### Scripts

All scripts are executable bash scripts with comprehensive validation and helpful output:

#### validate-deployment.sh

Pre-deployment validation script that checks:
- ✅ package.json exists with Next.js dependency
- ✅ vercel.json syntax and schema
- ✅ Environment variable documentation (.env.example)
- ✅ No committed secrets (.env files in git)
- ✅ .gitignore properly configured
- ✅ Build output directory (.next)
- ✅ Package manager lock files
- ✅ Performance issues (unoptimized images, large bundles)

**Usage:**
```bash
./scripts/validate-deployment.sh [project-directory]
```

**Example Output:**
```
🔍 Validating Vercel Deployment Configuration...

✓ package.json found
✓ Next.js dependency detected
✓ vercel.json syntax valid
✓ Schema reference included
✓ .env.example found
✓ .gitignore properly excludes environment files

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Validation Complete
  Errors: 0
  Warnings: 2

Configuration looks good! Ready to deploy.
```

#### optimize-build.sh

Build performance analysis script that:
- 📦 Builds the project with timing
- 📊 Analyzes route types (static, SSG, SSR, edge)
- 📦 Checks bundle sizes
- 🔍 Detects large dependencies
- 💡 Provides optimization recommendations
- ⚡ Analyzes build performance

**Usage:**
```bash
./scripts/optimize-build.sh [project-directory]
```

**Example Output:**
```
⚡ Next.js Build Optimization Analysis

📦 Building project...
✓ Build completed in 45s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Build Analysis

Route Analysis:
  Static Routes: 12
  SSG Routes: 8
  SSR Routes: 3
  Edge Routes: 2
  Static/SSG Routes: 80%

Bundle Size Analysis:
Largest JavaScript chunks:
  1.2M - main.js
  450K - framework.js
  230K - app.js

💡 Optimization Recommendations
→ Install @next/bundle-analyzer to visualize bundle sizes
→ Consider dynamic imports for large components
✓ Build time is reasonable
```

#### setup-env-vars.sh

Interactive environment variable setup script:
- 🔍 Scans codebase for process.env usage
- 📋 Checks existing .env files
- 🛠️ Creates .env.example template
- 🔐 Creates .env.local for development
- 📜 Generates Vercel CLI commands
- 📖 Provides environment variable guide

**Usage:**
```bash
./scripts/setup-env-vars.sh [project-directory]
```

**Interactive Menu:**
```
🔐 Environment Variable Setup for Vercel

What would you like to do?

  1) Create .env.example (documentation)
  2) Create .env.local (local development)
  3) Generate Vercel CLI commands
  4) View environment variable guide
  5) Exit
```

#### test-edge-functions.sh

Edge function validation script that:
- 🔍 Scans for edge runtime usage
- 🔬 Analyzes compatibility with Edge Runtime
- ❌ Detects Node.js-specific APIs
- ⚠️ Identifies large dependencies
- ✅ Validates middleware configuration
- 📏 Checks function sizes
- 💡 Provides best practices

**Usage:**
```bash
./scripts/test-edge-functions.sh [project-directory]
```

**Example Output:**
```
⚡ Edge Function Configuration Test

🔍 Scanning for Edge Runtime usage...
Found 3 file(s) using Edge Runtime:
  - app/api/edge/route.ts
  - middleware.ts

🔬 Analyzing Edge Function compatibility...
Checking: app/api/edge/route.ts
  ✓ Uses Web APIs (good for Edge)

✓ Edge Function Check Complete
  Errors: 0
  Warnings: 1

Edge functions look good!
```

### Templates

Production-ready configuration templates:

#### basic.vercel.json

Minimal Vercel configuration for simple deployments.

#### optimized.vercel.json

Production-optimized configuration with:
- Security headers (CSP, X-Frame-Options, etc.)
- Cache headers for static assets
- Image optimization
- Function configuration
- Clean URLs

#### edge-functions.vercel.json

Configuration for edge function deployments:
- Edge runtime configuration
- Multi-region deployment
- API rewrites
- Security headers

#### monorepo.vercel.json

Monorepo deployment configuration:
- Custom build commands
- Root directory configuration
- Workspace-aware installation

#### env-template.md

Comprehensive environment variable documentation:
- Public vs private variables
- Environment-specific values
- Vercel CLI commands
- Security best practices
- Validation patterns
- Common patterns
- Troubleshooting

### Examples

#### deployment-patterns.md

10 comprehensive deployment patterns:

1. **Simple Production Deployment** - Standard setup
2. **Multi-Environment Setup** - Dev/staging/prod
3. **Monorepo Deployment** - Turborepo/npm workspaces
4. **Edge Functions** - Geo-routing, A/B testing
5. **ISR** - Incremental static regeneration
6. **API Proxying** - Hide external endpoints
7. **Custom Redirects** - SEO and migrations
8. **Environment-Aware Config** - Per-environment settings
9. **Deploy Hooks** - External triggers
10. **Security Headers** - Production security

Each pattern includes:
- Use case description
- Complete configuration
- Code examples
- Best practices
- Troubleshooting tips

## Quick Start

### 1. Validate Your Deployment

```bash
./scripts/validate-deployment.sh
```

Fix any errors before deploying.

### 2. Set Up Environment Variables

```bash
./scripts/setup-env-vars.sh
```

Choose option 1 to create .env.example, then option 2 for .env.local.

### 3. Choose a Configuration Template

```bash
# For simple projects
cp templates/basic.vercel.json vercel.json

# For production-optimized setup
cp templates/optimized.vercel.json vercel.json

# For edge functions
cp templates/edge-functions.vercel.json vercel.json

# For monorepos
cp templates/monorepo.vercel.json vercel.json
```

### 4. Optimize Build

```bash
./scripts/optimize-build.sh
```

Review recommendations and implement optimizations.

### 5. Test Edge Functions (if using)

```bash
./scripts/test-edge-functions.sh
```

Ensure edge runtime compatibility.

### 6. Deploy

```bash
# Preview deployment
vercel

# Production deployment
vercel --prod
```

## Skill Activation

This skill is automatically activated when Claude detects:

- Deployment failures or errors
- Build performance issues
- Environment variable configuration needs
- Edge function setup
- vercel.json configuration
- Production deployment preparation
- Custom domain configuration

## Use Cases

### Pre-Deployment Checklist

Run validation before every deployment:

```bash
./scripts/validate-deployment.sh && echo "Ready to deploy!"
```

### Build Performance Investigation

When builds are slow:

```bash
./scripts/optimize-build.sh
```

### Environment Variable Setup

For new projects or environment changes:

```bash
./scripts/setup-env-vars.sh
# Choose option 1: Create .env.example
# Choose option 3: Generate Vercel CLI commands
```

### Edge Function Development

When implementing edge functions:

```bash
./scripts/test-edge-functions.sh
```

### Configuration from Template

Quick setup with best practices:

```bash
cp templates/optimized.vercel.json vercel.json
```

## Integration with Other Skills

This skill works well with:

- **component-analyzer** - Analyze components for edge compatibility
- **app-router-patterns** - Implement deployment-optimized routing
- **performance-optimizer** - Build-time performance improvements

## Best Practices

### Development Workflow

1. Create feature branch
2. Run `validate-deployment.sh` before committing
3. Push to Git (automatic preview deployment)
4. Review preview deployment
5. Merge to main (automatic production deployment)

### Environment Management

1. Keep `.env.example` updated and committed
2. Never commit `.env.local` or `.env.production`
3. Use different values per environment
4. Document all variables in env-template.md
5. Rotate secrets regularly

### Build Optimization

1. Run `optimize-build.sh` regularly
2. Use `@next/bundle-analyzer` for detailed analysis
3. Implement dynamic imports for large components
4. Optimize images with next/image
5. Use ISR for content-heavy pages

### Security

1. Use security headers from `optimized.vercel.json`
2. Never expose secrets with `NEXT_PUBLIC_`
3. Validate environment variables at build time
4. Use edge functions for authentication
5. Enable CSP headers in production

## Troubleshooting

### Validation Errors

```bash
# See detailed validation output
./scripts/validate-deployment.sh

# Common fixes:
# - Add .env files to .gitignore
# - Create .env.example
# - Fix vercel.json syntax
```

### Build Performance

```bash
# Analyze build
./scripts/optimize-build.sh

# Install bundle analyzer
npm install --save-dev @next/bundle-analyzer

# Check bundle
ANALYZE=true npm run build
```

### Edge Function Issues

```bash
# Test edge compatibility
./scripts/test-edge-functions.sh

# Common issues:
# - Using Node.js APIs (use Web APIs instead)
# - Large dependencies (reduce bundle size)
# - Missing middleware matcher
```

### Environment Variables

```bash
# View guide
./scripts/setup-env-vars.sh
# Choose option 4

# Pull from Vercel
vercel env pull .env.local

# List variables
vercel env ls
```

## Resources

- **Vercel Documentation**: https://vercel.com/docs
- **Next.js Deployment**: https://nextjs.org/docs/deployment
- **Edge Runtime**: https://edge-runtime.vercel.app/
- **Environment Variables**: https://vercel.com/docs/environment-variables

## Version

- **Version**: 1.0.0
- **Platform**: Vercel
- **Framework**: Next.js 13+ (App Router and Pages Router)
- **CLI**: Vercel CLI (latest)

## License

Part of the nextjs-frontend plugin.

## Support

For issues or questions:
1. Check examples/deployment-patterns.md for common scenarios
2. Run relevant validation script
3. Review Vercel documentation
4. Check Vercel deployment logs
