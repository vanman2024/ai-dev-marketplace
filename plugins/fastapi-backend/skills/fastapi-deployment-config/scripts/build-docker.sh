#!/bin/bash

# build-docker.sh - Build optimized Docker images for FastAPI applications
# Usage: ./build-docker.sh [OPTIONS]

set -euo pipefail

# Default values
PLATFORM="linux/amd64"
TAG="fastapi-app:latest"
NO_CACHE=""
VERBOSE=""
APP_DIR="."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display help
show_help() {
    cat << EOF
FastAPI Docker Build Script

Usage: ./build-docker.sh [OPTIONS]

Options:
  --platform=PLATFORM   Target platform (default: linux/amd64)
                        Examples: linux/amd64, linux/arm64, linux/arm/v7
  --tag=TAG            Docker image tag (default: fastapi-app:latest)
  --app-dir=DIR        Application directory (default: .)
  --no-cache           Build without using cache
  --verbose            Show detailed build output
  --help               Display this help message

Examples:
  ./build-docker.sh --tag myapp:v1.0.0
  ./build-docker.sh --platform=linux/arm64 --tag myapp:latest
  ./build-docker.sh --no-cache --verbose
  ./build-docker.sh --app-dir=/path/to/app --tag myapp:prod

Build Process:
  1. Validates Dockerfile existence
  2. Checks requirements.txt
  3. Builds multi-stage Docker image
  4. Runs basic validation on built image
  5. Displays image size and details

EOF
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --platform=*)
            PLATFORM="${arg#*=}"
            shift
            ;;
        --tag=*)
            TAG="${arg#*=}"
            shift
            ;;
        --app-dir=*)
            APP_DIR="${arg#*=}"
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --verbose)
            VERBOSE="--progress=plain"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Change to app directory
cd "$APP_DIR"

print_info "Starting Docker build process..."
print_info "Platform: $PLATFORM"
print_info "Tag: $TAG"
print_info "App Directory: $(pwd)"

# Validate Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found in $(pwd)"
    print_info "Looking for Dockerfile in skill templates..."

    # Try to find skill template
    SKILL_DOCKERFILE="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/fastapi-backend/skills/fastapi-deployment-config/templates/Dockerfile"
    if [ -f "$SKILL_DOCKERFILE" ]; then
        print_warning "Copying Dockerfile template from skill..."
        cp "$SKILL_DOCKERFILE" ./Dockerfile
        print_info "Dockerfile created from template"
    else
        print_error "Could not find Dockerfile template"
        exit 1
    fi
fi

# Validate requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    print_error "requirements.txt not found in $(pwd)"
    print_warning "FastAPI applications require requirements.txt for dependencies"
    exit 1
fi

print_info "Validating requirements.txt..."
if ! python3 -m pip install --dry-run -r requirements.txt > /dev/null 2>&1; then
    print_warning "Some dependencies in requirements.txt may have issues"
    print_info "Continuing with build anyway..."
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check Docker daemon
if ! docker info > /dev/null 2>&1; then
    print_error "Docker daemon is not running"
    print_info "Start Docker with: sudo systemctl start docker"
    exit 1
fi

# Build Docker image
print_info "Building Docker image..."
BUILD_CMD="docker build --platform=$PLATFORM --tag=$TAG $NO_CACHE $VERBOSE ."

if [ -n "$VERBOSE" ]; then
    print_info "Build command: $BUILD_CMD"
fi

# Execute build
if eval "$BUILD_CMD"; then
    print_info "Docker image built successfully!"
else
    print_error "Docker build failed"
    exit 1
fi

# Validate built image
print_info "Validating built image..."

# Check image exists
if ! docker image inspect "$TAG" > /dev/null 2>&1; then
    print_error "Built image not found: $TAG"
    exit 1
fi

# Get image details
IMAGE_SIZE=$(docker image inspect "$TAG" --format='{{.Size}}' | awk '{print $1/1024/1024 " MB"}')
IMAGE_ID=$(docker image inspect "$TAG" --format='{{.Id}}' | cut -d':' -f2 | cut -c1-12)
IMAGE_CREATED=$(docker image inspect "$TAG" --format='{{.Created}}')

print_info "Image Details:"
echo "  ID: $IMAGE_ID"
echo "  Tag: $TAG"
echo "  Size: $IMAGE_SIZE"
echo "  Created: $IMAGE_CREATED"
echo "  Platform: $PLATFORM"

# Test image can run (basic validation)
print_info "Running basic container validation..."
CONTAINER_ID=$(docker run -d --rm "$TAG" sleep 5 2>&1 || true)

if [ -n "$CONTAINER_ID" ] && [ "$CONTAINER_ID" != "docker:"* ]; then
    print_info "Container started successfully (ID: ${CONTAINER_ID:0:12})"
    docker stop "$CONTAINER_ID" > /dev/null 2>&1 || true
else
    print_warning "Could not start test container (this may be expected for some configurations)"
fi

# Check for security issues (basic)
print_info "Running basic security checks..."
USER_CHECK=$(docker image inspect "$TAG" --format='{{.Config.User}}')
if [ -z "$USER_CHECK" ] || [ "$USER_CHECK" = "root" ] || [ "$USER_CHECK" = "0" ]; then
    print_warning "Image may be running as root user (security concern)"
    print_info "Consider adding USER directive in Dockerfile"
else
    print_info "Image running as non-root user: $USER_CHECK"
fi

# Success summary
echo ""
print_info "============================================"
print_info "Docker build completed successfully!"
print_info "============================================"
echo ""
print_info "Next Steps:"
echo "  1. Test locally:     docker run -p 8000:8000 $TAG"
echo "  2. Push to registry: docker push $TAG"
echo "  3. Deploy to platform (see examples/ directory)"
echo ""
print_info "For deployment help, see:"
echo "  - Railway: examples/railway_setup.md"
echo "  - DigitalOcean: examples/digitalocean_setup.md"
echo "  - AWS: examples/aws_setup.md"
echo ""

exit 0
