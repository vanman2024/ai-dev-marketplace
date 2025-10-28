"""
Tests for MCP prompt functions

Comprehensive tests for 3 Ayrshare MCP prompts:
- optimize_for_platform
- generate_hashtags
- schedule_campaign
"""

import pytest
from src import server


@pytest.mark.prompts
class TestOptimizeForPlatformPrompt:
    """Tests for optimize_for_platform prompt"""

    def test_optimize_twitter(self):
        """Test prompt optimization for Twitter"""
        result = server.optimize_for_platform(
            post_content="This is a long post that needs to be optimized for Twitter platform",
            target_platform="twitter",
        )

        assert "twitter" in result.lower()
        assert "280" in result  # Character limit
        assert "1-2 relevant hashtags" in result
        assert "conversational and concise" in result
        assert "punchy and engaging" in result

    def test_optimize_facebook(self):
        """Test prompt optimization for Facebook"""
        result = server.optimize_for_platform(
            post_content="Product announcement for Facebook",
            target_platform="facebook",
        )

        assert "facebook" in result.lower()
        assert "63206" in result  # Character limit
        assert "friendly and personal" in result
        assert "detailed and engaging" in result
        assert "storytelling" in result

    def test_optimize_linkedin(self):
        """Test prompt optimization for LinkedIn"""
        result = server.optimize_for_platform(
            post_content="Professional update for business network",
            target_platform="linkedin",
        )

        assert "linkedin" in result.lower()
        assert "3000" in result  # Character limit
        assert "professional and insightful" in result
        assert "3-5 professional hashtags" in result
        assert "thought leadership" in result

    def test_optimize_instagram(self):
        """Test prompt optimization for Instagram"""
        result = server.optimize_for_platform(
            post_content="Visual content for Instagram feed",
            target_platform="instagram",
        )

        assert "instagram" in result.lower()
        assert "2200" in result  # Character limit
        assert "visual-first" in result
        assert "10-30 relevant hashtags" in result
        assert "storytelling with emoji support" in result

    def test_optimize_tiktok(self):
        """Test prompt optimization for TikTok"""
        result = server.optimize_for_platform(
            post_content="Trendy video content for TikTok",
            target_platform="tiktok",
        )

        assert "tiktok" in result.lower()
        assert "2200" in result  # Character limit
        assert "fun, trendy, authentic" in result
        assert "3-5 trending hashtags" in result
        assert "attention-grabbing" in result

    @pytest.mark.parametrize(
        "platform",
        ["twitter", "facebook", "linkedin", "instagram", "tiktok"],
    )
    def test_optimize_all_platforms(self, platform):
        """Test prompt generation for all supported platforms"""
        result = server.optimize_for_platform(
            post_content="Generic content to optimize",
            target_platform=platform,
        )

        assert platform in result.lower()
        assert "Character Limit:" in result
        assert "Tone:" in result
        assert "Hashtag Strategy:" in result
        assert "Style:" in result
        assert "Return ONLY the optimized post content" in result

    def test_optimize_unknown_platform(self):
        """Test prompt for unknown platform (uses defaults)"""
        result = server.optimize_for_platform(
            post_content="Content for unknown platform",
            target_platform="unknown_platform",
        )

        assert "unknown_platform" in result.lower()
        assert "2000" in result  # Default character limit
        assert "engaging and platform-appropriate" in result
        assert "2-5 relevant hashtags" in result

    def test_optimize_case_insensitive(self):
        """Test platform name is case insensitive"""
        result_lower = server.optimize_for_platform(
            post_content="Test content",
            target_platform="twitter",
        )
        result_upper = server.optimize_for_platform(
            post_content="Test content",
            target_platform="TWITTER",
        )

        # Both should reference Twitter's specs
        assert "280" in result_lower
        assert "280" in result_upper


@pytest.mark.prompts
class TestGenerateHashtagsPrompt:
    """Tests for generate_hashtags prompt"""

    def test_generate_hashtags_single_platform(self):
        """Test hashtag generation for single platform"""
        result = server.generate_hashtags(
            post_content="Launching our new sustainable product line",
            target_platforms=["instagram"],
            max_hashtags=5,
        )

        assert "sustainable product line" in result.lower()
        assert "instagram" in result.lower()
        assert "5" in result
        assert "#hashtag1 #hashtag2" in result

    def test_generate_hashtags_multiple_platforms(self):
        """Test hashtag generation for multiple platforms"""
        result = server.generate_hashtags(
            post_content="Tech innovation announcement",
            target_platforms=["twitter", "linkedin", "facebook"],
            max_hashtags=3,
        )

        assert "tech innovation" in result.lower()
        assert "twitter, linkedin, facebook" in result.lower()
        assert "3" in result

    def test_generate_hashtags_default_max(self):
        """Test hashtag generation with default max_hashtags"""
        result = server.generate_hashtags(
            post_content="Marketing campaign post",
            target_platforms=["facebook", "instagram"],
        )

        assert "5" in result  # Default max_hashtags
        assert "facebook, instagram" in result.lower()

    @pytest.mark.parametrize(
        "max_hashtags",
        [1, 3, 5, 10, 15],
    )
    def test_generate_hashtags_various_limits(self, max_hashtags):
        """Test hashtag generation with various max counts"""
        result = server.generate_hashtags(
            post_content="Test content",
            target_platforms=["twitter"],
            max_hashtags=max_hashtags,
        )

        assert str(max_hashtags) in result
        assert f"Generate {max_hashtags} highly relevant hashtags" in result

    def test_generate_hashtags_requirements(self):
        """Test that prompt includes all requirements"""
        result = server.generate_hashtags(
            post_content="Business growth tips",
            target_platforms=["linkedin"],
            max_hashtags=5,
        )

        assert "Mix of popular and niche hashtags" in result
        assert "platform-specific trends" in result
        assert "industry/topic-specific tags" in result
        assert "Avoid overused or spammy hashtags" in result


