#!/usr/bin/env bash
set -euo pipefail

# Fix tool formatting across all plugins
# Converts ALL formats to horizontal comma-separated without quotes
# Removes incorrect MCP wildcards and brackets

# Portable: Use argument or current directory (works from any location)
MARKETPLACE_ROOT="${1:-$(pwd)}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Fixing Tool Formatting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

fix_all_tool_formats() {
    local file="$1"
    
    python3 - "$file" << 'PYTHON'
import sys
import re

file_path = sys.argv[1]

with open(file_path, 'r') as f:
    content = f.read()

original = content

# Fix 1: Convert JSON array format to comma-separated
# tools: ["Bash", "Read", "Write"] -> tools: Bash, Read, Write
pattern1 = r'(tools|allowed-tools):\s*\[(.*?)\]'
def fix_json_array(match):
    prefix = match.group(1)
    tools_str = match.group(2)
    # Extract tool names from quoted strings
    tools = re.findall(r'"([^"]+)"', tools_str)
    return f'{prefix}: {", ".join(tools)}'

content = re.sub(pattern1, fix_json_array, content, flags=re.DOTALL)

# Fix 2: Convert vertical lists to horizontal
# tools:\n  - Bash\n  - Read -> tools: Bash, Read
pattern2 = r'(tools|allowed-tools):\n((?:  - [^\n]+\n)+)'
def fix_vertical(match):
    prefix = match.group(1)
    tools_section = match.group(2)
    tools = re.findall(r'  - ([^\n]+)', tools_section)
    return f'{prefix}: {", ".join(tools)}\n'

content = re.sub(pattern2, fix_vertical, content)

# Fix 3: Remove (*) from all tools EXCEPT Bash with restrictions
# Task(*) -> Task, but keep Bash(git add:*)
content = re.sub(r'\b(Task|Read|Write|Edit|Grep|Glob|WebFetch|AskUserQuestion|TodoWrite|SlashCommand)\(\*\)', r'\1', content)

# Fix 4: Remove wildcards from MCP tools
# mcp__server__* -> mcp__server
# Task(mcp__*) -> mcp__servername (placeholder)
content = re.sub(r'mcp__([^_,)\s]+)__\*', r'mcp__\1', content)
content = re.sub(r'Task\(mcp__\*\)', r'mcp__servername', content)

# Fix 5: Remove brackets from mcp tools (except those with specific tool names)
# mcp__server(*) -> mcp__server
content = re.sub(r'(mcp__[a-z0-9_]+)\(\*\)', r'\1', content)

if content != original:
    with open(file_path, 'w') as f:
        f.write(content)
    print(f"✅ Fixed: {file_path}")
    return True
return False
PYTHON
}

# Process all agent files
echo ""
echo "📋 Fixing Agent Files..."
find "$MARKETPLACE_ROOT/plugins" -name "*.md" -path "*/agents/*" | while read -r file; do
    fix_all_tool_formats "$file"
done

# Process all command files  
echo ""
echo "📋 Fixing Command Files..."
find "$MARKETPLACE_ROOT/plugins" -name "*.md" -path "*/commands/*" | while read -r file; do
    fix_all_tool_formats "$file"
done

# Process template files
echo ""
echo "📋 Fixing Template Files..."
find "$MARKETPLACE_ROOT/plugins/domain-plugin-builder/skills/build-assistant/templates" -name "*.md" 2>/dev/null | while read -r file; do
    fix_all_tool_formats "$file"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Tool Formatting Fixed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
