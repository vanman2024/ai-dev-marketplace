"""
Campaign Templates for Marketing Automation

Domain-agnostic templates for different campaign types:
- Job recruitment
- Product marketing
- Event promotion
- Service marketing
- Content marketing
"""

from typing import Dict, List, Any
from dataclasses import dataclass


@dataclass
class CampaignTemplate:
    """Base template for any marketing campaign"""
    
    campaign_type: str
    target_platforms: List[str]
    content_style: str
    visual_style: str
    posting_frequency: str
    optimal_times: List[str]
    hashtag_strategy: str
    cta_pattern: str


# Campaign Templates Library
CAMPAIGN_TEMPLATES = {
    "job_recruitment": CampaignTemplate(
        campaign_type="Job Recruitment",
        target_platforms=[
            "linkedin",      # Primary for professional recruiting
            "x",             # Tech community engagement
            "facebook",      # Broader reach
            "threads",       # Modern casual recruiting
        ],
        content_style="Professional, benefits-focused, clear requirements",
        visual_style="Office environment, team collaboration, company culture",
        posting_frequency="2-3 times per week per position",
        optimal_times=[
            "Tuesday 10am",
            "Wednesday 3pm", 
            "Thursday 11am"
        ],
        hashtag_strategy="Mix of role (#SeniorDeveloper), tech (#Python), and location (#RemoteJob)",
        cta_pattern="Apply now, View details, Join our team"
    ),
    
    "product_launch": CampaignTemplate(
        campaign_type="Product Marketing",
        target_platforms=[
            "instagram",     # Visual storytelling
            "tiktok",        # Product demos
            "pinterest",     # Product discovery
            "youtube",       # Detailed reviews
            "x",             # Tech announcements
        ],
        content_style="Benefit-driven, problem-solution, feature highlights",
        visual_style="Product mockups, UI screenshots, lifestyle context",
        posting_frequency="Daily leading to launch, 3x/week post-launch",
        optimal_times=[
            "Monday 9am",
            "Wednesday 1pm",
            "Friday 4pm"
        ],
        hashtag_strategy="Product category (#AITools), use case (#Productivity), industry (#SaaS)",
        cta_pattern="Learn more, Try free trial, Get early access"
    ),
    
    "event_promotion": CampaignTemplate(
        campaign_type="Event Marketing",
        target_platforms=[
            "linkedin",      # Professional events
            "facebook",      # Event pages and RSVPs
            "instagram",     # Visual teasers
            "threads",       # Event updates
            "x",             # Live event coverage
        ],
        content_style="Excitement-building, speaker highlights, agenda teasers",
        visual_style="Venue photos, speaker headshots, schedule graphics",
        posting_frequency="Weekly countdown, daily week-of, hourly day-of",
        optimal_times=[
            "Monday 8am",    # Week kickoff
            "Thursday 2pm",  # Pre-weekend planning
            "Sunday 6pm"     # Weekend planners
        ],
        hashtag_strategy="Event name (#TechConf2025), topic (#AIConference), location (#SFEvents)",
        cta_pattern="Register now, Save your spot, Get tickets"
    ),
    
    "service_marketing": CampaignTemplate(
        campaign_type="Service Marketing",
        target_platforms=[
            "linkedin",      # B2B services
            "google_business", # Local services
            "facebook",      # Community services
            "instagram",     # Visual service showcase
            "youtube",       # Service explainers
        ],
        content_style="Trust-building, case studies, client testimonials",
        visual_style="Client success stories, before/after, process diagrams",
        posting_frequency="2-3 times per week, consistent schedule",
        optimal_times=[
            "Tuesday 9am",
            "Thursday 2pm",
            "Saturday 10am"  # Weekend service planning
        ],
        hashtag_strategy="Service type (#Consulting), industry (#TechServices), value (#BusinessGrowth)",
        cta_pattern="Schedule consultation, Get quote, Learn more"
    ),
    
    "content_marketing": CampaignTemplate(
        campaign_type="Content Marketing",
        target_platforms=[
            "linkedin",      # Professional insights
            "x",             # Thought leadership
            "threads",       # Casual expertise
            "reddit",        # Community engagement
            "medium",        # Long-form content
        ],
        content_style="Educational, insight-driven, actionable tips",
        visual_style="Infographics, data visualizations, quote cards",
        posting_frequency="Daily or multiple times per day",
        optimal_times=[
            "Monday 7am",    # Commute reading
            "Wednesday 12pm", # Lunch break
            "Friday 5pm"     # Weekend reading
        ],
        hashtag_strategy="Topic (#MarketingTips), industry (#B2BMarketing), format (#Infographic)",
        cta_pattern="Read full article, Download guide, Subscribe for more"
    ),
    
    "recruitment_agency": CampaignTemplate(
        campaign_type="Recruitment Agency Portfolio",
        target_platforms=[
            "linkedin",      # Primary platform
            "x",             # Industry news
            "facebook",      # Local jobs
            "instagram",     # Employer branding
        ],
        content_style="Mix of job listings, career advice, industry insights",
        visual_style="Professional settings, success stories, career tips graphics",
        posting_frequency="Daily job posts + 2-3x weekly thought leadership",
        optimal_times=[
            "Monday 8am",    # Week start job search
            "Wednesday 11am",
            "Friday 3pm"     # Weekend job browsing
        ],
        hashtag_strategy="Job titles, skills, locations, career advice topics",
        cta_pattern="Apply now, Contact recruiter, View all jobs"
    ),
}


