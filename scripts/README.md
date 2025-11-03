# AI Dev Marketplace Scripts

This directory contains utility scripts for maintaining and managing the AI Dev Marketplace plugins.

## Available Scripts

### add-skill-tool.sh
Adds the `Skill` tool to all agents and commands that are missing it.

**What it does:**
- Adds `Skill` to the `tools:` field in agent markdown files
- Adds `Skill` to the `allowed-tools:` field in command markdown files
- Skips files that already have the Skill tool

**Usage:**
```bash
bash scripts/add-skill-tool.sh
# or from anywhere:
bash /path/to/add-skill-tool.sh
```

### add-skill-instructions.sh
Adds comprehensive skill availability documentation to all agents and commands.

**What it does:**
- Creates an "Available Skills" section in each component
- Lists all skills from that plugin with descriptions
- Shows how to invoke skills: `!{skill skill-name}`
- Provides guidance on when to use skills
- Pulls descriptions from each skill's SKILL.md file

**Usage:**
```bash
bash scripts/add-skill-instructions.sh
# or from anywhere:
bash /path/to/add-skill-instructions.sh
```

### fix-skill-newlines.sh
Fixes literal `\n` characters in skill descriptions, replacing them with actual newlines.

**What it does:**
- Finds all files with "Available Skills" sections
- Replaces literal `\n` text with actual line breaks
- Makes skill lists readable with each skill on its own line
- Only affects the skill description section

**Usage:**
```bash
bash scripts/fix-skill-newlines.sh
# or from anywhere:
bash /path/to/fix-skill-newlines.sh
```

## Universal Script Execution

All scripts are **universal** - they can be run from any directory and will automatically find the marketplace root.

**The scripts work by:**
1. Checking if you're already in the marketplace root directory
2. Checking if the script is in the `scripts/` subdirectory
3. Searching upwards through parent directories for the marketplace root
4. Validating by checking for `.claude-plugin/marketplace.json`

**You can run them from:**
- Marketplace root: `bash scripts/script.sh`
- Scripts directory: `bash script.sh`
- Any subdirectory: `bash ../../scripts/script.sh`
- Absolute path: `bash /full/path/to/script.sh`

**Output:**
Each script displays the working directory:
```
📍 Working in: /home/user/.claude/plugins/marketplaces/ai-dev-marketplace
```

## Workflow

Typical workflow when creating new plugins or updating existing ones:

1. **Add Skill Tool Access:**
   ```bash
   bash scripts/add-skill-tool.sh
   ```

2. **Add Skill Documentation:**
   ```bash
   bash scripts/add-skill-instructions.sh
   ```

3. **Fix Formatting (if needed):**
   ```bash
   bash scripts/fix-skill-newlines.sh
   ```

4. **Review and Commit:**
   ```bash
   git diff
   git add -A
   git commit -m "feat: Add skills to new plugin"
   git push
   ```

## Safety Features

All scripts:
- Use `set -e` to exit on errors
- Check for existing content before modifying
- Provide clear error messages if marketplace root not found
- Show summary of changes made
- Are idempotent - safe to run multiple times

## Maintenance

When creating new similar scripts:
1. Copy the `find_marketplace_root()` function from any existing script
2. Use `$MARKETPLACE_DIR` as the base directory
3. Make script executable: `chmod +x script.sh`
4. Add documentation to this README

## Notes

- Scripts use `sed` for simple replacements and `perl` for complex regex
- All scripts skip files that already have the desired content
- Summary output shows how many files were updated vs skipped
- Scripts are designed to be safe to run on the entire marketplace
