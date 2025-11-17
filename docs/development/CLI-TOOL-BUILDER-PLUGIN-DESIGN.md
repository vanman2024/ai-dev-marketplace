# CLI Tool Builder Plugin Design

## Overview

A comprehensive plugin for building professional CLI tools using the domain plugin builder framework. This plugin enables rapid development of command-line interfaces with best practices built-in.

---

## Plugin Structure

```
plugins/cli-tool-builder/
├── .claude-plugin/
│   └── plugin.json                 # Plugin metadata
├── README.md                        # Plugin overview
├── commands/                        # Slash commands
│   ├── new-cli.md                  # Initialize new CLI tool
│   ├── add-subcommand.md           # Add subcommands
│   ├── add-config.md               # Add configuration
│   ├── add-interactive.md          # Add prompts/menus
│   ├── add-args-parser.md          # Add argument parsing
│   ├── add-output-formatting.md    # Colors, tables, spinners
│   └── add-package.md              # Add distribution setup
├── agents/
│   ├── cli-setup.md                # Project initialization
│   ├── cli-feature-impl.md         # Feature implementation
│   ├── cli-verifier-node.md        # Node.js validator
│   └── cli-verifier-python.md      # Python validator
├── skills/
│   ├── python-frameworks/
│   │   ├── click-patterns/         # Click framework examples
│   │   ├── typer-patterns/         # Typer framework examples
│   │   ├── argparse-patterns/      # argparse examples
│   │   └── fire-patterns/          # Fire framework examples
│   ├── nodejs-frameworks/
│   │   ├── commander-patterns/     # commander.js examples
│   │   ├── yargs-patterns/         # yargs examples
│   │   ├── oclif-patterns/         # oclif examples
│   │   └── gluegun-patterns/       # gluegun examples
│   ├── go-frameworks/
│   │   ├── cobra-patterns/         # Cobra examples
│   │   └── cli-patterns/           # go-cli examples
│   ├── rust-frameworks/
│   │   └── clap-patterns/          # clap examples
│   ├── inquirer-patterns/          # Interactive prompts
│   └── cli-testing-patterns/       # Testing strategies
└── examples/
    ├── typescript/                  # TypeScript CLI examples
    └── python/                      # Python CLI examples
```

---

## Tools & Framework Selection

The plugin provides **interactive framework selection** based on your chosen language. Each framework has distinct advantages:

### Python CLI Frameworks

| Framework    | Best For                | Features                                          | Complexity |
| ------------ | ----------------------- | ------------------------------------------------- | ---------- |
| **Click**    | General-purpose CLIs    | Decorators, nested commands, parameter validation | Medium     |
| **Typer**    | Modern type-safe CLIs   | Type hints, auto-completion, minimal boilerplate  | Easy       |
| **argparse** | Standard library option | No dependencies, built-in Python                  | Medium     |
| **Fire**     | Rapid prototyping       | Auto-generate CLI from any Python object          | Easy       |

**Interactive Selection:**

```bash
/cli-tool-builder:new-cli my-tool

? Select language: Python
? Select Python CLI framework:
  ❯ Click - Popular, decorator-based framework (recommended)
    Typer - Modern, type-hint based framework
    argparse - Built-in Python standard library
    Fire - Auto-generate CLI from Python code
? Select package manager:
  ❯ pip (requirements.txt)
    poetry (pyproject.toml)
    pipenv (Pipfile)
```

### Node.js/TypeScript CLI Frameworks

| Framework        | Best For                 | Features                                | Complexity |
| ---------------- | ------------------------ | --------------------------------------- | ---------- |
| **Commander.js** | Full-featured CLIs       | Simple API, widely used, flexible       | Easy       |
| **yargs**        | Complex argument parsing | Advanced parsing, middleware support    | Medium     |
| **oclif**        | Large CLI applications   | Plugin system, auto-docs, testing tools | Advanced   |
| **gluegun**      | CLI with code generation | Templates, filesystem tools, HTTP       | Advanced   |

**Interactive Selection:**

```bash
/cli-tool-builder:new-cli my-tool

? Select language: TypeScript
? Select Node.js CLI framework:
  ❯ Commander.js - Simple and elegant (recommended)
    yargs - Advanced argument parsing
    oclif - Enterprise CLI framework
    gluegun - CLI with generators and tools
? Select package manager:
  ❯ npm
    yarn
    pnpm
```

### Go CLI Frameworks

| Framework | Best For         | Features                          | Complexity |
| --------- | ---------------- | --------------------------------- | ---------- |
| **Cobra** | Production CLIs  | Used by kubectl, hugo, GitHub CLI | Medium     |
| **cli**   | Lightweight CLIs | Minimal, fast, simple API         | Easy       |

### Rust CLI Frameworks

| Framework     | Best For           | Features                                            | Complexity |
| ------------- | ------------------ | --------------------------------------------------- | ---------- |
| **clap**      | Full-featured CLIs | Derive macros, validation, subcommands              | Medium     |
| **structopt** | Type-safe CLIs     | Struct-based definitions (deprecated, use clap v3+) | Easy       |

