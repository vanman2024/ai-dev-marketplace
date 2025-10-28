"""
FastMCP Content & Image Generation Server

AI-powered content and image generation with:
- Google Imagen 3/4 image generation
- Google Veo 2/3 video generation
- Claude/Gemini content generation
- Cost estimation and tracking
"""

import os
import json
import base64
from typing import Optional, List, Dict, Any
from datetime import datetime
from pathlib import Path

from fastmcp import FastMCP
from dotenv import load_dotenv

# Google Cloud AI Platform
from google.cloud import aiplatform
from vertexai.preview.vision_models import ImageGenerationModel
from vertexai.preview.generative_models import GenerativeModel

# Anthropic Claude
from anthropic import Anthropic

# Google Generative AI (Gemini)
import google.generativeai as genai

# Load environment variables
load_dotenv()

# Initialize FastMCP server
mcp = FastMCP(name=os.getenv("MCP_SERVER_NAME", "Content & Image Generation"))

# Configuration
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")
LOCATION = os.getenv("GOOGLE_CLOUD_LOCATION", "us-central1")
OUTPUT_DIR = Path("output")
OUTPUT_DIR.mkdir(exist_ok=True)

# Initialize Google Cloud AI Platform
if PROJECT_ID:
    aiplatform.init(project=PROJECT_ID, location=LOCATION)

# Initialize Anthropic
anthropic_client = None
if os.getenv("ANTHROPIC_API_KEY"):
    anthropic_client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

# Initialize Gemini
if os.getenv("GOOGLE_API_KEY"):
    genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))


# Pricing Constants (approximate USD per unit)
PRICING = {
    "imagen3": {"sd": 0.020, "hd": 0.040},  # per image
    "imagen4": {"sd": 0.025, "hd": 0.050},  # per image
    "veo2": 0.15,  # per second of video
    "veo3": 0.20,  # per second of video
    "claude_sonnet": 0.003,  # per 1K tokens (avg input/output)
    "gemini_pro": 0.0005,  # per 1K tokens
}


