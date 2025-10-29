"""
query-patterns.py
Python query patterns for content collections
Use for build scripts, static site generation, and content processing
"""

import os
import re
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Callable
import frontmatter
from dataclasses import dataclass


@dataclass
class ContentEntry:
    """Represents a content collection entry"""
    slug: str
    file_path: str
    data: Dict
    content: str
    collection: str


class ContentCollectionQuery:
    """Query content collections from Python build scripts"""

    def __init__(self, content_dir: str = "src/content"):
        self.content_dir = Path(content_dir)

    def get_collection(
        self,
        collection_name: str,
        filter_fn: Optional[Callable[[Dict], bool]] = None
    ) -> List[ContentEntry]:
        """
        Get all entries from a collection

        Args:
            collection_name: Name of collection (e.g., 'blog', 'docs')
            filter_fn: Optional filter function that takes frontmatter data

        Returns:
            List of ContentEntry objects
        """
        collection_path = self.content_dir / collection_name

        if not collection_path.exists():
            return []

        entries = []

        for file_path in collection_path.rglob("*.md"):
            try:
                post = frontmatter.load(file_path)

                # Apply filter if provided
                if filter_fn and not filter_fn(post.metadata):
                    continue

                # Calculate slug from file path
                slug = str(file_path.relative_to(collection_path)).replace(".md", "")

                entry = ContentEntry(
                    slug=slug,
                    file_path=str(file_path),
                    data=post.metadata,
                    content=post.content,
                    collection=collection_name
                )

                entries.append(entry)

            except Exception as e:
                print(f"Error loading {file_path}: {e}")
                continue

        return entries

    def get_entry(self, collection_name: str, slug: str) -> Optional[ContentEntry]:
        """Get single entry by slug"""
        entries = self.get_collection(collection_name)

        for entry in entries:
            if entry.slug == slug:
                return entry

        return None

    def get_published_posts(self, collection_name: str = "blog") -> List[ContentEntry]:
        """Get all published posts (exclude drafts)"""
        return self.get_collection(
            collection_name,
            lambda data: data.get("draft", False) is not True
        )

    def get_posts_by_tag(self, tag: str, collection_name: str = "blog") -> List[ContentEntry]:
        """Get posts filtered by tag"""
        return self.get_collection(
            collection_name,
            lambda data: (
                data.get("draft", False) is not True and
                tag in data.get("tags", [])
            )
        )

    def get_posts_by_author(self, author: str, collection_name: str = "blog") -> List[ContentEntry]:
        """Get posts by specific author"""
        return self.get_collection(
            collection_name,
            lambda data: (
                data.get("draft", False) is not True and
                data.get("author") == author
            )
        )

    def get_recent_posts(self, limit: int = 10, collection_name: str = "blog") -> List[ContentEntry]:
        """Get most recent posts sorted by publication date"""
        posts = self.get_published_posts(collection_name)

        # Sort by pubDate descending
        sorted_posts = sorted(
            posts,
            key=lambda p: p.data.get("pubDate", datetime.min),
            reverse=True
        )

        return sorted_posts[:limit]

    def get_featured_posts(self, collection_name: str = "blog") -> List[ContentEntry]:
        """Get featured posts"""
        return self.get_collection(
            collection_name,
            lambda data: (
                data.get("draft", False) is not True and
                data.get("featured", False) is True
            )
        )

    def search_posts(self, keyword: str, collection_name: str = "blog") -> List[ContentEntry]:
        """Search posts by keyword in title and description"""
        keyword_lower = keyword.lower()

        def matches_keyword(data):
            if data.get("draft", False):
                return False

            title = data.get("title", "").lower()
            description = data.get("description", "").lower()

            return keyword_lower in title or keyword_lower in description

        return self.get_collection(collection_name, matches_keyword)

    def get_posts_grouped_by_tag(self, collection_name: str = "blog") -> Dict[str, List[ContentEntry]]:
        """Get posts grouped by tag"""
        posts = self.get_published_posts(collection_name)

        grouped: Dict[str, List[ContentEntry]] = {}

        for post in posts:
            tags = post.data.get("tags", [])
            for tag in tags:
                if tag not in grouped:
                    grouped[tag] = []
                grouped[tag].append(post)

        return grouped

    def get_all_tags_with_counts(self, collection_name: str = "blog") -> List[Dict]:
        """Get all unique tags with post counts"""
        posts = self.get_published_posts(collection_name)

        tag_counts: Dict[str, int] = {}

        for post in posts:
            tags = post.data.get("tags", [])
            for tag in tags:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1

        # Convert to list and sort by count
        result = [
            {"tag": tag, "count": count}
            for tag, count in tag_counts.items()
        ]

        return sorted(result, key=lambda x: x["count"], reverse=True)

    def get_related_posts(
        self,
        current_slug: str,
        limit: int = 5,
        collection_name: str = "blog"
    ) -> List[ContentEntry]:
        """Get related posts based on shared tags"""
        current_post = self.get_entry(collection_name, current_slug)

        if not current_post:
            return []

        current_tags = set(current_post.data.get("tags", []))

        # Get all other posts
        all_posts = self.get_collection(
            collection_name,
            lambda data: data.get("draft", False) is not True
        )

        # Filter out current post
        other_posts = [p for p in all_posts if p.slug != current_slug]

        # Score posts by shared tags
        scored_posts = []
        for post in other_posts:
            post_tags = set(post.data.get("tags", []))
            shared_tags = current_tags & post_tags
            score = len(shared_tags)

            if score > 0:
                scored_posts.append((post, score))

        # Sort by score and return top results
        scored_posts.sort(key=lambda x: x[1], reverse=True)

        return [post for post, _ in scored_posts[:limit]]

    def get_archive_structure(self, collection_name: str = "blog") -> Dict[int, Dict[int, List[ContentEntry]]]:
        """Get posts grouped by year and month"""
        posts = self.get_published_posts(collection_name)

        archive: Dict[int, Dict[int, List[ContentEntry]]] = {}

        for post in posts:
            pub_date = post.data.get("pubDate")
            if not pub_date:
                continue

            year = pub_date.year
            month = pub_date.month

            if year not in archive:
                archive[year] = {}
            if month not in archive[year]:
                archive[year][month] = []

            archive[year][month].append(post)

        return archive

    def get_post_statistics(self, collection_name: str = "blog") -> Dict:
        """Get collection statistics"""
        all_posts = self.get_collection(collection_name)
        published = self.get_published_posts(collection_name)

        # Count by author
        by_author: Dict[str, int] = {}
        for post in all_posts:
            author = post.data.get("author", "Unknown")
            by_author[author] = by_author.get(author, 0) + 1

        # Count by tag
        by_tag: Dict[str, int] = {}
        total_tags = 0
        for post in all_posts:
            tags = post.data.get("tags", [])
            for tag in tags:
                by_tag[tag] = by_tag.get(tag, 0) + 1
                total_tags += 1

        avg_tags = total_tags / len(all_posts) if all_posts else 0

        return {
            "total": len(all_posts),
            "published": len(published),
            "drafts": len(all_posts) - len(published),
            "featured": len([p for p in all_posts if p.data.get("featured")]),
            "by_author": by_author,
            "by_tag": by_tag,
            "avg_tags_per_post": avg_tags,
        }


# Example usage
if __name__ == "__main__":
    # Initialize query
    query = ContentCollectionQuery("src/content")

    # Get all published posts
    posts = query.get_published_posts()
    print(f"Found {len(posts)} published posts")

    # Get recent posts
    recent = query.get_recent_posts(5)
    print(f"\nRecent posts:")
    for post in recent:
        print(f"  - {post.data.get('title')}")

    # Search posts
    results = query.search_posts("astro")
    print(f"\nSearch results for 'astro': {len(results)} posts")

    # Get tags with counts
    tags = query.get_all_tags_with_counts()
    print(f"\nTop tags:")
    for tag_info in tags[:5]:
        print(f"  - {tag_info['tag']}: {tag_info['count']} posts")

    # Get statistics
    stats = query.get_post_statistics()
    print(f"\nStatistics:")
    print(f"  Total: {stats['total']}")
    print(f"  Published: {stats['published']}")
    print(f"  Drafts: {stats['drafts']}")
    print(f"  Avg tags per post: {stats['avg_tags_per_post']:.1f}")