---

## Core Commands

### 1. `/cli-tool-builder:new-cli [tool-name]`

**Purpose:** Creates a complete CLI tool project from scratch

**Features:**

- Language selection (TypeScript/Node.js, Python, Go, Rust)
- **Framework selection based on language:**
  - **Python:** Click, Typer, argparse, Fire
  - **Node.js/TypeScript:** Commander.js, yargs, oclif, gluegun
  - **Go:** Cobra, cli
  - **Rust:** clap, structopt
- Package manager setup (npm/yarn/pnpm, pip/poetry/pipenv)
- CLI framework installation with best practices
- Basic entry point with `#!/usr/bin/env` shebang
- Package.json with `bin` field or setup.py with `entry_points`
- Starter command structure
- Help documentation generation
- Git initialization with .gitignore
- License file
- README template

**Example Usage:**

```bash
/cli-tool-builder:new-cli my-deploy-tool
```

**Generated Project (Node.js/TypeScript):**

```
my-deploy-tool/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts
│   └── commands/
├── bin/
│   └── my-deploy-tool
├── tests/
├── README.md
└── .gitignore
```

---

### 2. `/cli-tool-builder:add-subcommand [command-name]`

**Purpose:** Adds structured subcommands to your CLI tool

**Features:**

- Subcommand scaffolding (e.g., `mycli create`, `mycli deploy`)
- Option/flag definitions
- Argument validation
- Command grouping
- Help text generation
- Error handling
- Command aliases

**Example Usage:**

```bash
/cli-tool-builder:add-subcommand deploy
/cli-tool-builder:add-subcommand create --alias c
```

**Generated Code (commander.js):**

```typescript
program
  .command('deploy')
  .description('Deploy application to specified environment')
  .option('-e, --env <environment>', 'deployment environment', 'production')
  .option('-v, --verbose', 'verbose output')
  .action(async (options) => {
    try {
      await deploy(options);
    } catch (error) {
      console.error('Deploy failed:', error.message);
      process.exit(1);
    }
  });
```

---

### 3. `/cli-tool-builder:add-config [config-type]`

**Purpose:** Adds configuration file management to your CLI

**Supported Config Types:**

- `json` - JSON configuration files
- `yaml` - YAML configuration files
- `toml` - TOML configuration files
- `env` - Environment variables
- `rc` - RC files (.myclirc)

**Features:**

- Config file formats (JSON, YAML, TOML, .env)
- Config locations (`~/.config/mytool`, `.mytoolrc`)
- Environment variable support
- Config validation schemas
- Defaults and overrides
- Config file creation wizard
- Multiple config sources with precedence

**Example Usage:**

```bash
/cli-tool-builder:add-config yaml
```

**Generated Code:**

```typescript
import * as yaml from 'js-yaml';
import * as fs from 'fs';
import * as path from 'path';

interface Config {
  defaultEnvironment: string;
  apiEndpoint: string;
  timeout: number;
}

function loadConfig(): Config {
  const configPath = path.join(
    os.homedir(),
    '.config',
    'mytool',
    'config.yaml'
  );
  const defaults: Config = {
    defaultEnvironment: 'production',
    apiEndpoint: 'https://api.example.com',
    timeout: 30000,
  };

  if (!fs.existsSync(configPath)) {
    return defaults;
  }

  const fileConfig = yaml.load(
    fs.readFileSync(configPath, 'utf8')
  ) as Partial<Config>;
  return { ...defaults, ...fileConfig };
}
```

---

### 4. `/cli-tool-builder:add-interactive`

**Purpose:** Adds interactive prompts and menus

**Features:**

- Text input prompts
- Select menus (single choice)
- Multi-select checkboxes
- Password input (hidden)
- Autocomplete
- Confirmation prompts
- Validation
- Conditional questions

**Supported Libraries:**

- Node.js: inquirer, prompts, enquirer
- Python: questionary, PyInquirer, click.prompt

**Example Usage:**

```bash
/cli-tool-builder:add-interactive
```

**Generated Code (inquirer.js):**

```typescript
import inquirer from 'inquirer';

async function deployInteractive() {
  const answers = await inquirer.prompt([
    {
      type: 'list',
      name: 'environment',
      message: 'Select deployment environment:',
      choices: ['development', 'staging', 'production'],
      default: 'staging',
    },
    {
      type: 'confirm',
      name: 'runMigrations',
      message: 'Run database migrations?',
      default: true,
    },
    {
      type: 'password',
      name: 'apiKey',
      message: 'Enter API key:',
      validate: (input) => input.length > 0 || 'API key is required',
    },
  ]);

  return answers;
}
```

**Generated Code (Python/Click):**

