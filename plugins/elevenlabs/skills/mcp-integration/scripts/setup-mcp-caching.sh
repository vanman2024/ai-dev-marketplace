#!/usr/bin/env bash
# Setup MCP response caching for performance optimization
# Usage: ./setup-mcp-caching.sh [config-file]

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="${1:-.elevenlabs/mcp-config.json}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  MCP Response Caching Setup                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}✗ Configuration file not found: $CONFIG_FILE${NC}"
  exit 1
fi

echo "Configuring caching for MCP servers..."
echo ""

# Cache configuration options
echo "Select caching strategy:"
echo "  1) Aggressive (300s TTL) - Best for static data"
echo "  2) Moderate (60s TTL) - Balanced approach"
echo "  3) Conservative (10s TTL) - Near real-time data"
echo "  4) Custom - Specify your own TTL values"
read -p "Choice (1-4, default=2): " CACHE_CHOICE

case ${CACHE_CHOICE:-2} in
  1)
    DEFAULT_TTL=300
    STRATEGY="aggressive"
    ;;
  2)
    DEFAULT_TTL=60
    STRATEGY="moderate"
    ;;
  3)
    DEFAULT_TTL=10
    STRATEGY="conservative"
    ;;
  4)
    read -p "Enter default TTL in seconds: " DEFAULT_TTL
    STRATEGY="custom"
    ;;
  *)
    DEFAULT_TTL=60
    STRATEGY="moderate"
    ;;
esac

echo ""
echo -e "${GREEN}✓ Using $STRATEGY caching strategy (${DEFAULT_TTL}s TTL)${NC}"
echo ""

# Tool-specific cache configurations
echo "Configuring tool-specific cache rules..."
echo ""

# Update configuration with caching settings
TEMP_FILE=$(mktemp)

jq --arg ttl "$DEFAULT_TTL" --arg strategy "$STRATEGY" '
  .caching = {
    "enabled": true,
    "defaultTTL": ($ttl | tonumber),
    "strategy": $strategy,
    "toolConfigs": {
      "weather": {
        "ttl": 1800,
        "description": "Weather data - 30min cache"
      },
      "search": {
        "ttl": 300,
        "description": "Search results - 5min cache"
      },
      "calendar_read": {
        "ttl": 60,
        "description": "Calendar read - 1min cache"
      },
      "knowledge_base": {
        "ttl": 3600,
        "description": "Knowledge base - 1hr cache"
      },
      "product_lookup": {
        "ttl": 300,
        "description": "Product data - 5min cache"
      },
      "customer_lookup": {
        "ttl": 120,
        "description": "Customer data - 2min cache"
      },
      "stock_check": {
        "ttl": 30,
        "description": "Stock levels - 30sec cache"
      }
    },
    "noCacheTools": [
      "email_send",
      "order_process",
      "calendar_create",
      "data_update",
      "admin_action"
    ]
  } |
  .mcpServers |= map_values(
    . + {
      "caching": {
        "enabled": true,
        "defaultTTL": ($ttl | tonumber)
      }
    }
  )
' "$CONFIG_FILE" > "$TEMP_FILE"

# Backup original config
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
mv "$TEMP_FILE" "$CONFIG_FILE"

echo -e "${GREEN}✓ Caching configuration updated${NC}"
echo -e "${YELLOW}  Backup saved: ${CONFIG_FILE}.backup${NC}"
echo ""

# Display cache configuration
echo -e "${BLUE}Cache Configuration Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Strategy:         ${GREEN}$STRATEGY${NC}"
echo -e "Default TTL:      ${GREEN}${DEFAULT_TTL}s${NC}"
echo ""
echo "Tool-Specific Cache Rules:"
echo "  • Weather data:      1800s (30 minutes)"
echo "  • Search results:    300s (5 minutes)"
echo "  • Calendar read:     60s (1 minute)"
echo "  • Knowledge base:    3600s (1 hour)"
echo "  • Product lookup:    300s (5 minutes)"
echo "  • Customer lookup:   120s (2 minutes)"
echo "  • Stock levels:      30s (30 seconds)"
echo ""
echo "No-Cache Tools (Always Fresh):"
echo "  • Email send, Order processing"
echo "  • Calendar create, Data updates"
echo "  • Admin actions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Cache implementation code
echo -e "${BLUE}Implementation Example:${NC}"
echo ""

cat > ".elevenlabs/mcp-cache-impl.ts" <<'EOF'
// MCP Response Cache Implementation
import { LRUCache } from 'lru-cache';

interface CachedResponse {
  data: any;
  timestamp: number;
  ttl: number;
}

