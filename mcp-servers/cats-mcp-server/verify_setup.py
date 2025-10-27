#!/usr/bin/env python
"""
Verify CATS MCP Server setup

Run this script to check that everything is properly configured.
Usage: python verify_setup.py
"""

import sys
from pathlib import Path


def check_env_file():
    """Check if .env file exists"""
    env_path = Path(".env")
    if env_path.exists():
        print("✓ .env file exists")
        return True
    else:
        print("✗ .env file missing - copy from .env.example")
        return False


def check_dependencies():
    """Check if required dependencies are installed"""
    try:
        import fastmcp
        print(f"✓ FastMCP installed (version {fastmcp.__version__})")

        import httpx
        print(f"✓ httpx installed (version {httpx.__version__})")

        import pydantic
        print(f"✓ pydantic installed (version {pydantic.version.VERSION})")

        import dotenv
        print("✓ python-dotenv installed")

        return True
    except ImportError as e:
        print(f"✗ Missing dependency: {e}")
        return False


def check_server_imports():
    """Check if server.py can be imported"""
    try:
        import server
        print(f"✓ Server module imports successfully")
        print(f"  - Server name: {server.mcp.name}")
        return True
    except Exception as e:
        print(f"✗ Server import failed: {e}")
        return False


def check_configuration():
    """Check server configuration"""
    try:
        import server
        settings = server.get_server_settings.fn()

        print(f"✓ Server configuration:")
        print(f"  - Version: {settings['version']}")
        print(f"  - Transport: {settings['transport']}")
        print(f"  - API configured: {settings['api_configured']}")
        print(f"  - Tools: {', '.join(settings['tools'])}")

        return True
    except Exception as e:
        print(f"✗ Configuration check failed: {e}")
        return False


def main():
    """Run all verification checks"""
    print("CATS MCP Server Setup Verification")
    print("=" * 50)
    print()

    checks = [
        ("Environment File", check_env_file),
        ("Dependencies", check_dependencies),
        ("Server Imports", check_server_imports),
        ("Configuration", check_configuration),
    ]

    results = []
    for name, check_fn in checks:
        print(f"Checking {name}...")
        result = check_fn()
        results.append(result)
        print()

    print("=" * 50)
    if all(results):
        print("✓ All checks passed! Server is ready to run.")
        print()
        print("Next steps:")
        print("  1. Configure .env with your API keys")
        print("  2. Run: python server.py")
        print("  3. Or use: ./start.sh")
        return 0
    else:
        print("✗ Some checks failed. Please fix the issues above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
