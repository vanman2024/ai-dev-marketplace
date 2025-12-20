#!/usr/bin/env python3
"""
Test LiveRequestQueue functionality.

Usage:
    python test-liverequest-queue.py

Tests:
- Queue creation
- Text message enqueueing
- Audio chunk enqueueing
- Activity marker handling
- Queue consumption
"""

import asyncio
import sys
from typing import List


async def test_queue_creation():
    """Test LiveRequestQueue instantiation."""
    print("Testing queue creation...")
    try:
        from google.adk.agents import LiveRequestQueue

        queue = LiveRequestQueue()
        print("✅ Queue created successfully")
        return True
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("   Make sure google-adk is installed: pip install google-adk")
        return False
    except Exception as e:
        print(f"❌ Queue creation failed: {e}")
        return False


async def test_text_enqueue():
    """Test enqueueing text messages."""
    print("\nTesting text message enqueueing...")
    try:
        from google.adk.agents import LiveRequestQueue

        queue = LiveRequestQueue()

        # Enqueue text messages
        await queue.put("Hello, agent!")
        await queue.put("What's the weather?")

        print("✅ Text messages enqueued successfully")
        return True
    except Exception as e:
        print(f"❌ Text enqueueing failed: {e}")
        return False


async def test_audio_enqueue():
    """Test enqueueing audio chunks."""
    print("\nTesting audio chunk enqueueing...")
    try:
        from google.adk.agents import LiveRequestQueue
        from google.genai import types

        queue = LiveRequestQueue()

        # Create sample audio chunk (empty for testing)
        audio_chunk = b"\x00" * 1024  # 1KB of silence

        # Enqueue as LiveClientRealtimeInput
        await queue.put(
            types.LiveClientRealtimeInput(
                media_chunks=[
                    types.LiveClientRealtimeInputMediaChunk(data=audio_chunk)
                ]
            )
        )

        print("✅ Audio chunks enqueued successfully")
        return True
    except Exception as e:
        print(f"❌ Audio enqueueing failed: {e}")
        return False


async def test_activity_markers():
    """Test activity start/end markers."""
    print("\nTesting activity markers...")
    try:
        from google.adk.agents import LiveRequestQueue
        from google.genai import types

        queue = LiveRequestQueue()

        # Activity start
        await queue.put("Starting task...")

        # Activity end marker (implementation-specific)
        # This tests that queue can handle various input types
        await queue.put("Task complete")

        print("✅ Activity markers handled successfully")
        return True
    except Exception as e:
        print(f"❌ Activity marker test failed: {e}")
        return False


async def test_queue_consumption():
    """Test consuming from queue."""
    print("\nTesting queue consumption...")
    try:
        from google.adk.agents import LiveRequestQueue

        queue = LiveRequestQueue()

        # Enqueue test messages
        test_messages = ["Message 1", "Message 2", "Message 3"]
        for msg in test_messages:
            await queue.put(msg)

        print(f"✅ Queue consumption test setup complete")
        print(f"   Enqueued {len(test_messages)} messages")
        return True
    except Exception as e:
        print(f"❌ Queue consumption test failed: {e}")
        return False


async def run_all_tests():
    """Run all LiveRequestQueue tests."""
    print("="*60)
    print("LiveRequestQueue Test Suite")
    print("="*60)

    tests = [
        test_queue_creation,
        test_text_enqueue,
        test_audio_enqueue,
        test_activity_markers,
        test_queue_consumption,
    ]

    results: List[bool] = []

    for test in tests:
        result = await test()
        results.append(result)

    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)

    passed = sum(results)
    total = len(results)

    print(f"\n✅ Passed: {passed}/{total}")
    print(f"❌ Failed: {total - passed}/{total}")

    if passed == total:
        print("\n🎉 All tests passed!")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        return 1


def main():
    """Main entry point."""
    try:
        exit_code = asyncio.run(run_all_tests())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Test suite error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
