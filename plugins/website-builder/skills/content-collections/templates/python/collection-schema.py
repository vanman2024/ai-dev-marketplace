"""
collection-schema.py
Python equivalent of collection schemas for build scripts and content generation
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List, Dict
from enum import Enum


class PublishingStatus(Enum):
    """Publishing status for content"""
    DRAFT = "draft"
    PUBLISHED = "published"
    SCHEDULED = "scheduled"
    ARCHIVED = "archived"


@dataclass
class BlogPostSchema:
    """
    Blog post schema - Python equivalent of Zod schema
    Use for content generation, validation, and build scripts
    """
    # Core content fields
    title: str
    description: str
    pub_date: datetime
    author: str

    # Optional fields with defaults
    updated_date: Optional[datetime] = None
    tags: List[str] = field(default_factory=list)
    categories: List[str] = field(default_factory=list)

    # Media
    hero_image: Optional[str] = None
    hero_image_alt: Optional[str] = None

    # Publishing control
    draft: bool = False
    featured: bool = False

    # SEO
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None

    # Reading metadata
    reading_time: Optional[int] = None  # minutes
    excerpt: Optional[str] = None

    # Series
    series: Optional[str] = None
    series_order: Optional[int] = None
    related_posts: List[str] = field(default_factory=list)

    def to_frontmatter(self) -> str:
        """Convert to YAML frontmatter for markdown files"""
        lines = ["---"]
        lines.append(f'title: "{self.title}"')
        lines.append(f'description: "{self.description}"')
        lines.append(f'pubDate: {self.pub_date.isoformat()}')
        lines.append(f'author: "{self.author}"')

        if self.updated_date:
            lines.append(f'updatedDate: {self.updated_date.isoformat()}')

        if self.tags:
            lines.append(f'tags: {self.tags}')

        if self.categories:
            lines.append(f'categories: {self.categories}')

        if self.hero_image:
            lines.append(f'heroImage: "{self.hero_image}"')
            if self.hero_image_alt:
                lines.append(f'heroImageAlt: "{self.hero_image_alt}"')

        lines.append(f'draft: {str(self.draft).lower()}')
        lines.append(f'featured: {str(self.featured).lower()}')

        if self.reading_time:
            lines.append(f'readingTime: {self.reading_time}')

        if self.series:
            lines.append(f'series: "{self.series}"')
            if self.series_order:
                lines.append(f'seriesOrder: {self.series_order}')

        lines.append("---")
        return "\n".join(lines)

    def validate(self) -> List[str]:
        """Validate schema and return list of errors"""
        errors = []

        if not self.title or len(self.title) < 1:
            errors.append("Title is required")
        elif len(self.title) > 100:
            errors.append("Title too long (max 100 characters)")

        if not self.description or len(self.description) < 10:
            errors.append("Description too short (min 10 characters)")
        elif len(self.description) > 160:
            errors.append("Description too long (max 160 characters)")

        if not self.author:
            errors.append("Author is required")

        if self.excerpt and len(self.excerpt) > 300:
            errors.append("Excerpt too long (max 300 characters)")

        return errors


@dataclass
class DocsSchema:
    """Documentation collection schema"""
    title: str
    description: str
    category: str

    # Optional fields
    order: int = 999
    sidebar_label: Optional[str] = None
    parent: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    draft: bool = False
    toc: bool = True
    toc_depth: int = 3

    # Dates
    created_date: Optional[datetime] = None
    last_updated: Optional[datetime] = None

    # Versioning
    version: Optional[str] = None
    deprecated: bool = False

    def to_frontmatter(self) -> str:
        """Convert to YAML frontmatter"""
        lines = ["---"]
        lines.append(f'title: "{self.title}"')
        lines.append(f'description: "{self.description}"')
        lines.append(f'category: "{self.category}"')
        lines.append(f'order: {self.order}')

        if self.sidebar_label:
            lines.append(f'sidebar_label: "{self.sidebar_label}"')

        if self.parent:
            lines.append(f'parent: "{self.parent}"')

        if self.tags:
            lines.append(f'tags: {self.tags}')

        lines.append(f'draft: {str(self.draft).lower()}')
        lines.append(f'toc: {str(self.toc).lower()}')
        lines.append(f'tocDepth: {self.toc_depth}')

        if self.last_updated:
            lines.append(f'lastUpdated: {self.last_updated.isoformat()}')

        if self.version:
            lines.append(f'version: "{self.version}"')

        if self.deprecated:
            lines.append(f'deprecated: true')

        lines.append("---")
        return "\n".join(lines)


@dataclass
class AuthorSchema:
    """Author collection schema"""
    name: str
    bio: str

    # Optional fields
    title: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    avatar: Optional[str] = None

    # Social links
    twitter: Optional[str] = None
    github: Optional[str] = None
    linkedin: Optional[str] = None

    # Metadata
    role: str = "author"
    featured: bool = False

    def to_frontmatter(self) -> str:
        """Convert to YAML frontmatter"""
        lines = ["---"]
        lines.append(f'name: "{self.name}"')
        lines.append(f'bio: "{self.bio}"')

        if self.title:
            lines.append(f'title: "{self.title}"')

        if self.email:
            lines.append(f'email: "{self.email}"')

        if self.avatar:
            lines.append(f'avatar: "{self.avatar}"')

        # Social links
        social_links = []
        if self.twitter:
            social_links.append(f'  twitter: "{self.twitter}"')
        if self.github:
            social_links.append(f'  github: "{self.github}"')
        if self.linkedin:
            social_links.append(f'  linkedin: "{self.linkedin}"')

        if social_links:
            lines.append('social:')
            lines.extend(social_links)

        lines.append(f'role: "{self.role}"')
        lines.append(f'featured: {str(self.featured).lower()}')

        lines.append("---")
        return "\n".join(lines)


def create_blog_post(
    title: str,
    description: str,
    author: str,
    content: str,
    tags: List[str] = None,
    **kwargs
) -> str:
    """
    Create a complete blog post markdown file

    Args:
        title: Post title
        description: Post description
        author: Author name
        content: Markdown content body
        tags: List of tags
        **kwargs: Additional BlogPostSchema fields

    Returns:
        Complete markdown file content with frontmatter
    """
    post = BlogPostSchema(
        title=title,
        description=description,
        pub_date=datetime.now(),
        author=author,
        tags=tags or [],
        **kwargs
    )

    # Validate
    errors = post.validate()
    if errors:
        raise ValueError(f"Validation errors: {', '.join(errors)}")

    frontmatter = post.to_frontmatter()
    return f"{frontmatter}\n\n{content}"


# Example usage
if __name__ == "__main__":
    # Create blog post
    post = BlogPostSchema(
        title="Getting Started with Astro Content Collections",
        description="Learn how to use Astro's content collections for type-safe content management",
        pub_date=datetime.now(),
        author="Jane Doe",
        tags=["astro", "tutorial", "content-collections"],
        draft=False,
        featured=True,
    )

    print("Blog Post Frontmatter:")
    print(post.to_frontmatter())
    print()

    # Validate
    errors = post.validate()
    if errors:
        print("Validation errors:", errors)
    else:
        print("✓ Validation passed")

    print()

    # Create complete post
    content = """
## Introduction

Astro content collections provide type-safe content management...

## Setup

First, create your schema...
"""

    full_post = create_blog_post(
        title="Content Collections Tutorial",
        description="A comprehensive guide to Astro content collections",
        author="Jane Doe",
        content=content,
        tags=["astro", "tutorial"],
        featured=True
    )

    print("Complete Post:")
    print(full_post[:200] + "...")