```python
import click

def deploy_interactive():
    environment = click.prompt(
        'Select deployment environment',
        type=click.Choice(['development', 'staging', 'production']),
        default='staging'
    )

    run_migrations = click.confirm('Run database migrations?', default=True)

    api_key = click.prompt('Enter API key', hide_input=True)

    return {
        'environment': environment,
        'run_migrations': run_migrations,
        'api_key': api_key
    }
```

---

### 5. `/cli-tool-builder:add-args-parser`

**Purpose:** Adds advanced argument parsing capabilities

**Features:**

- Positional arguments
- Options/flags (`--verbose`, `-v`)
- Boolean flags
- Variadic arguments
- Mutually exclusive options
- Custom validators
- Type coercion
- Default values
- Required vs optional arguments

**Example Usage:**

```bash
/cli-tool-builder:add-args-parser
```

**Generated Code (commander.js):**

```typescript
program
  .command('deploy <app-name>')
  .description('Deploy application')
  .argument('<app-name>', 'name of the application')
  .argument('[version]', 'version to deploy', 'latest')
  .option('-e, --env <environment>', 'deployment environment', 'production')
  .option('-f, --force', 'force deployment', false)
  .option('-t, --timeout <seconds>', 'timeout in seconds', parseInt, 30)
  .option('--no-cache', 'disable cache')
  .addOption(
    new Option('-l, --log-level <level>', 'log level')
      .choices(['debug', 'info', 'warn', 'error'])
      .default('info')
  )
  .action((appName, version, options) => {
    // Validation
    if (options.timeout < 1) {
      console.error('Timeout must be at least 1 second');
      process.exit(1);
    }

    deploy(appName, version, options);
  });
```

---

### 6. `/cli-tool-builder:add-output-formatting`

**Purpose:** Adds rich terminal output capabilities

**Features:**

- Colored output (success, error, warning, info)
- Progress bars
- Spinners for async operations
- Tables (ASCII, unicode, markdown)
- Box drawing
- Icons and symbols
- Multi-line status updates
- File tree visualization

**Supported Libraries:**

- Node.js: chalk, ora, cli-table3, boxen, log-symbols
- Python: colorama, rich, tqdm, tabulate

**Example Usage:**

```bash
/cli-tool-builder:add-output-formatting
```

**Generated Code (Node.js):**

```typescript
import chalk from 'chalk';
import ora from 'ora';
import Table from 'cli-table3';
import boxen from 'boxen';
import logSymbols from 'log-symbols';

// Colored output
console.log(chalk.green('✓ Deployment successful!'));
console.log(chalk.red('✗ Build failed'));
console.log(chalk.yellow('⚠ Warning: Using cached data'));
console.log(chalk.blue('ℹ Info: Connecting to server...'));

// Spinner
const spinner = ora('Deploying application...').start();
await deploy();
spinner.succeed('Deployment complete!');

// Table
const table = new Table({
  head: ['Service', 'Status', 'Uptime'],
  colWidths: [20, 15, 15],
});

table.push(
  ['API Server', chalk.green('Running'), '5d 3h'],
  ['Database', chalk.green('Running'), '12d 8h'],
  ['Cache', chalk.red('Down'), '0h']
);

console.log(table.toString());

// Box
console.log(
  boxen(
    chalk.green('Deployment Successful!\n\n') +
      `Environment: ${chalk.cyan('production')}\n` +
      `Version: ${chalk.cyan('v1.2.3')}\n` +
      `URL: ${chalk.underline('https://app.example.com')}`,
    { padding: 1, borderStyle: 'round', borderColor: 'green' }
  )
);
```

**Generated Code (Python/Rich):**

```python
from rich.console import Console
from rich.table import Table
from rich.progress import track
from rich.panel import Panel
from rich import box

console = Console()

# Colored output
console.print("[green]✓[/green] Deployment successful!")
console.print("[red]✗[/red] Build failed")
console.print("[yellow]⚠[/yellow] Warning: Using cached data")

# Progress bar
for i in track(range(100), description="Deploying..."):
    deploy_step(i)

# Table
table = Table(title="Service Status", box=box.ROUNDED)
table.add_column("Service", style="cyan")
table.add_column("Status", style="magenta")
table.add_column("Uptime", style="green")

table.add_row("API Server", "[green]Running[/green]", "5d 3h")
table.add_row("Database", "[green]Running[/green]", "12d 8h")
table.add_row("Cache", "[red]Down[/red]", "0h")

console.print(table)

# Panel
console.print(Panel(
    "[green]Deployment Successful![/green]\n\n"
    f"Environment: [cyan]production[/cyan]\n"
    f"Version: [cyan]v1.2.3[/cyan]\n"
    f"URL: https://app.example.com",
    title="Deployment Complete",
    border_style="green"
))
```

---

### 7. `/cli-tool-builder:add-package`

**Purpose:** Sets up distribution and packaging for your CLI tool

**Features:**