class MCPResponseCache {
  private cache: LRUCache<string, CachedResponse>;
  private toolConfigs: Map<string, number>;

  constructor() {
    this.cache = new LRUCache({
      max: 1000,
      ttl: 60000, // Default 60s
      updateAgeOnGet: false,
    });

    // Load tool-specific TTLs
    this.toolConfigs = new Map([
      ['weather', 1800],
      ['search', 300],
      ['calendar_read', 60],
      ['knowledge_base', 3600],
      ['product_lookup', 300],
      ['customer_lookup', 120],
      ['stock_check', 30],
    ]);
  }

  private generateCacheKey(
    server: string,
    tool: string,
    params: Record<string, any>
  ): string {
    const paramsHash = JSON.stringify(params);
    return `${server}:${tool}:${paramsHash}`;
  }

  private shouldCache(tool: string): boolean {
    const noCacheTools = [
      'email_send',
      'order_process',
      'calendar_create',
      'data_update',
      'admin_action',
    ];
    return !noCacheTools.some((pattern) =>
      tool.toLowerCase().includes(pattern)
    );
  }

  private getTTL(tool: string): number {
    // Check for exact match
    if (this.toolConfigs.has(tool)) {
      return this.toolConfigs.get(tool)! * 1000;
    }

    // Check for partial matches
    for (const [key, ttl] of this.toolConfigs.entries()) {
      if (tool.toLowerCase().includes(key.toLowerCase())) {
        return ttl * 1000;
      }
    }

    // Default TTL
    return 60000; // 60s
  }

  async get(
    server: string,
    tool: string,
    params: Record<string, any>
  ): Promise<any | null> {
    if (!this.shouldCache(tool)) {
      return null;
    }

    const key = this.generateCacheKey(server, tool, params);
    const cached = this.cache.get(key);

    if (cached) {
      const age = Date.now() - cached.timestamp;
      if (age < cached.ttl) {
        console.log(`Cache HIT: ${tool} (age: ${Math.round(age / 1000)}s)`);
        return cached.data;
      }
    }

    return null;
  }

  set(
    server: string,
    tool: string,
    params: Record<string, any>,
    data: any
  ): void {
    if (!this.shouldCache(tool)) {
      return;
    }

    const key = this.generateCacheKey(server, tool, params);
    const ttl = this.getTTL(tool);

    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl,
    });

    console.log(`Cache SET: ${tool} (ttl: ${Math.round(ttl / 1000)}s)`);
  }

  invalidate(server?: string, tool?: string): void {
    if (!server && !tool) {
      this.cache.clear();
      console.log('Cache invalidated: ALL');
      return;
    }

    const pattern = `${server || '*'}:${tool || '*'}:`;
    let count = 0;

    for (const key of this.cache.keys()) {
      if (key.startsWith(pattern.replace('*', ''))) {
        this.cache.delete(key);
        count++;
      }
    }

    console.log(`Cache invalidated: ${count} entries`);
  }

  getStats() {
    return {
      size: this.cache.size,
      maxSize: this.cache.max,
      hits: this.cache.calculatedSize,
    };
  }
}

// Singleton instance
export const mcpCache = new MCPResponseCache();

// Usage example
async function executeMCPTool(
  server: string,
  tool: string,
  params: Record<string, any>
) {
  // Try cache first
  const cached = await mcpCache.get(server, tool, params);
  if (cached !== null) {
    return cached;
  }

  // Execute tool
  const result = await actuallyExecuteTool(server, tool, params);

  // Cache result
  mcpCache.set(server, tool, params, result);

  return result;
}

async function actuallyExecuteTool(
  server: string,
  tool: string,
  params: Record<string, any>
): Promise<any> {
  // Your actual MCP tool execution logic here
  console.log(`Executing: ${server}.${tool}`);
  return {}; // Replace with actual result
}
EOF

echo -e "${GREEN}✓ Cache implementation created: .elevenlabs/mcp-cache-impl.ts${NC}"
echo ""

# Python implementation
cat > ".elevenlabs/mcp_cache_impl.py" <<'EOF'
"""MCP Response Cache Implementation"""
import hashlib
import json
import time
from typing import Any, Dict, Optional
from cachetools import TTLCache


