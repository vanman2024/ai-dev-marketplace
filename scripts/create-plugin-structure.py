#!/usr/bin/env python3
"""
Create New Plugin with Enterprise Structure

Creates a complete plugin scaffold following enterprise standards:
- .claude-plugin/plugin.json
- .mcp.json placeholder
- hooks/hooks.json
- LICENSE (MIT)
- CHANGELOG.md
- commands/
- agents/
- skills/{skill-name}/
  ├── SKILL.md
  ├── reference.md
  ├── examples.md
  ├── scripts/
  └── templates/

Usage:
    python create-plugin-structure.py <plugin-name> [--skill <skill-name>]

Examples:
    python create-plugin-structure.py multiagent-analytics --skill analytics-assistant
    python create-plugin-structure.py multiagent-testing --skill test-runner
"""

import sys
import json
from pathlib import Path
from datetime import datetime

MARKETPLACE_DIR = Path.home() / ".claude/marketplaces/multiagent-dev/plugins"

# Templates
LICENSE_TEMPLATE = """MIT License

Copyright (c) {year} Multiagent Framework

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

CHANGELOG_TEMPLATE = """# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Initial plugin implementation
- Core features and commands
- Documentation

## [1.0.0] - {date}

### Added
- Plugin structure created
- Enterprise directory layout
- Skill scaffolding for {skill_name}
"""

PLUGIN_JSON_TEMPLATE = {
    "name": "{plugin_name}",
    "version": "1.0.0",
    "description": "{description}",
    "author": {
        "name": "Multiagent Framework",
        "email": "noreply@multiagent.dev"
    },
    "license": "MIT",
    "keywords": ["{subsystem}", "multiagent", "automation"],
    "components": {
        "commands": 0,
        "agents": 0,
        "skills": 1
    }
}

MCP_JSON_TEMPLATE = {
    "mcpServers": {},
    "notes": "MCP server configurations for this plugin. Add servers as needed."
}

HOOKS_JSON_TEMPLATE = {
    "hooks": {},
    "notes": "Event hooks for this plugin. Configure hook triggers and scripts as needed."
}

SKILL_MD_TEMPLATE = """---
name: {skill_display_name}
description: {skill_description}
allowed-tools: Read, Write, Bash
---

# {skill_display_name}

## Instructions

TODO: Add detailed instructions for this skill.

### Features

1. Feature 1
2. Feature 2
3. Feature 3

### Trigger Patterns

This skill is automatically invoked when:
- Pattern 1
- Pattern 2
- Pattern 3

## Examples

### Example 1: Basic Usage

TODO: Add example showing basic usage

```bash
# Example command or code
```

### Example 2: Advanced Usage

TODO: Add example showing advanced features

```bash
# Example command or code
```
"""

REFERENCE_MD_TEMPLATE = """# {skill_display_name} - Reference

## API Reference

### Trigger Patterns

- Pattern 1: Description
- Pattern 2: Description
- Pattern 3: Description

### Input Requirements

- Input 1: Description and format
- Input 2: Description and format

### Output Format

- Output 1: Description
- Output 2: Description

## Configuration

### Environment Variables

```bash
# VARIABLE_NAME=value  # Description
```

### Settings

TODO: Document configurable settings

## Advanced Usage

### Performance Considerations

TODO: Add performance notes

## Troubleshooting

### Issue 1
**Problem:** Description
**Solution:** How to fix
"""

EXAMPLES_MD_TEMPLATE = """# {skill_display_name} - Examples

## Example 1: Basic Use Case

TODO: Add first example

```bash
# Example code
```

**Expected Output:**
```
Expected result
```

## Example 2: Advanced Use Case

TODO: Add second example

```bash
# Example code
```

**Expected Output:**
```
Expected result
```

## Example 3: Real-World Scenario

TODO: Add real-world example

```bash
# Example code
```