- npm package publishing setup
- PyPI package publishing setup
- Binary compilation (pkg, PyInstaller, goreleaser)
- Homebrew formula generation
- Installation instructions
- Version management
- Changelog generation
- Release automation (GitHub Actions)

**Example Usage:**

```bash
/cli-tool-builder:add-package npm
/cli-tool-builder:add-package pypi
/cli-tool-builder:add-package homebrew
```

**Generated Files (npm):**

**package.json:**

```json
{
  "name": "my-deploy-tool",
  "version": "1.0.0",
  "description": "A deployment CLI tool",
  "main": "dist/index.js",
  "bin": {
    "my-deploy-tool": "./bin/my-deploy-tool"
  },
  "scripts": {
    "build": "tsc",
    "prepublishOnly": "npm run build",
    "release": "np"
  },
  "keywords": ["cli", "deployment", "devops"],
  "author": "Your Name",
  "license": "MIT",
  "files": ["dist", "bin", "README.md"],
  "engines": {
    "node": ">=14.0.0"
  }
}
```

**Generated Files (Python):**

**setup.py:**

```python
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="my-deploy-tool",
    version="1.0.0",
    author="Your Name",
    description="A deployment CLI tool",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/my-deploy-tool",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
    ],
    python_requires=">=3.7",
    install_requires=[
        "click>=8.0.0",
        "requests>=2.25.0",
    ],
    entry_points={
        "console_scripts": [
            "my-deploy-tool=my_deploy_tool.cli:main",
        ],
    },
)
```

**Homebrew Formula:**

```ruby
class MyDeployTool < Formula
  desc "A deployment CLI tool"
  homepage "https://github.com/yourusername/my-deploy-tool"
  url "https://github.com/yourusername/my-deploy-tool/archive/v1.0.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "1.0.0", shell_output("#{bin}/my-deploy-tool --version")
  end
end
```

---

## Agents

### `cli-setup` Agent

**Role:** Project initialization specialist

**Responsibilities:**

- Detect or prompt for target language/runtime
- Install CLI framework dependencies
- Create project structure
- Set up entry point files
- Configure executable permissions
- Generate package configuration files
- Initialize git repository
- Create README and LICENSE

**Workflow:**

```
1. Prompt for language (TypeScript, Python, Go, etc.)
2. Prompt for CLI name
3. Create directory structure
4. Install framework (commander.js, Click, etc.)
5. Generate entry point with proper shebang
6. Set executable permissions (chmod +x)
7. Configure package manager
8. Generate documentation templates
```

---

### `cli-feature-impl` Agent

**Role:** Feature implementation specialist

**Responsibilities:**

- Implement subcommands
- Add configuration handling
- Integrate interactive prompts
- Set up output formatting
- Add error handling
- Implement validation logic
- Create helper functions
- Write command documentation

**Workflow:**

```
1. Analyze requested feature
2. Identify dependencies needed
3. Generate implementation code
4. Add error handling
5. Create unit tests
6. Update help documentation
```

---

### `cli-verifier-node` Agent

**Role:** Node.js CLI validator

**Responsibilities:**

- Verify executable permissions
- Check package.json bin field
- Validate entry point exists
- Test command registration
- Verify help text generation
- Check error handling
- Validate exit codes
- Test with various argument combinations

**Validation Checklist:**

```
✓ package.json has "bin" field
✓ Executable file exists and has shebang
✓ File has execute permissions (chmod +x)
✓ Dependencies are installed
✓ Command runs without errors
✓ Help text is generated (--help)
✓ Version is displayed (--version)
✓ Exit codes are correct (0 for success, 1 for error)
✓ Unknown commands show helpful error
```

---

### `cli-verifier-python` Agent

**Role:** Python CLI validator

**Responsibilities:**

- Verify setup.py entry_points
- Check Python version requirements
- Validate command installation
- Test command execution
- Verify help text generation
- Check error handling
- Validate exit codes
- Test with various argument combinations

**Validation Checklist:**

```
✓ setup.py has entry_points configured
✓ Python version requirements met
✓ Dependencies installed correctly
✓ Command available in PATH after install
✓ Command runs without errors
✓ Help text generated (--help)
✓ Version displayed correctly
✓ Exit codes appropriate
✓ Error messages are clear
```

---

## Skills

### `commander-patterns` (Node.js)

**Complete Example:**

```typescript
import { Command, Option } from 'commander';
import chalk from 'chalk';

const program = new Command();

program.name('mycli').description('A powerful CLI tool').version('1.0.0');

// Simple command
program
  .command('init')
  .description('Initialize a new project')
  .option('-t, --template <type>', 'project template', 'basic')
  .action((options) => {
    console.log(
      chalk.green(`Initializing project with ${options.template} template...`)
    );
  });

// Command with arguments
program
  .command('deploy <environment>')
  .description('Deploy to specified environment')
  .argument('<environment>', 'target environment')
  .option('-f, --force', 'force deployment')
  .addOption(
    new Option('-m, --mode <mode>', 'deployment mode')
      .choices(['fast', 'safe', 'rollback'])
      .default('safe')
  )
  .action((environment, options) => {
    console.log(`Deploying to ${environment} in ${options.mode} mode`);
  });

// Nested subcommands
const config = program.command('config').description('Manage configuration');

config
  .command('get <key>')
  .description('Get configuration value')
  .action((key) => {
    console.log(`Config ${key}:`, getConfig(key));
  });

config
  .command('set <key> <value>')
  .description('Set configuration value')
  .action((key, value) => {
    setConfig(key, value);
    console.log(chalk.green(`✓ Set ${key} = ${value}`));
  });

program.parse();
```

