"""
Pytest configuration for CATS MCP Server tests
"""

import sys
from pathlib import Path

# Add project root to sys.path so tests can import server module
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
