/**
 * Automated Security Audit Script for Clerk Integration
 *
 * This script performs automated security checks on your Clerk integration:
 * - Scans for exposed API keys
 * - Validates environment variable usage
 * - Checks route protection
 * - Validates middleware configuration
 * - Checks for common security vulnerabilities
 *
 * Usage: ts-node security-audit.ts
 * or: tsx security-audit.ts
 *
 * Security Note: This script itself does not contain secrets
 */

import * as fs from 'fs';
import * as path from 'path';

interface SecurityIssue {
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  category: string;
  message: string;
  file?: string;
  line?: number;
  suggestion?: string;
}

class ClerkSecurityAuditor {
  private issues: SecurityIssue[] = [];
  private projectRoot: string;

  constructor(projectRoot: string = process.cwd()) {
    this.projectRoot = projectRoot;
  }

  async runAudit(): Promise<SecurityIssue[]> {
    console.log('🔒 Starting Clerk Security Audit...\n');

    await this.checkExposedSecrets();
    await this.checkEnvironmentVariables();
    await this.checkMiddlewareConfiguration();
    await this.checkRouteProtection();
    await this.checkWebhookSecurity();
    await this.checkDependencies();

    return this.issues;
  }

  private async checkExposedSecrets(): Promise<void> {
    console.log('🔑 Checking for exposed API keys...');

    const secretKeyPattern = /sk_(test|live)_[a-zA-Z0-9]{20,}/g;
    const publishableKeyPattern = /pk_(test|live)_[a-zA-Z0-9]{20,}/g;

    const filesToScan = this.getSourceFiles();

    for (const file of filesToScan) {
      // Skip .env files and node_modules
      if (
        file.includes('node_modules') ||
        file.includes('.env') ||
        file.includes('.git')
      ) {
        continue;
      }

      const content = fs.readFileSync(file, 'utf-8');
      const lines = content.split('\n');

      // Check for secret keys
      lines.forEach((line, index) => {
        if (secretKeyPattern.test(line)) {
          // Ignore placeholder patterns
          if (!line.includes('your_secret_key_here') && !line.includes('sk_test_xxx')) {
            this.addIssue({
              severity: 'CRITICAL',
              category: 'Exposed Secrets',
              message: 'SECRET KEY exposed in source code',
              file: file,
              line: index + 1,
              suggestion:
                'Remove the secret key immediately and rotate it in Clerk Dashboard. Use environment variables.',
            });
          }
        }

        // Check for hardcoded publishable keys
        if (publishableKeyPattern.test(line)) {
          if (
            !line.includes('your_publishable_key_here') &&
            !line.includes('pk_test_xxx') &&
            !line.includes('process.env') &&
            !line.includes('import.meta.env')
          ) {
            this.addIssue({
              severity: 'HIGH',
              category: 'Hardcoded Keys',
              message: 'Publishable key hardcoded in source',
              file: file,
              line: index + 1,
              suggestion: 'Use environment variables instead of hardcoding keys',
            });
          }
        }
      });
    }

    console.log('  ✓ Secret key scan complete\n');
  }

  private async checkEnvironmentVariables(): Promise<void> {
    console.log('📝 Checking environment variable configuration...');

    // Check .gitignore
    const gitignorePath = path.join(this.projectRoot, '.gitignore');
    if (fs.existsSync(gitignorePath)) {
      const gitignore = fs.readFileSync(gitignorePath, 'utf-8');

      if (!gitignore.includes('.env')) {
        this.addIssue({
          severity: 'CRITICAL',
          category: 'Environment Security',
          message: '.env not in .gitignore',
          file: '.gitignore',
          suggestion: 'Add .env, .env.local, and .env*.local to .gitignore',
        });
      }
    } else {
      this.addIssue({
        severity: 'HIGH',
        category: 'Environment Security',
        message: '.gitignore file not found',
        suggestion: 'Create .gitignore and add .env files to it',
      });
    }

    // Check for .env.example
    const envExamplePath = path.join(this.projectRoot, '.env.example');
    if (!fs.existsSync(envExamplePath)) {
      this.addIssue({
        severity: 'LOW',
        category: 'Documentation',
        message: '.env.example not found',
        suggestion:
          'Create .env.example with placeholder values for documentation',
      });
    } else {
      // Verify .env.example doesn't contain real keys
      const envExample = fs.readFileSync(envExamplePath, 'utf-8');
      const secretPattern = /sk_(test|live)_[a-zA-Z0-9]{20,}/;

      if (secretPattern.test(envExample)) {
        this.addIssue({
          severity: 'CRITICAL',
          category: 'Exposed Secrets',
          message: 'Real API key found in .env.example',
          file: '.env.example',
          suggestion: 'Replace with placeholder: your_secret_key_here',
        });
      }
    }

    console.log('  ✓ Environment variable check complete\n');
  }