@pytest.mark.prompts
class TestScheduleCampaignPrompt:
    """Tests for schedule_campaign prompt"""

    def test_schedule_campaign_basic(self):
        """Test basic campaign schedule generation"""
        result = server.schedule_campaign(
            campaign_name="Summer Product Launch",
            start_date="2025-06-01",
            end_date="2025-08-31",
            post_frequency="daily",
            platforms=["facebook", "instagram", "twitter"],
            campaign_goals="Increase brand awareness and drive sales",
        )

        assert "Summer Product Launch" in result
        assert "2025-06-01" in result
        assert "2025-08-31" in result
        assert "daily" in result
        assert "facebook, instagram, twitter" in result.lower()
        assert "Increase brand awareness and drive sales" in result

    def test_schedule_campaign_structure(self):
        """Test campaign schedule includes all required sections"""
        result = server.schedule_campaign(
            campaign_name="Holiday Campaign",
            start_date="2025-12-01",
            end_date="2025-12-25",
            post_frequency="twice daily",
            platforms=["facebook", "instagram"],
            campaign_goals="Drive holiday sales",
        )

        # Check for all major sections
        assert "Posting Calendar" in result
        assert "Content Strategy" in result
        assert "Engagement Strategy" in result
        assert "Performance Tracking" in result

    def test_schedule_campaign_calendar_details(self):
        """Test campaign calendar details are included"""
        result = server.schedule_campaign(
            campaign_name="Test Campaign",
            start_date="2025-01-01",
            end_date="2025-01-31",
            post_frequency="3x per week",
            platforms=["linkedin"],
            campaign_goals="B2B lead generation",
        )

        assert "Date/Time" in result
        assert "Platform(s)" in result
        assert "Post Type" in result
        assert "Content Theme" in result
        assert "Call-to-Action" in result

    @pytest.mark.parametrize(
        "post_frequency",
        ["daily", "twice daily", "3x per week", "every other day", "weekly"],
    )
    def test_schedule_campaign_frequencies(self, post_frequency):
        """Test various posting frequencies"""
        result = server.schedule_campaign(
            campaign_name="Frequency Test",
            start_date="2025-01-01",
            end_date="2025-02-01",
            post_frequency=post_frequency,
            platforms=["facebook"],
            campaign_goals="Engagement",
        )

        assert post_frequency in result

    def test_schedule_campaign_multiple_platforms(self):
        """Test campaign with multiple platforms"""
        platforms = ["facebook", "twitter", "linkedin", "instagram", "pinterest"]
        result = server.schedule_campaign(
            campaign_name="Multi-Platform Campaign",
            start_date="2025-03-01",
            end_date="2025-03-31",
            post_frequency="daily",
            platforms=platforms,
            campaign_goals="Maximum reach",
        )

        for platform in platforms:
            assert platform in result.lower()

    def test_schedule_campaign_content_strategy(self):
        """Test content strategy section details"""
        result = server.schedule_campaign(
            campaign_name="Content Test",
            start_date="2025-01-01",
            end_date="2025-01-31",
            post_frequency="daily",
            platforms=["facebook", "twitter"],
            campaign_goals="Build community",
        )

        assert "promotional, educational, engaging" in result
        assert "Content mix ratios" in result
        assert "Platform-specific adaptations" in result

    def test_schedule_campaign_engagement_strategy(self):
        """Test engagement strategy section details"""
        result = server.schedule_campaign(
            campaign_name="Engagement Test",
            start_date="2025-01-01",
            end_date="2025-01-31",
            post_frequency="daily",
            platforms=["twitter"],
            campaign_goals="Community growth",
        )

        assert "Peak posting times" in result
        assert "Community interaction plan" in result
        assert "Response templates" in result

    def test_schedule_campaign_performance_tracking(self):
        """Test performance tracking section details"""
        result = server.schedule_campaign(
            campaign_name="Performance Test",
            start_date="2025-01-01",
            end_date="2025-01-31",
            post_frequency="daily",
            platforms=["linkedin"],
            campaign_goals="Lead generation",
        )

        assert "Key metrics to monitor" in result
        assert "Success criteria" in result
        assert "Adjustment triggers" in result

    def test_schedule_campaign_goals_reference(self):
        """Test that campaign goals are referenced throughout"""
        goals = "Increase website traffic by 50% and generate 100 qualified leads"
        result = server.schedule_campaign(
            campaign_name="Goal-Focused Campaign",
            start_date="2025-01-01",
            end_date="2025-03-31",
            post_frequency="daily",
            platforms=["linkedin", "twitter"],
            campaign_goals=goals,
        )

        # Goals should appear multiple times
        assert result.count(goals) >= 2