**Expected Output:**
```
Expected result
```
"""

README_TEMPLATE = """# {plugin_name}

{description}

## Installation

```bash
/plugin install {plugin_name}@multiagent-dev
```

## Components

- **Commands**: 0 slash commands
- **Agents**: 0 specialized agents
- **Skills**: 1 skill

## Skills

### {skill_display_name}

{skill_description}

See `skills/{skill_slug}/SKILL.md` for details.

## Development

This plugin follows the multiagent enterprise plugin structure.

### Directory Layout

```
{plugin_name}/
├── .claude-plugin/
│   └── plugin.json
├── .mcp.json
├── hooks/
│   └── hooks.json
├── LICENSE
├── CHANGELOG.md
├── README.md
├── commands/          # Slash commands
├── agents/            # Specialized agents
└── skills/            # Auto-discovered skills
    └── {skill_slug}/
        ├── SKILL.md
        ├── reference.md
        ├── examples.md
        ├── scripts/
        └── templates/
```

## License

MIT License - see LICENSE file for details
"""


def create_plugin_structure(plugin_name: str, skill_name: str = None):
    """Create complete enterprise plugin structure."""

    # Extract subsystem name
    subsystem = plugin_name.replace("multiagent-", "")

    # Default skill name if not provided
    if not skill_name:
        skill_name = f"{subsystem}-assistant"

    skill_slug = skill_name.lower().replace(" ", "-")
    skill_display_name = skill_name.replace("-", " ").title()

    plugin_dir = MARKETPLACE_DIR / plugin_name

    if plugin_dir.exists():
        print(f"❌ Plugin directory already exists: {plugin_dir}")
        print(f"   Please remove it first or choose a different name.")
        return False

    print("=" * 70)
    print(f"Creating Plugin: {plugin_name}")
    print("=" * 70)
    print(f"Skill: {skill_display_name} ({skill_slug})")
    print(f"Location: {plugin_dir}\n")

    # Create directory structure
    print("Creating directory structure...")

    dirs_to_create = [
        plugin_dir / ".claude-plugin",
        plugin_dir / "hooks",
        plugin_dir / "commands",
        plugin_dir / "agents",
        plugin_dir / "skills" / skill_slug / "scripts",
        plugin_dir / "skills" / skill_slug / "templates",
    ]

    for dir_path in dirs_to_create:
        dir_path.mkdir(parents=True, exist_ok=True)
        print(f"  ✓ Created: {dir_path.relative_to(plugin_dir)}/")

    # Create plugin.json
    print("\nCreating plugin.json...")
    plugin_json = PLUGIN_JSON_TEMPLATE.copy()
    plugin_json["name"] = plugin_name
    plugin_json["description"] = f"{subsystem.title()} functionality for multiagent framework"
    plugin_json["keywords"] = [subsystem, "multiagent", "automation"]

    plugin_json_path = plugin_dir / ".claude-plugin" / "plugin.json"
    with open(plugin_json_path, 'w') as f:
        json.dump(plugin_json, f, indent=2)
    print(f"  ✓ Created: .claude-plugin/plugin.json")

    # Create .mcp.json
    print("\nCreating .mcp.json...")
    mcp_json_path = plugin_dir / ".mcp.json"
    with open(mcp_json_path, 'w') as f:
        json.dump(MCP_JSON_TEMPLATE, f, indent=2)
    print(f"  ✓ Created: .mcp.json")

    # Create hooks.json
    print("\nCreating hooks/hooks.json...")
    hooks_json_path = plugin_dir / "hooks" / "hooks.json"
    with open(hooks_json_path, 'w') as f:
        json.dump(HOOKS_JSON_TEMPLATE, f, indent=2)
    print(f"  ✓ Created: hooks/hooks.json")

    # Create LICENSE
    print("\nCreating LICENSE...")
    license_path = plugin_dir / "LICENSE"
    license_content = LICENSE_TEMPLATE.format(year=datetime.now().year)
    license_path.write_text(license_content)
    print(f"  ✓ Created: LICENSE")

    # Create CHANGELOG.md
    print("\nCreating CHANGELOG.md...")
    changelog_path = plugin_dir / "CHANGELOG.md"
    changelog_content = CHANGELOG_TEMPLATE.format(
        date=datetime.now().strftime("%Y-%m-%d"),
        skill_name=skill_display_name
    )
    changelog_path.write_text(changelog_content)
    print(f"  ✓ Created: CHANGELOG.md")

    # Create README.md
    print("\nCreating README.md...")
    readme_path = plugin_dir / "README.md"
    readme_content = README_TEMPLATE.format(
        plugin_name=plugin_name,
        description=f"{subsystem.title()} functionality for multiagent framework",
        skill_display_name=skill_display_name,
        skill_description=f"Provides {subsystem} capabilities",
        skill_slug=skill_slug
    )
    readme_path.write_text(readme_content)
    print(f"  ✓ Created: README.md")

    # Create skill files
    skill_dir = plugin_dir / "skills" / skill_slug

    print(f"\nCreating skill documentation for '{skill_display_name}'...")

    # SKILL.md
    skill_md_path = skill_dir / "SKILL.md"
    skill_md_content = SKILL_MD_TEMPLATE.format(
        skill_display_name=skill_display_name,
        skill_description=f"Provides {subsystem} capabilities for the multiagent framework"
    )
    skill_md_path.write_text(skill_md_content)
    print(f"  ✓ Created: skills/{skill_slug}/SKILL.md")

    # reference.md
    reference_md_path = skill_dir / "reference.md"
    reference_content = REFERENCE_MD_TEMPLATE.format(
        skill_display_name=skill_display_name
    )
    reference_md_path.write_text(reference_content)
    print(f"  ✓ Created: skills/{skill_slug}/reference.md")

    # examples.md
    examples_md_path = skill_dir / "examples.md"
    examples_content = EXAMPLES_MD_TEMPLATE.format(
        skill_display_name=skill_display_name
    )
    examples_md_path.write_text(examples_content)
    print(f"  ✓ Created: skills/{skill_slug}/examples.md")

    # Create .gitkeep files
    (skill_dir / "scripts" / ".gitkeep").touch()
    (skill_dir / "templates" / ".gitkeep").touch()
    (plugin_dir / "commands" / ".gitkeep").touch()
    (plugin_dir / "agents" / ".gitkeep").touch()

    print("\n" + "=" * 70)
    print("SUCCESS: Plugin Structure Created!")
    print("=" * 70)

    print(f"\nLocation: {plugin_dir}")
    print(f"\nNext Steps:")
    print(f"   1. Edit skills/{skill_slug}/SKILL.md with actual skill instructions")
    print(f"   2. Add commands to commands/ directory")
    print(f"   3. Add agents to agents/ directory")
    print(f"   4. Add scripts to skills/{skill_slug}/scripts/")
    print(f"   5. Add templates to skills/{skill_slug}/templates/")
    print(f"   6. Update README.md with actual documentation")
    print(f"   7. Test with: /plugin install {plugin_name}@multiagent-dev")
    print()

    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python create-plugin-structure.py <plugin-name> [--skill <skill-name>]")
        print("\nExamples:")
        print("  python create-plugin-structure.py multiagent-analytics")
        print("  python create-plugin-structure.py multiagent-testing --skill test-runner")
        sys.exit(1)

    plugin_name = sys.argv[1]
    skill_name = None

    # Parse optional --skill argument
    if "--skill" in sys.argv:
        skill_idx = sys.argv.index("--skill")
        if skill_idx + 1 < len(sys.argv):
            skill_name = sys.argv[skill_idx + 1]

    success = create_plugin_structure(plugin_name, skill_name)
    sys.exit(0 if success else 1)
