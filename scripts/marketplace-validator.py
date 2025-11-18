#!/usr/bin/env python3
"""
AI Dev Marketplace Validator
Validates and syncs all components in ai-dev-marketplace

This is the SINGLE source of truth for validation/sync in this marketplace.
All commands should call THIS script, not generic ones.

Usage:
    python marketplace-validator.py --validate    # Just validate
    python marketplace-validator.py --fix         # Fix + sync to Airtable
"""

import os
import sys
import subprocess
import argparse

# Marketplace configuration
MARKETPLACE_NAME = "ai-dev-marketplace"
MARKETPLACE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# External tools (reuse existing infrastructure)
SYNC_VALIDATOR = os.path.expanduser(
    "~/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/scripts/sync-validator.py"
)
REGISTER_COMMANDS = os.path.expanduser(
    "~/.claude/plugins/marketplaces/dev-lifecycle-marketplace/scripts/register-all-commands.sh"
)
REGISTER_SKILLS = os.path.expanduser(
    "~/.claude/plugins/marketplaces/domain-plugin-builder/plugins/domain-plugin-builder/skills/build-assistant/scripts/register-skills-in-settings.sh"
)


def validate_only():
    """Run validation checks without fixing"""
    print("=" * 80)
    print(f"🔍 Validating {MARKETPLACE_NAME}")
    print("=" * 80)
    print()

    # Run bash validator for reporting
    bash_validator = os.path.join(MARKETPLACE_ROOT, "scripts", "validate-marketplace-sync.sh")
    if os.path.exists(bash_validator):
        subprocess.run(["bash", bash_validator])
    else:
        print(f"❌ Bash validator not found: {bash_validator}")
        return 1

    return 0


def fix_and_sync():
    """Fix registration and sync to Airtable"""
    print("=" * 80)
    print(f"🔧 Fixing {MARKETPLACE_NAME}")
    print("=" * 80)
    print()

    # 1. Register commands
    print("📋 Registering all commands...")
    if os.path.exists(REGISTER_COMMANDS):
        subprocess.run(["bash", REGISTER_COMMANDS])
    else:
        print(f"⚠️  Command registration script not found")

    print()

    # 2. Register skills
    print("🎯 Registering all skills...")
    if os.path.exists(REGISTER_SKILLS):
        subprocess.run(["bash", REGISTER_SKILLS])
    else:
        print(f"⚠️  Skill registration script not found")

    print()

    # 3. Sync to Airtable
    print("💾 Syncing to Airtable...")
    if not os.path.exists(SYNC_VALIDATOR):
        print(f"❌ Sync validator not found: {SYNC_VALIDATOR}")
        return 1

    airtable_token = os.getenv("AIRTABLE_TOKEN") or os.getenv("MCP_AIRTABLE_TOKEN")
    if not airtable_token:
        print("⚠️  AIRTABLE_TOKEN not set, skipping Airtable sync")
        return 0

    result = subprocess.run([
        "python", SYNC_VALIDATOR,
        f"--marketplace={MARKETPLACE_NAME}",
        "--auto-sync"
    ])

    return result.returncode


def main():
    parser = argparse.ArgumentParser(
        description=f"Validate and sync {MARKETPLACE_NAME}"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Only validate, don't fix"
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Fix registration and sync to Airtable"
    )

    args = parser.parse_args()

    if args.fix:
        return fix_and_sync()
    elif args.validate:
        return validate_only()
    else:
        print("❌ Must specify --validate or --fix")
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