---

### `click-patterns` (Python - Click Framework)

**Complete Example:**

```python
import click
from rich.console import Console

console = Console()

@click.group()
@click.version_option(version='1.0.0')
@click.pass_context
def cli(ctx):
    """A powerful CLI tool"""
    ctx.ensure_object(dict)

@cli.command()
@click.option('--template', '-t', default='basic', help='Project template')
def init(template):
    """Initialize a new project"""
    console.print(f"[green]Initializing project with {template} template...[/green]")

@cli.command()
@click.argument('environment')
@click.option('--force', '-f', is_flag=True, help='Force deployment')
@click.option('--mode', '-m',
              type=click.Choice(['fast', 'safe', 'rollback']),
              default='safe',
              help='Deployment mode')
def deploy(environment, force, mode):
    """Deploy to specified environment"""
    console.print(f"Deploying to {environment} in {mode} mode")
    if force:
        console.print("[yellow]⚠ Force mode enabled[/yellow]")

@cli.group()
def config():
    """Manage configuration"""
    pass

@config.command()
@click.argument('key')
def get(key):
    """Get configuration value"""
    value = get_config(key)
    console.print(f"Config {key}: {value}")

@config.command()
@click.argument('key')
@click.argument('value')
def set(key, value):
    """Set configuration value"""
    set_config(key, value)
    console.print(f"[green]✓[/green] Set {key} = {value}")

if __name__ == '__main__':
    cli()
```

---

### `typer-patterns` (Python - Typer Framework)

**Complete Example (Modern Type-Safe Approach):**

```python
import typer
from typing import Optional
from enum import Enum
from rich.console import Console

console = Console()
app = typer.Typer()

class DeployMode(str, Enum):
    fast = "fast"
    safe = "safe"
    rollback = "rollback"

@app.command()
def init(
    template: str = typer.Option("basic", "--template", "-t", help="Project template")
):
    """Initialize a new project"""
    console.print(f"[green]Initializing project with {template} template...[/green]")

@app.command()
def deploy(
    environment: str = typer.Argument(..., help="Target environment"),
    force: bool = typer.Option(False, "--force", "-f", help="Force deployment"),
    mode: DeployMode = typer.Option(DeployMode.safe, "--mode", "-m", help="Deployment mode")
):
    """Deploy to specified environment"""
    console.print(f"Deploying to {environment} in {mode.value} mode")
    if force:
        console.print("[yellow]⚠ Force mode enabled[/yellow]")

# Nested commands with sub-app
config_app = typer.Typer()
app.add_typer(config_app, name="config", help="Manage configuration")

@config_app.command("get")
def config_get(key: str = typer.Argument(..., help="Configuration key")):
    """Get configuration value"""
    value = get_config(key)
    console.print(f"Config {key}: {value}")

@config_app.command("set")
def config_set(
    key: str = typer.Argument(..., help="Configuration key"),
    value: str = typer.Argument(..., help="Configuration value")
):
    """Set configuration value"""
    set_config(key, value)
    console.print(f"[green]✓[/green] Set {key} = {value}")

if __name__ == "__main__":
    app()
```

---

### `argparse-patterns` (Python - Standard Library)

**Complete Example (No Dependencies):**

```python
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(
        description='A powerful CLI tool',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('--version', action='version', version='1.0.0')

    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # Init command
    init_parser = subparsers.add_parser('init', help='Initialize a new project')
    init_parser.add_argument(
        '--template', '-t',
        default='basic',
        help='Project template'
    )

    # Deploy command
    deploy_parser = subparsers.add_parser('deploy', help='Deploy to specified environment')
    deploy_parser.add_argument('environment', help='Target environment')
    deploy_parser.add_argument(
        '--force', '-f',
        action='store_true',
        help='Force deployment'
    )
    deploy_parser.add_argument(
        '--mode', '-m',
        choices=['fast', 'safe', 'rollback'],
        default='safe',
        help='Deployment mode'
    )

    # Config commands
    config_parser = subparsers.add_parser('config', help='Manage configuration')
    config_subparsers = config_parser.add_subparsers(dest='config_command')

    config_get = config_subparsers.add_parser('get', help='Get configuration value')
    config_get.add_argument('key', help='Configuration key')

    config_set = config_subparsers.add_parser('set', help='Set configuration value')
    config_set.add_argument('key', help='Configuration key')
    config_set.add_argument('value', help='Configuration value')

    args = parser.parse_args()

    if args.command == 'init':
        print(f"Initializing project with {args.template} template...")
    elif args.command == 'deploy':
        print(f"Deploying to {args.environment} in {args.mode} mode")
        if args.force:
            print("⚠ Force mode enabled")
    elif args.command == 'config':
        if args.config_command == 'get':
            value = get_config(args.key)
            print(f"Config {args.key}: {value}")
        elif args.config_command == 'set':
            set_config(args.key, args.value)
            print(f"✓ Set {args.key} = {args.value}")
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()
```

