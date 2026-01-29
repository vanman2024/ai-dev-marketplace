#!/bin/bash
# Create managed PostgreSQL database
# Usage: ./create-postgres.sh <db-name> <region>

DB_NAME=${1:-"my-database"}
REGION=${2:-"nyc3"}
SIZE=${3:-"db-s-1vcpu-1gb"}

echo "🗄️ Creating PostgreSQL database: $DB_NAME in $REGION"

doctl databases create "$DB_NAME" \
    --engine pg \
    --region "$REGION" \
    --size "$SIZE" \
    --version 16 \
    --num-nodes 1

echo "✅ Database created. Get connection info with:"
echo "   doctl databases connection <db-id>"
