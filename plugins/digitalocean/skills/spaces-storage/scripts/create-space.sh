#!/bin/bash
# Create Spaces bucket
# Usage: ./create-space.sh <bucket-name> <region>

BUCKET_NAME=${1:-"my-bucket"}
REGION=${2:-"nyc3"}

echo "📦 Creating Space: $BUCKET_NAME in $REGION"

# Spaces uses S3-compatible API
# Configure s3cmd first with your Spaces keys

s3cmd mb "s3://$BUCKET_NAME" --region="$REGION"

echo "✅ Space created: $BUCKET_NAME.$REGION.digitaloceanspaces.com"