---

### `fire-patterns` (Python - Google Fire)

**Complete Example (Auto-Generated CLI):**

```python
import fire
from rich.console import Console

console = Console()

class MyCLI:
    """A powerful CLI tool"""

    def __init__(self):
        self.version = "1.0.0"

    def init(self, template='basic'):
        """Initialize a new project

        Args:
            template: Project template (default: basic)
        """
        console.print(f"[green]Initializing project with {template} template...[/green]")

    def deploy(self, environment, force=False, mode='safe'):
        """Deploy to specified environment

        Args:
            environment: Target environment
            force: Force deployment (default: False)
            mode: Deployment mode - fast, safe, or rollback (default: safe)
        """
        console.print(f"Deploying to {environment} in {mode} mode")
        if force:
            console.print("[yellow]⚠ Force mode enabled[/yellow]")

    class Config:
        """Manage configuration"""

        def get(self, key):
            """Get configuration value

            Args:
                key: Configuration key
            """
            value = get_config(key)
            console.print(f"Config {key}: {value}")

        def set(self, key, value):
            """Set configuration value

            Args:
                key: Configuration key
                value: Configuration value
            """
            set_config(key, value)
            console.print(f"[green]✓[/green] Set {key} = {value}")

if __name__ == '__main__':
    fire.Fire(MyCLI)

# Usage:
# python mycli.py init --template=react
# python mycli.py deploy production --force
# python mycli.py config get database_url
# python mycli.py config set api_key abc123
```

---### `inquirer-patterns` (Interactive Prompts)

**Complete Example:**

```typescript
import inquirer from 'inquirer';
import chalk from 'chalk';

async function deployWizard() {
  console.log(chalk.bold.cyan('\n🚀 Deployment Wizard\n'));

  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'appName',
      message: 'Application name:',
      default: 'my-app',
      validate: (input) => {
        if (!/^[a-z0-9-]+$/.test(input)) {
          return 'App name must contain only lowercase letters, numbers, and hyphens';
        }
        return true;
      },
    },
    {
      type: 'list',
      name: 'environment',
      message: 'Select environment:',
      choices: [
        { name: '🔧 Development', value: 'dev' },
        { name: '🎭 Staging', value: 'staging' },
        { name: '🚀 Production', value: 'prod' },
      ],
      default: 'staging',
    },
    {
      type: 'checkbox',
      name: 'services',
      message: 'Select services to deploy:',
      choices: [
        { name: 'API Server', checked: true },
        { name: 'Worker Queue', checked: true },
        { name: 'Database Migrations', checked: false },
        { name: 'Static Assets', checked: true },
      ],
      validate: (input) => {
        if (input.length === 0) {
          return 'You must select at least one service';
        }
        return true;
      },
    },
    {
      type: 'confirm',
      name: 'runTests',
      message: 'Run tests before deployment?',
      default: true,
    },
    {
      type: 'password',
      name: 'apiKey',
      message: 'Enter deployment API key:',
      mask: '*',
      validate: (input) => {
        if (input.length < 20) {
          return 'API key must be at least 20 characters';
        }
        return true;
      },
    },
    {
      type: 'number',
      name: 'instances',
      message: 'Number of instances:',
      default: 2,
      validate: (input) => {
        if (input < 1 || input > 10) {
          return 'Must be between 1 and 10';
        }
        return true;
      },
    },
    {
      type: 'confirm',
      name: 'confirmed',
      message: (answers) => {
        return chalk.yellow(
          `Deploy ${answers.appName} to ${answers.environment}?`
        );
      },
      default: false,
    },
  ]);

  if (!answers.confirmed) {
    console.log(chalk.red('\n✗ Deployment cancelled\n'));
    return;
  }

  return answers;
}

// Conditional questions
async function conditionalPrompts() {
  const answers = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'useCustomDomain',
      message: 'Use custom domain?',
      default: false,
    },
    {
      type: 'input',
      name: 'domain',
      message: 'Enter custom domain:',
      when: (answers) => answers.useCustomDomain,
      validate: (input) => {
        const domainRegex = /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$/;
        return domainRegex.test(input) || 'Invalid domain format';
      },
    },
  ]);

  return answers;
}

// Autocomplete
import inquirerAutocomplete from 'inquirer-autocomplete-prompt';

inquirer.registerPrompt('autocomplete', inquirerAutocomplete);

async function autocompleteExample() {
  const regions = [
    'us-east-1',
    'us-west-1',
    'us-west-2',
    'eu-west-1',
    'eu-central-1',
    'ap-southeast-1',
    'ap-northeast-1',
  ];

  const answer = await inquirer.prompt([
    {
      type: 'autocomplete',
      name: 'region',
      message: 'Select AWS region:',
      source: (answersSoFar, input) => {
        input = input || '';
        return new Promise((resolve) => {
          const filtered = regions.filter((region) =>
            region.toLowerCase().includes(input.toLowerCase())
          );
          resolve(filtered);
        });
      },
    },
  ]);

  return answer;
}
```