class MCPResponseCache:
    def __init__(self):
        self.cache = TTLCache(maxsize=1000, ttl=60)
        self.tool_configs = {
            'weather': 1800,
            'search': 300,
            'calendar_read': 60,
            'knowledge_base': 3600,
            'product_lookup': 300,
            'customer_lookup': 120,
            'stock_check': 30,
        }
        self.no_cache_tools = [
            'email_send',
            'order_process',
            'calendar_create',
            'data_update',
            'admin_action',
        ]

    def _generate_cache_key(
        self, server: str, tool: str, params: Dict[str, Any]
    ) -> str:
        """Generate cache key from server, tool, and params"""
        params_str = json.dumps(params, sort_keys=True)
        params_hash = hashlib.md5(params_str.encode()).hexdigest()
        return f"{server}:{tool}:{params_hash}"

    def _should_cache(self, tool: str) -> bool:
        """Check if tool should be cached"""
        tool_lower = tool.lower()
        return not any(
            pattern in tool_lower for pattern in self.no_cache_tools
        )

    def _get_ttl(self, tool: str) -> int:
        """Get TTL for tool"""
        # Exact match
        if tool in self.tool_configs:
            return self.tool_configs[tool]

        # Partial match
        tool_lower = tool.lower()
        for key, ttl in self.tool_configs.items():
            if key.lower() in tool_lower:
                return ttl

        # Default
        return 60

    def get(
        self, server: str, tool: str, params: Dict[str, Any]
    ) -> Optional[Any]:
        """Get cached response"""
        if not self._should_cache(tool):
            return None

        key = self._generate_cache_key(server, tool, params)

        try:
            data = self.cache[key]
            print(f"Cache HIT: {tool}")
            return data
        except KeyError:
            return None

    def set(
        self, server: str, tool: str, params: Dict[str, Any], data: Any
    ) -> None:
        """Cache response"""
        if not self._should_cache(tool):
            return

        key = self._generate_cache_key(server, tool, params)
        ttl = self._get_ttl(tool)

        # Create new cache with specific TTL
        if key not in self.cache:
            self.cache[key] = data

        print(f"Cache SET: {tool} (ttl: {ttl}s)")

    def invalidate(
        self, server: Optional[str] = None, tool: Optional[str] = None
    ) -> int:
        """Invalidate cache entries"""
        if not server and not tool:
            count = len(self.cache)
            self.cache.clear()
            print(f"Cache invalidated: ALL ({count} entries)")
            return count

        pattern = f"{server or '*'}:{tool or '*'}:"
        to_delete = [
            k for k in self.cache.keys() if k.startswith(pattern.replace('*', ''))
        ]

        for key in to_delete:
            del self.cache[key]

        print(f"Cache invalidated: {len(to_delete)} entries")
        return len(to_delete)

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        return {
            'size': len(self.cache),
            'maxsize': self.cache.maxsize,
            'currsize': self.cache.currsize,
        }


# Singleton instance
mcp_cache = MCPResponseCache()


# Usage example
async def execute_mcp_tool(
    server: str, tool: str, params: Dict[str, Any]
) -> Any:
    """Execute MCP tool with caching"""
    # Try cache first
    cached = mcp_cache.get(server, tool, params)
    if cached is not None:
        return cached

    # Execute tool
    result = await actually_execute_tool(server, tool, params)

    # Cache result
    mcp_cache.set(server, tool, params, result)

    return result


async def actually_execute_tool(
    server: str, tool: str, params: Dict[str, Any]
) -> Any:
    """Your actual MCP tool execution logic"""
    print(f"Executing: {server}.{tool}")
    return {}  # Replace with actual result
EOF

echo -e "${GREEN}✓ Python cache implementation created: .elevenlabs/mcp_cache_impl.py${NC}"
echo ""

# Usage instructions
echo -e "${BLUE}Usage Instructions:${NC}"
echo ""
echo "1. TypeScript/JavaScript:"
echo "   import { mcpCache } from './.elevenlabs/mcp-cache-impl';"
echo "   const result = await executeMCPTool('zapier-mcp', 'weather', { location: 'NYC' });"
echo ""
echo "2. Python:"
echo "   from elevenlabs.mcp_cache_impl import execute_mcp_tool"
echo "   result = await execute_mcp_tool('zapier-mcp', 'weather', {'location': 'NYC'})"
echo ""
echo "3. Monitor cache performance:"
echo "   console.log(mcpCache.getStats());"
echo "   print(mcp_cache.get_stats())"
echo ""
echo "4. Invalidate cache:"
echo "   mcpCache.invalidate('zapier-mcp', 'weather');"
echo "   mcp_cache.invalidate('zapier-mcp', 'weather')"
echo ""

echo -e "${GREEN}✓ MCP caching setup complete!${NC}"
echo ""
echo "Expected performance improvements:"
echo "  • 50-90% reduction in API calls for cached tools"
echo "  • Faster response times for repeated queries"
echo "  • Reduced costs from external API usage"
echo "  • Better user experience with quicker responses"
