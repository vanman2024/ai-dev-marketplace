#!/bin/bash
# validate-output.sh
# Check quality of generated assets (images, videos, content)

set -e

# Parse arguments
TYPE=""
PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE="$2"
            shift 2
            ;;
        --path)
            PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            shift
            ;;
    esac
done

if [ -z "$TYPE" ] || [ -z "$PATH" ]; then
    echo "Usage: $0 --type TYPE --path PATH"
    echo
    echo "Types:"
    echo "  image    Validate image files (PNG, JPEG, WebP)"
    echo "  video    Validate video files (MP4, WebM)"
    echo "  content  Validate content files (MD, MDX, TXT, HTML)"
    echo
    echo "Examples:"
    echo "  $0 --type image --path /path/to/hero-image.png"
    echo "  $0 --type content --path /path/to/blog-post.md"
    echo "  $0 --type video --path /path/to/promo-video.mp4"
    exit 1
fi

echo "=== AI Generation Output Validation ==="
echo

# Check if file exists
if [ ! -f "$PATH" ]; then
    echo "✗ File not found: $PATH"
    exit 1
fi

echo "✓ File exists: $PATH"
echo

# Validate based on type
case "$TYPE" in
    image)
        echo "Validating image..."
        echo

        # Check if ImageMagick is installed for better validation
        if command -v identify &> /dev/null; then
            echo "Image information:"
            identify -verbose "$PATH" | grep -E "Format:|Geometry:|Filesize:|Colorspace:|Quality:" || true
            echo

            # Extract dimensions
            DIMENSIONS=$(identify -format "%wx%h" "$PATH")
            WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
            HEIGHT=$(echo "$DIMENSIONS" | cut -d'x' -f2)

            echo "Validation checks:"
            echo "  • Dimensions: ${WIDTH}x${HEIGHT}"

            # Check minimum dimensions
            if [ "$WIDTH" -lt 100 ] || [ "$HEIGHT" -lt 100 ]; then
                echo "  ✗ Image too small (minimum 100x100)"
            else
                echo "  ✓ Dimensions are acceptable"
            fi

            # Check aspect ratios
            RATIO=$(echo "scale=2; $WIDTH / $HEIGHT" | bc -l)
            echo "  • Aspect ratio: $RATIO:1"

            # Common aspect ratios
            if echo "$RATIO" | grep -qE "^1\.00|^0\.99|^1\.01"; then
                echo "    (1:1 - Square, good for products/avatars)"
            elif echo "$RATIO" | grep -qE "^1\.77|^1\.78"; then
                echo "    (16:9 - Widescreen, good for hero sections)"
            elif echo "$RATIO" | grep -qE "^1\.33"; then
                echo "    (4:3 - Traditional, good for content)"
            elif echo "$RATIO" | grep -qE "^0\.56|^0\.57"; then
                echo "    (9:16 - Portrait, good for mobile/stories)"
            fi

            # Check file size
            FILESIZE=$(stat -f%z "$PATH" 2>/dev/null || stat -c%s "$PATH" 2>/dev/null)
            FILESIZE_MB=$(echo "scale=2; $FILESIZE / 1024 / 1024" | bc -l)
            echo "  • File size: ${FILESIZE_MB} MB"

            if [ $(echo "$FILESIZE > 5242880" | bc -l) -eq 1 ]; then
                echo "  ⚠ Large file size (>5MB), consider optimization"
            else
                echo "  ✓ File size is reasonable"
            fi

        else
            echo "○ ImageMagick not installed, basic validation only"
            echo "  Install for detailed analysis: apt install imagemagick"
            echo

            # Basic file type check
            FILE_TYPE=$(file -b "$PATH")
            echo "  File type: $FILE_TYPE"

            if echo "$FILE_TYPE" | grep -qiE "png|jpeg|jpg|webp"; then
                echo "  ✓ Valid image format"
            else
                echo "  ✗ Invalid or unsupported image format"
                exit 1
            fi
        fi

        echo
        echo "Recommendations:"
        echo "  • Use WebP format for web (better compression)"
        echo "  • Optimize images before deployment"
        echo "  • Use lazy loading for below-the-fold images"
        echo "  • Consider responsive image formats (srcset)"
        ;;

    video)
        echo "Validating video..."
        echo

        # Check if ffprobe is installed
        if command -v ffprobe &> /dev/null; then
            echo "Video information:"
            ffprobe -v error -show_format -show_streams "$PATH" 2>&1 | grep -E "codec_name|width|height|duration|bit_rate|size" || true
            echo

            # Extract duration
            DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$PATH" 2>/dev/null)
            echo "Validation checks:"
            echo "  • Duration: ${DURATION}s"

            if [ $(echo "$DURATION > 30" | bc -l) -eq 1 ]; then
                echo "  ⚠ Long video (>${DURATION}s), consider splitting or shortening"
            else
                echo "  ✓ Duration is reasonable"
            fi

            # Check file size
            FILESIZE=$(stat -f%z "$PATH" 2>/dev/null || stat -c%s "$PATH" 2>/dev/null)
            FILESIZE_MB=$(echo "scale=2; $FILESIZE / 1024 / 1024" | bc -l)
            echo "  • File size: ${FILESIZE_MB} MB"

            if [ $(echo "$FILESIZE > 52428800" | bc -l) -eq 1 ]; then
                echo "  ⚠ Very large file (>50MB), consider compression"
            else
                echo "  ✓ File size is acceptable"
            fi

        else
            echo "○ ffprobe not installed, basic validation only"
            echo "  Install for detailed analysis: apt install ffmpeg"
            echo

            FILE_TYPE=$(file -b "$PATH")
            echo "  File type: $FILE_TYPE"

            if echo "$FILE_TYPE" | grep -qiE "mp4|webm|video"; then
                echo "  ✓ Valid video format"
            else
                echo "  ✗ Invalid or unsupported video format"
                exit 1
            fi
        fi

        echo
        echo "Recommendations:"
        echo "  • Use MP4 (H.264) for best compatibility"
        echo "  • Provide WebM as alternative for modern browsers"
        echo "  • Include video poster image for loading state"
        echo "  • Add appropriate video controls and accessibility"
        ;;

    content)
        echo "Validating content..."
        echo

        # Check file size
        FILESIZE=$(stat -f%z "$PATH" 2>/dev/null || stat -c%s "$PATH" 2>/dev/null)
        WORD_COUNT=$(wc -w < "$PATH")
        CHAR_COUNT=$(wc -m < "$PATH")
        LINE_COUNT=$(wc -l < "$PATH")

        echo "Content statistics:"
        echo "  • Word count: $WORD_COUNT words"
        echo "  • Character count: $CHAR_COUNT characters"
        echo "  • Line count: $LINE_COUNT lines"
        echo "  • File size: $FILESIZE bytes"
        echo

        echo "Validation checks:"

        if [ "$WORD_COUNT" -lt 50 ]; then
            echo "  ⚠ Very short content (<50 words)"
        elif [ "$WORD_COUNT" -gt 5000 ]; then
            echo "  ⚠ Very long content (>5000 words), consider splitting"
        else
            echo "  ✓ Content length is reasonable"
        fi

        # Check for common markdown/MDX syntax
        if echo "$PATH" | grep -qE "\.mdx?$"; then
            echo "  • Format: Markdown/MDX"

            # Check for frontmatter
            if head -1 "$PATH" | grep -q "^---"; then
                echo "    ✓ Has frontmatter"
            else
                echo "    ○ No frontmatter detected"
            fi

            # Check for headings
            HEADING_COUNT=$(grep -cE "^#{1,6} " "$PATH" || true)
            echo "    • Headings: $HEADING_COUNT"

            # Check for links
            LINK_COUNT=$(grep -coE "\[.*\]\(.*\)" "$PATH" || true)
            echo "    • Links: $LINK_COUNT"

            # Check for images
            IMAGE_COUNT=$(grep -coE "!\[.*\]\(.*\)" "$PATH" || true)
            echo "    • Images: $IMAGE_COUNT"
        fi

        # Basic readability check
        AVG_WORD_LENGTH=$(echo "scale=2; $CHAR_COUNT / $WORD_COUNT" | bc -l)
        echo "  • Average word length: ${AVG_WORD_LENGTH} characters"

        if [ $(echo "$AVG_WORD_LENGTH > 7" | bc -l) -eq 1 ]; then
            echo "    ⚠ Long average word length, consider simplifying"
        fi

        echo
        echo "Recommendations:"
        echo "  • Review content for tone and style consistency"
        echo "  • Check for proper heading hierarchy (H1 -> H2 -> H3)"
        echo "  • Verify all links and image references"
        echo "  • Run spell check and grammar check"
        echo "  • Ensure SEO metadata is included"
        ;;

    *)
        echo "✗ Unknown type: $TYPE"
        exit 1
        ;;
esac

echo
echo "✓ Validation complete"
