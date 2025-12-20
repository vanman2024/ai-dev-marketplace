#!/usr/bin/env python3
"""
Check response modality support and configuration.

Usage:
    python check-modality-support.py [--modality TEXT|AUDIO]

Checks:
- ADK installation and version
- Modality support availability
- Platform configuration (AI Studio vs Vertex AI)
- Required dependencies for chosen modality
"""

import sys
import os
import argparse
from typing import Optional


def check_adk_installation() -> bool:
    """Check if google-adk is installed."""
    print("Checking ADK installation...")
    try:
        import google.adk
        version = getattr(google.adk, "__version__", "unknown")
        print(f"✅ google-adk installed (version: {version})")

        # Check for minimum version (0.5.0+ for bidi-streaming)
        if version != "unknown":
            major, minor = map(int, version.split(".")[:2])
            if major == 0 and minor < 5:
                print(f"⚠️  Warning: Bidi-streaming requires ADK 0.5.0+")
                print(f"   Current version: {version}")
                return False

        return True
    except ImportError:
        print("❌ google-adk not installed")
        print("   Install with: pip install google-adk")
        return False


def check_platform_config() -> None:
    """Check platform configuration (AI Studio vs Vertex AI)."""
    print("\nChecking platform configuration...")

    vertex_ai = os.getenv("GOOGLE_GENAI_USE_VERTEXAI", "FALSE")

    if vertex_ai.upper() == "TRUE":
        print("✅ Platform: Vertex AI Live API")
        print("   (GOOGLE_GENAI_USE_VERTEXAI=TRUE)")
    else:
        print("✅ Platform: Google AI Studio (Gemini Live API)")
        print("   (GOOGLE_GENAI_USE_VERTEXAI=FALSE or unset)")

    print("\n   To switch platforms, set environment variable:")
    print("   export GOOGLE_GENAI_USE_VERTEXAI=TRUE   # For Vertex AI")
    print("   export GOOGLE_GENAI_USE_VERTEXAI=FALSE  # For AI Studio")


def check_text_modality() -> bool:
    """Check TEXT modality support."""
    print("\nChecking TEXT modality support...")

    try:
        from google.adk.agents.run_config import RunConfig, StreamingMode

        # TEXT modality should work on all platforms
        config = RunConfig(
            response_modalities=["TEXT"],
            streaming_mode=StreamingMode.BIDI
        )

        print("✅ TEXT modality configuration successful")
        print("   Response format: Text-based responses")
        print("   Use case: Chat-based streaming agents")
        return True

    except Exception as e:
        print(f"❌ TEXT modality check failed: {e}")
        return False


def check_audio_modality() -> bool:
    """Check AUDIO modality support and dependencies."""
    print("\nChecking AUDIO modality support...")

    try:
        from google.adk.agents.run_config import RunConfig, StreamingMode
        from google.genai import types

        # Check if types includes audio-related configs
        has_speech_config = hasattr(types, "SpeechConfig")
        has_audio_transcription = hasattr(types, "AudioTranscriptionConfig")

        if not (has_speech_config and has_audio_transcription):
            print("⚠️  Warning: Audio configuration types not found")
            print("   Update google-genai package for full audio support")

        # AUDIO modality configuration
        config = RunConfig(
            response_modalities=["AUDIO"],
            streaming_mode=StreamingMode.BIDI
        )

        print("✅ AUDIO modality configuration successful")
        print("   Response format: Audio/voice responses")
        print("   Use case: Voice-based streaming agents")
        print("   Native audio models: Gemini 2.0 Flash Multimodal Live")

        return True

    except Exception as e:
        print(f"❌ AUDIO modality check failed: {e}")
        return False


def check_imports() -> bool:
    """Check all required imports."""
    print("\nChecking required imports...")

    required = {
        "RunConfig": "google.adk.agents.run_config",
        "StreamingMode": "google.adk.agents.run_config",
        "LiveRequestQueue": "google.adk.agents",
        "types": "google.genai"
    }

    all_found = True

    for name, module in required.items():
        try:
            parts = module.split(".")
            obj = __import__(module, fromlist=[name])
            getattr(obj, name)
            print(f"✅ {name} from {module}")
        except (ImportError, AttributeError) as e:
            print(f"❌ {name} from {module} - {e}")
            all_found = False

    return all_found


def main():
    parser = argparse.ArgumentParser(
        description="Check ADK modality support and configuration"
    )
    parser.add_argument(
        "--modality",
        choices=["TEXT", "AUDIO"],
        help="Check specific modality support"
    )

    args = parser.parse_args()

    print("="*60)
    print("ADK Modality Support Check")
    print("="*60 + "\n")

    # Run checks
    checks_passed = 0
    total_checks = 0

    # ADK installation check
    total_checks += 1
    if check_adk_installation():
        checks_passed += 1

    # Platform config check (informational only)
    check_platform_config()

    # Import checks
    total_checks += 1
    if check_imports():
        checks_passed += 1

    # Modality-specific checks
    if args.modality:
        total_checks += 1
        if args.modality == "TEXT":
            if check_text_modality():
                checks_passed += 1
        else:  # AUDIO
            if check_audio_modality():
                checks_passed += 1
    else:
        # Check both modalities
        total_checks += 2
        if check_text_modality():
            checks_passed += 1
        if check_audio_modality():
            checks_passed += 1

    # Summary
    print("\n" + "="*60)
    print("Summary")
    print("="*60)
    print(f"\n✅ Checks passed: {checks_passed}/{total_checks}")

    if checks_passed == total_checks:
        print("\n🎉 All modality checks passed!")
        print("\nYou're ready to build streaming agents!")
        return 0
    else:
        print(f"\n⚠️  {total_checks - checks_passed} check(s) failed")
        print("\nResolve issues above before building streaming agents")
        return 1


if __name__ == "__main__":
    sys.exit(main())