  private async checkMiddlewareConfiguration(): Promise<void> {
    console.log('🛡️  Checking middleware configuration...');

    const middlewarePaths = [
      path.join(this.projectRoot, 'middleware.ts'),
      path.join(this.projectRoot, 'middleware.js'),
      path.join(this.projectRoot, 'src/middleware.ts'),
      path.join(this.projectRoot, 'src/middleware.js'),
    ];

    let middlewareFound = false;
    let middlewareContent = '';
    let middlewareFile = '';

    for (const middlewarePath of middlewarePaths) {
      if (fs.existsSync(middlewarePath)) {
        middlewareFound = true;
        middlewareContent = fs.readFileSync(middlewarePath, 'utf-8');
        middlewareFile = middlewarePath;
        break;
      }
    }

    if (!middlewareFound) {
      this.addIssue({
        severity: 'MEDIUM',
        category: 'Route Protection',
        message: 'No middleware.ts found',
        suggestion:
          'Create middleware.ts to protect routes with Clerk authMiddleware',
      });
      return;
    }

    // Check if Clerk middleware is used
    if (
      !middlewareContent.includes('authMiddleware') &&
      !middlewareContent.includes('clerkMiddleware')
    ) {
      this.addIssue({
        severity: 'HIGH',
        category: 'Route Protection',
        message: 'Clerk middleware not configured',
        file: middlewareFile,
        suggestion:
          'Import and use authMiddleware from @clerk/nextjs to protect routes',
      });
    }

    // Check for publicRoutes configuration
    if (!middlewareContent.includes('publicRoutes')) {
      this.addIssue({
        severity: 'MEDIUM',
        category: 'Route Protection',
        message: 'publicRoutes not explicitly defined',
        file: middlewareFile,
        suggestion:
          'Define publicRoutes array to explicitly control which routes are public',
      });
    }

    console.log('  ✓ Middleware check complete\n');
  }

  private async checkRouteProtection(): Promise<void> {
    console.log('🔐 Checking route protection...');

    // Check for unprotected admin routes
    const appDir = path.join(this.projectRoot, 'app');
    const pagesDir = path.join(this.projectRoot, 'pages');

    if (fs.existsSync(appDir)) {
      this.checkDirectoryForUnprotectedRoutes(appDir);
    }

    if (fs.existsSync(pagesDir)) {
      this.checkDirectoryForUnprotectedRoutes(pagesDir);
    }

    console.log('  ✓ Route protection check complete\n');
  }

  private checkDirectoryForUnprotectedRoutes(dir: string): void {
    const adminPaths = ['admin', 'dashboard', 'settings'];

    for (const adminPath of adminPaths) {
      const adminDir = path.join(dir, adminPath);

      if (fs.existsSync(adminDir)) {
        // Check if page.tsx or index.tsx has auth check
        const pageFiles = ['page.tsx', 'page.js', 'index.tsx', 'index.js'];

        for (const pageFile of pageFiles) {
          const pagePath = path.join(adminDir, pageFile);

          if (fs.existsSync(pagePath)) {
            const content = fs.readFileSync(pagePath, 'utf-8');

            // Check for auth usage
            const hasAuthCheck =
              content.includes('useAuth()') ||
              content.includes('auth()') ||
              content.includes('currentUser()');

            if (!hasAuthCheck) {
              this.addIssue({
                severity: 'MEDIUM',
                category: 'Route Protection',
                message: `Potentially unprotected ${adminPath} route`,
                file: pagePath,
                suggestion:
                  'Add authentication check or ensure middleware protects this route',
              });
            }
          }
        }
      }
    }
  }

  private async checkWebhookSecurity(): Promise<void> {
    console.log('🪝 Checking webhook security...');

    const webhookPaths = this.findWebhookHandlers();

    for (const webhookPath of webhookPaths) {
      const content = fs.readFileSync(webhookPath, 'utf-8');

      // Check for signature verification
      if (!content.includes('verify') && !content.includes('svix')) {
        this.addIssue({
          severity: 'CRITICAL',
          category: 'Webhook Security',
          message: 'Webhook handler missing signature verification',
          file: webhookPath,
          suggestion:
            'Use svix library to verify webhook signatures before processing events',
        });
      }

      // Check for webhook secret
      if (
        !content.includes('WEBHOOK_SECRET') &&
        !content.includes('CLERK_WEBHOOK_SECRET')
      ) {
        this.addIssue({
          severity: 'HIGH',
          category: 'Webhook Security',
          message: 'Webhook secret not used',
          file: webhookPath,
          suggestion:
            'Store webhook secret in environment variables and use for verification',
        });
      }
    }

    console.log('  ✓ Webhook security check complete\n');
  }

  private findWebhookHandlers(): string[] {
    const webhookFiles: string[] = [];
    const searchDirs = [
      path.join(this.projectRoot, 'app/api'),
      path.join(this.projectRoot, 'pages/api'),
      path.join(this.projectRoot, 'src/app/api'),
      path.join(this.projectRoot, 'src/pages/api'),
    ];

    for (const dir of searchDirs) {
      if (fs.existsSync(dir)) {
        this.findWebhookFilesRecursive(dir, webhookFiles);
      }
    }

    return webhookFiles;
  }