def get_campaign_config(campaign_type: str) -> Dict[str, Any]:
    """
    Get campaign configuration for a specific type.
    
    Args:
        campaign_type: One of: job_recruitment, product_launch, event_promotion,
                      service_marketing, content_marketing, recruitment_agency
    
    Returns:
        Dictionary with campaign configuration
    """
    template = CAMPAIGN_TEMPLATES.get(campaign_type)
    
    if not template:
        return {
            "error": f"Unknown campaign type: {campaign_type}",
            "available_types": list(CAMPAIGN_TEMPLATES.keys())
        }
    
    return {
        "campaign_type": template.campaign_type,
        "recommended_platforms": template.target_platforms,
        "content_guidelines": {
            "style": template.content_style,
            "posting_frequency": template.posting_frequency,
            "optimal_times": template.optimal_times,
        },
        "visual_guidelines": {
            "style": template.visual_style,
        },
        "engagement_strategy": {
            "hashtags": template.hashtag_strategy,
            "call_to_action": template.cta_pattern,
        }
    }


def estimate_campaign_cost(
    campaign_type: str,
    post_count: int,
    image_count: int = 0,
    video_count: int = 0,
    video_length_seconds: int = 30
) -> Dict[str, Any]:
    """
    Estimate total cost for a campaign.
    
    Args:
        campaign_type: Type of campaign
        post_count: Number of social media posts
        image_count: Number of images to generate
        video_count: Number of videos to generate
        video_length_seconds: Average video length
    
    Returns:
        Cost breakdown and total estimate
    """
    # Ayrshare posting costs (average $0.35/post)
    post_cost = post_count * 0.35
    
    # Image generation (Imagen 3 HD: $0.04/image)
    image_cost = image_count * 0.04
    
    # Video generation (Veo 2: $0.15/second)
    video_cost = video_count * video_length_seconds * 0.15
    
    # Content generation (Claude Sonnet: ~$0.06/post)
    content_cost = post_count * 0.06
    
    total_cost = post_cost + image_cost + video_cost + content_cost
    
    return {
        "campaign_type": campaign_type,
        "breakdown": {
            "social_posts": {
                "count": post_count,
                "unit_cost": 0.35,
                "total": round(post_cost, 2)
            },
            "images": {
                "count": image_count,
                "unit_cost": 0.04,
                "total": round(image_cost, 2)
            },
            "videos": {
                "count": video_count,
                "seconds_each": video_length_seconds,
                "unit_cost": 0.15,
                "total": round(video_cost, 2)
            },
            "content_generation": {
                "posts": post_count,
                "unit_cost": 0.06,
                "total": round(content_cost, 2)
            }
        },
        "total_cost": round(total_cost, 2),
        "cost_per_post": round(total_cost / post_count, 2) if post_count > 0 else 0
    }


# Example campaign scenarios
CAMPAIGN_EXAMPLES = {
    "job_recruitment": {
        "scenario": "Hire 5 developers over 2 months",
        "posts": 30,
        "images": 10,
        "videos": 2,
        "estimated_cost": estimate_campaign_cost("job_recruitment", 30, 10, 2, 30)
    },
    "product_launch": {
        "scenario": "Launch new SaaS product",
        "posts": 50,
        "images": 25,
        "videos": 5,
        "estimated_cost": estimate_campaign_cost("product_launch", 50, 25, 5, 45)
    },
    "event_promotion": {
        "scenario": "Promote tech conference",
        "posts": 40,
        "images": 15,
        "videos": 3,
        "estimated_cost": estimate_campaign_cost("event_promotion", 40, 15, 3, 30)
    }
}


if __name__ == "__main__":
    # Demo: Show all campaign types
    print("=" * 80)
    print("MARKETING AUTOMATION: CAMPAIGN TEMPLATES")
    print("=" * 80)
    
    for campaign_key, template in CAMPAIGN_TEMPLATES.items():
        print(f"\n📊 {template.campaign_type.upper()}")
        print(f"   Platforms: {', '.join(template.target_platforms[:3])}...")
        print(f"   Style: {template.content_style[:60]}...")
        print(f"   Frequency: {template.posting_frequency}")
    
    # Show example scenarios
    print("\n" + "=" * 80)
    print("COST EXAMPLES")
    print("=" * 80)
    
    for campaign_key, example in CAMPAIGN_EXAMPLES.items():
        print(f"\n💰 {campaign_key.upper()}")
        print(f"   Scenario: {example['scenario']}")
        print(f"   Posts: {example['posts']} | Images: {example['images']} | Videos: {example['videos']}")
        print(f"   Estimated Cost: ${example['estimated_cost']['total_cost']}")
