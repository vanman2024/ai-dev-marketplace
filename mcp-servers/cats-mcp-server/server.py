"""
CATS MCP Server - FastMCP server for CATS API v3

Supports toolset-based loading for 162 endpoints across 17 toolsets.
Use --toolsets flag or CATS_TOOLSETS env var to control which tools load.
"""

import os
import argparse
from typing import Any, Optional, Set
import httpx
from dotenv import load_dotenv
from fastmcp import FastMCP

load_dotenv()

mcp = FastMCP("CATS API v3")

# Configuration
CATS_API_BASE_URL = os.getenv("CATS_API_BASE_URL", "https://api.catsone.com/v3")
CATS_API_KEY = os.getenv("CATS_API_KEY", "")

# Toolset definitions
DEFAULT_TOOLSETS = ['candidates', 'jobs', 'pipelines', 'context', 'tasks']
ALL_TOOLSETS = DEFAULT_TOOLSETS + [
    'companies', 'contacts', 'activities', 'portals', 'work_history',
    'tags', 'webhooks', 'users', 'triggers', 'attachments', 'backups', 'events'
]


class CATSAPIError(Exception):
    """CATS API error"""
    pass


async def make_request(
    method: str,
    endpoint: str,
    params: dict = None,
    json_data: dict = None
) -> dict:
    """Make authenticated request to CATS API"""
    if not CATS_API_KEY:
        raise CATSAPIError("CATS_API_KEY not configured")

    url = f"{CATS_API_BASE_URL.rstrip('/')}/{endpoint.lstrip('/')}"
    headers = {
        "Authorization": f"Token {CATS_API_KEY}",
        "Content-Type": "application/json",
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.request(
                method,
                url,
                headers=headers,
                params=params,
                json=json_data
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise CATSAPIError(f"API error: {e}")


def load_toolsets(toolsets: Set[str]):
    """Load specified toolsets"""
    from toolsets_default import (
        register_candidates_tools,
        register_jobs_tools,
        register_pipelines_tools,
        register_context_tools,
        register_tasks_tools
    )
    from toolsets_recruiting import (
        register_companies_tools,
        register_contacts_tools,
        register_activities_tools,
        register_portals_tools,
        register_work_history_tools
    )
    from toolsets_data import (
        register_tags_tools,
        register_webhooks_tools,
        register_users_tools,
        register_triggers_tools,
        register_attachments_tools,
        register_backups_tools,
        register_events_tools
    )

    print(f"Loading toolsets: {', '.join(sorted(toolsets))}")

    # DEFAULT TOOLSETS (89 tools)
    if 'candidates' in toolsets or 'all' in toolsets:
        register_candidates_tools()
        print("  ✓ candidates (28 tools)")

    if 'jobs' in toolsets or 'all' in toolsets:
        register_jobs_tools()
        print("  ✓ jobs (40 tools)")

    if 'pipelines' in toolsets or 'all' in toolsets:
        register_pipelines_tools()
        print("  ✓ pipelines (13 tools)")

    if 'context' in toolsets or 'all' in toolsets:
        register_context_tools()
        print("  ✓ context (3 tools)")

    if 'tasks' in toolsets or 'all' in toolsets:
        register_tasks_tools()
        print("  ✓ tasks (5 tools)")

    # RECRUITING TOOLSETS (52 tools)
    if 'companies' in toolsets or 'all' in toolsets:
        register_companies_tools()
        print("  ✓ companies (18 tools)")

    if 'contacts' in toolsets or 'all' in toolsets:
        register_contacts_tools()
        print("  ✓ contacts (18 tools)")

    if 'activities' in toolsets or 'all' in toolsets:
        register_activities_tools()
        print("  ✓ activities (6 tools)")

    if 'portals' in toolsets or 'all' in toolsets:
        register_portals_tools()
        print("  ✓ portals (8 tools)")

    if 'work_history' in toolsets or 'all' in toolsets:
        register_work_history_tools()
        print("  ✓ work_history (3 tools)")

    # DATA & CONFIG TOOLSETS (21 tools)
    if 'tags' in toolsets or 'all' in toolsets:
        register_tags_tools()
        print("  ✓ tags (2 tools)")

    if 'webhooks' in toolsets or 'all' in toolsets:
        register_webhooks_tools()
        print("  ✓ webhooks (4 tools)")

    if 'users' in toolsets or 'all' in toolsets:
        register_users_tools()
        print("  ✓ users (2 tools)")

    if 'triggers' in toolsets or 'all' in toolsets:
        register_triggers_tools()
        print("  ✓ triggers (2 tools)")

    if 'attachments' in toolsets or 'all' in toolsets:
        register_attachments_tools()
        print("  ✓ attachments (4 tools)")

    if 'backups' in toolsets or 'all' in toolsets:
        register_backups_tools()
        print("  ✓ backups (3 tools)")

    if 'events' in toolsets or 'all' in toolsets:
        register_events_tools()
        print("  ✓ events (5 tools)")

    # Calculate and display total
    loaded_count = len(toolsets) if 'all' not in toolsets else len(ALL_TOOLSETS)
    print(f"\nTotal toolsets loaded: {loaded_count}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CATS API v3 MCP Server")
    parser.add_argument(
        "--toolsets",
        type=str,
        default=None,
        help="Comma-separated list of toolsets to load (default: core set)"
    )
    parser.add_argument(
        "--list-toolsets",
        action="store_true",
        help="List available toolsets and exit"
    )

    args = parser.parse_args()

    if args.list_toolsets:
        print("CATS API v3 MCP Server - Available Toolsets\n")
        print("DEFAULT toolsets (loaded by default, 89 tools):")
        print("  - candidates (28 tools) - Core recruiting")
        print("  - jobs (40 tools) - Job management")
        print("  - pipelines (13 tools) - Workflow management")
        print("  - context (3 tools) - Site/user info")
        print("  - tasks (5 tools) - Task management")
        print("\nRECRUITING toolsets (52 tools):")
        print("  - companies (18 tools)")
        print("  - contacts (18 tools)")
        print("  - activities (6 tools)")
        print("  - portals (8 tools)")
        print("  - work_history (3 tools)")
        print("\nDATA & CONFIG toolsets (21 tools):")
        print("  - tags (2 tools)")
        print("  - webhooks (4 tools)")
        print("  - users (2 tools)")
        print("  - triggers (2 tools)")
        print("  - attachments (4 tools)")
        print("  - backups (3 tools)")
        print("  - events (5 tools)")
        print("\nUsage:")
        print("  python server.py                                    # Default toolsets")
        print("  python server.py --toolsets candidates,jobs          # Specific toolsets")
        print("  python server.py --toolsets all                      # All 162 tools")
        print("  export CATS_TOOLSETS='candidates,companies' && python server.py")
        exit(0)

    # Determine which toolsets to load
    if args.toolsets:
        requested = {t.strip() for t in args.toolsets.split(',')}
    else:
        env_toolsets = os.getenv('CATS_TOOLSETS', '')
        if env_toolsets:
            requested = {t.strip() for t in env_toolsets.split(',')}
        else:
            requested = set(DEFAULT_TOOLSETS)

    # Validate toolsets
    if 'all' not in requested:
        invalid_toolsets = requested - set(ALL_TOOLSETS)
        if invalid_toolsets:
            print(f"Error: Invalid toolsets specified: {', '.join(invalid_toolsets)}")
            print(f"Valid toolsets: {', '.join(ALL_TOOLSETS)}")
            print("Use --list-toolsets to see all available toolsets")
            exit(1)

    # Load toolsets
    load_toolsets(requested)

    # Determine transport mode
    transport = os.getenv('CATS_TRANSPORT', 'stdio').lower()

    print("\nStarting CATS MCP Server...")
    print(f"Transport: {transport.upper()}")
    print(f"API Base URL: {CATS_API_BASE_URL}")
    print(f"API Key configured: {'Yes' if CATS_API_KEY else 'No'}")

    if transport == 'stdio':
        # STDIO transport for Claude Desktop, Claude Code, Cursor
        # Configured via .mcp.json or IDE config files
        mcp.run()
    elif transport == 'http':
        # HTTP transport for remote services, web applications
        port = int(os.getenv('CATS_PORT', '8000'))
        host = os.getenv('CATS_HOST', '0.0.0.0')
        print(f"HTTP Server: http://{host}:{port}/mcp")
        mcp.run(transport="http", host=host, port=port)
    else:
        print(f"Error: Invalid transport '{transport}'. Use 'stdio' or 'http'")
        print("Set CATS_TRANSPORT environment variable to 'stdio' or 'http'")
        exit(1)