  private findWebhookFilesRecursive(dir: string, files: string[]): void {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory() && entry.name.includes('webhook')) {
        files.push(fullPath);
      } else if (
        entry.isFile() &&
        (entry.name.includes('webhook') || entry.name.includes('clerk'))
      ) {
        files.push(fullPath);
      } else if (entry.isDirectory()) {
        this.findWebhookFilesRecursive(fullPath, files);
      }
    }
  }

  private async checkDependencies(): Promise<void> {
    console.log('📦 Checking dependencies...');

    const packageJsonPath = path.join(this.projectRoot, 'package.json');

    if (!fs.existsSync(packageJsonPath)) {
      return;
    }

    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
    const dependencies = {
      ...packageJson.dependencies,
      ...packageJson.devDependencies,
    };

    // Check for Clerk SDK
    const clerkPackages = Object.keys(dependencies).filter((dep) =>
      dep.startsWith('@clerk/')
    );

    if (clerkPackages.length === 0) {
      this.addIssue({
        severity: 'HIGH',
        category: 'Dependencies',
        message: 'No Clerk SDK installed',
        suggestion: 'Install @clerk/nextjs or appropriate Clerk package',
      });
    }

    console.log('  ✓ Dependency check complete\n');
  }

  private getSourceFiles(): string[] {
    const files: string[] = [];
    const extensions = ['.ts', '.tsx', '.js', '.jsx'];

    const scanDirs = [
      path.join(this.projectRoot, 'app'),
      path.join(this.projectRoot, 'pages'),
      path.join(this.projectRoot, 'src'),
      path.join(this.projectRoot, 'components'),
      path.join(this.projectRoot, 'lib'),
    ];

    for (const dir of scanDirs) {
      if (fs.existsSync(dir)) {
        this.getFilesRecursive(dir, files, extensions);
      }
    }

    return files;
  }

  private getFilesRecursive(
    dir: string,
    files: string[],
    extensions: string[]
  ): void {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory() && entry.name !== 'node_modules') {
        this.getFilesRecursive(fullPath, files, extensions);
      } else if (
        entry.isFile() &&
        extensions.some((ext) => entry.name.endsWith(ext))
      ) {
        files.push(fullPath);
      }
    }
  }

  private addIssue(issue: SecurityIssue): void {
    this.issues.push(issue);
  }

  printReport(): void {
    console.log('='.repeat(70));
    console.log('SECURITY AUDIT REPORT');
    console.log('='.repeat(70));
    console.log('');

    if (this.issues.length === 0) {
      console.log('✅ No security issues found!\n');
      return;
    }

    const groupedIssues = this.groupIssuesBySeverity();

    for (const severity of ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']) {
      const issues = groupedIssues[severity] || [];

      if (issues.length > 0) {
        console.log(`\n${this.getSeverityEmoji(severity)} ${severity} (${issues.length})`);
        console.log('-'.repeat(70));

        for (const issue of issues) {
          console.log(`\n  Category: ${issue.category}`);
          console.log(`  Message: ${issue.message}`);

          if (issue.file) {
            console.log(`  File: ${issue.file}${issue.line ? `:${issue.line}` : ''}`);
          }

          if (issue.suggestion) {
            console.log(`  💡 Suggestion: ${issue.suggestion}`);
          }
        }
      }
    }

    console.log('\n' + '='.repeat(70));
    console.log('SUMMARY');
    console.log('='.repeat(70));
    console.log(`Total Issues: ${this.issues.length}`);
    console.log(`Critical: ${groupedIssues['CRITICAL']?.length || 0}`);
    console.log(`High: ${groupedIssues['HIGH']?.length || 0}`);
    console.log(`Medium: ${groupedIssues['MEDIUM']?.length || 0}`);
    console.log(`Low: ${groupedIssues['LOW']?.length || 0}`);
    console.log('');

    if (groupedIssues['CRITICAL']?.length > 0) {
      console.log('⛔ CRITICAL issues must be fixed immediately!');
    }
  }

  private groupIssuesBySeverity(): Record<string, SecurityIssue[]> {
    return this.issues.reduce((acc, issue) => {
      if (!acc[issue.severity]) {
        acc[issue.severity] = [];
      }
      acc[issue.severity].push(issue);
      return acc;
    }, {} as Record<string, SecurityIssue[]>);
  }

  private getSeverityEmoji(severity: string): string {
    const emojis = {
      CRITICAL: '🔴',
      HIGH: '🟠',
      MEDIUM: '🟡',
      LOW: '🔵',
    };
    return emojis[severity as keyof typeof emojis] || '⚪';
  }
}

// Run audit
async function main() {
  const auditor = new ClerkSecurityAuditor();
  await auditor.runAudit();
  auditor.printReport();

  // Exit with error code if critical issues found
  const criticalIssues = auditor['issues'].filter(
    (i) => i.severity === 'CRITICAL'
  );
  if (criticalIssues.length > 0) {
    process.exit(1);
  }
}

main().catch(console.error);