---

### `cli-testing-patterns`

**Node.js Testing (Jest):**

```typescript
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

describe('CLI Tool Tests', () => {
  const CLI_PATH = path.join(__dirname, '../bin/mycli');

  function runCLI(args: string): {
    stdout: string;
    stderr: string;
    code: number;
  } {
    try {
      const stdout = execSync(`${CLI_PATH} ${args}`, {
        encoding: 'utf8',
        stdio: 'pipe',
      });
      return { stdout, stderr: '', code: 0 };
    } catch (error: any) {
      return {
        stdout: error.stdout || '',
        stderr: error.stderr || '',
        code: error.status || 1,
      };
    }
  }

  test('should display version', () => {
    const { stdout, code } = runCLI('--version');
    expect(code).toBe(0);
    expect(stdout).toContain('1.0.0');
  });

  test('should display help', () => {
    const { stdout, code } = runCLI('--help');
    expect(code).toBe(0);
    expect(stdout).toContain('Usage:');
    expect(stdout).toContain('Commands:');
  });

  test('should handle unknown command', () => {
    const { stderr, code } = runCLI('unknown-command');
    expect(code).toBe(1);
    expect(stderr).toContain('unknown command');
  });

  test('should deploy with correct arguments', () => {
    const { stdout, code } = runCLI('deploy production --force');
    expect(code).toBe(0);
    expect(stdout).toContain('Deploying to production');
  });

  test('should validate required arguments', () => {
    const { stderr, code } = runCLI('deploy');
    expect(code).toBe(1);
    expect(stderr).toContain('missing required argument');
  });

  test('should handle configuration', () => {
    const { stdout, code } = runCLI('config set key value');
    expect(code).toBe(0);

    const { stdout: getValue } = runCLI('config get key');
    expect(getValue).toContain('value');
  });
});
```

**Python Testing (pytest):**

```python
import pytest
from click.testing import CliRunner
from mycli.cli import cli

@pytest.fixture
def runner():
    return CliRunner()

def test_version(runner):
    result = runner.invoke(cli, ['--version'])
    assert result.exit_code == 0
    assert '1.0.0' in result.output

def test_help(runner):
    result = runner.invoke(cli, ['--help'])
    assert result.exit_code == 0
    assert 'Usage:' in result.output
    assert 'Commands:' in result.output

def test_unknown_command(runner):
    result = runner.invoke(cli, ['unknown-command'])
    assert result.exit_code != 0
    assert 'no such command' in result.output.lower()

def test_deploy_command(runner):
    result = runner.invoke(cli, ['deploy', 'production', '--force'])
    assert result.exit_code == 0
    assert 'Deploying to production' in result.output

def test_deploy_validation(runner):
    result = runner.invoke(cli, ['deploy'])
    assert result.exit_code != 0
    assert 'missing argument' in result.output.lower()

def test_config_set_and_get(runner):
    result = runner.invoke(cli, ['config', 'set', 'key', 'value'])
    assert result.exit_code == 0

    result = runner.invoke(cli, ['config', 'get', 'key'])
    assert result.exit_code == 0
    assert 'value' in result.output

def test_interactive_prompts(runner):
    """Test interactive prompts with input simulation"""
    result = runner.invoke(cli, ['deploy-wizard'], input='my-app\n1\nyes\n')
    assert result.exit_code == 0
    assert 'my-app' in result.output
```

---

## Example Workflows

### Workflow 1: Create a Deployment CLI

```bash
# Step 1: Create new CLI tool
/cli-tool-builder:new-cli my-deploy-tool

# Step 2: Add deployment subcommand
/cli-tool-builder:add-subcommand deploy

# Step 3: Add interactive configuration wizard
/cli-tool-builder:add-interactive

# Step 4: Add rich output formatting
/cli-tool-builder:add-output-formatting

# Step 5: Add YAML configuration support
/cli-tool-builder:add-config yaml

# Step 6: Prepare for npm distribution
/cli-tool-builder:add-package npm

# Result: Complete CLI tool
# ✓ my-deploy-tool deploy --env production
# ✓ my-deploy-tool wizard (interactive mode)
# ✓ Colored output with progress indicators
# ✓ Configuration in ~/.config/my-deploy-tool/config.yaml
# ✓ Ready to publish to npm
```

