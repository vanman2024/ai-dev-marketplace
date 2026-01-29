#!/bin/bash
# Create VPC for private networking
# Usage: ./create-vpc.sh <vpc-name> <region>

VPC_NAME=${1:-"my-vpc"}
REGION=${2:-"nyc3"}

echo "🌐 Creating VPC: $VPC_NAME in $REGION"

doctl vpcs create \
    --name "$VPC_NAME" \
    --region "$REGION" \
    --ip-range "10.10.10.0/24"

echo "✅ VPC created"
