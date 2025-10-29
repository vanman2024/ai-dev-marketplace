#!/bin/bash
# query-builder.sh
# Generate optimized query patterns for content collections

set -e

COLLECTION_NAME="$1"
QUERY_TYPE="${2:-all}"

if [ -z "$COLLECTION_NAME" ]; then
  echo "Usage: $0 <collection-name> [query-type]"
  echo ""
  echo "Query types:"
  echo "  all         - Get all entries (default)"
  echo "  filtered    - Filter by frontmatter fields"
  echo "  sorted      - Sort by date/title/field"
  echo "  paginated   - Paginate results"
  echo "  related     - Find related content"
  echo ""
  echo "Example: $0 blog filtered"
  exit 1
fi

echo "Building query pattern for collection: $COLLECTION_NAME"
echo "Query type: $QUERY_TYPE"
echo ""

case "$QUERY_TYPE" in
  all)
    cat << 'EOF'
// Get all entries from collection
import { getCollection } from 'astro:content';

const allPosts = await getCollection('COLLECTION_NAME');

// Exclude drafts
const publishedPosts = await getCollection('COLLECTION_NAME', ({ data }) => {
  return data.draft !== true;
});

console.log(`Found ${publishedPosts.length} published posts`);
EOF
    ;;

  filtered)
    cat << 'EOF'
// Filter entries by frontmatter fields
import { getCollection } from 'astro:content';

// Filter by tag
const taggedPosts = await getCollection('COLLECTION_NAME', ({ data }) => {
  return data.tags?.includes('your-tag');
});

// Filter by date range
const recentPosts = await getCollection('COLLECTION_NAME', ({ data }) => {
  const cutoffDate = new Date('2024-01-01');
  return data.pubDate >= cutoffDate;
});

// Filter by multiple conditions
const filteredPosts = await getCollection('COLLECTION_NAME', ({ data }) => {
  return (
    data.draft !== true &&
    data.tags?.includes('featured') &&
    data.pubDate >= new Date('2024-01-01')
  );
});

console.log(`Found ${filteredPosts.length} filtered posts`);
EOF
    ;;

  sorted)
    cat << 'EOF'
// Sort entries by various fields
import { getCollection } from 'astro:content';

const posts = await getCollection('COLLECTION_NAME', ({ data }) => {
  return data.draft !== true;
});

// Sort by date descending (newest first)
const sortedByDate = posts.sort((a, b) =>
  b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);

// Sort by title alphabetically
const sortedByTitle = posts.sort((a, b) =>
  a.data.title.localeCompare(b.data.title)
);

// Sort by custom field
const sortedByOrder = posts.sort((a, b) =>
  (a.data.order || 999) - (b.data.order || 999)
);

// Multi-field sort (category then date)
const multiSorted = posts.sort((a, b) => {
  if (a.data.category !== b.data.category) {
    return a.data.category.localeCompare(b.data.category);
  }
  return b.data.pubDate.valueOf() - a.data.pubDate.valueOf();
});

console.log(`Sorted ${sortedByDate.length} posts`);
EOF
    ;;

  paginated)
    cat << 'EOF'
// Paginate collection entries
import { getCollection } from 'astro:content';

const POSTS_PER_PAGE = 10;

async function getPaginatedPosts(page = 1) {
  const allPosts = await getCollection('COLLECTION_NAME', ({ data }) => {
    return data.draft !== true;
  });

  // Sort by date descending
  const sortedPosts = allPosts.sort((a, b) =>
    b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
  );

  const totalPages = Math.ceil(sortedPosts.length / POSTS_PER_PAGE);
  const startIndex = (page - 1) * POSTS_PER_PAGE;
  const endIndex = startIndex + POSTS_PER_PAGE;

  const posts = sortedPosts.slice(startIndex, endIndex);

  return {
    posts,
    currentPage: page,
    totalPages,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
    totalPosts: sortedPosts.length,
  };
}

// Usage in page
export async function getStaticPaths() {
  const allPosts = await getCollection('COLLECTION_NAME');
  const totalPages = Math.ceil(allPosts.length / POSTS_PER_PAGE);

  return Array.from({ length: totalPages }, (_, i) => ({
    params: { page: String(i + 1) },
  }));
}

const page = Number(Astro.params.page || 1);
const { posts, currentPage, totalPages, hasNextPage, hasPrevPage } =
  await getPaginatedPosts(page);

console.log(`Page ${currentPage} of ${totalPages}`);
EOF
    ;;

  related)
    cat << 'EOF'
// Find related content based on tags, category, or other fields
import { getCollection, getEntry } from 'astro:content';

async function getRelatedPosts(currentSlug: string, limit = 5) {
  // Get current post
  const currentPost = await getEntry('COLLECTION_NAME', currentSlug);
  if (!currentPost) return [];

  // Get all other posts
  const allPosts = await getCollection('COLLECTION_NAME', ({ data, slug }) => {
    return data.draft !== true && slug !== currentSlug;
  });

  // Calculate relevance score based on shared tags
  const scoredPosts = allPosts.map(post => {
    let score = 0;

    // Tag matching (higher weight)
    const sharedTags = post.data.tags?.filter(tag =>
      currentPost.data.tags?.includes(tag)
    );
    score += (sharedTags?.length || 0) * 3;

    // Category matching
    if (post.data.category === currentPost.data.category) {
      score += 2;
    }

    // Author matching
    if (post.data.author === currentPost.data.author) {
      score += 1;
    }

    // Recency boost (posts within 30 days)
    const daysDiff = Math.abs(
      post.data.pubDate.valueOf() - currentPost.data.pubDate.valueOf()
    ) / (1000 * 60 * 60 * 24);
    if (daysDiff <= 30) {
      score += 1;
    }

    return { post, score };
  });

  // Sort by score and return top results
  return scoredPosts
    .filter(({ score }) => score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ post }) => post);
}

// Usage
const relatedPosts = await getRelatedPosts('current-post-slug');
console.log(`Found ${relatedPosts.length} related posts`);
EOF
    ;;

  *)
    echo "Error: Unknown query type: $QUERY_TYPE"
    echo "Use: all, filtered, sorted, paginated, or related"
    exit 1
    ;;
esac

# Replace placeholder with actual collection name
sed "s/COLLECTION_NAME/$COLLECTION_NAME/g"

echo ""
echo ""
echo "Query pattern generated successfully!"
echo ""
echo "Copy the code above and paste into your .astro file."
echo "Adjust the query parameters as needed for your use case."
