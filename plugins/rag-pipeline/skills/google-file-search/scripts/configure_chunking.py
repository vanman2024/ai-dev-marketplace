#!/usr/bin/env python3
"""
Google File Search Chunking Configuration Script

Generates chunking configuration files for different document types and use cases.

Usage:
    python configure_chunking.py --max-tokens 200 --overlap 20 --output chunking.json
    python configure_chunking.py --preset small
    python configure_chunking.py --preset large
"""

import argparse
import json
from pathlib import Path


# Preset configurations for common use cases
PRESETS = {
    "small": {
        "description": "Small chunks for code and structured data",
        "max_tokens_per_chunk": 100,
        "max_overlap_tokens": 10
    },
    "medium": {
        "description": "Medium chunks for general content",
        "max_tokens_per_chunk": 200,
        "max_overlap_tokens": 20
    },
    "large": {
        "description": "Large chunks for technical documentation",
        "max_tokens_per_chunk": 500,
        "max_overlap_tokens": 50
    },
    "technical-docs": {
        "description": "Optimized for technical documentation",
        "max_tokens_per_chunk": 400,
        "max_overlap_tokens": 40
    },
    "legal": {
        "description": "Precise boundaries for legal documents",
        "max_tokens_per_chunk": 300,
        "max_overlap_tokens": 30
    },
    "code": {
        "description": "Function-level chunks for code",
        "max_tokens_per_chunk": 150,
        "max_overlap_tokens": 15
    },
    "scientific": {
        "description": "Section-based chunks for scientific papers",
        "max_tokens_per_chunk": 500,
        "max_overlap_tokens": 75
    }
}


def create_chunking_config(max_tokens, overlap):
    """Create chunking configuration dictionary."""
    return {
        "chunking_config": {
            "white_space_config": {
                "max_tokens_per_chunk": max_tokens,
                "max_overlap_tokens": overlap
            }
        }
    }


def main():
    parser = argparse.ArgumentParser(
        description="Generate Google File Search chunking configuration"
    )
    parser.add_argument(
        "--preset",
        choices=PRESETS.keys(),
        help="Use a preset configuration"
    )
    parser.add_argument(
        "--max-tokens",
        type=int,
        help="Maximum tokens per chunk"
    )
    parser.add_argument(
        "--overlap",
        type=int,
        help="Overlap tokens between chunks"
    )
    parser.add_argument(
        "--output",
        default="chunking-config.json",
        help="Output file path"
    )
    parser.add_argument(
        "--list-presets",
        action="store_true",
        help="List available presets"
    )
    args = parser.parse_args()

    # List presets
    if args.list_presets:
        print("📋 Available Presets:\n")
        for name, config in PRESETS.items():
            print(f"  {name:20s} - {config['description']}")
            print(f"    {'':20s}   Max tokens: {config['max_tokens_per_chunk']}, Overlap: {config['max_overlap_tokens']}\n")
        return

    # Determine configuration
    if args.preset:
        preset_config = PRESETS[args.preset]
        max_tokens = preset_config["max_tokens_per_chunk"]
        overlap = preset_config["max_overlap_tokens"]
        description = preset_config["description"]
        print(f"📦 Using preset: {args.preset}")
        print(f"   {description}")
    elif args.max_tokens and args.overlap:
        max_tokens = args.max_tokens
        overlap = args.overlap
        description = "Custom configuration"
    else:
        print("❌ Error: Either --preset or both --max-tokens and --overlap required")
        print("Run with --list-presets to see available presets")
        return

    # Validate overlap
    if overlap >= max_tokens:
        print(f"⚠️  Warning: Overlap ({overlap}) should be less than max tokens ({max_tokens})")
        print("   Setting overlap to 10% of max tokens")
        overlap = max(1, max_tokens // 10)

    # Create configuration
    config = create_chunking_config(max_tokens, overlap)

    # Save to file
    output_path = Path(args.output)
    with open(output_path, "w") as f:
        json.dump(config, f, indent=2)

    print(f"\n✅ Configuration saved to: {output_path}")
    print(f"   Max tokens per chunk: {max_tokens}")
    print(f"   Overlap tokens: {overlap}")
    print(f"   Overlap percentage: {(overlap/max_tokens)*100:.1f}%")

    print(f"\n💡 Usage:")
    print(f"   python upload_documents.py --chunking-config {output_path} --file document.pdf")


if __name__ == "__main__":
    main()
