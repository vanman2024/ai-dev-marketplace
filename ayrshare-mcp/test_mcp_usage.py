"""Direct test of MCP server tools."""
import asyncio
import sys
sys.path.insert(0, 'src')

async def test_list_platforms():
    """Test the list_platforms tool directly."""
    from server import list_platforms
    
    print("Testing MCP Tool: list_platforms")
    print("=" * 50)
    
    result = await list_platforms()
    
    print(f"\nResult:")
    print(f"  Status: {result.get('status')}")
    
    if result.get('status') == 'success':
        platforms = result.get('platforms', [])
        print(f"  Connected Platforms: {len(platforms)}")
        for p in platforms:
            print(f"    - {p['platform']}: {p.get('username', 'N/A')}")
    else:
        print(f"  Error: {result.get('message')}")

if __name__ == "__main__":
    asyncio.run(test_list_platforms())
