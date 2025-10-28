#!/usr/bin/env python3
"""
Test script for Marketing Automation MCP Server

Demonstrates the server configuration and available tools.
"""

import json
from server import mcp


def list_tools():
    """List all available tools."""
    print("Available Tools:")
    print("-" * 60)

    tools = [
        {
            "name": "generate_image_imagen3",
            "description": "Generate marketing images using Google Imagen 3/4",
            "params": ["prompt", "negative_prompt", "aspect_ratio", "quality", "output_format", "seed"]
        },
        {
            "name": "batch_generate_images",
            "description": "Generate multiple marketing images in batch",
            "params": ["prompts", "aspect_ratio", "quality", "model_version"]
        },
        {
            "name": "generate_video_veo3",
            "description": "Generate marketing videos using Google Veo 2/3",
            "params": ["prompt", "duration_seconds", "resolution", "fps"]
        },
        {
            "name": "generate_marketing_content",
            "description": "Generate marketing content using Claude or Gemini",
            "params": ["content_type", "topic", "tone", "length", "model", "include_hashtags"]
        },
        {
            "name": "calculate_cost_estimate",
            "description": "Calculate estimated costs for a marketing campaign",
            "params": ["images_sd", "images_hd", "video_seconds", "content_pieces", "model_preference", "video_model"]
        }
    ]

    for i, tool in enumerate(tools, 1):
        print(f"\n{i}. {tool['name']}")
        print(f"   Description: {tool['description']}")
        print(f"   Parameters: {', '.join(tool['params'])}")


def list_resources():
    """List all available resources."""
    print("\n\nAvailable Resources:")
    print("-" * 60)

    resources = [
        {
            "uri": "config://pricing",
            "description": "Get current pricing information for all services"
        },
        {
            "uri": "config://models",
            "description": "Get information about available AI models"
        }
    ]

    for i, resource in enumerate(resources, 1):
        print(f"\n{i}. {resource['uri']}")
        print(f"   Description: {resource['description']}")


def list_prompts():
    """List all available prompts."""
    print("\n\nAvailable Prompts:")
    print("-" * 60)

    prompts = [
        {
            "name": "campaign_planner",
            "description": "Generate a comprehensive marketing campaign plan"
        },
        {
            "name": "image_prompt_enhancer",
            "description": "Enhance image generation prompts for better results"
        }
    ]

    for i, prompt in enumerate(prompts, 1):
        print(f"\n{i}. {prompt['name']}")
        print(f"   Description: {prompt['description']}")


def show_usage_examples():
    """Show usage examples."""
    print("\n\nUsage Examples:")
    print("=" * 60)

    examples = [
        {
            "title": "Generate a Product Image",
            "code": '''generate_image_imagen3(
    prompt="Professional product photography of a smartwatch,
    white background, studio lighting, high detail",
    aspect_ratio="1:1",
    quality="hd"
)'''
        },
        {
            "title": "Create Marketing Copy",
            "code": '''generate_marketing_content(
    content_type="social_post",
    topic="New AI-powered analytics platform launch",
    tone="enthusiastic",
    length="medium",
    model="claude",
    include_hashtags=True
)'''
        },
        {
            "title": "Estimate Campaign Costs",
            "code": '''calculate_cost_estimate(
    images_hd=10,
    images_sd=20,
    video_seconds=30,
    content_pieces=15
)'''
        }
    ]

    for i, example in enumerate(examples, 1):
        print(f"\n{i}. {example['title']}")
        print("-" * 60)
        print(example['code'])


def main():
    """Display server information."""
    print("=" * 60)
    print("Marketing Automation MCP Server")
    print("=" * 60)
    print(f"\nServer Name: {mcp.name}")
    print("Version: 0.1.0")
    print("FastMCP Version: 2.13.0")
    print("\nStatus: Ready (awaiting API configuration)")
    print("=" * 60)

    list_tools()
    list_resources()
    list_prompts()
    show_usage_examples()

    print("\n" + "=" * 60)
    print("Setup Instructions:")
    print("=" * 60)
    print("\n1. Configure environment:")
    print("   cp .env.example .env")
    print("   # Edit .env with your API keys")
    print("\n2. Run server locally (STDIO for Claude Desktop):")
    print("   python server.py")
    print("\n3. Run server in HTTP mode (for deployment):")
    print("   python server.py --http")
    print("\n4. Add to Claude Desktop:")
    print("   See claude_desktop_config.example.json")
    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()