### Workflow 2: Create a Database Migration CLI

```bash
# Step 1: Create Python-based CLI
/cli-tool-builder:new-cli db-migrate --lang python

# Step 2: Add migration commands
/cli-tool-builder:add-subcommand migrate
/cli-tool-builder:add-subcommand rollback
/cli-tool-builder:add-subcommand status

# Step 3: Add configuration for database connection
/cli-tool-builder:add-config env

# Step 4: Add table output for migration status
/cli-tool-builder:add-output-formatting

# Step 5: Package for PyPI
/cli-tool-builder:add-package pypi

# Result: Database migration tool
# ✓ db-migrate migrate --target latest
# ✓ db-migrate rollback --steps 1
# ✓ db-migrate status (shows table of migrations)
# ✓ Configuration via .env or environment variables
# ✓ Ready to publish to PyPI
```

### Workflow 3: Create a Project Generator CLI

```bash
# Step 1: Create TypeScript CLI
/cli-tool-builder:new-cli create-app --lang typescript

# Step 2: Add interactive project wizard
/cli-tool-builder:add-interactive

# Step 3: Add template selection argument
/cli-tool-builder:add-args-parser

# Step 4: Add progress indicators for file generation
/cli-tool-builder:add-output-formatting

# Step 5: Package as standalone binary
/cli-tool-builder:add-package binary

# Result: Project generator
# ✓ create-app (interactive wizard)
# ✓ create-app my-project --template react-ts
# ✓ Beautiful progress bars during setup
# ✓ Standalone executable (no Node.js required)
```

---

## Best Practices Enforced by Plugin

### 1. **Help Documentation**

- Auto-generate help text for all commands
- Include usage examples
- Document all options and arguments
- Provide command descriptions

### 2. **Error Handling**

- Clear error messages
- Proper exit codes (0 = success, 1+ = error)
- Validation before execution
- Graceful failure handling

### 3. **User Experience**

- Consistent output formatting
- Progress indicators for long operations
- Interactive prompts when appropriate
- Confirmation for destructive operations

### 4. **Configuration**

- Multiple config sources (file, env, flags)
- Clear precedence order
- Config validation
- Sensible defaults

### 5. **Testing**

- Unit tests for commands
- Integration tests for workflows
- Mock external dependencies
- Test error scenarios

### 6. **Distribution**

- Proper packaging
- Clear installation instructions
- Version management
- Cross-platform support

---

## Advanced Features

### Plugin Extensibility

Users can extend CLI tools with plugins:

```typescript
// Plugin architecture
interface CLIPlugin {
  name: string;
  commands: Command[];
  hooks: {
    beforeCommand?: (context: Context) => void;
    afterCommand?: (context: Context) => void;
  };
}

// Load plugins
function loadPlugins(pluginDir: string): CLIPlugin[] {
  const plugins: CLIPlugin[] = [];
  const files = fs.readdirSync(pluginDir);

  for (const file of files) {
    if (file.endsWith('.js')) {
      const plugin = require(path.join(pluginDir, file));
      plugins.push(plugin);
    }
  }

  return plugins;
}

// Register plugin commands
const plugins = loadPlugins('./plugins');
plugins.forEach((plugin) => {
  plugin.commands.forEach((cmd) => {
    program.addCommand(cmd);
  });
});
```

### Shell Completion

Auto-generate shell completion scripts:

```bash
# Bash completion
my-tool completion bash > /etc/bash_completion.d/my-tool

# Zsh completion
my-tool completion zsh > /usr/local/share/zsh/site-functions/_my-tool

# Fish completion
my-tool completion fish > ~/.config/fish/completions/my-tool.fish
```

### Update Notifications

Check for updates automatically:

```typescript
import updateNotifier from 'update-notifier';
import pkg from '../package.json';

const notifier = updateNotifier({
  pkg,
  updateCheckInterval: 1000 * 60 * 60 * 24, // Check daily
});

notifier.notify({
  isGlobal: true,
  message:
    `Update available ${chalk.dim('{currentVersion}')} → ${chalk.green(
      '{latestVersion}'
    )}\n` + `Run ${chalk.cyan('npm i -g {name}')} to update`,
});
```

---

## Summary

This CLI Tool Builder Plugin provides everything needed to create professional, user-friendly command-line tools:

✅ **Quick Setup** - Initialize projects in seconds  
✅ **Best Practices** - Enforces CLI design patterns  
✅ **Rich Features** - Interactive prompts, formatting, config  
✅ **Testing** - Built-in testing patterns  
✅ **Distribution** - Ready for npm, PyPI, Homebrew  
✅ **Validation** - Automated verification agents  
✅ **Documentation** - Auto-generated help and docs  
✅ **Cross-Platform** - Works on Windows, macOS, Linux

**Use this plugin to build CLI tools 10x faster with production-ready quality.**