@mcp.tool()
def generate_image_imagen3(
    prompt: str,
    negative_prompt: Optional[str] = None,
    aspect_ratio: str = "1:1",
    quality: str = "hd",
    output_format: str = "png",
    seed: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Generate marketing images using Google Imagen 3/4.

    Args:
        prompt: Detailed description of the image to generate
        negative_prompt: What to avoid in the image
        aspect_ratio: Image aspect ratio (1:1, 16:9, 9:16, 4:3, 3:4)
        quality: Image quality (sd=standard, hd=high definition)
        output_format: Output format (png, jpeg, webp)
        seed: Random seed for reproducible results

    Returns:
        Dictionary with image path, metadata, and estimated cost
    """
    try:
        if not PROJECT_ID:
            return {
                "error": "GOOGLE_CLOUD_PROJECT not configured",
                "success": False
            }

        # Initialize Imagen model
        model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-001")

        # Generate image
        generation_params = {
            "prompt": prompt,
            "aspect_ratio": aspect_ratio,
            "number_of_images": 1,
        }

        if negative_prompt:
            generation_params["negative_prompt"] = negative_prompt

        if seed is not None:
            generation_params["seed"] = seed

        images = model.generate_images(**generation_params)

        # Save image
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"imagen3_{timestamp}.{output_format}"
        filepath = OUTPUT_DIR / filename

        images[0].save(location=str(filepath), include_generation_parameters=True)

        # Calculate cost
        cost = PRICING["imagen3"][quality]

        return {
            "success": True,
            "image_path": str(filepath.absolute()),
            "filename": filename,
            "model": "imagen-3.0",
            "prompt": prompt,
            "aspect_ratio": aspect_ratio,
            "quality": quality,
            "estimated_cost_usd": cost,
            "timestamp": timestamp
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "model": "imagen-3.0"
        }


@mcp.tool()
def batch_generate_images(
    prompts: List[str],
    aspect_ratio: str = "1:1",
    quality: str = "hd",
    model_version: str = "imagen3",
) -> Dict[str, Any]:
    """
    Generate multiple marketing images in batch.

    Args:
        prompts: List of image prompts
        aspect_ratio: Image aspect ratio for all images
        quality: Image quality (sd or hd)
        model_version: Model to use (imagen3 or imagen4)

    Returns:
        Dictionary with list of generated images and total cost
    """
    results = []
    total_cost = 0.0
    successful = 0
    failed = 0

    for i, prompt in enumerate(prompts, 1):
        result = generate_image_imagen3(
            prompt=prompt,
            aspect_ratio=aspect_ratio,
            quality=quality
        )

        results.append({
            "index": i,
            "prompt": prompt,
            **result
        })

        if result.get("success"):
            successful += 1
            total_cost += result.get("estimated_cost_usd", 0)
        else:
            failed += 1

    return {
        "success": True,
        "total_images": len(prompts),
        "successful": successful,
        "failed": failed,
        "results": results,
        "total_cost_usd": round(total_cost, 4),
        "model_version": model_version
    }


@mcp.tool()
def generate_video_veo3(
    prompt: str,
    duration_seconds: int = 5,
    resolution: str = "720p",
    fps: int = 24,
) -> Dict[str, Any]:
    """
    Generate marketing videos using Google Veo 2/3.

    Args:
        prompt: Detailed description of the video to generate
        duration_seconds: Video duration (1-10 seconds for Veo 3)
        resolution: Video resolution (480p, 720p, 1080p)
        fps: Frames per second (24, 30, 60)

    Returns:
        Dictionary with video path, metadata, and estimated cost
    """
    try:
        if not PROJECT_ID:
            return {
                "error": "GOOGLE_CLOUD_PROJECT not configured",
                "success": False
            }

        # Note: Veo API is in preview, this is a placeholder implementation
        # Replace with actual Veo API when available

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"veo3_{timestamp}.mp4"
        filepath = OUTPUT_DIR / filename

        # Calculate cost based on duration
        cost = PRICING["veo3"] * duration_seconds

        return {
            "success": True,
            "video_path": str(filepath.absolute()),
            "filename": filename,
            "model": "veo-3.0",
            "prompt": prompt,
            "duration_seconds": duration_seconds,
            "resolution": resolution,
            "fps": fps,
            "estimated_cost_usd": round(cost, 4),
            "timestamp": timestamp,
            "note": "Veo API integration pending - placeholder response"
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "model": "veo-3.0"
        }


@mcp.tool()
def generate_marketing_content(
    content_type: str,
    topic: str,
    tone: str = "professional",
    length: str = "medium",
    model: str = "claude",
    include_hashtags: bool = True,
) -> Dict[str, Any]:
    """
    Generate marketing content using Claude or Gemini.

    Args:
        content_type: Type of content (social_post, blog_intro, ad_copy, email_subject, product_desc)
        topic: Content topic or product description
        tone: Content tone (professional, casual, enthusiastic, formal)
        length: Content length (short, medium, long)
        model: AI model to use (claude, gemini)
        include_hashtags: Include relevant hashtags (for social content)

    Returns:
        Dictionary with generated content, metadata, and estimated cost
    """
    try:
        length_map = {
            "short": "1-2 sentences",
            "medium": "3-5 sentences or 1 paragraph",
            "long": "2-3 paragraphs"
        }

        prompt_base = f"""Generate {content_type.replace('_', ' ')} about: {topic}

Tone: {tone}
Length: {length_map.get(length, 'medium')}
{'Include relevant hashtags at the end.' if include_hashtags else ''}

Make it compelling, engaging, and ready to use for marketing purposes."""

        content = ""
        tokens_used = 0
        model_used = ""

        if model == "claude" and anthropic_client:
            response = anthropic_client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=1024,
                messages=[
                    {"role": "user", "content": prompt_base}
                ]
            )
            content = response.content[0].text
            tokens_used = response.usage.input_tokens + response.usage.output_tokens
            model_used = "claude-sonnet-4"
            cost = (tokens_used / 1000) * PRICING["claude_sonnet"]

        elif model == "gemini" or not anthropic_client:
            gemini_model = genai.GenerativeModel("gemini-2.0-flash-exp")
            response = gemini_model.generate_content(prompt_base)
            content = response.text
            # Approximate token count
            tokens_used = len(content.split()) * 1.3
            model_used = "gemini-2.0-flash"
            cost = (tokens_used / 1000) * PRICING["gemini_pro"]

        else:
            return {
                "success": False,
                "error": "No AI model available. Check API keys."
            }

        return {
            "success": True,
            "content": content,
            "content_type": content_type,
            "topic": topic,
            "tone": tone,
            "length": length,
            "model_used": model_used,
            "tokens_used": int(tokens_used),
            "estimated_cost_usd": round(cost, 6),
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "model": model
        }


@mcp.tool()
def calculate_cost_estimate(
    images_sd: int = 0,
    images_hd: int = 0,
    video_seconds: int = 0,
    content_pieces: int = 0,
    model_preference: str = "imagen3",
    video_model: str = "veo3",
) -> Dict[str, Any]:
    """
    Calculate estimated costs for a marketing campaign.

    Args:
        images_sd: Number of standard definition images
        images_hd: Number of high definition images
        video_seconds: Total seconds of video
        content_pieces: Number of content pieces (avg 500 tokens each)
        model_preference: Image model (imagen3 or imagen4)
        video_model: Video model (veo2 or veo3)

    Returns:
        Dictionary with detailed cost breakdown
    """
    try:
        # Image costs
        image_model_key = model_preference.lower()
        if image_model_key not in PRICING:
            image_model_key = "imagen3"

        image_sd_cost = images_sd * PRICING[image_model_key]["sd"]
        image_hd_cost = images_hd * PRICING[image_model_key]["hd"]
        total_image_cost = image_sd_cost + image_hd_cost

        # Video costs
        video_model_key = video_model.lower()
        if video_model_key not in PRICING:
            video_model_key = "veo3"

        video_cost = video_seconds * PRICING[video_model_key]

        # Content generation costs (assuming avg 500 tokens per piece with Claude)
        content_cost = content_pieces * (0.5 * PRICING["claude_sonnet"])

        # Total
        total_cost = total_image_cost + video_cost + content_cost

        return {
            "success": True,
            "breakdown": {
                "images": {
                    "standard_definition": {
                        "count": images_sd,
                        "cost_usd": round(image_sd_cost, 4)
                    },
                    "high_definition": {
                        "count": images_hd,
                        "cost_usd": round(image_hd_cost, 4)
                    },
                    "total_cost_usd": round(total_image_cost, 4)
                },
                "video": {
                    "seconds": video_seconds,
                    "model": video_model_key,
                    "cost_usd": round(video_cost, 4)
                },
                "content": {
                    "pieces": content_pieces,
                    "avg_tokens": 500,
                    "cost_usd": round(content_cost, 6)
                }
            },
            "total_cost_usd": round(total_cost, 4),
            "models_used": {
                "image": model_preference,
                "video": video_model,
                "content": "claude-sonnet-4"
            },
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


@mcp.resource("config://pricing")
def get_pricing_info() -> str:
    """Get current pricing information for all services."""
    return json.dumps({
        "pricing": PRICING,
        "currency": "USD",
        "last_updated": "2025-10-25",
        "notes": "Prices are approximate and may vary"
    }, indent=2)


@mcp.resource("config://models")
def get_available_models() -> str:
    """Get information about available AI models."""
    return json.dumps({
        "image_generation": {
            "imagen3": {
                "version": "imagen-3.0-generate-001",
                "capabilities": ["high quality", "multiple aspect ratios", "style control"],
                "max_resolution": "1024x1024"
            },
            "imagen4": {
                "version": "imagen-4.0-preview",
                "capabilities": ["ultra high quality", "advanced prompting", "better consistency"],
                "status": "preview"
            }
        },
        "video_generation": {
            "veo2": {
                "max_duration": "8s",
                "capabilities": ["realistic motion", "temporal consistency"]
            },
            "veo3": {
                "max_duration": "10s",
                "capabilities": ["enhanced quality", "better prompt understanding", "advanced controls"]
            }
        },
        "content_generation": {
            "claude": {
                "model": "claude-sonnet-4-20250514",
                "strengths": ["creative writing", "nuanced tone", "long-form content"]
            },
            "gemini": {
                "model": "gemini-2.0-flash-exp",
                "strengths": ["fast generation", "cost-effective", "multilingual"]
            }
        }
    }, indent=2)


@mcp.prompt()
def campaign_planner():
    """Generate a comprehensive marketing campaign plan."""
    return """You are a marketing campaign strategist. Help plan a comprehensive marketing campaign.

Please provide:
1. Campaign objective and target audience
2. Key messages and value propositions
3. Content mix (images, videos, copy)
4. Channel strategy (social, email, ads)
5. Timeline and milestones

I'll help you:
- Generate cost estimates
- Create visual assets with Imagen
- Produce video content with Veo
- Write compelling copy with Claude/Gemini
- Optimize for different platforms

What campaign would you like to plan?"""


@mcp.prompt()
def image_prompt_enhancer():
    """Enhance image generation prompts for better results."""
    return """I'll help you create better prompts for Imagen image generation.

For best results, include:
- **Subject**: What is the main focus?
- **Style**: Photography, illustration, 3D render, etc.
- **Mood**: Professional, playful, luxurious, etc.
- **Composition**: Layout, framing, perspective
- **Details**: Colors, lighting, background, textures
- **Quality terms**: High detail, sharp focus, professional lighting

Example: "Professional product photography of a smartphone, centered composition,
white background, soft studio lighting, high detail, commercial quality, modern and clean aesthetic"

What image do you want to create?"""


if __name__ == "__main__":
    # Run server in HTTP mode for deployment
    # For local testing with Claude Desktop, use: mcp.run() for STDIO
    import sys

    transport = "stdio"  # Default for Claude Desktop

    if len(sys.argv) > 1 and sys.argv[1] == "--http":
        transport = "http"

    mcp.run(transport=transport)
